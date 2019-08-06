#!/bin/bash

set -euo pipefail

first_page="${TARGET_DIR}/OEBPS/Text/section001.html"

# find "${TARGET_DIR}/OEBPS"

function strip_tags() {
  sed -r 's#<[^>]+>([^<]+)</[^>]+>#\1#g'
}

function get_attr() {
  attr="$1"

  sed -r "s#.* ${attr}= *(('([^']+)')|(\"([^\"]+)\")).*#\\3\\5#"
}

OPF_DATE="${OPF_DATE:-0000}"
OPF_TITLE="${OPF_TITLE:-$(grep -E '<title>[^<]+</title>' "${first_page}" | strip_tags)}"
OPF_COVER_IMAGE="${OPF_COVER_IMAGE:-$(tr \\n ' ' <"${first_page}" | grep -Eo '<img [^>]+/>' | get_attr src)}"
OPF_LANGUAGE="${OPF_LANGUAGE:-$(tr \\n ' ' <"${first_page}" | grep -Eo '<html [^>]+>' | get_attr xml:lang)}"

read -r HEADER_TEMPLATE <<EOF
    <dc:language>${OPF_LANGUAGE}</dc:language>
    <dc:title>${OPF_TITLE}</dc:title>
    <dc:date opf:event="publication">${OPF_DATE}</dc:date>
    <meta name="cover" content="${OPF_COVER_IMAGE}" />
EOF

read -r DOCTITLE_TEMPLATE <<'EOF'
  <docTitle>
    <text>${DOCTITLE_TITLE}</text>
  </docTitle>
EOF

read -r NAVPOINT_TEMPLATE <<'EOF'
    <navPoint id="navPoint-${NAVPOINT_ID}" playOrder="${NAVPOINT_ID}">
      <navLabel>
        <text>${NAVPOINT_LABEL}</text>
      </navLabel>
      <content src="${NAVPOINT_SRC}"/>
    </navPoint>
EOF

echo "${HEADER_TEMPLATE}" | envsubst
