#!/bin/bash

set -euo pipefail

export FIRST_PAGE
declare -ix SECTION_COUNT

trimmed_book_url=$(echo "${BOOK_URL}" | sed -r 's#/[0-9]+/\?callback=.+##')

_download "${trimmed_book_url}/indexes/" "${JSON_INDEX_FILE}"

declare -i current_section=1
SECTION_COUNT=$(_jq "${JSON_INDEX_FILE}" '.[-1].Index')
FIRST_PAGE="${OEBPS}/Text/$(_jq "${JSON_INDEX_FILE}" '.[0].Filename')"

while (( DOWNLOAD == 1 )); do
  target_file="${OEBPS}/Text/$(_jq "${JSON_INDEX_FILE}" ".[$((current_section-1))].Filename")"

  if should_refetch || [[ ! -f "${target_file}" ]]; then
    log "fetching section ${current_section}"
    _download_js_json "${trimmed_book_url}/${current_section}/" "${target_file}"
    log "saved section ${current_section} to '${target_file}'"
  fi

  if [[ $current_section -ge $SECTION_COUNT ]]; then
      break
  fi

  _=$(( current_section++ ))
done
