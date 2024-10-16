[no-exit-message]
_check-node:
    @[ -s "$HOME/.nvm/nvm.sh" ] || (echo >&2 'ERROR: Please install `nvm`.' && just _install-instructions "nvm" && exit 1)

[no-cd]
[script]
_setup-node-subproject RECREATE="true": _check-node _check-env-file
    . "$HOME/.nvm/nvm.sh"

    nvm install --latest-npm
    nvm use
    ! {{ RECREATE }} || ${OFFLINE:-false} || rm -rf node_modules
    npm i

    echo
    echo 'NOTE: Please run `nvm use` before running npm commands.'
    echo 'NOTE: You need to run `nvm use` again if you start a new shell session.'
