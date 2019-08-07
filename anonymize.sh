#!/bin/bash

set -euo pipefail

while read -r f; do
  sed -ri "s#${OPF_BOOK_ID_ORIGINAL}#${OPF_BOOK_ID}#g" "${f}"
done < <(find "${OEBPS}/Text/" \
              -name '*.html' \
              -exec grep -q "${OPF_BOOK_ID_ORIGINAL}" {} \; -printf '%p\n' | \
           sort | uniq)
