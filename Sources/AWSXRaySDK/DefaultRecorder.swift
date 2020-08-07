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

@_exported import AWSXRayRecorder
import AWSXRayUDPEmitter

extension XRayRecorder {
    /// Creates an instance of `XRayRecorder` with `XRayUDPEmitter`.
    ///
    /// - Parameters:
    ///   - eventLoopGroupProvider: specifies how the `EventLoopGroup` used by `XRayUDPEmitter` will be created and establishes lifecycle ownership.
    ///   - config: configuration, **overrides** enviromental variables.
    public convenience init(eventLoopGroupProvider: XRayUDPEmitter.EventLoopGroupProvider = .createNew,
                            config: Config = Config())
    {
        do {
            let emitter = try XRayUDPEmitter(encoding: XRayUDPEmitter.SegmentEncoding.default,
                                             eventLoopGroupProvider: eventLoopGroupProvider)
            self.init(emitter: emitter, config: config)
        } catch {
            preconditionFailure("Failed to create XRayUDPEmitter: \(error)")
        }
    }
}
