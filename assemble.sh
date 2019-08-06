#!/bin/bash
#
# shellcheck disable=SC2155

set -euo pipefail

first_page="${TARGET_DIR}/OEBPS/Text/section001.html"

function strip_tags() {
  sed -r 's#<[^>]+>([^<]+)</[^>]+>#\1#g'
}

function get_attr() {
  attr="$1"

  sed -r "s#.* ${attr}= *(('([^']+)')|(\"([^\"]+)\")).*#\\3\\5#"
}

function get_title() {
  tr \\n ' ' <"${1}" | grep -Eo '<title>[^<]+</title>' | strip_tags
}

function wordify() {
  echo "${1^}" | tr - ' '
}

export OPF_DATE="${OPF_DATE:-0000}" \
       OPF_TITLE="${OPF_TITLE:-$(get_title "${first_page}")}" \
       OPF_COVER_IMAGE="${OPF_COVER_IMAGE:-$(tr \\n ' ' <"${first_page}" | grep -Eo '<img [^>]+/>' | get_attr src)}" \
       OPF_LANGUAGE="${OPF_LANGUAGE:-$(tr \\n ' ' <"${first_page}" | grep -Eo '<html [^>]+>' | get_attr xml:lang)}"

read -rd HEADER_TEMPLATE <<'EOF'
    <dc:language>${OPF_LANGUAGE}</dc:language>
    <dc:title>${OPF_TITLE}</dc:title>
    <dc:date opf:event="publication">${OPF_DATE}</dc:date>
    <meta name="cover" content="${OPF_COVER_IMAGE}" />
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



# https://idpf.github.io/epub-vocabs/structure/
_GUIDE_COVER_VOCABULARY=(cover frontmatter bodymatter backmatter volume part chapter subchapter division abstract foreword preface prologue introduction preamble conclusion epilogue afterword epigraph toc toc-brief landmarks loa loi lot lov appendix colophon credits keywords index index-headnotes index-legend index-group index-entry-list index-entry index-term index-editor-note index-locator index-locator-list index-locator-range index-xref-preferred index-xref-related index-term-category index-term-categories glossary glossterm glossdef bibliography biblioentry titlepage halftitlepage copyright-page seriespage acknowledgments imprint imprimatur contributors other-credits errata dedication revision-history case-study help marginalia notice pullquote sidebar tip warning halftitle fulltitle covertitle title subtitle label ordinal bridgehead learning-objective learning-objectives learning-outcome learning-outcomes learning-resource learning-resources learning-standard learning-standards answer answers assessment assessments feedback fill-in-the-blank-problem general-problem qna match-problem multiple-choice-problem practice question practices true-false-problem panel panel-group balloon text-area sound-area annotation note footnote endnote rearnote footnotes endnotes rearnotes annoref biblioref glossref noteref backlink credit keyword topic-sentence concluding-sentence pagebreak page-list table table-row table-cell list list-item figure aside)

GUIDE_COVER_TEMPLATE='<reference type="${GUIDE_COVER_TYPE}" title="${GUIDE_COVER_TITLE}" href="${GUIDE_COVER_HREF}"/>'

export HEADER="$(envsubst <<<"${HEADER_TEMPLATE}")"

# build the manifest
export MANIFEST='' \
       MANIFEST_LINE_HREF \
       MANIFEST_LINE_MEDIA_TYPE \
       MANIFEST_LINE_ID
export SPINE_TOC=''

while read -r MANIFEST_LINE_HREF; do
  MANIFEST_LINE_MEDIA_TYPE=$(file --brief --mime-type "${MANIFEST_LINE_HREF}")
  MANIFEST_LINE_ID=$(basename "${MANIFEST_LINE_HREF}")
  MANIFEST+="$(envsubst <<<"${MANIFEST_LINE_TEMPLATE}")"

  if [[ "${MANIFEST_LINE_HREF}" =~ \.html$ ]]; then
    SPINE_TOC+="$(envsubst <<<"${SPINE_TOC_TEMPLATE}")"
  fi

done < <(find "${TARGET_DIR}/OEBPS" | sort)
export GUIDE_COVER_LINES='' \
       GUIDE_LINE_TEMPLATE_HREF \
       GUIDE_LINE_TEMPLATE_TITLE \
       GUIDE_LINE_TEMPLATE_TYPE \
       TOC_NAVMAP_LINES=''

declare -A GUIDE_TYPE_COUNT
declare -xi NAVPOINT_INDEX=0
# build the guide
while read -r match; do
  [[ "${match}" =~ ^([^:]+):(.+)$ ]]
  GUIDE_LINE_TEMPLATE_HREF="${BASH_REMATCH[1]}"
  tag="${BASH_REMATCH[2]}"
  GUIDE_LINE_TEMPLATE_TYPE="$(echo "${tag}" | get_attr epub:type)"

  GUIDE_LINE_TEMPLATE_TITLE="$(get_title "${OEBPS}/${GUIDE_LINE_TEMPLATE_HREF}")"
  # if title is the same as the book title then we just use the name of the
  # type
  if [[ "${GUIDE_LINE_TEMPLATE_TITLE}" == "${OPF_TITLE}" ]]; then
    count=${GUIDE_TYPE_COUNT[${GUIDE_LINE_TEMPLATE_TYPE}]:-0}
    _=$((count++))
    GUIDE_TYPE_COUNT["${GUIDE_LINE_TEMPLATE_TYPE}"]=$count
    GUIDE_LINE_TEMPLATE_TITLE="$(wordify "${GUIDE_LINE_TEMPLATE_TYPE} ${count}")"
  fi

  GUIDE_COVER_LINES+="$(envsubst <<<"${GUIDE_LINE_TEMPLATE}")"

  if [[ "${GUIDE_LINE_TEMPLATE_TYPE}" == 'chapter' ]]; then
    _=$((NAVPOINT_INDEX++))
    TOC_NAVMAP_LINES+="$(envsubst <<<"${TOC_NAVPOINT_TEMPLATE}")"
  fi
done < <( (cd "${OEBPS}" && grep -r -i epub:type | sort ) )

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
