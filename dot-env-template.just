ENV_TEMPLATE := ".env.template"
REQUIRED_FILES := ""

_create-required-files ENV="dev":

_configure-files ENV="dev":

# Configure project for some environment
[group: "setup"]
configure ENV="dev":
    [ -f .env ] || cp "${ENV_TEMPLATE:-{{ENV_TEMPLATE}}}" .env
    @just _create-required-files "{{ENV}}"

    @just _check-dot-env

    @just _configure-files "{{ENV}}"

    @if [ "{{ENV}}" = "dev" ]; then just _ensure-pre-commit; fi

[no-exit-message]
[script]
_check-dot-env:
    for file in .env ${REQUIRED_FILES:-{{REQUIRED_FILES}}}; do
      if [ ! -f "$file" ]; then
        echo >&2 "ERROR: File \`$file\` not found. Please run \`just configure\` first."
        exit 1
      fi
    done
    if [ "${ENV_TEMPLATE:-{{ENV_TEMPLATE}}}" -nt .env ]; then
      echo >&2 "ERROR: Please integrate recent changes of \`${ENV_TEMPLATE:-{{ENV_TEMPLATE}}}\` into \`.env\`."
      echo >&2 '       If nothing needs to be done, run `touch .env` in the project root.'
      exit 1
    fi
