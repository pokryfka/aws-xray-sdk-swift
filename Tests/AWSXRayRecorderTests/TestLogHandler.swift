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

import Foundation
import Logging

class TestLogHandler: LogHandler {
    var errorMessages = [String]()

    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt)
    {
        print("\(level): \(message)")
        if level == .error {
            errorMessages.append("\(message)")
        }
    }

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set(newValue) { metadata[key] = newValue }
    }

    var metadata: Logger.Metadata = .init()

    var logLevel: Logger.Level = .info
}
