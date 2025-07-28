docker-login: (_check-cmd "docker") (_check-env "DOCKER_REGISTRY" "DOCKER_USER" "DOCKER_PASS")
    docker login --username "$DOCKER_USER" --password "$DOCKER_PASS" "$DOCKER_REGISTRY"

docker-logout: (_check-cmd "docker") (_check-env "DOCKER_REGISTRY")
    docker logout "$DOCKER_REGISTRY"

_check-justile-relevance:
    @command -v docker
