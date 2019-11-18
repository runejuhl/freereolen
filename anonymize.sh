#!/bin/bash

set -euo pipefail

if [[ -n "${OPF_BOOK_ID_ORIGINAL}" ]]; then
  while read -r f; do
    sed -ri "s#${OPF_BOOK_ID_ORIGINAL}#${OPF_BOOK_ID}#g" "${f}"
  done < <(find "${OEBPS}/Text/" \
                -iregex '.*?\.x?html?' \
                -exec grep -q "${OPF_BOOK_ID_ORIGINAL}" {} \; -printf '%p\n' | \
             sort | uniq)
fi

# Check for URLs that lead to external pages
if urls=$(grep -rPo --include='**.htm' --include='**.html' --include='**.xhtml' '(?<=")http[^"]+(?=")' "${OEBPS}/Text/" | \
            grep -E --file=valid-urls.list --invert-match); then
  error 42 "Files contains URLs that you might want to redact:\\n${urls}"
fi
