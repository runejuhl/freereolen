#!/bin/bash

set -euo pipefail

# For case-insensitive regexes
shopt -s nocasematch

urls=$(find "${OEBPS}/Text/" \
            -iregex '.*?\.x?html?' \
            -exec grep -iEo "https?[^'\"]+?\\.(jpe?g|gif|svg|png|otf)" {} \; | \
         sort | uniq)

if (( DOWNLOAD == 1 )) && [ -n "$urls" ]; then
  log "Fetching $(wc -l <<< "$urls") remote files"
  while read -r original_url; do
    # replace HTML entities
    url=${original_url//&amp;/&}

    name="$(basename "$url")"

    if [[ "${name}" =~ (jpe?g|gif|svg|png)$ ]]; then
      name="Images/${name}"
    fi

    if [[ "${name}" =~ (otf)$ ]]; then
      name="Fonts/${name}"
    fi

    target_file="${OEBPS}/${name}"

    if should_refetch || [[ ! -f "${target_file}" ]]; then
      _download "${url}" "${target_file}"
    fi

    # Update all references
    find "${OEBPS}/Text/"\
         -iregex '.*?\.x?html?' | \
      while read -r f; do
      sed -ri "s#${original_url}#../${name}#g" "$f"
    done
  done <<< "$urls"
fi
