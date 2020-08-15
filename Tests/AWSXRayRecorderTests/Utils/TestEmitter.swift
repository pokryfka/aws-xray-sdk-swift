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

import NIOConcurrencyHelpers

@testable import AWSXRayRecorder

class TestEmitter: XRayEmitter {
    private let lock = Lock()
    private var _segments = [XRayRecorder.Segment]()

    var segments: [XRayRecorder.Segment] { lock.withLock { _segments } }

    func send(_ segment: XRayRecorder.Segment) {
        lock.withLock {
            _segments.append(segment)
        }
    }

    func flush(_ callback: @escaping (Error?) -> Void) { callback(nil) }
    func shutdown(_ callback: @escaping (Error?) -> Void) { callback(nil) }

    func reset() {
        lock.withLock {
            _segments = [XRayRecorder.Segment]()
        }
    }
}
