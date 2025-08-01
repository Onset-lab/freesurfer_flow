process FASTSURFER {
    tag "$meta.id"
    maxForks 1

    container "${ 'deepmi/fastsurfer:cuda-v2.4.2' }"

    input:
        tuple val(meta), path(anat), path(fs_license)

    output:
        tuple val(meta), path("*_fastsurfer/*")    , emit: fastsurferdirectory
        path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def acq3T = task.ext.acq3T ? "--3T" : ""
        def seg_only = task.ext.seg_only ? "--seg_only" : ""
        def FASTSURFER_HOME = "/fastsurfer"
        def SUBJECTS_DIR = "${prefix}_fastsurfer"
    """
    mkdir ${prefix}_fastsurfer/
    $FASTSURFER_HOME/run_fastsurfer.sh  --allow_root \
                                        --sd \$(realpath ${SUBJECTS_DIR}) \
                                        --fs_license \$(realpath $fs_license) \
                                        --t1 \$(realpath ${anat}) \
                                        --sid ${prefix} \
                                        --py python3 --parallel \
                                        --threads ${task.cpus} \
                                        --fsaparc \
                                        ${acq3T} ${seg_only}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastsurfer: \$($FASTSURFER_HOME/run_fastsurfer.sh --version)
    END_VERSIONS
    """

    stub:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def FASTSURFER_HOME = "/fastsurfer"
    """
    $FASTSURFER_HOME/run_fastsurfer.sh --version

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastsurfer: \$($FASTSURFER_HOME/run_fastsurfer.sh --version)
    END_VERSIONS
    """
}