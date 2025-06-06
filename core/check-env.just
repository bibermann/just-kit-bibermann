[no-exit-message]
[script]
_check-env *VARS:
    [ -f .env ] && source .env
    missing=0
    for var in "$@"; do
      if [ -z "${!var:-}" ]; then
        echo >&2 "ERROR: Please provide variable '$var'."
        missing=1
      fi
    done
    exit $missing
