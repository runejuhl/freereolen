#!/bin/bash
#
# shellcheck disable=SC1090,SC2155

set -euo pipefail

export OPF_DATE="${OPF_DATE:-0000}" \
       OPF_TITLE="${OPF_TITLE:-$(get_title "${FIRST_PAGE}")}" \
       OPF_LANGUAGE="${OPF_LANGUAGE:-$(get_language "${FIRST_PAGE}")}"

# Generate a stable UUID from the publication title
export OPF_BOOK_ID="${OPF_BOOK_ID:-$(uuidgen -n @oid -N "${OPF_TITLE}" --sha1)}"

export OPF_BOOK_ID_ORIGINAL="$(grep -Eo --max-count=1 'https://streaming.pubhub.dk/StreamPackages/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}' "${FIRST_PAGE}" | awk -F/ '{print $NF}')"

export OPF_AUTHOR="${OPF_AUTHOR:-$(get_author)}"

while [[ -z "${OPF_AUTHOR}" ]]; do
  read -r -e -p 'Author: ' OPF_AUTHOR
done

while [[ -z "${OPF_TITLE}" ]]; do
  read -r -e -p 'Title: ' OPF_TITLE
done

while [[ -z "${OPF_DATE}" || "${OPF_DATE}" == '0000' ]]; do
  read -r -e -p 'Date: ' OPF_DATE
done

[[ ! "${OPF_DATE}" =~ ^[0-9]{4}(-[0-9]{2}-[0-9]{2})?$ ]] && \
  error 10 'invalid date'

[[ "${OPF_TITLE}" =~ \>\< ]] && \
  error 11 'invalid title'

[[ "${OPF_AUTHOR}" =~ \>\< ]] && \
  error 11 'invalid author'

# load dictionary for localized translations of markers
i18n_dict="${CWD}/i18n/${OPF_LANGUAGE}.sh"
if [[ -f "${i18n_dict}" ]]; then
  . "${i18n_dict}"
fi
