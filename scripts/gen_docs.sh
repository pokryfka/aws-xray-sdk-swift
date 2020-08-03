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

swift doc generate --module-name=aws-xray-sdk-swift --output=Documentation Sources
swift doc coverage Sources
