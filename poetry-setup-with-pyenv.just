[no-exit-message]
_check-python: (_check-cmd "pyenv" "poetry" "make")

[no-cd]
_bootstrap-python-env: _check-python _check-dot-env
    pyenv install -s

[no-cd]
_install-python-project RECREATE="true":
    ! {{ RECREATE }} || ${OFFLINE:-false} || rm -rf .venv
    poetry env use $(pyenv which python)
    just _poetry-install

[no-cd]
_setup-python-project RECREATE="true": _bootstrap-python-env
    @just _install-python-project '{{RECREATE}}'

[no-cd]
_poetry-install:
    poetry install

_check-justile-relevance:
    @[ -n "$(find . -name "poetry.lock" -type f -print -quit)" ]
