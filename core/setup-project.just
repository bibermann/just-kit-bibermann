[no-exit-message]
[no-cd]
_bootstrap-env:
    @if [ -f pyproject.toml ]; then just _bootstrap-python-env; fi
    @if [ -f package.json ]; then just _bootstrap-node-env; fi
    @if ! [ -f pyproject.toml ] && ! [ -f package.json ]; then \
       echo >&2 "ERROR: Run this inside a subproject's directory." && exit 1; \
     fi

[no-exit-message]
[no-cd]
_install-project RECREATE="true":
    @if [ -f pyproject.toml ]; then just _install-python-project '{{RECREATE}}'; fi
    @if [ -f package.json ]; then just _install-node-project '{{RECREATE}}'; fi

# Setup subproject for development
[no-exit-message]
[no-cd]
[group: "maintenance"]
setup-project RECREATE="true": _bootstrap-env
    @just _install-project '{{RECREATE}}'

_check-justile-relevance:
    false
