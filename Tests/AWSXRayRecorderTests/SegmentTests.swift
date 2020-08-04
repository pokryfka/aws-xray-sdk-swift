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

import AnyCodable
import Logging
import XCTest

@testable import AWSXRayRecorder

private typealias Segment = XRayRecorder.Segment
private typealias SegmentError = XRayRecorder.SegmentError

final class SegmentTests: XCTestCase {
    // MARK: ID

    func testParsingInvalidId() {
        for string in ["", "1", "1234567890", "123456789012345z"] {
            let id = Segment.ID(rawValue: string)
            XCTAssertNil(id)
        }
    }

    func testParsingValidId() {
        for string in ["ce7cc02792adb89e"] {
            let id = Segment.ID(rawValue: string)
            XCTAssertNotNil(id)
        }
    }

    func testTruncatingName() {
        let maxNameLength: Int = 200

        let veryLongName = String(repeating: "x", count: maxNameLength)
        let segment = Segment(id: .init(), name: veryLongName, context: .init())
        XCTAssertEqual(maxNameLength, segment.name.count)

        let tooLongName = String(repeating: "x", count: maxNameLength + 1)
        let segmentWithTruncatedName = Segment(id: .init(), name: tooLongName, context: .init())
        XCTAssertEqual(maxNameLength, segmentWithTruncatedName.name.count)
        XCTAssertTrue(tooLongName.starts(with: segmentWithTruncatedName.name))
    }

    // MARK: Subsegments

    func testCreatingSubsegments() {
        let context = XRayContext()

        let segmentId = Segment.ID()
        let segmentName = UUID().uuidString

        let segment = Segment(id: segmentId, name: segmentName, context: context)
        XCTAssertEqual(segmentId, segment.id)
        XCTAssertEqual(segmentName, segment.name)
        XCTAssertEqual(context.isSampled, segment.isSampled)
        XCTAssertNotNil(segment.baggage.xRayContext)
        XCTAssertEqual(segmentId, segment.baggage.xRayContext?.parentId)
        XCTAssertTrue(segment.baggage.xRayContext!.isSampled)

        let subsegment = segment.beginSubsegment(name: UUID().uuidString)
        XCTAssertNotEqual(segmentId, subsegment.id)
        XCTAssertNotEqual(segmentName, subsegment.name)
        XCTAssertEqual(context.isSampled, subsegment.isSampled)
        XCTAssertNotNil(subsegment.baggage.xRayContext)
        XCTAssertNotEqual(segmentId, subsegment.baggage.xRayContext?.parentId)
        XCTAssertTrue(subsegment.baggage.xRayContext!.isSampled)

        segment.subsegment(name: UUID().uuidString) { subsegment in
            XCTAssertNotEqual(segmentId, subsegment.id)
            XCTAssertNotEqual(segmentName, subsegment.name)
            XCTAssertEqual(context.isSampled, subsegment.isSampled)
            XCTAssertNotNil(subsegment.baggage.xRayContext)
            XCTAssertNotEqual(segmentId, subsegment.baggage.xRayContext?.parentId)
            XCTAssertTrue(subsegment.baggage.xRayContext!.isSampled)
        }
    }

    func testSubsegmentsInProgress() {
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init(), baggage: .init())
        let subsegmentA = segment.beginSubsegment(name: UUID().uuidString)
        let subsegmentB = segment.beginSubsegment(name: UUID().uuidString)
        let subsegmentA1 = subsegmentA.beginSubsegment(name: UUID().uuidString)
        let subsegmentA2 = subsegmentA.beginSubsegment(name: UUID().uuidString)

        XCTAssertEqual(segment.subsegmentsInProgress().map(\.id), [subsegmentA, subsegmentB].map(\.id))
        XCTAssertEqual(subsegmentA.subsegmentsInProgress().map(\.id), [subsegmentA1, subsegmentA2].map(\.id))
        XCTAssertTrue(subsegmentB.subsegmentsInProgress().isEmpty)
        XCTAssertTrue(subsegmentA1.subsegmentsInProgress().isEmpty)
        XCTAssertTrue(subsegmentA2.subsegmentsInProgress().isEmpty)

        subsegmentA.end()

