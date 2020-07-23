import AnyCodable
import XCTest

@testable import AWSXRayRecorder

private typealias Segment = XRayRecorder.Segment
private typealias SegmentError = XRayRecorder.SegmentError

// TODO: test segment name?

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

    // MARK: State

    func testStateChanges() {
        let now = Date().timeIntervalSince1970
        let startTime = Timestamp(secondsSinceEpoch: now)!
        let beforeTime = Timestamp(secondsSinceEpoch: now - 1)!

        let segment = Segment(name: UUID().uuidString, traceId: XRayRecorder.TraceID(), startTime: startTime)

        // cannot emit if still in progress
        XCTAssertThrowsError(try segment.emit()) { error in
            guard case SegmentError.inProgress = error else {
                XCTFail()
                return
            }
        }

        // cannot end before started
        XCTAssertThrowsError(try segment.end(beforeTime)) { error in
            guard case SegmentError.startedInFuture = error else {
                XCTFail()
                return
            }
        }

        XCTAssertNoThrow(try segment.end(Timestamp()))

        // cannot end if already end
        XCTAssertThrowsError(try segment.end(Timestamp())) { error in
            guard case SegmentError.alreadyEnded = error else {
                XCTFail()
                return
            }
        }

        XCTAssertNoThrow(try segment.emit())

        // cannot emit twice
        XCTAssertThrowsError(try segment.emit()) { error in
            guard case SegmentError.alreadyEmitted = error else {
                XCTFail()
                return
            }
        }
    }

    // MARK: Subsegments

    func testSubsegmentsInProgress() {
        let segment = Segment(name: UUID().uuidString, traceId: XRayRecorder.TraceID())
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

    func testSettingAnnotations() {
        let segment = Segment(name: UUID().uuidString, traceId: XRayRecorder.TraceID())

        let stringKey = UUID().uuidString
        let stringValue = UUID().uuidString
        segment.setAnnotation(stringValue, forKey: stringKey)
        XCTAssertEqual(Segment.AnnotationValue.string(stringValue), segment.annotations[stringKey])

        let integerKey = UUID().uuidString
        let integerValue = Int.random(in: Int.min ... Int.max)
        segment.setAnnotation(integerValue, forKey: integerKey)
        XCTAssertEqual(Segment.AnnotationValue.integer(integerValue), segment.annotations[integerKey])

        let doubleKey = UUID().uuidString
        let doubleValue = Double.random(in: -1000 ... 1000)
        segment.setAnnotation(doubleValue, forKey: doubleKey)
        XCTAssertEqual(Segment.AnnotationValue.double(doubleValue), segment.annotations[doubleKey])

        let boolKey = UUID().uuidString
        let boolValue = false
        segment.setAnnotation(boolValue, forKey: boolKey)
        XCTAssertEqual(Segment.AnnotationValue.bool(boolValue), segment.annotations[boolKey])

        XCTAssertEqual(4, segment.annotations.count)
    }

    // MARK: Metadata

    func testSettingMetadata() {
        let segment = Segment(name: UUID().uuidString, traceId: XRayRecorder.TraceID())

        let stringKey = UUID().uuidString
        let stringValue = AnyEncodable(UUID().uuidString)
        segment.setMetadata(stringValue, forKey: stringKey)
        XCTAssertEqual(stringValue, segment.metadata[stringKey])

        let integerKey = UUID().uuidString
        let ingeterValue = AnyEncodable(UInt64.random(in: UInt64.min ... UInt64.max))
        segment.setMetadata(ingeterValue, forKey: integerKey)
        XCTAssertEqual(ingeterValue, segment.metadata[integerKey])

        segment.setMetadata([1, 2, 3], forKey: UUID().uuidString)

        segment.setMetadata([1: 2], forKey: UUID().uuidString)

        XCTAssertEqual(4, segment.metadata.count)
    }

    func testAppendingMetadata() {
        let segment = Segment(name: UUID().uuidString, traceId: XRayRecorder.TraceID())

        let key = UUID().uuidString
        let value1 = AnyEncodable(UUID().uuidString)
        let value2 = AnyEncodable(UInt64.random(in: UInt64.min ... UInt64.max))

        segment.appendMetadata(value1, forKey: key)
        segment.appendMetadata(value2, forKey: key)

        XCTAssertEqual(1, segment.metadata.count)
        let array = segment.metadata[key]?.value as? [Any]
        XCTAssertNotNil(array)
        XCTAssertEqual(2, array?.count)
        XCTAssertEqual(value1, array?[0] as? AnyEncodable)
        XCTAssertEqual(value2, array?[1] as? AnyEncodable)
    }
}
