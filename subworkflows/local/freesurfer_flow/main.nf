include { FASTSURFER } from '../../../modules/local/fastsurfer/main.nf'
include { FS_BN_GL_SF_ATLASES } from '../../../modules/local/FS_BN_GL_SF_atlases/main.nf'
include { LOBE_ATLAS } from '../../../modules/local/lobe_atlas/main.nf'
include { LAUSANNE_ATLAS } from '../../../modules/local/lausanne_atlas/main.nf'
include { YALE_ATLAS } from '../../../modules/local/yale_atlas/main.nf'

workflow FREESURFER_FLOW {

    take:
    t1         // path
    fs_output  // path
    fs_license // path

    main:

    ch_versions = Channel.empty()

    ch_fastsurfer = t1.combine(fs_license)
    FASTSURFER( ch_fastsurfer )
    ch_versions = ch_versions.mix(FASTSURFER.out.versions.first())

    ch_fs_output = fs_output.concat(FASTSURFER.out.fastsurferdirectory)

    FS_BN_GL_SF_ATLASES(ch_fs_output)
    ch_versions = ch_versions.mix(FS_BN_GL_SF_ATLASES.out.versions.first())

    LOBE_ATLAS(ch_fs_output)
    ch_versions = ch_versions.mix(LOBE_ATLAS.out.versions.first())

    scales = Channel.from(1,2,3,4,5)
    LAUSANNE_ATLAS(ch_fs_output, scales)
    ch_versions = ch_versions.mix(LAUSANNE_ATLAS.out.versions.first())

    YALE_ATLAS(ch_fs_output)
    ch_versions = ch_versions.mix(YALE_ATLAS.out.versions.first())

    emit:
    versions = ch_versions                          // channel: [ versions.yml ]
}
