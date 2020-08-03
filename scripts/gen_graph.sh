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

INPUTS=Sources
OUTPUT=Documentation

swift doc diagram ${INPUTS} > ${OUTPUT}/graph.dot
dot -T svg ${OUTPUT}/graph.dot > ${OUTPUT}/graph.svg
# requires imagemagick
convert ${OUTPUT}/graph.svg ${OUTPUT}/graph.pdf
