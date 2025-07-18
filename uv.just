[no-exit-message]
_check-python: (_check-cmd "uv" "make")

# Setup uv subproject for development
[no-cd]
_setup-python-subproject RECREATE="true": _check-python _check-env-file
    ! {{ RECREATE }} || ${OFFLINE:-false} || rm -rf .venv
    uv sync

_check-justile-relevance:
    @[ -n "$(find . -name "uv.lock" -type f -print -quit)" ]