        XCTAssertEqual(segment.subsegmentsInProgress().map(\.id), [subsegmentA1, subsegmentA2, subsegmentB].map(\.id))
        XCTAssertEqual(subsegmentA.subsegmentsInProgress().map(\.id), [subsegmentA1, subsegmentA2].map(\.id))
        XCTAssertTrue(subsegmentB.subsegmentsInProgress().isEmpty)
        XCTAssertTrue(subsegmentA1.subsegmentsInProgress().isEmpty)
        XCTAssertTrue(subsegmentA2.subsegmentsInProgress().isEmpty)

        subsegmentA2.end()

        XCTAssertEqual(segment.subsegmentsInProgress().map(\.id), [subsegmentA1, subsegmentB].map(\.id))
        XCTAssertEqual(subsegmentA.subsegmentsInProgress().map(\.id), [subsegmentA1].map(\.id))
        XCTAssertTrue(subsegmentB.subsegmentsInProgress().isEmpty)
        XCTAssertTrue(subsegmentA1.subsegmentsInProgress().isEmpty)
        XCTAssertTrue(subsegmentA2.subsegmentsInProgress().isEmpty)

        subsegmentB.end()

        XCTAssertEqual(segment.subsegmentsInProgress().map(\.id), [subsegmentA1].map(\.id))
        XCTAssertEqual(subsegmentA.subsegmentsInProgress().map(\.id), [subsegmentA1].map(\.id))
        XCTAssertTrue(subsegmentB.subsegmentsInProgress().isEmpty)
        XCTAssertTrue(subsegmentA1.subsegmentsInProgress().isEmpty)
        XCTAssertTrue(subsegmentA2.subsegmentsInProgress().isEmpty)

        subsegmentA1.end()

