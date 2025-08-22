# Filter pytest output for specific tests
[no-cd]
[group: "debug"]
[positional-arguments]
[script]
filter-pytest *TEST_NAMES: (_check-cmd "uv")
    STDIN_DATA="$(cat)"
    TEST_NAMES="$@"
    if [[ -z "${TEST_NAMES}" ]]; then
      TESTS="$(
        echo "$STDIN_DATA" \
        | uv run --project "{{source_directory()}}" "{{source_directory()}}/scripts/filter_pytest.py" \
        | tee >({{source_directory()}}/scripts/color-status.sh >&2)
      )"
      if [[ -z "${TESTS}" ]]; then exit 0; fi
      options=()
      while IFS= read -r line; do
        if [[ -n "$line" ]]; then
          status="${line%% *}"
          if [[ "$status" == "PASSED" || "$status" == "SKIPPED" || "$status" == =* ]]; then continue; fi
          test_name="${line#* }"
          options+=("$test_name" "$status" off)
        fi
      done <<< "$TESTS"
      if [[ ${#options[@]} -eq 0 ]]; then exit 0; fi
      read -p "Press enter to see test details" </dev/tty
      if [[ ${#options[@]} -eq 3 ]]; then
        TEST_NAMES="${options[0]}"
      else
        cmd=(dialog --separate-output --checklist "Select tests:" 0 0 0)
        if ! TEST_NAMES="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"; then
          clear -x
          exit 0
        fi
        clear -x
      fi
    fi
    if [[ ! -z "${TEST_NAMES}" ]]; then
        readarray -t TEST_NAMES_ARRAY <<<"$TEST_NAMES"
        echo "$STDIN_DATA" | uv run --project "{{source_directory()}}" "{{source_directory()}}/scripts/filter_pytest.py" "${TEST_NAMES_ARRAY[@]}"
    fi

_check-justile-relevance:
    @[ -n "$(find . -name "pyproject.toml" -type f -print -quit)" ]
