process FS_BN_GL_SF_ATLASES {
    tag "$meta.id"

    container "${ 'scilus/scilus-freesurfer:2.1.0' }"

    input:
        tuple val(meta), path(folder)

    output:
        path "*[brainnetome,freesurfer,glasser,schaefer]*.nii.gz", emit: atlases_nii
        path "*[brainnetome,freesurfer,glasser,schaefer]*.txt", emit: atlases_txt
        path "*[brainnetome,freesurfer,glasser,schaefer]*.json", emit: atlases_json
        path "versions.yml", emit: versions
        

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    ln -s $task.ext.atlas_utils_folder/fsaverage \$(dirname ${folder})/
    bash $task.ext.atlas_utils_folder/freesurfer_utils/generate_atlas_FS_BN_GL_SF_v5.sh \$(dirname ${folder}) ${prefix} ${params.nb_threads} FS_BN_GL_SF_Atlas/

    cp $prefix/FS_BN_GL_SF_Atlas/* ./

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