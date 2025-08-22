#!/usr/bin/env bash
set -euo pipefail

COLOR_SUCCESS='\e[1;32m'
COLOR_WARNING='\e[1;33m'
COLOR_ERROR='\e[1;31m'
COLOR_INFO='\e[0;37m'
COLOR_SUCCESS_LIGHT='\e[0;92m'
COLOR_WARNING_LIGHT='\e[0;93m'
COLOR_ERROR_LIGHT='\e[0;91m'
COLOR_INFO_LIGHT='\e[0;97m'
COLOR_NO='\e[0m'

while read line; do
  case $line in
  PASSED\ *)
    status="${line%% *}"
    name="${line#* }"
    echo -e "$COLOR_SUCCESS$status$COLOR_NO\t$COLOR_SUCCESS_LIGHT$name$COLOR_NO"
    ;;
  ERROR\ *|FAILED\ *)
    status="${line%% *}"
    name="${line#* }"
    echo -e "$COLOR_ERROR$status$COLOR_NO\t$COLOR_ERROR_LIGHT$name$COLOR_NO"
    ;;
  SKIPPED\ *)
    status="${line%% *}"
    name="${line#* }"
    echo -e "$COLOR_WARNING$status$COLOR_NO\t$COLOR_WARNING_LIGHT$name$COLOR_NO"
    ;;
  RUNNING\ *)
    status="${line%% *}"
    name="${line#* }"
    echo -e "$COLOR_INFO$status$COLOR_NO\t$COLOR_INFO_LIGHT$name$COLOR_NO"
    ;;
  *)
    echo -e "$line"
    ;;
  esac
done <"${1:-/dev/stdin}"
