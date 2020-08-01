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
import XCTest

private typealias Segment = XRayRecorder.Segment
private typealias SegmentEncoding = XRayRecorder.Segment.Encoding

final class EncodingTests: XCTestCase {
    override func setUp() {
        #if DEBUG
        preconditionFailure("Use Release configuration")
        #endif
    }

    private let segment: Segment = {
        let recorder = XRayRecorder(emitter: XRayNoOpEmitter(), config: .init(logLevel: .error))
        let segment = recorder.beginSegment(name: "Root Segment", context: .init())
        segment.setAnnotation("key", forKey: "value")
        segment.setMetadata(["key": 42])
        segment.addException(message: "Root Segment Exception")
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

    private func measureEncoding(_ segment: Segment, encoding: SegmentEncoding, count: UInt = 1000) {
        measure {
            for _ in 0 ..< count {
                _ = try! encoding.encode(segment)
            }
        }
    }

    func testEncodingUsingFoundationJSON() {
        measureEncoding(segment, encoding: FoundationJSON.segmentEncoding)
    }

    func testEncodingUsingIkigaJSON() {
        measureEncoding(segment, encoding: Ikiga.segmentEncoding)
    }

    func testEncodingUsingPureSwiftJSON() {
        measureEncoding(segment, encoding: PureSwift.segmentEncoding)
    }
}
