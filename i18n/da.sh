#!/bin/bash

set -euo pipefail

declare -Ax DICT=(
  [cover]=cover
  [volume]=bind
  [part]=del
  [chapter]=kapitel
  [subchapter]=underkapitel
  [division]=inddeling
  [abstract]=resume
  [foreword]=forord
  [preface]=indledning
  [prologue]=prolog
  [introduction]=introduktion
  [preamble]=præambel
  [conclusion]=konklusion
  [epilogue]=epilog
  [afterword]=efterskrift
  [epigraph]=epigraf
  [toc]=indholdsfortegnelse
  [appendix]=appendiks
  [colophon]=kolofon
)
