#!/bin/bash
#
# Attempts to remove any unique features from the book so that the output is
# reproducible. This means removing links that have unique identifiers,
# timestamps, debug metadata etc. Think "reproducible builds".

set -euo pipefail

if [[ -n "${OPF_BOOK_ID_ORIGINAL}" ]]; then
  while read -r f; do
    sed -ri "s#${OPF_BOOK_ID_ORIGINAL}#${OPF_BOOK_ID}#g" "${f}"
  done < <(find "${OEBPS}/Text/" \
                -iregex '.*?\.x?html?' \
                -exec grep -q "${OPF_BOOK_ID_ORIGINAL}" {} \; -printf '%p\n' | \
             sort | uniq)
fi

# Fix broken URL. This is due to an `a` tag that is broken over multiple lines,
# causing later scripts to fail. The easy fix here is to simply rewrite the tag
# so that it doesn't contain newlines between tag header and attributes.
( grep -sl -rPo --include='**.htm' --include='**.html' --include='**.xhtml' '(?<=")http[^"]+www\.(lindhardtogringhof|gyldendal)\.dk(?=")' "${OEBPS}/Text/" || true) | while read -r f; do
  sed -ri 's@http[^"]+?/Revision[^/]+/([^"]+)@https://\1@g' "${f}"
done

# Check for URLs that lead to external pages, as these might contain unique identifiers.
if urls=$(grep -rPo --include='**.htm' --include='**.html' --include='**.xhtml' '(?<=")http[^"]+(?=")' "${OEBPS}/Text/" | \
            grep -E --file=valid-urls.list --invert-match); then
  error 42 "Files contains URLs that you might want to redact:\\n${urls}"
fi
