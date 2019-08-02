#!/bin/bash

set -euo pipefail

url="$1"
# url='https://streaming.pubhub.dk/publicstreaming/v3/57390305-cb51-4161-afda-cd4049de1df0/67428365-0936-4348-b4bb-b2b02f1d854f/1/?callback=jQuery111008914592642029278_1564765367312&_=1564765367324'
# current_page=$(echo "${url}" | sed -r 's#.+/([0-9]+)/\?callback=.+#\1#')
trimmed_url=$(echo "${url}}" | sed -r 's#/[0-9]+/\?callback=.+##')

function _curl() {
  url="$1"
  out="${2:-tmp.json}"

  curl -s "${url}" -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' -H 'Accept: */*' -H 'Accept-Language: da-DK;q=0.7,en;q=0.3' --compressed -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Referer: https://streaming.pubhub.dk/' | sed -r 's/^jQuery[0-9]+_[0-9]+\((.+)\);/\1/' > "${out}"
}

current_page=1
page_count=0
while true; do
  >&2 echo "fetching page ${current_page}"
  _curl "${trimmed_url}/${current_page}/"

  if [[ $page_count -eq 0 ]]; then
    page_count="$(jq -r .TotalIndexCount tmp.json)"
  fi

  if [[ $current_page -ge $page_count ]]; then
    break
  fi

  jq -r .Source tmp.json | dos2unix > "page${current_page}.html"
  current_page=$(( current_page + 1))
  sleep 0.5
done

rm -f tmp.json

# exit
# curl "$url"  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' -H 'Accept: */*' -H 'Accept-Language: da-DK;q=0.7,en;q=0.3' --compressed -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Referer: https://streaming.pubhub.dk/' | sed -r 's/^jQuery[0-9]+_[0-9]+\((.+)\);/\1/' > tmp.json

# total_pages=$(jq .TotalIndexCount tmp.json)
