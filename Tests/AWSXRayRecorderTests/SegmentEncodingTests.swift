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

private typealias Segment = XRayRecorder.Segment
private typealias SegmentError = XRayRecorder.SegmentError

// TODO: use snapshot testing?

private enum EnumError: Error {
    case test
}

private struct StructError: Error {
    var message: String
}

final class SegmentEncodingTests: XCTestCase {
    private func encode(_ segment: Segment) throws -> String {
        try JSONEncoder.testEncoder.encode(segment) as String
    }

    private func encode(_ annotations: Segment.Annotations) throws -> String {
        try JSONEncoder.testEncoder.encode(annotations) as String
    }

    private func encode(_ metadata: Segment.Metadata) throws -> String {
        try JSONEncoder.testEncoder.encode(metadata) as String
    }

    // MARK: Segment

    func testEncodingSegmentInProgressRandom() {
        let numTests = 1000
        for _ in 0 ..< numTests {
            let segment = Segment(id: .init(), name: UUID().uuidString, context: .init(), baggage: .init())
            XCTAssertNoThrow(try encode(segment))
        }
    }

    func testEncodingSegmentEndedRandom() {
        let numTests = 1000
        for _ in 0 ..< numTests {
            let segment = Segment(id: .init(), name: UUID().uuidString, context: .init(), baggage: .init())
            segment.end()
            XCTAssertNoThrow(try encode(segment))
        }
    }

    func testEncodingSegmentInProgress() {
        let id = Segment.ID(rawValue: "ce7cc02792adb89e")!
        let name = "test"
        let traceId = try! XRayRecorder.TraceID(string: "1-5f09554c-c57fda56a353c8cdcc318570")
        let startTime = Timestamp(secondsSinceEpoch: 1)!
        let segment = Segment(id: id, name: name, context: .init(traceId: traceId), baggage: .init(), startTime: startTime)
        let result = #"{"id":"ce7cc02792adb89e","in_progress":true,"name":"test","start_time":1,"trace_id":"1-5f09554c-c57fda56a353c8cdcc318570"}"#
        XCTAssertEqual(result, try! encode(segment))
    }

    func testEncodingSegmentEnded() {
        let id = Segment.ID(rawValue: "ce7cc02792adb89e")!
        let name = "test"
        let traceId = try! XRayRecorder.TraceID(string: "1-5f09554c-c57fda56a353c8cdcc318570")
        let startTime = Timestamp(secondsSinceEpoch: 1)!
        let endTime = Timestamp(secondsSinceEpoch: 2)!
        let segment = Segment(id: id, name: name, context: .init(traceId: traceId), baggage: .init(), startTime: startTime)
        XCTAssertNoThrow(try segment.end(endTime))
        let result = #"{"end_time":2,"id":"ce7cc02792adb89e","name":"test","start_time":1,"trace_id":"1-5f09554c-c57fda56a353c8cdcc318570"}"#
        XCTAssertEqual(result, try! encode(segment))
    }

    func testEncodingSubsegmentInProgress() {
        let id = Segment.ID(rawValue: "ce7cc02792adb89e")!
        let name = "test"
        let traceId = try! XRayRecorder.TraceID(string: "1-5f09554c-c57fda56a353c8cdcc318570")
        let startTime = Timestamp(secondsSinceEpoch: 1)!
        let parentId = Segment.ID(rawValue: "ce7cc02792adb89f")!
        let segment = Segment(id: id, name: name,
                              context: .init(traceId: traceId, parentId: parentId), baggage: .init(),
                              startTime: startTime, subsegment: true)
        let result = #"{"id":"ce7cc02792adb89e","in_progress":true,"name":"test","parent_id":"ce7cc02792adb89f","start_time":1,"trace_id":"1-5f09554c-c57fda56a353c8cdcc318570","type":"subsegment"}"#
        XCTAssertEqual(result, try! encode(segment))
    }

    // MARK: - Subsegments

    // TODO: test encoding subsegments

