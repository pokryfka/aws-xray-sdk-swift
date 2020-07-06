import AWSXRayRecorder
import NIO

enum ExampleError: Error {
    case test
}

let recorder = XRayRecorder()

// begin and end (sub)segments explicitly
let segment = recorder.beginSegment(name: "Segment 1 A")
// let segment = recorder.beginSubsegment(name: "Segment 1 X", parentId: "9d9dfbe1c4befbec")
segment.setAnnotation("zip_code", value: 98101)
segment.setMetadata(["debug": ["test": "Metadata string"]])
usleep(100_000)
segment.end()

usleep(100_000)

let fakeParentId = "9d9dfbe1c4befbec"

let subsegment3 = recorder.beginSubsegment(name: "Segment 3 X A", parentId: fakeParentId)
usleep(100_000)
let subsegment4 = recorder.beginSubsegment(name: "Segment 3 X B", parentId: fakeParentId)
usleep(100_000)

// use closures for convenience
recorder.segment(name: "Segment 2") { segment in
    try? segment.subsegment(name: "Subsegment 2.1") { segment in
        _ = segment.subsegment(name: "Subsegment 2.1.1 with Result") { _ -> String in
            usleep(100_000)
            return "Result"
        }
        try segment.subsegment(name: "Subsegment 2.1.2 with Error") { _ in
            usleep(200_000)
            throw ExampleError.test
        }
    }
}

// try recorder.flush().wait()
recorder.flush()

// sleep(5)

exit(0)
