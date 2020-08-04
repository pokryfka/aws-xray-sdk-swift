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

import Foundation
import XCTest

@testable import AWSXRayRecorder

private typealias TraceID = XRayRecorder.TraceID
private typealias TraceContext = XRayRecorder.TraceContext
private typealias TraceError = XRayRecorder.TraceError
private typealias SampleDecision = XRayRecorder.SampleDecision
private typealias SegmentError = XRayRecorder.SegmentError

final class TraceTests: XCTestCase {
    // MARK: TraceID

    func testTraceRandomId() {
        let numTests = 1000
        var values = Set<TraceID.RawValue>()
        for _ in 0 ..< numTests {
            let traceId = TraceID()
            values.insert(traceId.rawValue)
        }
        XCTAssertEqual(values.count, numTests)
    }

    func testTraceOldId() {
        let identifier = String.random96()
        XCTAssertEqual(TraceID(secondsSinceEpoch: 1, identifier: identifier),
                       TraceID(secondsSinceEpoch: 1, identifier: identifier))
    }

    func testTraceOverflowId() {
        let identifier = String.random96()
        XCTAssertEqual(TraceID(secondsSinceEpoch: 0xA_1234_5678, identifier: identifier),
                       TraceID(secondsSinceEpoch: 0xB_1234_5678, identifier: identifier))
    }

    // MARK: TraceHeader

    func testTraceHeaderNoParentUnknownSampleDecision() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793"
        do {
            let value = try TraceContext(tracingHeader: string)
            XCTAssertEqual(string, value.tracingHeader)
            XCTAssertNotNil(value)
            XCTAssertEqual(value.traceId.rawValue, "1-5759e988-bd862e3fe1be46a994272793")
            XCTAssertNil(value.parentId)
            XCTAssertEqual(value.sampled, SampleDecision.unknown)
        } catch {
            XCTFail()
        }
    }

    func testTraceHeaderNoParentSampled() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Sampled=1"
        do {
            let value = try TraceContext(tracingHeader: string)
            XCTAssertEqual(string, value.tracingHeader)
            XCTAssertNotNil(value)
            XCTAssertEqual(value.traceId.rawValue, "1-5759e988-bd862e3fe1be46a994272793")
            XCTAssertNil(value.parentId)
            XCTAssertEqual(value.sampled, SampleDecision.sampled)
        } catch {
            XCTFail()
        }
    }

    func testTraceHeaderWithParentSampled() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=1"
        do {
            let value = try TraceContext(tracingHeader: string)
            XCTAssertEqual(string, value.tracingHeader)
            XCTAssertEqual(value.traceId.rawValue, "1-5759e988-bd862e3fe1be46a994272793")
            XCTAssertEqual(value.parentId?.rawValue, "53995c3f42cd8ad8")
            XCTAssertEqual(value.sampled, SampleDecision.sampled)
        } catch {
            XCTFail()
        }
    }

    func testTraceHeaderWithParentNotSampled() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=0"
        do {
            let value = try TraceContext(tracingHeader: string)
            XCTAssertEqual(string, value.tracingHeader)
            XCTAssertEqual(value.traceId.rawValue, "1-5759e988-bd862e3fe1be46a994272793")
            XCTAssertEqual(value.parentId?.rawValue, "53995c3f42cd8ad8")
            XCTAssertEqual(value.sampled, SampleDecision.notSampled)
        } catch {
            XCTFail()
        }
    }

    func testTraceHeaderWithParentUnkownUnkownSample() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8"
        do {
            let value = try TraceContext(tracingHeader: string)
            XCTAssertEqual(string, value.tracingHeader)
            XCTAssertEqual(value.traceId.rawValue, "1-5759e988-bd862e3fe1be46a994272793")
            XCTAssertEqual(value.parentId?.rawValue, "53995c3f42cd8ad8")
            XCTAssertEqual(value.sampled, SampleDecision.unknown)
        } catch {
            XCTFail()
        }
    }

    func testTraceHeaderWithParentUnkownRequestedSample() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8;Sampled=?"
        do {
            let value = try TraceContext(tracingHeader: string)
            XCTAssertEqual(string, value.tracingHeader)
            XCTAssertEqual(value.traceId.rawValue, "1-5759e988-bd862e3fe1be46a994272793")
            XCTAssertEqual(value.parentId?.rawValue, "53995c3f42cd8ad8")
            XCTAssertEqual(value.sampled, SampleDecision.requested)
        } catch {
            XCTFail()
        }
    }

    func testTraceHeaderInvalidFormat() {
        let string = "Root2799;Sampled=1"
        XCTAssertThrowsError(try TraceContext(tracingHeader: string)) { error in
            if case TraceError.invalidTracingHeader(let invalidValue) = error {
                XCTAssertEqual(invalidValue, "Root2799;Sampled=1")
            } else {
                XCTFail()
            }
        }
    }

    func testTraceHeaderInvalidRoot() {
        let string = "Root=-2799;Parent=-15277;Sampled=1"
        XCTAssertThrowsError(try TraceContext(tracingHeader: string)) { error in
            if case TraceError.invalidTraceID(let invalidValue) = error {
                XCTAssertEqual(invalidValue, "-2799")
            } else {
                XCTFail()
            }
        }
    }

    func testTraceHeaderInvalidParent() {
        let string = "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=-15277;Sampled=1"
        XCTAssertThrowsError(try TraceContext(tracingHeader: string)) { error in
            if case TraceError.invalidParentID(let invalidValue) = error {
                XCTAssertEqual(invalidValue, "-15277")
            } else {
                XCTFail()
            }
        }
    }
}
