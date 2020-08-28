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

@testable import AWSXRayRecorder

class TestEmitter: XRayEmitter {
    var segments = [XRayRecorder.Segment]()

    func send(_ segment: XRayRecorder.Segment) {
        segments.append(segment)
    }

    func flush(_ callback: @escaping (Error?) -> Void) { callback(nil) }
    func shutdown(_ callback: @escaping (Error?) -> Void) { callback(nil) }

    func reset() {
        segments = [XRayRecorder.Segment]()
    }
}
