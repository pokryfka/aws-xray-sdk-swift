//===----------------------------------------------------------------------===//
//
// This source file is part of the aws-xray-sdk-swift open source project
//
// Copyright (c) 2020 pokryfka and the aws-xray-sdk-swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension String {
    // naive implementation of `contains` implemented in `Foundation` extention of `String`.
    func contains(_ needle: String) -> Bool {
        // make sure needle is not empty
        guard let firstCharacter = needle.first else { return isEmpty }
        // otherwise compare the substrings starting with the first character of the needle
        var substring: Substring = drop { $0 != firstCharacter }
        while true {
            if substring.first == nil {
                return false
            }
            if substring.starts(with: needle) {
                return true
            }
            substring = substring.dropFirst().drop { $0 != firstCharacter }
        }
    }
}
