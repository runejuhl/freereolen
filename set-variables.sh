#!/bin/bash
#
# shellcheck disable=SC1090,SC2155

set -euo pipefail

if [[ -f "${METADATA_FILE}" ]]; then
  set -a
  . "${METADATA_FILE}"
  set +a
fi

export OPF_DATE="${OPF_DATE:-0000}" \
       OPF_TITLE="${OPF_TITLE:-$(get_title "${FIRST_PAGE}")}" \
       OPF_LANGUAGE="${OPF_LANGUAGE:-$(get_language "${FIRST_PAGE}")}" \
       OPF_COVER_IMAGE="${OPF_COVER_IMAGE:-Images/$(get_cover_image_name)}"

export OPF_BOOK_ISBN="${OPF_BOOK_ISBN:-$(get_book_isbn)}"

# Generate a stable UUID from the publication title
export OPF_BOOK_ID="${OPF_BOOK_ID:-$(uuidgen -n @oid -N "${OPF_TITLE}" --sha1)}"

# FIXME: is this correct, or is the ID actually the second regex?
export OPF_BOOK_ID_ORIGINAL="${OPF_BOOK_ID_ORIGINAL:-$(grep -Eo --max-count=1 'https://streaming.pubhub.dk/StreamPackages/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}' "${FIRST_PAGE}" | awk -F/ '{print $NF}')}"

export OPF_AUTHOR="${OPF_AUTHOR:-$(get_author)}"
export OPF_LANGUAGE_SHORT

while (( EDIT_METADATA == 1 )); do
  read -r -e -p 'Author: ' -i "${OPF_AUTHOR}" OPF_AUTHOR

  if [[ ! "${OPF_AUTHOR}" =~ \>\< ]]; then
    break
  fi

  log 'invalid author'
done

while (( EDIT_METADATA == 1 )); do
  read -r -e -p 'Title: ' -i "${OPF_TITLE}" OPF_TITLE

  if [[ ! "${OPF_TITLE}" =~ \>\< ]]; then
    break
  fi

  log 'invalid title'
done

while (( EDIT_METADATA == 1 )); do
  read -r -e -p 'Date: ' -i "${OPF_DATE}" OPF_DATE

  if [[ "${OPF_DATE}" =~ ^[0-9]{4}(-[0-9]{2}-[0-9]{2})?$ ]]; then
    break
  fi

  log 'invalid date'
done

while (( EDIT_METADATA == 1 )); do
  read -r -e -p 'Language code: ' -i "${OPF_LANGUAGE}" OPF_LANGUAGE

  # Validation is hard! See https://github.com/w3c/epubcheck/issues/702,
  # http://idpf.org/epub/30/spec/epub30-publications.html#elemdef-opf-dclanguage
  # and https://github.com/w3c/epubcheck/issues/702
  #
  # We just check that the two first characters are lower-case characters;
  # that's all we need to open the dict.
  if [[ "${OPF_LANGUAGE}" =~ ^([a-z]{2}) ]]; then
    OPF_LANGUAGE_SHORT="${BASH_REMATCH[1]}"
    break
  fi

  log 'invalid language code'
done

# TODO: Write metadata file to user dir
cat > "${METADATA_FILE}" <<EOF
OPF_BOOK_ID="${OPF_BOOK_ID}"
OPF_BOOK_ID_ORIGINAL="${OPF_BOOK_ID_ORIGINAL}"
OPF_DATE="${OPF_DATE}"
OPF_TITLE="${OPF_TITLE}"
OPF_LANGUAGE="${OPF_LANGUAGE}"
OPF_LANGUAGE_SHORT="${OPF_LANGUAGE_SHORT}"
OPF_AUTHOR="${OPF_AUTHOR}"
EOF

# load dictionary for localized translations of markers
i18n_dict="${CWD}/i18n/${OPF_LANGUAGE_SHORT}.sh"
if [[ -f "${i18n_dict}" ]]; then
  . "${i18n_dict}"
fi
