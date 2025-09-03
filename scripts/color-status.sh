#!/usr/bin/env bash
set -euo pipefail

COLOR_SUCCESS_DARK_BOLD='\e[1;32m'
COLOR_WARNING_DARK_BOLD='\e[1;33m'
COLOR_ERROR_DARK_BOLD='\e[1;31m'
COLOR_SUCCESS_BOLD='\e[1;92m'
COLOR_WARNING_BOLD='\e[1;93m'
COLOR_ERROR_BOLD='\e[1;91m'
COLOR_INFO='\e[0;37m'
COLOR_SUCCESS_LIGHT='\e[0;92m'
COLOR_WARNING_LIGHT='\e[0;93m'
COLOR_ERROR_LIGHT='\e[0;91m'
COLOR_INFO_LIGHT='\e[0;97m'
COLOR_SUCCESS_DARK='\e[0;32m'
COLOR_WARNING_DARK='\e[0;33m'
COLOR_ERROR_DARK='\e[0;31m'
COLOR_INFO_DARK='\e[0;37m'
COLOR_INFO_DARKER='\e[1;90m'
COLOR_NO='\e[0m'

format_test_line() {
  local line="$1"
  local status_color="$2"
  local light_color="$3"
  local dark_color="$4"

  local status="${line%% *}"
  local name="${line#* }"

  if [[ "$name" == *::* ]]; then
    local before_colon="${name%%::*}"
    local after_colon="${name#*::}"

    if [[ "$after_colon" == *\[* ]]; then
      local middle_part="${after_colon%%\[*}"
      local bracket_part="${after_colon#*\[}"
      echo -e "${status_color}${status}${COLOR_NO}\t${dark_color}${before_colon}${COLOR_NO}::${light_color}${middle_part}${COLOR_NO}[${dark_color}${bracket_part::-1}${COLOR_NO}]"
    else
      echo -e "${status_color}${status}${COLOR_NO}\t${dark_color}${before_colon}${COLOR_NO}::${light_color}${after_colon}${COLOR_NO}"
    fi
  else
    if [[ "$name" == *\[* ]]; then
      local before_bracket="${name%%\[*}"
      local bracket_part="${name#*\[}"
      echo -e "${status_color}${status}${COLOR_NO}\t${light_color}${before_bracket}${COLOR_NO}[${dark_color}${bracket_part::-1}${COLOR_NO}]"
    else
      echo -e "${status_color}${status}${COLOR_NO}\t${light_color}${name}${COLOR_NO}"
    fi
  fi
}

while read line; do
  case $line in
  PASSED\ *|XPASS\ *)
    format_test_line "$line" "$COLOR_SUCCESS_DARK_BOLD" "$COLOR_SUCCESS_LIGHT" "$COLOR_SUCCESS_DARK"
    ;;
  ERROR\ *|FAILED\ *)
    format_test_line "$line" "$COLOR_ERROR_DARK_BOLD" "$COLOR_ERROR_LIGHT" "$COLOR_ERROR_DARK"
    ;;
  SKIPPED\ *|XFAIL\ *)
    format_test_line "$line" "$COLOR_WARNING_DARK_BOLD" "$COLOR_WARNING_LIGHT" "$COLOR_WARNING_DARK"
    ;;
  RUNNING\ *)
    format_test_line "$line" "$COLOR_INFO" "$COLOR_INFO_LIGHT" "$COLOR_INFO_DARK"
    ;;
  *)
    echo -e "$line"
    ;;
  esac
done <"${1:-/dev/stdin}"
