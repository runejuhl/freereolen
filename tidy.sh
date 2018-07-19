#!/bin/bash

find . -iregex '.*\.[hx]tml?' | \
  while read -r f; do
    tidy -modify -quiet --tidy-mark 0 "$f"
  done
