#!/bin/bash

set -euo pipefail

urls=$(find . -name '*.html' \
            -exec grep -iEo 'https?.+?\.(jpe?g|gif|svg|png|otf)' {} \; | \
         sort | uniq)

if [ -z "$urls" ]; then
  exit
fi

>&2 echo "Fetching $(wc -l <<< "$urls") images"
while read -r url; do
    curl -O "$url"

    name=$(basename "$url")
    curl -O "$url"

    find . -name '*.html' | while read -r f; do
      sed -ri "s#${url}#${name}#g" "$f"
    done
done <<< "$urls"
