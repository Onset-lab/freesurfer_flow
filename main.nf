#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { PIPELINE_INITIALISATION } from './subworkflows/local/pipeline_initialisation/main.nf'
include { FREESURFER_FLOW } from './subworkflows/local/freesurfer_flow/main.nf'

if(params.help) {
    usage = file("$baseDir/USAGE")

    cpu_count = Runtime.runtime.availableProcessors()
    bindings = ["run_atlases":"$params.run_atlases",
                "run_lausanne_atlas":"$params.run_lausanne_atlas",
                "run_lobe_atlas":"$params.run_lobe_atlas",
                "output_dir":"$params.output_dir"]

    engine = new groovy.text.SimpleTemplateEngine()
    template = engine.createTemplate(usage.text).make(bindings)

    print template.toString()
    return
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.fs_input,
        params.fs_output,
        params.fs_license,
        params.output_dir
    )

    FREESURFER_FLOW(
        PIPELINE_INITIALISATION.out.t1,
        PIPELINE_INITIALISATION.out.fs_channel,
        PIPELINE_INITIALISATION.out.fs_license
    )
}
