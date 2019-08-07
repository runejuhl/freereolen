#!/bin/bash
#
#
# Created with help from the following resources:
#
# + https://ebooks.stackexchange.com/questions/257/how-to-repack-an-epub-file-from-command-line
# + https://blogs.datalogics.com/2013/10/09/embedding-a-font-into-an-epub-file/
#
# shellcheck disable=SC1090


set -euo pipefail

export BOOK_URL="${1}"
export TARGET_DIR="${2}"
export OUTPUT_DIR="${PWD}"
export OEBPS="${TARGET_DIR}/OEBPS"
shift 2

export CLEAN="${CLEAN:-1}" \
       REFETCH="${REFETCH:-0}"

mkdir -p "${TARGET_DIR}"/{META-INF,OEBPS/{,Fonts,Images,Text}}

cwd="${BASH_SOURCE%/*}"

. "${cwd}/common.sh"

. "${cwd}/get.sh"
. "${cwd}/fix-headings.sh"
. "${cwd}/download-remote-files.sh"
. "${cwd}/tidy.sh"
. "${cwd}/assemble.sh"
