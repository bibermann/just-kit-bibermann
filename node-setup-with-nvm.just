[no-exit-message]
_check-node:
    @[ -s "$HOME/.nvm/nvm.sh" ] || (echo >&2 'ERROR: Please install `nvm`.' && just _install-instructions "nvm")

[no-cd]
[script]
_bootstrap-node-env: _check-node _check-dot-env
    . "$HOME/.nvm/nvm.sh"

    nvm install --latest-npm

[no-cd]
[script]
_install-node-project RECREATE="true":
    . "$HOME/.nvm/nvm.sh"

    nvm use
    ! {{ RECREATE }} || ${OFFLINE:-false} || rm -rf node_modules
    npm i

    echo
    echo 'NOTE: Please run `nvm use` before running npm commands.'
    echo 'NOTE: You need to run `nvm use` again if you start a new shell session.'

[no-cd]
_setup-node-project RECREATE="true": _bootstrap-node-env
    @just _install-node-project '{{RECREATE}}'

_check-justile-relevance:
    @[ -n "$(find . -name "package.json" -type f -print -quit)" ]
