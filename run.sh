#!/bin/bash


set -euo pipefail

# set basedir
pwd="${BASH_SOURCE%/*}"

$pwd/fix-headings.sh
$pwd/download-remote-files.sh
$pwd/remove-marks.sh
$pwd/tidy.sh
