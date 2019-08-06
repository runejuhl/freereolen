#!/bin/bash

set -euo pipefail

trimmed_book_url=$(echo "${BOOK_URL}" | sed -r 's#/[0-9]+/\?callback=.+##')

function _curl() {
  url="$1"
  out="${2:-tmp.json}"

  if ! curl -s "${url}" -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' -H 'Accept: */*' -H 'Accept-Language: da-DK;q=0.7,en;q=0.3' --compressed -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Referer: https://streaming.pubhub.dk/' | sed -r 's/^jQuery[0-9]+_[0-9]+\((.+)\);/\1/' > "${out}"; then
    >&2 echo "An error occurred when fetching '${url}'"
    exit 1
  fi
}

declare -i current_section=1
declare -i section_count=0
while true; do
  target_file="${TARGET_DIR}/OEBPS/Text/$(printf "section%03d.html" $current_section)"

  if [[ ( "$REFETCH" == 1 || $section_count -eq 0 ) || ! -f "${target_file}" ]]; then
    >&2 echo "fetching section ${current_section}"
    _curl "${trimmed_book_url}/${current_section}/"

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
