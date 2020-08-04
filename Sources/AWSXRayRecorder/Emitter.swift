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

/// A type representing the ability to emit `XRayRecorder.Segment`.
public protocol XRayEmitter {
    /// Sends `XRayRecorder.Segment`.
    /// Should **NOT** be blocking.
    ///
    /// Emitter may choose to postpone the operation and send `XRayRecorder.Segment`s in batches.
    ///
    /// - Parameter segment: segment
    func send(_ segment: XRayRecorder.Segment)

    /// Sends pending `XRayRecorder.Segment`s,
    /// May be blocking.
    ///
    /// - Parameter callback: callback with error if the operation failed.
    func flush(_ callback: @escaping (Error?) -> Void)

    /// Sends pending `XRayRecorder.Segment`s,
    /// May be blocking.
    ///
    /// - Parameter callback: callback with error if the operation failed.
    func shutdown(_ callback: @escaping (Error?) -> Void)
}

/// Implements `XRayEmitter` which does not do anything.
public struct XRayNoOpEmitter: XRayEmitter {
    public func send(_: XRayRecorder.Segment) {}
    public func flush(_ callback: @escaping (Error?) -> Void) { callback(nil) }
    public func shutdown(_ callback: @escaping (Error?) -> Void) { callback(nil) }

    public init() {}
}
