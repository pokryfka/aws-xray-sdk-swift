#!/usr/bin/env bash

DOCKER_IMAGE=swift-lambda-builder

docker inspect ${DOCKER_IMAGE} > /dev/null 2>&1 || exit 1

docker run \
  --rm \
  --volume "$(pwd)/:/src" \
  --workdir "/src/" \
  ${DOCKER_IMAGE} \
  swift test --enable-test-discovery
