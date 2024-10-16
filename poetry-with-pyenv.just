[no-exit-message]
_check-python: (_check-cmd "pyenv") (_check-cmd "poetry") (_check-cmd "make")

# Setup Poetry subproject for development
[no-cd]
_setup-python-subproject RECREATE="true": _check-python _check-env-file
    pyenv install -s
    ! {{ RECREATE }} || ${OFFLINE:-false} || rm -rf .venv
    poetry env use $(pyenv which python)
    just _poetry-install

[no-cd]
_poetry-install:
    poetry install
