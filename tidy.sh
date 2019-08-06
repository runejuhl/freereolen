#!/bin/bash

>&2 echo "Running tidy..."

find . -iregex '.+?/.+\.x?html?' | \
  while read -r f; do
    tidy -modify \
         -quiet \
         --warn-proprietary-attributes no \
         --tidy-mark 0 \
         "$f"
  done
