docker-login:
    source .env && docker login --username "$DOCKER_USER" --password "$DOCKER_PASS" "$DOCKER_REGISTRY"

docker-logout:
    docker logout "$DOCKER_REGISTRY"
