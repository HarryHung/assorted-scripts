// Import subworkflows
include { MIXED_INPUT } from "./assorted-sub-workflows/mixed_input/mixed_input"
include { FILE_VALIDATION; PREPROCESS } from './modules/preprocess'
include { GET_SEROBA_DB; SEROTYPE } from './modules/serotype'
include { GENERATE_SAMPLE_REPORT; GENERATE_OVERALL_REPORT } from './modules/output'

workflow {
    // Validate parameters
    Validate.validate(params, workflow, log)

    // Get path SeroBA Databases, download and rebuild if necessary
    GET_SEROBA_DB(params.seroba_db_remote, params.db, params.seroba_kmer)

    raw_read_pairs_ch = Channel.empty()

    // Get read pairs into Channel raw_read_pairs_ch
    if (params.reads) {
        Channel.fromFilePairs("${params.reads}/*_{,R}{1,2}{,_001}.{fq,fastq}{,.gz}", checkIfExists: true)
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
    ids_ch = raw_read_pairs_ch.map { it [0] }
    ids_ch.count()
        .combine(ids_ch.unique().count())
        .subscribe {
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
                        .filter { it[1] == 'PASS' }
                        .map { it[0, 2..-1] }
    
    // Preprocess valid read pairs
    // Output into Channels PREPROCESS.out.processed_reads
    PREPROCESS(VALID_READS_ch)

    // From Channel VALID_READS_ch, serotype the preprocess reads of samples 
    // Output into Channel SEROTYPE.out.report
    SEROTYPE(GET_SEROBA_DB.out.path, PREPROCESS.out.processed_reads)

    GENERATE_SAMPLE_REPORT(
        raw_read_pairs_ch.map{ it[0] }
        .join(SEROTYPE.out.report, failOnDuplicate: true, remainder: true)
        .map { [it[0], it[1..-1].minus(null)] } // Map Sample_ID to index 0 and all reports (with null entries removed) as a list to index 1
    )

    GENERATE_OVERALL_REPORT(GENERATE_SAMPLE_REPORT.out.report.collect(), params.output)
}