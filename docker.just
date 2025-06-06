docker-login:
    source .env && docker login --username "$DOCKER_USER" --password "$DOCKER_PASS" "$DOCKER_REGISTRY"

docker-logout:
    docker logout "$DOCKER_REGISTRY"

_check-justile-relevance:
    @command -v docker

_get-required-variables:
    @echo "DOCKER_REGISTRY"
    @echo "DOCKER_USER"
    @echo "DOCKER_PASS"
