#!/bin/bash
#
# shellcheck disable=SC2016,SC2034,SC2155

set -euo pipefail

OUTPUT_FILE="${OUTPUT_DIR}/"

if [[ -n "${OPF_AUTHOR}" ]]; then
  OUTPUT_FILE+="${OPF_AUTHOR} - "
fi

OUTPUT_FILE+="${OPF_TITLE}"
if [[ -n "${OPF_DATE}" && ! "${OPF_DATE}" =~ ^0+$ ]]; then
  OUTPUT_FILE+=" (${OPF_DATE})"
fi

OUTPUT_FILE+='.epub'

export OPF_COVER_IMAGE="${OPF_COVER_IMAGE:-$(basename "$(tr \\n ' ' <"${FIRST_PAGE}" | grep -Eo '<img [^>]+/>' | get_attr src)")}" \

read -rd HEADER_TEMPLATE <<'EOF'
    <dc:language>${OPF_LANGUAGE}</dc:language>
    <dc:title>${OPF_TITLE}</dc:title>
    <dc:date opf:event="publication">${OPF_DATE}</dc:date>
    <dc:creator id="creator01">${OPF_AUTHOR}</dc:creator>
    <meta name="cover" content="${OPF_COVER_IMAGE}" />
    <dc:identifier opf:scheme="UUID" id="BookId">urn:uuid:${OPF_BOOK_ID}</dc:identifier>
EOF

read -rd TOC_DOCTITLE_TEMPLATE <<'EOF'
  <docTitle>
    <text>${OPF_TITLE}</text>
  </docTitle>
EOF

read -rd TOC_NAVPOINT_TEMPLATE <<'EOF'
    <navPoint id="navPoint-${NAVPOINT_INDEX}" playOrder="${NAVPOINT_INDEX}">
      <navLabel>
        <text>${GUIDE_LINE_TEMPLATE_TITLE}</text>
      </navLabel>
      <content src="${GUIDE_LINE_TEMPLATE_HREF}"/>
    </navPoint>
EOF

read -rd MANIFEST_LINE_TEMPLATE <<'EOF'
    <item id="${MANIFEST_LINE_ID}" href="${MANIFEST_LINE_HREF}" media-type="${MANIFEST_LINE_MEDIA_TYPE}"/>
EOF

read -rd SPINE_TOC_TEMPLATE <<'EOF'
    <itemref idref="${MANIFEST_LINE_ID}"/>
EOF

read -rd GUIDE_TEMPLATE <<'EOF'
  <guide>
    ${GUIDE_COVER_LINES}
  </guide>
EOF


read -rd GUIDE_LINE_TEMPLATE <<'EOF'
    <reference type="${GUIDE_LINE_TEMPLATE_TYPE}" title="${GUIDE_LINE_TEMPLATE_TITLE}" href="${GUIDE_LINE_TEMPLATE_HREF}"/>
EOF

GUIDE_COVER_TEMPLATE='<reference type="${GUIDE_COVER_TYPE}" title="${GUIDE_COVER_TITLE}" href="${GUIDE_COVER_HREF}"/>'

export HEADER="$(envsubst <<<"${HEADER_TEMPLATE}")"

# build the manifest
export MANIFEST='' \
       MANIFEST_LINE_HREF \
       MANIFEST_LINE_MEDIA_TYPE \
       MANIFEST_LINE_ID
export SPINE_TOC=''

while read -r f; do
  MANIFEST_LINE_MEDIA_TYPE="$(file --brief --mime-type "${f}")"
  MANIFEST_LINE_HREF="${f#${OEBPS}/}"
  MANIFEST_LINE_ID="$(basename "${f}")"
  MANIFEST+="$(envsubst <<<"${MANIFEST_LINE_TEMPLATE}")"

  if [[ "${MANIFEST_LINE_HREF}" =~ \.html$ ]]; then
    SPINE_TOC+="$(envsubst <<<"${SPINE_TOC_TEMPLATE}")"
  fi

done < <(find "${OEBPS}" -type f | sort)
export GUIDE_COVER_LINES='' \
       GUIDE_LINE_TEMPLATE_HREF \
       GUIDE_LINE_TEMPLATE_TITLE \
       GUIDE_LINE_TEMPLATE_TYPE \
       TOC_NAVMAP_LINES=''

declare -A GUIDE_TYPE_COUNT
declare -xi NAVPOINT_INDEX=0

# build the guide

