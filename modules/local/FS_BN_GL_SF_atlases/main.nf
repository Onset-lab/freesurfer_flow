process FS_BN_GL_SF_ATLASES {
    tag "$meta.id"

    container "${ 'onsetlab/freesurfer-flow:1.0.0' }"

    input:
        tuple val(meta), path(folder)

    output:
        path "atlas_*.nii.gz", emit: atlases_nii
        path "atlas_*.txt", emit: atlases_txt
        path "atlas_*.json", emit: atlases_json
        path "versions.yml", emit: versions
        

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    ln -s $task.ext.atlas_utils_folder/fsaverage \$(dirname ${folder})/

    # FastSurfer doesn't run the classic CA-based subcortical registration, so
    # talairach.m3z (needed by generate_atlas_FS_BN_GL_SF_v5.sh's mri_ca_label
    # calls) is missing from its output. Generate it here if absent.
    if [ ! -f ${folder}/mri/transforms/talairach.m3z ]; then
        export OMP_NUM_THREADS=${task.cpus}
        mri_ca_register -nobigventricles -align-after \
            -mask ${folder}/mri/brainmask.mgz \
            -T ${folder}/mri/transforms/talairach.lta \
            ${folder}/mri/norm.mgz \
            \$FREESURFER_HOME/average/RB_all_2019_10_25.talxfm.mni305.gca \
            ${folder}/mri/transforms/talairach.m3z
    fi

    bash $task.ext.atlas_utils_folder/freesurfer_utils/generate_atlas_FS_BN_GL_SF_v5.sh \$(dirname ${folder}) ${prefix} ${task.cpus} FS_BN_GL_SF_Atlas/

    # generate_atlas_FS_BN_GL_SF_v5.sh has no `set -e`, so a broken step inside
    # it (e.g. an scilpy CLI change) fails silently and leaves this empty.
    for atlas in freesurfer brainnetome glasser schaefer_100 schaefer_200 schaefer_400; do
        if [ ! -f $prefix/FS_BN_GL_SF_Atlas/atlas_\${atlas}_v5.nii.gz ]; then
            echo "ERROR: generate_atlas_FS_BN_GL_SF_v5.sh did not produce atlas_\${atlas}_v5.nii.gz" >&2
            exit 1
        fi
    done

    cp $prefix/FS_BN_GL_SF_Atlas/* ./

    mri_convert ${folder}/mri/orig/001.mgz orig.nii.gz
    for f in atlas_*.nii.gz; do
        scil_volume_reslice_to_reference.py "\$f" orig.nii.gz "\$f" --interpolation nearest -f
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.1.0
    END_VERSIONS
    """

    stub:
    """
    mri_convert -h

    touch brainnetome_atlas.nii.gz
    touch brainnetome_atlas.txt
    touch brainnetome_atlas.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.1.0
    END_VERSIONS
    """
}