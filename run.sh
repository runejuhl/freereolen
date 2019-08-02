#!/bin/bash

set -euo pipefail

export BOOK_URL="${1}"
export TARGET_DIR="${2}"
shift 2

export REFETCH=0
# set basedir
export pwd="${BASH_SOURCE%/*}"
rsync -Paq "template/" "${TARGET_DIR}/"

"${pwd}/get.sh"
"${pwd}/fix-headings.sh"
"${pwd}/download-remote-files.sh"
"${pwd}/remove-marks.sh"
"${pwd}/tidy.sh"
