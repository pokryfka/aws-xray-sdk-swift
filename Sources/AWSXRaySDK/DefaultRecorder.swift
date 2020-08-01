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
    /// Creates XRay recorder with UDP Emitter.
    public convenience init(config: Config = Config()) {
        // TODO: pass ELG
        do {
            let emitter = try XRayUDPEmitter(encoding: XRayRecorder.Segment.Encoding.default)
            self.init(emitter: emitter, config: config)
        } catch {
            preconditionFailure("Failed to create XRayUDPEmitter: \(error)")
        }
    }
}
