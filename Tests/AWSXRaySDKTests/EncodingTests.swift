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

import AWSXRayRecorder
import AWSXRayUDPEmitter
import XCTest

private typealias Segment = XRayRecorder.Segment
private typealias SegmentEncoding = XRayRecorder.Segment.Encoding

final class EncodingTests: XCTestCase {
    private let segment: Segment = {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter(), config: .init(logLevel: .error))
        let segment = recorder.beginSegment(name: "Root Segment", context: .init())
        segment.setAnnotation("key", forKey: "value")
        segment.setMetadata(["key": 42])
        segment.addException(message: "Root Segment Exception")
        segment.setHTTPRequest(method: .POST, url: "http://www.example.com/api/user")
        segment.setHTTPResponse(status: .ok)
        for i in 1 ... 10 {
            segment.subsegment(name: "Subsegment \(i)") { segment in
                segment.setAnnotation("key", forKey: "value")
                segment.setMetadata(["key": 42])
                segment.addException(message: "Subsegment \(i) Exception")
            }
        }
        segment.end()
        return segment
    }()

    private func measureEncoding(_ segment: Segment, encoding: XRayUDPEmitter.SegmentEncoding, count: UInt = 10) {
        measure {
            for _ in 0 ..< count {
                _ = try! encoding.encode(segment)
            }
        }
    }

    func testEncodingUsingDefault() {
        measureEncoding(segment, encoding: .default)
    }
}
