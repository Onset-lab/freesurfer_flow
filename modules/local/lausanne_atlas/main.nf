process LAUSANNE_ATLAS {
    tag "$meta.id"

    container "${ 'onsetlab/freesurfer-flow:1.0.0' }"

    input:
        tuple val(meta), path(folder)
        each scale

    output:
        path "lausanne_2008_scale_${scale}.nii.gz", emit: lausanne_nii
        path "lausanne_2008_scale_${scale}_dilate.nii.gz", emit: lausanne_dilate
        path "*.txt", emit: lausanne_txt
        path "*.json", emit: lausanne_json
        path "versions.yml", emit: versions
        

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    export OMP_NUM_THREADS=${task.cpus}
    ln -s $task.ext.atlas_utils_folder/fsaverage \$(dirname ${folder})/
    freesurfer_home=\$(dirname \$(dirname \$(which mri_label2vol)))
    python3.10 $task.ext.atlas_utils_folder/lausanne_multi_scale_atlas/generate_multiscale_parcellation.py \$(dirname ${folder}) ${prefix} \$freesurfer_home --scale ${scale} --dilation_factor 0 --log_level DEBUG

    mri_convert ${folder}/mri/orig/001.mgz orig.nii.gz
    mri_convert ${folder}/mri/brainmask.mgz brain_mask.nii.gz
    scil_volume_math.py lower_threshold brain_mask.nii.gz 0.001 brain_mask.nii.gz --data_type uint8 -f
    scil_volume_reslice_to_reference.py brain_mask.nii.gz orig.nii.gz brain_mask.nii.gz --interpolation nearest -f
    scil_volume_math.py convert brain_mask.nii.gz brain_mask.nii.gz --data_type uint8 -f
    scil_volume_reslice_to_reference.py ${folder}/mri/lausanne2008.scale${scale}+aseg.nii.gz orig.nii.gz lausanne_2008_scale_${scale}.nii.gz --interpolation nearest
    scil_volume_math.py convert lausanne_2008_scale_${scale}.nii.gz lausanne_2008_scale_${scale}.nii.gz --data_type int16 -f
    scil_labels_dilate.py lausanne_2008_scale_${scale}.nii.gz lausanne_2008_scale_${scale}_dilate.nii.gz --distance 2 --mask brain_mask.nii.gz
    
    cp $task.ext.atlas_utils_folder/lausanne_multi_scale_atlas/*.txt ./
    cp $task.ext.atlas_utils_folder/lausanne_multi_scale_atlas/*.json ./

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