#!/bin/bash

urls=$(find . -name '*.html' \
            -exec grep -iEo 'https?.+?\.(jpe?g|gif|svg|png)' {} \; | \
         sort | uniq)

while read -r url; do
    curl -O "$url"

    name=$(basename "$url")
    curl -O "$url"

    find . -name '*.html' | while read -r f; do
      sed -ri "s#${url}#${name}#g" "$f"
    done
done <<< "$urls"
