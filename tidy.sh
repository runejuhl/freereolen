#!/bin/bash

set -euo pipefail

log "Running tidy..."

set +o errexit

while read -r f; do
  log "Tidying '${f}'..."

  # Join HTML tags that are split after `=`; this makes it a lot harder to
  # search and replace
  perl -i -0 -pe 's/=\n/=/gms' "${f}"

  tidy -modify \
       -quiet \
       --warn-proprietary-attributes no \
       --tidy-mark 0 \
       "$f"

  if [[ $? -eq 2 ]]; then
    error 2 "tidy choked on '${f}', exiting"
  fi
done < <(find "${OEBPS}/Text/" -iregex '.+?/.+\.x?html?' | sort)

set -o errexit
