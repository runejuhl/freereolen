#!/bin/bash
#
#
# Created with help from the following resources:
#
# + https://ebooks.stackexchange.com/questions/257/how-to-repack-an-epub-file-from-command-line
# + https://blogs.datalogics.com/2013/10/09/embedding-a-font-into-an-epub-file/

set -euo pipefail

export BOOK_URL="${1}"
export TARGET_DIR="${2}"
export OUTPUT_DIR="${PWD}"
export OEBPS="${TARGET_DIR}/OEBPS"
shift 2

export REFETCH=0

cwd="${BASH_SOURCE%/*}"
"${cwd}/get.sh"
"${cwd}/fix-headings.sh"
"${cwd}/download-remote-files.sh"
"${cwd}/remove-marks.sh"
"${cwd}/tidy.sh"
"${cwd}/assemble.sh"
