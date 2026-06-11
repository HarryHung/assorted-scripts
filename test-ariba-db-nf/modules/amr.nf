// Return database path, create if necessary
process GET_ARIBA_DB {
    label 'ariba_container'
    label 'farm_low'
    label 'farm_scratchless'
    label 'farm_slow'

    input:
    path ref_sequences
    path metadata
    path db

    output:
    path ariba_db, emit: path

    script:
    ariba_db="${db}/ariba"
    json='done_ariba_db.json'
    checksum='checksum.md5'
    """
    REF_SEQUENCES="$ref_sequences"
    METADATA="$metadata"
    DB_LOCAL="$ariba_db"
    JSON_FILE="$json"
    CHECKSUM_FILE='$checksum'

    source check-create_ariba_db.sh
    """
}

// Run ARIBA to identify AMR
process OTHER_RESISTANCE {
    label 'ariba_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    path ariba_database
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path(report_debug), emit: report

    script:
    report_debug='result/debug.report.tsv'
    """
    ariba run --nucmer_min_id 80 "$ariba_database" "$read1" "$read2" result
    """
}

// Extracting resistance information from ARIBA report
process PARSE_OTHER_RESISTANCE {
    label 'python_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(report_debug)
    path metadata

    output:
    tuple val(sample_id), path(output_file), emit: report

    script:
    output_file="other_amr_report.csv"
    """
    parse_other_resistance.py "$report_debug" "$metadata" "$output_file"
    """
}
