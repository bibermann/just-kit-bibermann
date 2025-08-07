#!/usr/bin/env bash
set -euo pipefail

COLOR_SUCCESS='\e[1;32m'
COLOR_WARNING='\e[1;33m'
COLOR_ERROR='\e[1;31m'
COLOR_INFO='\e[0;37m'
COLOR_NO='\e[0m'

while read line; do
  case $line in
    PASSED\ *)
      status="${line%% *}"
      name="${line#* }"
      echo -e "$COLOR_SUCCESS$status$COLOR_NO\t$name"
      ;;
    ERROR\ *|FAILED\ *)
      status="${line%% *}"
      name="${line#* }"
      echo -e "$COLOR_ERROR$status$COLOR_NO\t$name"
      ;;
    SKIPPED\ *)
      status="${line%% *}"
      name="${line#* }"
      echo -e "$COLOR_WARNING$status$COLOR_NO\t$name"
      ;;
    RUNNING\ *)
      status="${line%% *}"
      name="${line#* }"
      echo -e "$COLOR_INFO$status$COLOR_NO\t$name"
      ;;
    *)
      echo -e "$line"
      ;;
  esac
done <"${1:-/dev/stdin}"
