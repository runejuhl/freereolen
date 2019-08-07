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

function wordify() {
  echo "${1^}" | tr - ' '
}
