#!/bin/bash

if [ "$1" == "-h" ] || [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: create_poppunk_query_file.sh <path to assemblies> <path to output> <suffix of assemblies (default: .contigs.fasta)>"
  exit 0
fi

ASSEMBLIES_PATH="$1"
OUTPUT_PATH="$2"
SUFFIX="${3:-".contigs.fasta"}"

for ASSEMBLY_PATH in ${ASSEMBLIES_PATH}/*${SUFFIX}; do 
    SAMPLE_NAME=$(basename -s $SUFFIX $ASSEMBLY_PATH );
    echo -e ${SAMPLE_NAME}'\t'${ASSEMBLY_PATH} >> $OUTPUT_PATH
done;
