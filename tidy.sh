#!/bin/bash -x

>&2 echo "Running tidy..."

set +o errexit

while read -r f; do
  >&2 echo "Tidying '${f}'..."
  tidy -modify \
       -quiet \
       --warn-proprietary-attributes no \
       --tidy-mark 0 \
       "$f"

  if [[ $? -eq 2 ]]; then
    >&2 echo "tidy choked on '${f}', exiting"
    exit 2
  fi
done < <(find "${OEBPS}" -iregex '.+?/.+\.x?html?')

set -o errexit
