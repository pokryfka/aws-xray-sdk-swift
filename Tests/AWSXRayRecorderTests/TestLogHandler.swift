//
//  File.swift
//
//
//  Created by Michał A on 2020/7/31.
//

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
