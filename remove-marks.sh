#!/bin/bash

grep -Erl '"ekolofon-web"' . | \
  while read -r f; do
    sed -ri '/<.+?"ekolofon-web"/D' "$f"
  done
