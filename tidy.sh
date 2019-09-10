#!/bin/bash -x

log "Running tidy..."

set +o errexit

while read -r f; do
  log "Tidying '${f}'..."
  tidy -modify \
       -quiet \
       --warn-proprietary-attributes no \
       --tidy-mark 0 \
       "$f"

  if [[ $? -eq 2 ]]; then
    error 2 "tidy choked on '${f}', exiting"
  fi
done < <(find "${OEBPS}" -iregex '.+?/.+\.x?html?')

set -o errexit
