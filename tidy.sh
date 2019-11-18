#!/bin/bash

set -euo pipefail

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
done < <(find "${OEBPS}/Text/" -iregex '.+?/.+\.x?html?')

set -o errexit
