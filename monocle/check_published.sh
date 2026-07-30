#!/bin/bash

if [ "$1" == "-h" ] || [ -z "$1" ]; then
  echo "Usage: check_published.sh <path to old published public name list> <path to new published public name list>"
  exit 0
fi

OLD_PUBLISHED="$1"
NEW_PUBLISHED="$2"
OLD_PUBLISHED_REMOVED=$(sed -E 's/.txt$/-removed.txt/' <<< ${OLD_PUBLISHED})
NEW_PUBLISHED_NEW=$(sed -E 's/.txt$/-new.txt/' <<< ${NEW_PUBLISHED})

# Extract removed published samples
if [[ -n $(comm -23 <(sort ${OLD_PUBLISHED}) <(sort ${NEW_PUBLISHED})) ]]; then
	echo "Published sample(s) removed. Saving removed sample(s) to ${OLD_PUBLISHED_REMOVED}"
	comm -23 <(sort ${OLD_PUBLISHED}) <(sort ${NEW_PUBLISHED}) > ${OLD_PUBLISHED_REMOVED}
else
	echo "No published sample is removed."
fi

# Extract new published samples
if [[ -n $(comm -13 <(sort ${OLD_PUBLISHED}) <(sort ${NEW_PUBLISHED})) ]]; then
	echo "New published sample(s) is found. Saving new sample(s) to ${NEW_PUBLISHED_NEW}"
	comm -13 <(sort ${OLD_PUBLISHED}) <(sort ${NEW_PUBLISHED}) > ${NEW_PUBLISHED_NEW}
fi
