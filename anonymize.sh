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
