import AWSXRayRecorder
import NIO // usleep

enum ExampleError: Error {
    case test
}

let recorder = XRayRecorder(config: .init(logLevel: .debug, serviceVersion: "aws-xray-sdk-example"))

// begin and end (sub)segments explicitly
let segment = recorder.beginSegment(name: "Segment 1")
segment.setAnnotation("zip_code", value: 98101)
segment.setMetadata(["debug": ["test": "Metadata string"]])
usleep(100_000)
_ = segment.beginSubsegment(name: "Subsegment 1.1 in progress")
let subsegment = segment.beginSubsegment(name: "Subsegment 1.2 async")
segment.end()

// ending after parent
usleep(100_000)
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

recorder.wait()

exit(0)
