#!/bin/bash

set -euo pipefail

function _download() {
  url="${1}"
  out="${2:-}"

  if ! curl \
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
