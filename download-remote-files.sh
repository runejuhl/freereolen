#!/bin/bash

set -euo pipefail

# For case-insensitive regexes
shopt -s nocasematch

urls=$(find . -name '*.html' \
            -exec grep -iEo 'https?.+?\.(jpe?g|gif|svg|png|otf)' {} \; | \
         sort | uniq)

if [ -z "$urls" ]; then
  exit
fi

>&2 echo "Fetching $(wc -l <<< "$urls") images"
while read -r url; do
    curl -O "$url"

    name="$(basename "$url")"

    if [[ "${name}" =~ (jpe?g|gif|svg|png)$ ]]; then
      name="Images/${name}"
    fi

    if [[ "${name}" =~ (otf)$ ]]; then
      name="Fonts/${name}"
    fi

    target_file="${TARGET_DIR}/OEBPS/${name}"
    if [[ "$REFETCH" -ne 1 && -f "${target_file}" ]]; then
      continue
    fi

    curl -o "${target_file}" "${url}"

    find "${TARGET_DIR}/OEBPS/Text/" -name '*.html' | while read -r f; do
      sed -ri "s#${url}#../${name}#g" "$f"
    done
done <<< "$urls"
