import Foundation
import XCTest

@testable import AWSXRayRecorder

private typealias Segment = XRayRecorder.Segment
private typealias SegmentError = XRayRecorder.SegmentError

private extension JSONEncoder {
    func encode<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try encode(value), as: UTF8.self)
    }
}

// TODO: use snapshot testing?
// TODO: make segment decodable?
// TODO: test encoding subsegments?
// TODO: test encoding errors?

final class SegmentEncodingTests: XCTestCase {
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()

    private func encode(_ segment: Segment) -> String {
        try! jsonEncoder.encode(segment) as String
    }

    private func encode(_ annotations: Segment.Annotations) -> String {
        try! jsonEncoder.encode(annotations) as String
    }

    private func encode(_ metadata: Segment.Metadata) -> String {
        try! jsonEncoder.encode(metadata) as String
    }

    // MARK: Segment

    func testEncodingSegmentInProgressRandom() {
        let numTests = 1000
        for _ in 0 ..< numTests {
            let segment = Segment(name: UUID().uuidString, traceId: XRayRecorder.TraceID())
            XCTAssertNoThrow(try jsonEncoder.encode(segment) as String)
        }
    }

    func testEncodingSegmentEndedRandom() {
        let numTests = 1000
        for _ in 0 ..< numTests {
            let segment = Segment(name: UUID().uuidString, traceId: XRayRecorder.TraceID())
            segment.end()
            XCTAssertNoThrow(try jsonEncoder.encode(segment) as String)
        }
    }

    func testEncodingSegmentInProgress() {
        let id = Segment.ID(rawValue: "ce7cc02792adb89e")!
        let name = "test"
        let traceId = try! XRayRecorder.TraceID(string: "1-5f09554c-c57fda56a353c8cdcc318570")
        let startTime = Timestamp(secondsSinceEpoch: 1)!
        let segment = Segment(id: id, name: name, traceId: traceId, startTime: startTime)
        let result = #"{"id":"ce7cc02792adb89e","in_progress":true,"name":"test","start_time":1,"trace_id":"1-5f09554c-c57fda56a353c8cdcc318570"}"#
        XCTAssertEqual(result, encode(segment))
    }

    func testEncodingSegmentEnded() {
        let id = Segment.ID(rawValue: "ce7cc02792adb89e")!
        let name = "test"
        let traceId = try! XRayRecorder.TraceID(string: "1-5f09554c-c57fda56a353c8cdcc318570")
        let startTime = Timestamp(secondsSinceEpoch: 1)!
        let endTime = Timestamp(secondsSinceEpoch: 2)!
        let segment = Segment(id: id, name: name, traceId: traceId, startTime: startTime)
        segment.end(endTime)
        let result = #"{"end_time":2,"id":"ce7cc02792adb89e","name":"test","start_time":1,"trace_id":"1-5f09554c-c57fda56a353c8cdcc318570"}"#
        XCTAssertEqual(result, encode(segment))
    }

    func testEncodingSubsegmentInProgress() {
        let id = Segment.ID(rawValue: "ce7cc02792adb89e")!
        let name = "test"
        let traceId = try! XRayRecorder.TraceID(string: "1-5f09554c-c57fda56a353c8cdcc318570")
        let startTime = Timestamp(secondsSinceEpoch: 1)!
        let parentId = Segment.ID(rawValue: "ce7cc02792adb89f")!
        let segment = Segment(id: id, name: name, traceId: traceId, startTime: startTime, parentId: parentId, subsegment: true)
        let result = #"{"id":"ce7cc02792adb89e","in_progress":true,"name":"test","parent_id":"ce7cc02792adb89f","start_time":1,"trace_id":"1-5f09554c-c57fda56a353c8cdcc318570","type":"subsegment"}"#
        XCTAssertEqual(result, encode(segment))
    }

    // MARK: Annotations

    func testEncodingAnnotationEmpty() {
        let annotations = Segment.Annotations()
        XCTAssertEqual("{}", encode(annotations))
    }

