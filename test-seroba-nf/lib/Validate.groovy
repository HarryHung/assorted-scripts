class Validate {
    // Validate whether all provided parameters are valid
    public static void validate(Map params, workflow, log) {
        // Map of valid parameters for which to skip validation
        Map skipValidationParams = [
            // From common config
            input: 'skip',
            tracedir: 'skip',
            max_memory: 'skip',
            max_cpus: 'skip',
            max_time: 'skip',
            max_retries: 'skip',
            retry_strategy: 'skip',
            queue_size: 'skip',
            submit_rate_limit: 'skip',
            // From mixed input config
            outdir: 'skip',
            manifest_of_reads: 'skip',
            manifest_of_lanes: 'skip',
            manifest_ena: 'skip',
            manifest: 'skip',
            save_metadata: 'skip',
            combine_same_id_crams: 'skip',
            dehumanising_method: 'skip',
            cleanup_intermediate_files_irods_extractor: 'skip',
            save_fastqs: 'skip',
            save_method: 'skip',
            raw_reads_prefix: 'skip',
            preexisting_fastq_tag: 'skip',
            split_sep_for_ID_from_fastq: 'skip',
            lane_plex_sep: 'skip',
            start_queue: 'skip',
            irods_subset_to_skip: 'skip',
            short_metacsv_name: 'skip',
            studyid: 'skip',
            runid: 'skip',
            laneid: 'skip',
            plexid: 'skip',
            target: 'skip',
            type: 'skip',
            large_data: 'skip',
            read_type: 'skip',
            publish_metadata: 'skip',
            accession_type: 'skip',
            help: 'skip',
            preexisting_output_tag: 'skip',
            existing_output_id_suffix: 'skip',
            existing_output_extension: 'skip',
            manifest_from_dir: 'skip',
            fastq_validation: 'skip',
            max_depth: 'skip',
            only_new_input: 'skip',
            // From GPS Pipeline config
            reads: 'skip', // reads is optional due to mixed input
        ] 

        // Map of valid parameters and their value types
        Map validParams = [
            output: 'path',
            db: 'path',
            file_publish: 'publish_mode',
            seroba_db_remote: 'url_targz',
            seroba_kmer: 'int',
        ]

        validParams += skipValidationParams

        // Add params.singularity_cachedir when workflow.containerEngine == 'singularity'
        if (workflow.containerEngine == 'singularity') {
            validParams.put("singularity_cachedir", "path")
        }

        // To save invalid parameters in this list
        def invalidParams = []
        // To save invalid parameter values as "parameter : [value, issue]" in this map
        def Map invalidValues = [:]

        params.each {
            key, value ->

            // If parameter is invalid, add it to invalidParams list and skip the following checks
            if (!validParams.keySet().contains(key)) {
                invalidParams.add(key)
                return
            }

            // Based on the value type of the parameter, perform the appropriate check
            switch (validParams[key]) {
                case 'skip':
                    break

                case 'int':
                    if (value !instanceof Integer) {
                        invalidValues[key] = [value, 'integer value']
                    }
                    break

                case 'publish_mode':
                    if (!['link', 'symlink', 'copy'].contains(value)) {
                        invalidValues[key] = [value, 'Nextflow publish mode']
                    }
                    break

                case 'path':
                    File dir = new File(value)
                    if (!(dir.exists() || dir.mkdirs())) {
                        invalidValues[key] = [value, 'directory path (invalid path or insufficient permissions)']
                    }
                    break

                case 'path_fasta':
                    File fasta = new File(value)
                    if (!fasta.exists()) {
                        invalidValues[key] = [value, 'path to a fasta file (file does not exist)']
                    } else if (!(value ==~ /.+\.(fa|fasta)$/)) {
                        invalidValues[key] = [value, 'path to a fasta file (file does not have an filename extension of .fasta or .fa)']
                    }
                    break

                case 'url_targz':
                    if (!(value ==~ /^(https?:\/\/)?(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)\.(tar\.gz|tgz)$/)) {
                        invalidValues[key] = [value, 'URL that points a .tar.gz file (valid URL ending with .tar.gz or .tgz)']
                    }
                    break

                // Should only reach this statement if a new value type is added to validParams without adding its case above
                default:
                    log.error("""
                        |Unknown value type \"${validParams[key]}\"
                        |Please submit an issue at \"https://github.com/GlobalPneumoSeq/gps-pipeline/issues\"}
                        """.stripMargin())
                    System.exit(1)
            }
        }

        // If invalidParams list or invalidValues map is not empty, log error messages and terminate the pipeline
        if (invalidParams || invalidValues) {
            log.error('The pipeline will now be terminated due to the following critical error(s):')

            if (invalidParams) {
                log.error("The following invalid option(s) were provided: --${invalidParams.join(', --')}.")
            }

            if (invalidValues) {
                invalidValues.each {
                    key, values ->
                    log.error("The provided value \"${values[0]}\" for option --${key} is not a valid ${values[1]}.")
                }
            }

            System.exit(1)
        }
    }
}