        XCTAssertTrue(segment.subsegmentsInProgress().isEmpty)
        XCTAssertTrue(subsegmentA.subsegmentsInProgress().isEmpty)
        XCTAssertTrue(subsegmentB.subsegmentsInProgress().isEmpty)
        XCTAssertTrue(subsegmentA1.subsegmentsInProgress().isEmpty)
        XCTAssertTrue(subsegmentA2.subsegmentsInProgress().isEmpty)
    }

    // MARK: Annotations

    func testAnnotationKeys() {
        let validCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        XCTAssertFalse(" ".containsOnly(charactersIn: validCharacters))
        XCTAssertFalse("@".containsOnly(charactersIn: validCharacters))
        XCTAssertTrue("_key".containsOnly(charactersIn: validCharacters))

        let invalidKey = "\(UUID().uuidString)_!_\(UUID().uuidString)"
        XCTAssertFalse(invalidKey.containsOnly(charactersIn: validCharacters))
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init())
        XCTAssertEqual(0, segment._test_annotations.count)

        segment.setAnnotation("\(UUID().uuidString)", forKey: invalidKey)
        // the value should be recorded but with corrected key
        XCTAssertEqual(1, segment._test_annotations.count)
        XCTAssertNil(segment._test_annotations[invalidKey])
        let validKey = String(segment._test_annotations.keys.first!)
        XCTAssertTrue(validKey.containsOnly(charactersIn: validCharacters))
    }

    func testSettingAnnotations() {
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init())
        XCTAssertEqual(0, segment._test_annotations.count)

        let stringKey = UUID().uuidString
        let stringValue = UUID().uuidString
        segment.setAnnotation(stringValue, forKey: stringKey)
        XCTAssertEqual(1, segment._test_annotations.count)
        XCTAssertEqual(Segment.AnnotationValue.string(stringValue), segment._test_annotations[stringKey])

        let integerKey = UUID().uuidString
        let integerValue = Int.random(in: Int.min ... Int.max)
        segment.setAnnotation(integerValue, forKey: integerKey)
        XCTAssertEqual(2, segment._test_annotations.count)
        XCTAssertEqual(Segment.AnnotationValue.integer(integerValue), segment._test_annotations[integerKey])

        let doubleKey = UUID().uuidString
        let doubleValue = Double.random(in: -1000 ... 1000)
        segment.setAnnotation(doubleValue, forKey: doubleKey)
        XCTAssertEqual(3, segment._test_annotations.count)
        XCTAssertEqual(Segment.AnnotationValue.double(doubleValue), segment._test_annotations[doubleKey])

        let boolKey = UUID().uuidString
        let boolValue = false
        segment.setAnnotation(boolValue, forKey: boolKey)
        XCTAssertEqual(4, segment._test_annotations.count)
        XCTAssertEqual(Segment.AnnotationValue.bool(boolValue), segment._test_annotations[boolKey])
    }

    // MARK: Metadata

    func testMetadataKeys() {
        let invalidKey = "AWS.\(UUID().uuidString)"
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init())
        XCTAssertEqual(0, segment._test_metadata.count)

        segment.setMetadata("\(UUID().uuidString)", forKey: invalidKey)
        // the value should be recorded but with corrected key
        XCTAssertEqual(1, segment._test_metadata.count)
        XCTAssertNil(segment._test_metadata[invalidKey])

        // reset metadata
        segment.setMetadata([:])
        XCTAssertEqual(0, segment._test_metadata.count)

        segment.setMetadata([invalidKey: "\(UUID().uuidString)"])
        // the value should be recorded but with corrected key
        XCTAssertEqual(1, segment._test_metadata.count)
        XCTAssertNil(segment._test_metadata[invalidKey])

        // reset metadata
        segment.setMetadata([:])
        XCTAssertEqual(0, segment._test_metadata.count)

        segment.appendMetadata("\(UUID().uuidString)", forKey: invalidKey)
        segment.appendMetadata("\(UUID().uuidString)", forKey: invalidKey)
        XCTAssertEqual(1, segment._test_metadata.count)
        XCTAssertNil(segment._test_metadata[invalidKey])
    }

    func testSettingMetadata() {
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init())
        XCTAssertEqual(0, segment._test_metadata.count)

        let stringKey = UUID().uuidString
        let stringValue = AnyEncodable(UUID().uuidString)
        segment.setMetadata(stringValue, forKey: stringKey)
        XCTAssertEqual(1, segment._test_metadata.count)
        XCTAssertEqual(stringValue, segment._test_metadata[stringKey])

        let integerKey = UUID().uuidString
        let ingeterValue = AnyEncodable(UInt64.random(in: UInt64.min ... UInt64.max))
        segment.setMetadata(ingeterValue, forKey: integerKey)
        XCTAssertEqual(2, segment._test_metadata.count)
        XCTAssertEqual(ingeterValue, segment._test_metadata[integerKey])

        segment.setMetadata([1, 2, 3], forKey: UUID().uuidString)
        segment.setMetadata([1: 2], forKey: UUID().uuidString)

        XCTAssertEqual(4, segment._test_metadata.count)
    }

    func testReplacingMetadata() {
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init())
        XCTAssertEqual(0, segment._test_metadata.count)

        let key = UUID().uuidString
        let value = AnyEncodable(UUID().uuidString)
        segment.setMetadata(value, forKey: key)
        XCTAssertEqual(1, segment._test_metadata.count)
        XCTAssertEqual(value, segment._test_metadata[key])

        let key2 = UUID().uuidString
        segment.setMetadata([key2: "\(UUID().uuidString)"])
        XCTAssertEqual(1, segment._test_metadata.count)
        XCTAssertNotEqual(value, segment._test_metadata[key])
        XCTAssertNil(segment._test_metadata[key])
        XCTAssertNotNil(segment._test_metadata[key2])
    }

    func testAppendingMetadata() {
        let segment = Segment(id: .init(), name: UUID().uuidString, context: .init())

        let key = UUID().uuidString
        let value1 = UUID().uuidString
        let value2 = UInt64.random(in: UInt64.min ... UInt64.max)

        // TODO: improve API, see https://github.com/pokryfka/aws-xray-sdk-swift/issues/61
        segment.appendMetadata(AnyEncodable(value1), forKey: key)
        segment.appendMetadata(AnyEncodable(value2), forKey: key)

        XCTAssertEqual(1, segment._test_metadata.count)
        let array = segment._test_metadata[key]?.value as? [Any]
        XCTAssertNotNil(array)
        XCTAssertEqual(2, array?.count)
        XCTAssertEqual(value1, array?[0] as? String)
        XCTAssertEqual(value2, array?[1] as? UInt64)
    }
}
