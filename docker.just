docker-login: (_check-env "DOCKER_REGISTRY" "DOCKER_USER" "DOCKER_PASS")
    source .env && docker login --username "$DOCKER_USER" --password "$DOCKER_PASS" "$DOCKER_REGISTRY"

docker-logout: (_check-env "DOCKER_REGISTRY")
    docker logout "$DOCKER_REGISTRY"

_check-justile-relevance:
    @command -v docker
