#!/bin/bash

>&2 echo "Removing colophon"

grep -Erl '"ekolofon-web"' . | \
  while read -r f; do
    sed -ri '/<.+?"ekolofon-web"/D' "$f"
  done
