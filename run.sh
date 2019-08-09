#!/bin/bash
#
#
# Created with help from the following resources:
#
# + https://ebooks.stackexchange.com/questions/257/how-to-repack-an-epub-file-from-command-line
# + https://blogs.datalogics.com/2013/10/09/embedding-a-font-into-an-epub-file/
#
# shellcheck disable=SC1090,SC2155

set -euo pipefail

export BOOK_URL="${1}"
TMPDIR="${TMPDIR:-/tmp}"
export TARGET_DIR="${TMPDIR}/makeebook/$( (sha256sum | cut -d' ' -f1) <<< "${BOOK_URL}")"
mkdir -p "${TARGET_DIR}"

export OUTPUT_DIR="${PWD}"
export OEBPS="${TARGET_DIR}/OEBPS"
export FIRST_PAGE="${OEBPS}/Text/section001.html"

export CLEAN="${CLEAN:-1}" \
       REFETCH="${REFETCH:-0}"

mkdir -p "${TARGET_DIR}"/{META-INF,OEBPS/{,Fonts,Images,Text}}

export CWD="${BASH_SOURCE%/*}"

. "${CWD}/common.sh"

. "${CWD}/get.sh"
. "${CWD}/set-variables.sh"
. "${CWD}/fix-headings.sh"
. "${CWD}/download-remote-files.sh"
. "${CWD}/anonymize.sh"
. "${CWD}/tidy.sh"
. "${CWD}/assemble.sh"
