#!/bin/bash

if [ "$1" == "-h" ] || [ -z "$1" ]; then
  echo "Usage: check_metadata.sh <path to old metadata file> <path to new metadata file>"
  exit 0
fi

OLD_METADATA="$1"
NEW_METADATA="$2"
OLD_METADATA_REMOVED=$(sed -E 's/.csv$/-removed-publicnames.txt/' <<< ${OLD_METADATA})
NEW_METADATA_NEW=$(sed -E 's/.csv$/-new-publicnames.txt/' <<< ${NEW_METADATA})
NEW_METADATA_CHANGE=$(sed -E 's/.csv$/-change.csv/' <<< ${NEW_METADATA})

# Extract removed Public_name(s)
if [[ -n $(comm -23 <(cut -d',' -f 2 ${OLD_METADATA} | sort) <(cut -d',' -f 2 ${NEW_METADATA} | sort)) ]]; then
	echo "Public_name(s) removed. Saving removed Public_name(s) to ${OLD_METADATA_REMOVED}"
	comm -23 <(cut -d',' -f 2 ${OLD_METADATA} | sort) <(cut -d',' -f 2 ${NEW_METADATA} | sort) > ${OLD_METADATA_REMOVED}
else
	echo "No Public_name(s) is removed."
fi

# Extract new Public_name(s)
if [[ -n $(comm -13 <(cut -d',' -f 2 ${OLD_METADATA} | sort) <(cut -d',' -f 2 ${NEW_METADATA} | sort)) ]]; then
	echo "Public_name(s) added. Saving new Public_name(s) to ${NEW_METADATA_NEW}"
	comm -13 <(cut -d',' -f 2 ${OLD_METADATA} | sort) <(cut -d',' -f 2 ${NEW_METADATA} | sort) > ${NEW_METADATA_NEW}
else
	echo "No Public_name(s) is added."
fi

if [[ $(head -n 1 ${OLD_METADATA}) != $(head -n 1 ${NEW_METADATA}) ]]; then
    echo "Metadata headers do not match. Aborting..."
    exit 1
fi

# Extract header with new/changed row(s)
if [[ -n $(comm -13 <(sort ${OLD_METADATA}) <(sort ${NEW_METADATA})) ]]; then
    echo "New/changed row(s) is found. Saving new/changed row(s) to ${NEW_METADATA_CHANGE}"
    # Extract header
    head -n 1 ${NEW_METADATA} > ${NEW_METADATA_CHANGE}
    # Extract new/changed row(s)
    comm -13 <(sort ${OLD_METADATA}) <(sort ${NEW_METADATA}) >> ${NEW_METADATA_CHANGE}
else
    echo "No new/changed row(s) is found."
fi