set -x
# start by looking for epub spec markers
if [[ "${GUIDE_COVER_LINES}" == '' ]]; then
  while read -r match; do
    [[ "${match}" =~ ^([^:]+):(.+)$ ]]
    GUIDE_LINE_TEMPLATE_HREF="${BASH_REMATCH[1]}"
    tag="${BASH_REMATCH[2]}"
    GUIDE_LINE_TEMPLATE_TYPE="$(echo "${tag}" | get_attr epub:type)"

    if ! grep -E "${GUIDE_COVER_VOCABULARY}" <<< "${GUIDE_LINE_TEMPLATE_TYPE}"; then
      continue
    fi

    GUIDE_LINE_TEMPLATE_TITLE="$(get_title "${OEBPS}/${GUIDE_LINE_TEMPLATE_HREF}")"
    # if title is the same as the book title then we just use the name of the
    # type
    if [[ "${GUIDE_LINE_TEMPLATE_TITLE}" == "${OPF_TITLE}" ]]; then
      count=${GUIDE_TYPE_COUNT[${GUIDE_LINE_TEMPLATE_TYPE}]:-0}
      _=$((count++))
      GUIDE_TYPE_COUNT["${GUIDE_LINE_TEMPLATE_TYPE}"]=$count
      GUIDE_LINE_TEMPLATE_TITLE="$(wordify "${GUIDE_LINE_TEMPLATE_TYPE}") ${count}"
    fi

    GUIDE_COVER_LINES+="$(envsubst <<<"${GUIDE_LINE_TEMPLATE}")"

    if [[ "${GUIDE_LINE_TEMPLATE_TYPE}" == 'chapter' ]]; then
      _=$((NAVPOINT_INDEX++))
      TOC_NAVMAP_LINES+="$(envsubst <<<"${TOC_NAVPOINT_TEMPLATE}")"
    fi
  done < <( (cd "${OEBPS}" && grep -r -i epub:type | sort ) )
fi

# if we don't have any markers we'll make do with the index
if [[ "${GUIDE_COVER_LINES}" == '' ]]; then

  # start with just using the index
  NAVPOINT_INDEX=1

  until [[ $NAVPOINT_INDEX -eq $SECTION_COUNT ]]; do
    file=$(_jq index.json ".[${NAVPOINT_INDEX}].Filename")
    GUIDE_LINE_TEMPLATE_HREF="Text/${file}"
    GUIDE_LINE_TEMPLATE_TITLE="$(_jq index.json ".[${NAVPOINT_INDEX}].Title")"
    GUIDE_LINE_TEMPLATE_TYPE=$(deduce_type_from_filename "${file}")

    GUIDE_COVER_LINES+="$(envsubst <<<"${GUIDE_LINE_TEMPLATE}")"
    TOC_NAVMAP_LINES+="$(envsubst <<<"${TOC_NAVPOINT_TEMPLATE}")"

    _=$((NAVPOINT_INDEX++))
  done

fi

set +x

# Broken epubs may use non-standard chapter markers
if [[ "${GUIDE_COVER_LINES}" == '' ]]; then
  while read -r match; do
    [[ "${match}" =~ ^([^:]+):(.+)$ ]]
    GUIDE_LINE_TEMPLATE_HREF="${BASH_REMATCH[1]}"
    tag="${BASH_REMATCH[2]}"
    GUIDE_LINE_TEMPLATE_TYPE=chapter
    GUIDE_LINE_TEMPLATE_TITLE="$(echo "${tag}" | strip_tags)"

    count=${GUIDE_TYPE_COUNT[${GUIDE_LINE_TEMPLATE_TYPE}]:-0}
    _=$((count++))

    GUIDE_COVER_LINES+="$(envsubst <<<"${GUIDE_LINE_TEMPLATE}")"

    _=$((NAVPOINT_INDEX++))
    TOC_NAVMAP_LINES+="$(envsubst <<<"${TOC_NAVPOINT_TEMPLATE}")"
  done < <( (cd "${OEBPS}" && grep -r -i '"chaptitle"' | sort ) )
fi

export GUIDE="$(envsubst <<<"${GUIDE_TEMPLATE}")"
export TOC_DOCTITLE="$(envsubst <<<"${TOC_DOCTITLE_TEMPLATE}")"

envsubst < template/OEBPS/content.opf > "${TARGET_DIR}/OEBPS/content.opf"
envsubst < template/OEBPS/toc.ncx > "${TARGET_DIR}/OEBPS/toc.ncx"
cp template/META-INF/container.xml "${TARGET_DIR}/META-INF/"

pushd "${TARGET_DIR}"

echo -n 'application/epub+zip' > mimetype
zip -X0 "${OUTPUT_FILE}" "mimetype"
zip -Xr "${OUTPUT_FILE}" "META-INF/" "OEBPS/"

popd

if [[ "${CLEAN}" != '0' ]]; then
  rm -rf "${TARGET_DIR}"
fi

echo "Wrote ${OUTPUT_FILE}"
