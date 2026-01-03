#!/usr/bin/env bash
set -euo pipefail

REGISTRY_HOST=localhost
REGISTRY_PORT=5000
REGISTRY="${REGISTRY_HOST}:${REGISTRY_PORT}"

echo "▶ Ensuring local registry is running at ${REGISTRY}"
if ! docker ps --format '{{.Names}}' | grep -q '^local-registry$'; then
  if docker ps -a --format '{{.Names}}' | grep -q '^local-registry$'; then
    echo "▶ Starting existing local-registry container"
    docker start local-registry
  else
    echo "▶ Creating local registry container"
    docker run -d -p ${REGISTRY_PORT}:5000 --restart=always --name local-registry registry:2
  fi
else
  echo "▶ local-registry already running"
fi

# Login to Docker Hub if credentials are provided (env DOCKER_USER, DOCKER_PASS)
if [ -n "${DOCKER_USER:-}" ] && [ -n "${DOCKER_PASS:-}" ]; then
  echo "▶ Logging into Docker Hub"
  echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin || true
fi

# Base images to mirror to the local registry
images=(
  "maven:3.9.4-jdk-17-slim"
  "openjdk:17-jdk-slim"
  "python:3.11-slim"
)

for img in "${images[@]}"; do
  echo "▶ Mirroring $img -> ${REGISTRY}/$img"
  # pull (may be from remote)
  for try in 1 2 3; do
    if docker pull "$img"; then
      break
    else
      echo "⏳ retrying pull $img ($try)"
      sleep 3
    fi
  done

  # tag and push to local registry
  docker tag "$img" "${REGISTRY}/$img"
  docker push "${REGISTRY}/$img"
done

echo "✔ Local registry populated"

echo "Now you can run builds with --build-arg REGISTRY=${REGISTRY}/ or set REGISTRY=${REGISTRY}/ in Jenkins environment."
