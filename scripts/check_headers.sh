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
##===----------------------------------------------------------------------===##
##
## This source file is part of the SwiftAWSLambdaRuntime open source project
##
## Copyright (c) 2017-2018 Apple Inc. and the SwiftAWSLambdaRuntime project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of SwiftAWSLambdaRuntime project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

set -eu

here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function replace_acceptable_years() {
    # this needs to replace all acceptable forms with 'YEARS'
    sed -e 's/2020/YEARS/'
}

printf "=> Checking format... "
FIRST_OUT="$(git status --porcelain)"
swiftformat . > /dev/null 2>&1
SECOND_OUT="$(git status --porcelain)"
if [[ "$FIRST_OUT" != "$SECOND_OUT" ]]; then
  printf "\033[0;31mformatting issues!\033[0m\n"
  git --no-pager diff
  exit 1
else
  printf "\033[0;32mokay.\033[0m\n"
fi

printf "=> Checking license headers\n"
tmp=$(mktemp /tmp/.aws-xray-sdk-swift_XXXXXX)

for language in swift-or-c bash; do
  printf "   * $language... "
  declare -a matching_files
  declare -a exceptions
  expections=( )
  matching_files=( -name '*' )
  case "$language" in
      swift-or-c)
        exceptions=( -name Package.swift )
        matching_files=( -name '*.swift' -o -name '*.c' -o -name '*.h' )
        cat > "$tmp" <<"EOF"
//===----------------------------------------------------------------------===//
//
// This source file is part of the aws-xray-sdk-swift open source project
//
// Copyright (c) YEARS pokryfka and the aws-xray-sdk-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
EOF
        ;;
      bash)
        matching_files=( -name '*.sh' )
        cat > "$tmp" <<"EOF"
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
EOF
      ;;
    *)
      echo >&2 "ERROR: unknown language '$language'"
      ;;
  esac

  expected_lines=$(cat "$tmp" | wc -l)
  expected_sha=$(cat "$tmp" | shasum)

  (
    cd "$here/.."
    find . \
      \( \! -path '*/.build/*' -a \
      \( "${matching_files[@]}" \) -a \
      \( \! \( "${exceptions[@]}" \) \) \) | while read line; do
      if [[ "$(cat "$line" | replace_acceptable_years | head -n $expected_lines | shasum)" != "$expected_sha" ]]; then
        printf "\033[0;31mmissing headers in file '$line'!\033[0m\n"
        diff -u <(cat "$line" | replace_acceptable_years | head -n $expected_lines) "$tmp"
        exit 1
      fi
    done
    printf "\033[0;32mokay.\033[0m\n"
  )
done

rm "$tmp"
