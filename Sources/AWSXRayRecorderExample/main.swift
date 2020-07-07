import AWSXRayRecorder
import NIO

enum ExampleError: Error {
    case test
}

let recorder = XRayRecorder()

// begin and end (sub)segments explicitly
let segment = recorder.beginSegment(name: "Segment 1")
segment.setAnnotation("zip_code", value: 98101)
segment.setMetadata(["debug": ["test": "Metadata string"]])
usleep(100_000)
let subsegment = segment.beginSubsegment(name: "Subsegment 1.1 async")
segment.end()

usleep(100_000)
// ending after parent
subsegment.end()

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
