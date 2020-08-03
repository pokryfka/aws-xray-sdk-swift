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

import NIO

/// A `SwiftNIO` `XRayEmitter`.
public protocol XRayNIOEmitter: XRayEmitter {
    /// Sends pending `XRayRecorder.Segment`s in `SwiftNIO` future.
    ///
    /// - Parameter eventLoop: `EventLoop` used to "do the flushing".
    func flush(on eventLoop: EventLoop?) -> EventLoopFuture<Void>
}
