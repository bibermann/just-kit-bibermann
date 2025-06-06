[no-exit-message]
_check-python: (_check-cmd "uv") (_check-cmd "make")

# Setup uv subproject for development
[no-cd]
_setup-python-subproject RECREATE="true": _check-python _check-env-file
    ! {{ RECREATE }} || ${OFFLINE:-false} || rm -rf .venv
    uv sync

[no-cd]
_check-justile-relevance:
    @[ -f pyproject.toml ] && [ -f uv.lock ]
