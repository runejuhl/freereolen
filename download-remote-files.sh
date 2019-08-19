#!/bin/bash

set -euo pipefail

# For case-insensitive regexes
shopt -s nocasematch

urls=$(find "${OEBPS}/Text/" \
            -iregex '.*?\.x?html?' \
            -exec grep -iEo "https?[^'\"]+?\\.(jpe?g|gif|svg|png|otf)" {} \; | \
         sort | uniq)

if [ -n "$urls" ]; then
  >&2 echo "Fetching $(wc -l <<< "$urls") remote files"
  while read -r url; do
    name="$(basename "$url")"

    if [[ "${name}" =~ (jpe?g|gif|svg|png)$ ]]; then
      name="Images/${name}"
    fi

    if [[ "${name}" =~ (otf)$ ]]; then
      name="Fonts/${name}"
    fi

    target_file="${OEBPS}/${name}"
    if [[ ! -f "${target_file}" || "$REFETCH" -eq 1 ]]; then
      _download "${url}" "${target_file}"
    fi

    find "${OEBPS}/Text/"\
         -iregex '.*?\.x?html?' | \
      while read -r f; do
      sed -ri "s#${url}#../${name}#g" "$f"
    done
  done <<< "$urls"
fi
