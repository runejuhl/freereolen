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

function usage() {
  cat <<EOF
[CLEAN=0|1] [REFETCH=[0|1] ${0} <EREOLEN-UUID-URL> [OUTPUT-FILE]

Download ebooks from eReolen.dk and assemble them into full epubs.

Fetches remote resources (images, fonts), cleans HTML with tidy, anonymizes the
files (by replacing bookId UUIDs) and assembles it into a epub, complete with
TOC.

Output file is named as "\${AUTHOR} - \${TITLE} (\${DATE})".

The following environment variables may be used to set values:
  - OPF_AUTHOR
  - OPF_DATE
  - OPF_LANGUAGE
  - OPF_TITLE

Example:
  OPF_AUTHOR='Terry Pratchett' ${0} 'https://streaming.pubhub.dk/publicstreaming/v3/69f63101-9caf-40b9-a31e-b2fdb5642e3d/43c44150-9d2c-4506-8fe6-c0bb904ea563/1/?callback=jQuery11100348712123123213_123123121313&_=1231313123123'
EOF

  exit 0
}

if [[ $# -ne 1 ]]; then
  usage
fi

export CWD="${BASH_SOURCE%/*}"
. "${CWD}/common.sh"

export BOOK_URL="${1}"
export TMP="${TMP:-/tmp}"
export TARGET_DIR="${TMP}/makeebook/$( (grep_uuids | last) <<< "${BOOK_URL}")"
export OUTPUT_DIR="${PWD}"
export OEBPS="${TARGET_DIR}/OEBPS"

export CLEAN="${CLEAN:-1}" \
       REFETCH="${REFETCH:-0}"

mkdir -p "${TARGET_DIR}"/{,META-INF,OEBPS/{,Fonts,Images,Text}}

. "${CWD}/get.sh"
. "${CWD}/tidy.sh"
. "${CWD}/set-variables.sh"
. "${CWD}/fix-headings.sh"
. "${CWD}/download-remote-files.sh"
. "${CWD}/anonymize.sh"
. "${CWD}/assemble.sh"