    func testEncodingAnnotationString() {
        var annotations = Segment.Annotations()

        annotations["key"] = .string("value")
        XCTAssertEqual(#"{"key":"value"}"#, encode(annotations))

        // replace the previous value
        annotations["key"] = .string("")
        XCTAssertEqual(#"{"key":""}"#, encode(annotations))

        // remove the value
        annotations["key"] = nil
        XCTAssertEqual("{}", encode(annotations))
    }

    func testEncodingAnnotationInt() {
        var annotations = Segment.Annotations()

        annotations["keyPositive"] = .int(42)
        annotations["keyNegative"] = .int(-42)
        annotations["keyZero"] = .int(0)
        XCTAssertEqual(#"{"keyNegative":-42,"keyPositive":42,"keyZero":0}"#, encode(annotations))

        // replace the previous value
        annotations["keyPositive"] = .int(137)
        XCTAssertEqual(#"{"keyNegative":-42,"keyPositive":137,"keyZero":0}"#, encode(annotations))

        // remove the value
        annotations["keyPositive"] = nil
        XCTAssertEqual(#"{"keyNegative":-42,"keyZero":0}"#, encode(annotations))
    }

    func testEncodingAnnotationFloat() {
        var annotations = Segment.Annotations()

        annotations["key"] = .float(4.2)
        XCTAssertEqual("{\"key\":4.1999998092651367}", encode(annotations))

        // replace the previous value
        annotations["key"] = .float(13.7)
        XCTAssertEqual(#"{"key":13.699999809265137}"#, encode(annotations))

        // remove the value
        annotations["key"] = nil
        XCTAssertEqual("{}", encode(annotations))
    }

    func testEncodingAnnotationBool() {
        var annotations = Segment.Annotations()

        annotations["key"] = .bool(true)
        XCTAssertEqual(#"{"key":true}"#, encode(annotations))

        // replace the previous value
        annotations["key"] = .bool(false)
        XCTAssertEqual(#"{"key":false}"#, encode(annotations))

        // remove the value
        annotations["key"] = nil
        XCTAssertEqual("{}", encode(annotations))
    }

    func testEncodingAnnotationMixed() {
        var annotations = Segment.Annotations()

        annotations["stringKey"] = .string("value")
        annotations["intKey"] = .int(1)
        annotations["floatKey"] = .float(4.2)
        annotations["boolKey"] = .bool(true)

        XCTAssertEqual(#"{"boolKey":true,"floatKey":4.1999998092651367,"intKey":1,"stringKey":"value"}"#, encode(annotations))
    }

    // MARK: Metadata

    func testEncodingMetadataEmpty() {
        let metadata = Segment.Metadata()
        XCTAssertEqual("{}", encode(metadata))
    }

    func testEncodingMetadataString() {
        var metadata = Segment.Metadata()
        metadata["key"] = "value"
        XCTAssertEqual(#"{"key":"value"}"#, encode(metadata))

        // replace the previous value
        metadata["key"] = "value2"
        XCTAssertEqual(#"{"key":"value2"}"#, encode(metadata))

        // remove the value
        metadata["key"] = nil
        XCTAssertEqual("{}", encode(metadata))
    }

    func testEncodingMetadataInt() {
        var metadata = Segment.Metadata()
        metadata["key"] = 1
        XCTAssertEqual(#"{"key":1}"#, encode(metadata))

        // replace the previous value
        metadata["key"] = 2
        XCTAssertEqual(#"{"key":2}"#, encode(metadata))

        // remove the value
        metadata["key"] = nil
        XCTAssertEqual("{}", encode(metadata))
    }

    func testEncodingMetadataFloat() {
        var metadata = Segment.Metadata()
        metadata["key"] = 4.2
        XCTAssertEqual(#"{"key":4.2000000000000002}"#, encode(metadata))

        // replace the previous value
        metadata["key"] = 13.7
        XCTAssertEqual(#"{"key":13.699999999999999}"#, encode(metadata))

        // remove the value
        metadata["key"] = nil
        XCTAssertEqual("{}", encode(metadata))
    }

    func testEncodingMetadataBool() {
        var metadata = Segment.Metadata()
        metadata["key"] = true
        XCTAssertEqual(#"{"key":true}"#, encode(metadata))

        // replace the previous value
        metadata["key"] = false
        XCTAssertEqual(#"{"key":false}"#, encode(metadata))

        // remove the value
        metadata["key"] = nil
        XCTAssertEqual("{}", encode(metadata))
    }
}
