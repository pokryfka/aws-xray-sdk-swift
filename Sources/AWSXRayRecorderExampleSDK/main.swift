import AWSS3
import AWSXRayRecorder
import NIO

func env(_ name: String) -> String? {
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
}

let xrayEndpoint = env("XRAY_ENDPOINT") ?? "http://127.0.0.1:2000"

assert(env("AWS_ACCESS_KEY_ID") != nil, "AWS_ACCESS_KEY_ID not set")
assert(env("AWS_SECRET_ACCESS_KEY") != nil, "AWS_SECRET_ACCESS_KEY not set")

enum ExampleError: Error {
    case test
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let emmiter = XRayEmmiter(eventLoop: group.next(), endpoint: xrayEndpoint)

let recorder = XRayRecorder()

// TODO: WIP

let s3 = S3(middlewares: [XRayMiddleware(recorder: recorder, name: "S3")],
            httpClientProvider: .createNew)

let aFuture = recorder.segment(name: "Segment 1") {
    group.next().submit { usleep(100_000) }.map { _ in }
}

let s3futures = recorder.beginSegment(name: "Segment 2", body: { segment in
    segment.subsegment(name: "List Buckets") {
        s3.listBuckets().map { _ in }
    }
})
    .flatMap { segment, _ in
        segment.subsegment(name: "Get Invalid Object") {
            s3.getObject(.init(bucket: "invalidBucket", key: "invalidKey")).map { _ in }
        }
        .recover { _ in }
        .map { (segment, $0) } // pass the segment
    }
    .map { $0.0.end() } // end the segment

try aFuture.and(s3futures)
    .flatMap { _ in
        emmiter.send(segments: recorder.removeAll())
    }.wait()

try group.syncShutdownGracefully()
exit(0)
