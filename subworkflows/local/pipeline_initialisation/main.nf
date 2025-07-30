
def logoHeader(){
    // Log colors ANSI codes
    c_reset = "\033[0m";
    c_dim = "\033[2m";
    c_blue = "\033[0;34m";

    return """
    ${c_dim}-----------------------------------${c_reset}
    ${c_blue}    ___  _   _ ____  _____ _____   ${c_reset}
    ${c_blue}   / _ \\| \\ | / ___|| ____|_   _|  ${c_reset}
    ${c_blue}  | | | |  \\| \\___ \\|  _|   | |    ${c_reset}
    ${c_blue}  | |_| | |\\  |___) | |___  | |    ${c_reset}
    ${c_blue}   \\___/|_| \\_|____/|_____| |_|    ${c_reset}

    ${c_dim}------------------------------------${c_reset}
    """.stripIndent()
}

log.info logoHeader()

log.info "\033[0;33m ${workflow.manifest.name} \033[0m"
log.info "  ${workflow.manifest.description}"
log.info "  Version: ${workflow.manifest.version}"
log.info "  Github: ${workflow.manifest.homePage}"
log.info " "

workflow.onComplete {
    log.info " "
    log.info "Pipeline completed at: $workflow.complete"
    log.info "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
    log.info "Execution duration: $workflow.duration"
}

include { DCM2BIDS } from '../../../modules/local/dcm2bids/main.nf'

workflow PIPELINE_INITIALISATION {

    take:
    fs_input        // path
    fs_output       // path
    fs_license      // path
    outdir          // path

    main:

    if (fs_input) {
        t1_channel = Channel.fromPath("$fs_input/**/*t1.nii.gz")
                        .map{ch1 ->
                            def fmeta = [:]
                            // Set meta.id
                            fmeta.id = ch1.parent.name
                            [fmeta, ch1]
                            }
        fs_channel = Channel.empty()
    }
    else if (fs_output) {
        fs_channel = Channel.fromPath("$fs_output", type:"dir")
                        .map{ch1 ->
                            def fmeta = [:]
                            // Set meta.id
                            fmeta.id = ch1.parent.name
                            [fmeta, ch1]
                            }
        t1_channel = Channel.empty()
    }
    else {
        log.error "Please provide either --fs_input or --fs_output."
        exit 1
    }

    if (fs_license) {
        fs_license_channel = Channel.fromPath("$fs_license")
    }
    else {
        log.error "Please provide a FreeSurfer license file with --fs_license."
        exit 1
    }

    log.info "\033[0;33m Parameters \033[0m"
    log.info " Freesurfer Input: ${fs_input}"
    log.info " Freesurfer Output: ${fs_output}"
    log.info " FreeSurfer license: ${fs_license}"
    log.info " Output directory: ${outdir}"

    emit:
    t1 = t1_channel        // channel: [ val(meta), [ image ] ]
    fs_channel = fs_channel // channel: [ val(meta), [ folder ] ]
    fs_license = fs_license_channel // channel: [ path(fs_license) ]
}
