#!/bin/bash

set -euo pipefail

trimmed_book_url=$(echo "${BOOK_URL}" | sed -r 's#/[0-9]+/\?callback=.+##')

_download_json "${trimmed_book_url}/indexes/" index.json

declare -i current_section=1
# shellcheck disable=SC2155
{
  declare -ix SECTION_COUNT=$(_jq index.json '.[-1].Index')
  export FIRST_PAGE="${OEBPS}/Text/$(_jq index.json '.[1].Filename')"
}

while true; do
  target_file="${OEBPS}/Text/$(_jq index.json ".[$current_section].Filename")"

  if should_refetch || [[ ! -f "${target_file}" ]]; then
    >&2 echo "fetching section ${current_section}"
    _download_json "${trimmed_book_url}/${current_section}/"

    if [[ $current_section -ge $SECTION_COUNT ]]; then
      break
    fi

    jq -r .Source tmp.json | dos2unix > "${target_file}"
    >&2 echo "saved section ${current_section}"
    sleep 0.5
  fi

  _=$(( current_section++ ))
done

if should_clean; then
  rm -f tmp.json
fi
