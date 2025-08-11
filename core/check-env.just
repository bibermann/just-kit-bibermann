[no-exit-message]
[script]
[positional-arguments]
_check-env *VARS: _check-dot-env
    missing=0
    for var in "$@"; do
      if [ -z "${!var:-}" ]; then
        echo >&2 "ERROR: Please provide variable '$var'."
        missing=1
      fi
    done
    exit $missing

_check-justile-relevance:
    false
