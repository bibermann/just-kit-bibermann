[no-exit-message]
_check-python: (_check-cmd "pyenv" "poetry" "make")

# Setup Poetry subproject for development
[no-cd]
_setup-python-subproject RECREATE="true": _check-python _check-dot-env
    pyenv install -s
    ! {{ RECREATE }} || ${OFFLINE:-false} || rm -rf .venv
    poetry env use $(pyenv which python)
    just _poetry-install

[no-cd]
_poetry-install:
    poetry install

_check-justile-relevance:
    @[ -n "$(find . -name "poetry.lock" -type f -print -quit)" ]