    // MARK: - Errors and exceptions

//    func testEncodingSegmentWithHTTPError() {
//        let throttleError = Segment.HTTPError(statusCode: 429)
//        XCTAssertNotNil(throttleError)
//
//        let id = Segment.ID(rawValue: "ce7cc02792adb89e")!
//        let name = "test"
//        let traceId = try! XRayRecorder.TraceID(string: "1-5f09554c-c57fda56a353c8cdcc318570")
//        let startTime = Timestamp(secondsSinceEpoch: 1)!
//        let segment = Segment(id: id, name: name, context: .init(traceId: traceId), baggage: .init(), startTime: startTime)
//        segment.addError(throttleError!)
//        XCTAssertEqual(try! encode(segment),
//                       #"""
//                       {"error":true,"id":"ce7cc02792adb89e","in_progress":true,"name":"test","start_time":1,"throttle":true,"trace_id":"1-5f09554c-c57fda56a353c8cdcc318570"}
//                       """#)
//    }

    func testEncodingSegmentWithExceptions() {
        let id = Segment.ID(rawValue: "ce7cc02792adb89e")!
        let name = "test"
        let traceId = try! XRayRecorder.TraceID(string: "1-5f09554c-c57fda56a353c8cdcc318570")
        let startTime = Timestamp(secondsSinceEpoch: 1)!
        let segment = Segment(id: id, name: name, context: .init(traceId: traceId), baggage: .init(), startTime: startTime)

        let exceptionId = Segment.Exception.ID(rawValue: "9ad32cb3ede3e000")!
        segment.addException(Segment.Exception(id: exceptionId, error: EnumError.test))
        let exceptionId2 = Segment.Exception.ID(rawValue: "80265802f849a556")!
        segment.addException(Segment.Exception(id: exceptionId2, error: StructError(message: "test2")))

        XCTAssertEqual(try! encode(segment),
                       #"""
                       {"cause":{"exceptions":[{"id":"9ad32cb3ede3e000","message":"test"},{"id":"80265802f849a556","message":"StructError(message: \"test2\")"}]},"error":true,"id":"ce7cc02792adb89e","in_progress":true,"name":"test","start_time":1,"trace_id":"1-5f09554c-c57fda56a353c8cdcc318570"}
                       """#)
    }

    // MARK: Annotations

    func testEncodingAnnotationEmpty() {
        let annotations = Segment.Annotations()
        XCTAssertEqual("{}", try! encode(annotations))
    }

    func testEncodingAnnotationString() {
        var annotations = Segment.Annotations()

        annotations["key"] = .string("value")
        XCTAssertEqual(#"{"key":"value"}"#, try! encode(annotations))

        // replace the previous value
        annotations["key"] = .string("")
        XCTAssertEqual(#"{"key":""}"#, try! encode(annotations))

        // remove the value
        annotations["key"] = nil
        XCTAssertEqual("{}", try! encode(annotations))
    }

    func testEncodingAnnotationInt() {
        var annotations = Segment.Annotations()

        annotations["keyPositive"] = .integer(42)
        annotations["keyNegative"] = .integer(-42)
        annotations["keyZero"] = .integer(0)
        XCTAssertEqual(#"{"keyNegative":-42,"keyPositive":42,"keyZero":0}"#, try! encode(annotations))

        // replace the previous value
        annotations["keyPositive"] = .integer(137)
        XCTAssertEqual(#"{"keyNegative":-42,"keyPositive":137,"keyZero":0}"#, try! encode(annotations))

        // remove the value
        annotations["keyPositive"] = nil
        XCTAssertEqual(#"{"keyNegative":-42,"keyZero":0}"#, try! encode(annotations))
    }

    func testEncodingAnnotationDouble() {
        var annotations = Segment.Annotations()

        annotations["key"] = .double(4.2)
        // expect different precision on different platforms
        let json = try! encode(annotations)
        XCTAssertTrue(json.starts(with: "{\"key\":4."))

        // replace the previous value
        annotations["key"] = .double(13.7)
        let json2 = try! encode(annotations)
        XCTAssertTrue(json2.starts(with: "{\"key\":13."))

        // remove the value
        annotations["key"] = nil
        XCTAssertEqual("{}", try! encode(annotations))
    }

    func testEncodingAnnotationBool() {
        var annotations = Segment.Annotations()

        annotations["key"] = .bool(true)
        XCTAssertEqual(#"{"key":true}"#, try! encode(annotations))

        // replace the previous value
        annotations["key"] = .bool(false)
        XCTAssertEqual(#"{"key":false}"#, try! encode(annotations))

        // remove the value
        annotations["key"] = nil
        XCTAssertEqual("{}", try! encode(annotations))
    }

    func testEncodingAnnotationMixed() {
        var annotations = Segment.Annotations()

        annotations["stringKey"] = .string("value")
        annotations["intKey"] = .integer(1)
        annotations["boolKey"] = .bool(true)

        let json = try! encode(annotations)
        XCTAssertEqual(#"{"boolKey":true,"intKey":1,"stringKey":"value"}"#, json)
    }

    // MARK: Metadata

    func testEncodingMetadataEmpty() {
        let metadata = Segment.Metadata()
        XCTAssertEqual("{}", try! encode(metadata))
    }

    func testEncodingMetadataString() {
        var metadata = Segment.Metadata()
        metadata["key"] = "value"
        XCTAssertEqual(#"{"key":"value"}"#, try! encode(metadata))

        // replace the previous value
        metadata["key"] = "value2"
        XCTAssertEqual(#"{"key":"value2"}"#, try! encode(metadata))

        // remove the value
        metadata["key"] = nil
        XCTAssertEqual("{}", try! encode(metadata))
    }

    func testEncodingMetadataStringInterpolation() {
        var metadata = Segment.Metadata()
        let value = "value"
        metadata["key"] = "\(value)"
        XCTAssertEqual(#"{"key":"value"}"#, try! encode(metadata))

        // replace the previous value
        let value2 = 2
        metadata["key"] = "\(value2)"
        XCTAssertEqual(#"{"key":"2"}"#, try! encode(metadata))

        // remove the value
        metadata["key"] = nil
        XCTAssertEqual("{}", try! encode(metadata))
    }

    func testEncodingMetadataInt() {
        var metadata = Segment.Metadata()
        metadata["key"] = 1
        XCTAssertEqual(#"{"key":1}"#, try! encode(metadata))

        // replace the previous value
        metadata["key"] = 2
        XCTAssertEqual(#"{"key":2}"#, try! encode(metadata))

        // remove the value
        metadata["key"] = nil
        XCTAssertEqual("{}", try! encode(metadata))
    }

    func testEncodingMetadataFloat() {
        var metadata = Segment.Metadata()
        metadata["key"] = 4.2
//        XCTAssertEqual(#"{"key":4.2000000000000002}"#, try! encode(metadata))
        let json = try! encode(metadata)
        XCTAssertTrue(#"{"key":4.2000000000000002}"# == json || #"{"key":4.2}"# == json)

        // replace the previous value
        metadata["key"] = 13.7
//        XCTAssertEqual(#"{"key":13.699999999999999}"#, try! encode(metadata))
        let json2 = try! encode(metadata)
        XCTAssertTrue(#"{"key":13.699999999999999}"# == json2 || #"{"key":13.7}"# == json2)

        // remove the value
        metadata["key"] = nil
        XCTAssertEqual("{}", try! encode(metadata))
    }

    func testEncodingMetadataBool() {
        var metadata = Segment.Metadata()
        metadata["key"] = true
        XCTAssertEqual(#"{"key":true}"#, try! encode(metadata))

        // replace the previous value
        metadata["key"] = false
        XCTAssertEqual(#"{"key":false}"#, try! encode(metadata))

        // remove the value
        metadata["key"] = nil
        XCTAssertEqual("{}", try! encode(metadata))
    }
}
