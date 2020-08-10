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

import AWSXRayUDPEmitter
import NIO
import PureSwiftJSON
import XCTest

@testable import AWSXRayRecorder

private typealias Segment = XRayRecorder.Segment
private typealias SegmentError = XRayRecorder.SegmentError
private typealias SegmentEncoding = XRayUDPEmitter.SegmentEncoding

// TODO: review and extend

private extension Segment {
    var object: [String: JSONValue] {
        var dict: [String: JSONValue] = [
            "id": .string(id.rawValue),
            "name": .string(name),
            "trace_id": .string(_test_traceId.rawValue),
            "start_time": .number("\(_test_startTime.secondsSinceEpoch)"),
        ]
        if let inProgress = _test_inProgress {
            dict["in_progress"] = .bool(inProgress)
        }
        return dict
    }
}

final class SegmentEncodingTests: XCTestCase {
    func testEncodingSegmentInProgress() {
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init())
        var result: ByteBuffer?
        XCTAssertNoThrow(result = try SegmentEncoding.default.encode(segment))
        let resultLength = result?.readableBytes ?? 0
        XCTAssertTrue(resultLength > 0)
        // PureSwiftJSON
        var parsed: JSONValue?
        XCTAssertNoThrow(parsed = try JSONParser().parse(bytes: XCTUnwrap(result?.readBytes(length: resultLength))))
        XCTAssertEqual(parsed, .object(segment.object))
    }
}
