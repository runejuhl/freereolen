#!/bin/bash

>&2 echo "Removing colophon"

grep -Erl '"ekolofon-web"' . | \
  while read -r f; do
    echo "fixme $f"
    # FIXME
  done
