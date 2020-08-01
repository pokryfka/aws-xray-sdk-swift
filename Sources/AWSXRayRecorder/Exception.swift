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

extension XRayRecorder.Segment {
    internal struct Cause {
        /// The full path of the working directory when the exception occurred.
        var workingDirectory: String?
        /// The **array** of paths to libraries or modules in use when the exception occurred.
        var paths: [String]?
        /// The **array** of **exception** objects.
        var exceptions: [Exception] = [Exception]()
    }

    internal struct Exception {
        /// A 64-bit identifier in **16 hexadecimal digits**.
        struct ID: RawRepresentable, Hashable, Encodable, CustomStringConvertible {
            let rawValue: String
            var description: String { rawValue }
            init?(rawValue: String) {
                guard rawValue.count == 16, Float("0x\(rawValue)") != nil else { return nil }
                self.rawValue = rawValue
            }

            init() { rawValue = String.random64() }
        }

        struct StackFrame: Encodable {
            /// The relative path to the file.
            var path: String?
            /// The line in the file.
            var line: UInt?
            /// The function or method name.
            var label: String?
        }

        /// A 64-bit identifier for the exception, unique among segments in the same trace, in **16 hexadecimal digits**.
        let id: ID
        /// The exception message.
        var message: String?
        /// The exception type.
        var type: String?
        /// **boolean** indicating that the exception was caused by an error returned by a downstream service.
        var remote: Bool?
        /// **integer** indicating the number of stack frames that are omitted from the stack.
        var truncated: UInt?
        /// **integer** indicating the number of exceptions that were skipped between this exception and its child, that is, the exception that it caused.
        var skipped: UInt?
        /// Exception ID of the exception's parent, that is, the exception that caused this exception.
        var cause: ID?
        /// **array** of **stackFrame** objects.
        var stack: [StackFrame]?

        init(id: ID, message: String, type: String? = nil) {
            self.id = id
            self.message = message
            self.type = type
        }

        init(message: String, type: String? = nil) {
            self.init(id: ID(), message: message, type: type)
        }

        init(id: ID, error: Error) {
            self.id = id
            message = "\(error)"
        }

        init(_ error: Error) {
            self.init(id: ID(), error: error)
        }
    }
}

// MARK: Encodable

extension XRayRecorder.Segment.Cause: Encodable {
    enum CodingKeys: String, CodingKey {
        case workingDirectory = "working_directory"
        case paths
        case exceptions
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(workingDirectory, forKey: .workingDirectory)
        try container.encodeIfPresent(paths, forKey: .paths)
        try container.encode(exceptions, forKey: .exceptions)
    }
}

extension XRayRecorder.Segment.Exception: Encodable {
    enum CodingKeys: String, CodingKey {
        case id
        case message
        // for nowe we just only use id and message
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(message, forKey: .message)
    }
}
