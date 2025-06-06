# Setup subproject for development
[no-exit-message]
[no-cd]
setup-subproject RECREATE="true":
    @if [ -f pyproject.toml ]; then just _setup-python-subproject {{ RECREATE }}; fi
    @if [ -f package.json ]; then just _setup-node-subproject {{ RECREATE }}; fi
    @if ! [ -f pyproject.toml ] && ! [ -f package.json ]; then \
       echo >&2 "ERROR: Run this inside a subproject's directory." && exit 1; \
     fi
