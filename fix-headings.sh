#!/bin/bash

>&2 echo 'Fixing chapter titles...'

find "${OEBPS}" -iregex '.+?/.+\.x?html?' | while read -r f; do
  sed -ri 's#<p id="([^"]+)" class="chaptitle">([^>]+)</p>#<h1 id="\1" class="chaptitle">\2</h1>#g' "$f"
done
