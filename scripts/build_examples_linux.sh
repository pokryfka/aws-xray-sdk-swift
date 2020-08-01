#!/usr/bin/env bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the aws-xray-sdk-swift open source project
##
## Copyright (c) YEARS pokryfka and the aws-xray-sdk-swift project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

DOCKER_IMAGE=swift-lambda-builder

docker inspect ${DOCKER_IMAGE} > /dev/null 2>&1 || exit 1

docker run \
  --rm \
  --volume "$(pwd)/:/src" \
  --workdir "/src/" \
  ${DOCKER_IMAGE} \
  bash -c "cd Examples && swift build -c release"
