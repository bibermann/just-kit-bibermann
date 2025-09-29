[no-exit-message]
_check-python: (_check-cmd "uv" "make")

[no-cd]
_bootstrap-python-env: _check-python _check-dot-env

[no-cd]
_install-python-project RECREATE="true":
    ! {{ RECREATE }} || ${OFFLINE:-false} || rm -rf .venv
    uv sync

[no-cd]
_setup-python-project RECREATE="true": _bootstrap-python-env
    @just _install-python-project '{{RECREATE}}'

_check-justile-relevance:
    @[ -n "$(find . -name "uv.lock" -type f -print -quit)" ]
