#!/bin/bash

set -euo pipefail

trimmed_book_url=$(echo "${BOOK_URL}" | sed -r 's#/[0-9]+/\?callback=.+##')

declare -i current_section=1
declare -i section_count=0
while true; do
  target_file="${TARGET_DIR}/OEBPS/Text/$(printf "section%03d.html" $current_section)"

  if [[ ( "$REFETCH" == 1 || $section_count -eq 0 ) || ! -f "${target_file}" ]]; then
    >&2 echo "fetching section ${current_section}"
    _download_json "${trimmed_book_url}/${current_section}/"

    if [[ $section_count -eq 0 ]]; then
      section_count="$(jq -r .TotalIndexCount tmp.json)"
    fi

    if [[ $current_section -ge $section_count ]]; then
      break
    fi

    jq -r .Source tmp.json | dos2unix > "${target_file}"
    >&2 echo "saved section ${current_section}"
    sleep 0.5
  fi

  _=$(( current_section++ ))
done

rm -f tmp.json
