// Import subworkflows
include { MIXED_INPUT } from "./assorted-sub-workflows/mixed_input/mixed_input"
include { FILE_VALIDATION; PREPROCESS } from './modules/preprocess'
include { GET_ARIBA_DB; OTHER_RESISTANCE; PARSE_OTHER_RESISTANCE } from './modules/amr'
include { GENERATE_SAMPLE_REPORT; GENERATE_OVERALL_REPORT } from './modules/output'

workflow {
    // Validate parameters
    Validate.validate(params, workflow, log)

    // Get path to ARIBA database, generate from reference sequences and metadata if necessary
    GET_ARIBA_DB(params.ariba_ref, params.ariba_metadata, params.db)

    raw_read_pairs_ch = channel.empty()

    // Get read pairs into Channel raw_read_pairs_ch
    if (params.reads) {
        channel.fromFilePairs("${params.reads}/*_{,R}{1,2}{,_001}.{fq,fastq}{,.gz}", checkIfExists: true)
            .mix(raw_read_pairs_ch)
            .set { raw_read_pairs_ch }
    }

    // Obtain input from manifests and iRODS params
    if (params.manifest_ena || params.manifest_of_lanes || params.manifest_of_reads || params.manifest || params.studyid != -1|| params.runid != -1 || params.laneid != -1 || params.plexid != -1) {
        MIXED_INPUT()
            .map { meta, R1, R2 -> [meta.ID.toString(), [R1, R2]] }
            .mix(raw_read_pairs_ch)
            .set { raw_read_pairs_ch }
    }

    // Validate IDs in the raw_read_pairs_ch are unique before further processing
    ids_ch = raw_read_pairs_ch.map { it -> it [0] }
    ids_ch.count()
        .combine(ids_ch.unique().count())
        .subscribe { it -> 
            if ( it[0] != it[1]) {
                log.error("There are duplicated IDs in the input. Please make sure IDs are unique across all input sources.") 
                System.exit(1)
            }
        }

    // Basic input files validation
    // Output into Channel FILE_VALIDATION.out.result
    FILE_VALIDATION(raw_read_pairs_ch)

    // From Channel raw_read_pairs_ch, only output valid reads of samples based on Channel FILE_VALIDATION.out.result
    VALID_READS_ch = FILE_VALIDATION.out.result.join(raw_read_pairs_ch, failOnDuplicate: true)
                        .filter { it -> it[1] == 'PASS' }
                        .map { it -> it[0, 2..-1] }
    
    // Preprocess valid read pairs
    // Output into Channels PREPROCESS.out.processed_reads
    PREPROCESS(VALID_READS_ch)

    // From Channel OVERALL_QC_PASSED_READS_ch, infer resistance and determinants of other antimicrobials
    // Output into Channel PARSE_OTHER_RESISTANCE.out.report
    OTHER_RESISTANCE(GET_ARIBA_DB.out.path, PREPROCESS.out.processed_reads)
    PARSE_OTHER_RESISTANCE(OTHER_RESISTANCE.out.report, params.ariba_metadata)

    GENERATE_SAMPLE_REPORT(
        raw_read_pairs_ch.map{ it -> it[0] }
        .join(PARSE_OTHER_RESISTANCE.out.report, failOnDuplicate: true, remainder: true)
        .map { it -> [it[0], it[1..-1].minus(null)] } // Map Sample_ID to index 0 and all reports (with null entries removed) as a list to index 1
    )

    GENERATE_OVERALL_REPORT(GENERATE_SAMPLE_REPORT.out.report.collect(), params.output)
}