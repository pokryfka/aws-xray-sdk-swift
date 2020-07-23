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
}
