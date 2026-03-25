process GENERATE_SAMPLE_REPORT {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path("${sample_id}_process_report_?.csv")

    output:
    path sample_report, emit: report

    script:
    sample_report="${sample_id}_report.csv"
    """
    SAMPLE_ID="$sample_id"
    SAMPLE_REPORT="$sample_report"

    source generate_sample_report.sh
    """
}

process GENERATE_OVERALL_REPORT {
    label 'bash_container'
    label 'farm_low'

    publishDir "${output}", mode: "copy"

    input:
    path '*'
    val output

    output:
    path "$overall_report", emit: report

    script:
    input_pattern='*_report.csv'
    overall_report='results.csv'
    """
    awk ' NR == 1 || FNR > 1' $input_pattern > "$overall_report"
    """
}
