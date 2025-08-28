[no-exit-message]
_check-docker: (_check-cmd "docker")
    @( id -nG "$USER" | grep -qw "docker" ) || (echo >&2 "ERROR: Please add yourself to the docker group." && exit 1)
    @docker compose version &>/dev/null || (echo >&2 "ERROR: Please install docker compose plugin." && exit 1)

_check-justile-relevance:
    @command -v docker
