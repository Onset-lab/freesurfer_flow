process YALE_ATLAS {
    tag "$meta.id"

    container "${ 'onsetlab/freesurfer-flow:dev' }"

    input:
        tuple val(meta), path(folder)

    output:
        path "*yale*.nii.gz", emit: yale_nii
        path "*yale*.txt", emit: yale_txt
        path "versions.yml", emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    export SUBJECTS_DIR=\$(dirname ${folder})
    ln -sf /FS_BN_GL_SF_utils/fsaverage \$SUBJECTS_DIR/

    mri_surf2surf --hemi lh --srcsubject fsaverage --trgsubject ${prefix} \
        --sval-annot $task.ext.atlas_utils_folder/YBA_696_LH_fsaverage.annot \
        --tval \$SUBJECTS_DIR/${prefix}/label/lh.yale.annot
    mri_surf2surf --hemi rh --srcsubject fsaverage --trgsubject ${prefix} \
        --sval-annot $task.ext.atlas_utils_folder/YBA_696_RH_fsaverage.annot \
        --tval \$SUBJECTS_DIR/${prefix}/label/rh.yale.annot

    mri_aparc2aseg --s ${prefix} --annot yale --o yale_aparc+aseg.mgz

    # --- Cortex: real YBA_696 parcel ids (1-696) ---
    mri_binarize --i yale_aparc+aseg.mgz --min 1000 --max 1999 --o lh_yale_mask.mgz
    mri_binarize --i yale_aparc+aseg.mgz --min 2000 --max 2999 --o rh_yale_mask.mgz
    mri_mask yale_aparc+aseg.mgz lh_yale_mask.mgz lh_yale.mgz
    mri_mask yale_aparc+aseg.mgz rh_yale_mask.mgz rh_yale.mgz

    # scilpy only reads nifti, not mgz
    mri_convert lh_yale.mgz lh_yale.nii.gz
    mri_convert rh_yale.mgz rh_yale.nii.gz

    # mri_aparc2aseg offsets cortical labels by +1000 (lh) / +2000 (rh); undo that
    # so voxel values match the real YBA_696 parcel ids (1-696) from the LUT.
    scil_volume_math.py subtraction lh_yale.nii.gz 1000 lh_yale.nii.gz --exclude_background --data_type int16 -f
    scil_volume_math.py subtraction rh_yale.nii.gz 2000 rh_yale.nii.gz --exclude_background --data_type int16 -f

    # --- Subcortical nuclei only (thalamus, caudate, putamen, pallidum,
    # hippocampus, amygdala, accumbens, ventral DC) from the standard FreeSurfer
    # aseg, renumbered to consecutive ids continuing right after the Yale range ---
    subcortical_ids="10 11 12 13 17 18 26 28 49 50 51 52 53 54 58 60"
    other_files=""
    new_id=696
    for id in \$subcortical_ids; do
        new_id=\$((new_id + 1))
        mri_binarize --i yale_aparc+aseg.mgz --match \$id --o struct_\${new_id}.mgz
        mri_convert struct_\${new_id}.mgz struct_\${new_id}.nii.gz
        scil_volume_math.py multiplication struct_\${new_id}.nii.gz \$new_id struct_\${new_id}.nii.gz --data_type int16 -f
        other_files="\$other_files struct_\${new_id}.nii.gz"
    done

    scil_volume_math.py addition lh_yale.nii.gz rh_yale.nii.gz \$other_files yale_atlas.nii.gz --data_type int16 -f

    mri_convert ${folder}/mri/rawavg.mgz rawavg.nii.gz
    scil_volume_reslice_to_reference.py yale_atlas.nii.gz rawavg.nii.gz yale_atlas.nii.gz --interpolation nearest -f
    scil_volume_math.py convert yale_atlas.nii.gz yale_atlas.nii.gz --data_type int16 -f

    cp $task.ext.atlas_utils_folder/YBA_696_LUT.txt ./yale_atlas_LUT.txt
    awk -v ids="\$subcortical_ids" 'BEGIN{n=split(ids,a," "); for(i=1;i<=n;i++) newid[a[i]]=696+i}
        \$1 ~ /^[0-9]+\$/ && (\$1 in newid) { \$1 = newid[\$1]; print }' \
        \$FREESURFER_HOME/FreeSurferColorLUT.txt >> ./yale_atlas_LUT.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.1.0
    END_VERSIONS
    """

    stub:
    """
    mri_convert -h

    touch yale_atlas.nii.gz
    touch yale_atlas_LUT.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.1.0
    END_VERSIONS
    """
}
