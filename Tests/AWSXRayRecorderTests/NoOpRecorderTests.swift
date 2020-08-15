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

import XCTest

@testable import AWSXRayRecorder

final class NoOpRecorderTests: XCTestCase {
    func testCreatingSegments() {
        let recorder = XRayNoOpRecorder()
        XCTAssertTrue(recorder.beginSegment(name: UUID().uuidString, context: .init()) is XRayRecorder.NoOpSegment)
        XCTAssertTrue(recorder.beginSegment(name: UUID().uuidString, baggage: .init()) is XRayRecorder.NoOpSegment)
    }

    func testFlushing() {
        let recorder = XRayNoOpRecorder()
        let exp = expectation(description: "hasFlushed")
        recorder.wait { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func testShutdown() {
        let recorder = XRayNoOpRecorder()
        let exp = expectation(description: "hasShutdown")
        recorder.shutdown { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
}
