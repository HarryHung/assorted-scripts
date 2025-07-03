#!/bin/bash

if [ "$1" == "-h" ] || [ -z "$1" ]; then
  echo "Usage: table_splitter.sh <path to table> <number of rows (default: 10,000)>"
  exit 0
fi

TABLE="$1"
TABLE_EXT=".${TABLE##*.}"
TABLE_NAME=$(basename $TABLE ${TABLE_EXT})

if [ ! -f "$TABLE" ]; then
  echo "Error: $TABLE not found!"
  exit 0
fi

HEADER=$(head -1 $TABLE)

SPLIT_SIZE="${2:-15000}"

tail -n +2 $TABLE | split -l $SPLIT_SIZE -d - ${TABLE_NAME}_split_

for FILE in ${TABLE_NAME}_split_*; do
    (echo $HEADER; cat $FILE) > ${FILE}.csv
    rm $FILE;
done
