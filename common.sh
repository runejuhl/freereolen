#!/bin/bash

set -euo pipefail

# We only want to use the following structure IDs for the content guide
#
# https://idpf.github.io/epub-vocabs/structure/
GUIDE_COVER_VOCABULARY='title|cover|frontmatter|bodymatter|backmatter|volume|part|chapter|subchapter|division|abstract|foreword|preface|prologue|introduction|preamble|conclusion|epilogue|afterword|epigraph|toc|toc-brief|landmarks|loa|loi|lot|lov|appendix|colophon|credits|keywords|copyright-page|copyright'
# These are just here in case we need them in the future.
_GUIDE_COVER_VOCABULARY_IGNORED=(index index-headnotes index-legend index-group index-entry-list index-entry index-term index-editor-note index-locator index-locator-list index-locator-range index-xref-preferred index-xref-related index-term-category index-term-categories glossary glossterm glossdef bibliography biblioentry titlepage halftitlepage copyright-page seriespage acknowledgments imprint imprimatur contributors other-credits errata dedication revision-history case-study help marginalia notice pullquote sidebar tip warning halftitle fulltitle covertitle subtitle label ordinal bridgehead learning-objective learning-objectives learning-outcome learning-outcomes learning-resource learning-resources learning-standard learning-standards answer answers assessment assessments feedback fill-in-the-blank-problem general-problem qna match-problem multiple-choice-problem practice question practices true-false-problem panel panel-group balloon text-area sound-area annotation note footnote endnote rearnote footnotes endnotes rearnotes annoref biblioref glossref noteref backlink credit keyword topic-sentence concluding-sentence pagebreak page-list table table-row table-cell list list-item figure aside)

declare -A GUIDE_COVER_VOCABULARY_NONSTANDARD_LOOKUP=(
  [copyright]='copyright-page'
)

function _download() {
  url="${1}"
  out="${2:-}"

  if ! curl \
       --fail \
       -s "${url}" \
       -o "${out}" \
       -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' \
       -H 'Accept: */*' \
       -H 'Accept-Language: da-DK;q=0.7,en;q=0.3' \
       --compressed \
       -H 'DNT: 1' \
       -H 'Connection: keep-alive' \
       -H 'Referer: https://streaming.pubhub.dk/'; then
    >&2 echo "An error occurred when fetching '${url}'"
    exit 1
  fi
}

function _download_json() {
  url="${1}"
  out="${2:-tmp.json}"

  if ! _download "${url}" "${out}"; then
    >&2 echo "An error occurred when fetching '${url}'"
    exit 1
  fi
}

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

function get_translation() {
  set +o nounset
  word="${DICT[${1}]}"
  set -o nounset
  if [[ -z "${word}" ]]; then
    word="${1}"
  fi

  echo -n "${word}"
}

function wordify() {
  word="$(get_translation "${1}")"
  echo "${word^}" | tr - ' '
}

function get_author() {
  # Find a file that has the author tag
  file_line="$(grep -Eirn 'class="e?author"' "${OEBPS/Text}")"
  if ! [[ "${file_line}" =~ ^([^:]+?\.html):([0-9]+): ]]; then
    return
  fi
  file="${BASH_REMATCH[1]}"
  line="${BASH_REMATCH[2]}"

  # Author name may be split over multiple lines, so we need to treat it
  # carefully
  file_content=$(tail -n "${line}" "${file}" | tr \\n ' ')

  text="$(grep -Po '<[^ ]+ +class=.?e?author.?.*?</[^ ]+>' <<< "${file_content}")"
  # turn line breaks into commas
  text="$(sed -r 's#<br ?/?>#, #g' <<< "${text}")"

  echo "$text" | strip_tags
}

function get_language() {
  page="${1}"
  tr \\n ' ' <"${page}" | grep -Eo '<html .*?xml:lang.*? [^>]+?>' | get_attr xml:lang || echo 'en'
}

function should_clean() {
  [[ "${CLEAN}" != '0' ]]
}

function should_refetch() {
  [[ "${REFETCH}" != '0' ]]
}

function _jq() {
    jq -r "${2}" < "${1}"

}

function deduce_type_from_filename() {
  type="$(grep -Eo "${GUIDE_COVER_VOCABULARY}" <<< "${1}")"

  type="${GUIDE_COVER_VOCABULARY_NONSTANDARD_LOOKUP[$type]:-$type}"
  echo "${type}"
}
