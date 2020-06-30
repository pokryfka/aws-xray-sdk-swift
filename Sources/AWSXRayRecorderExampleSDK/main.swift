import AsyncHTTPClient
import AWSS3
import AWSXRayHTTPEmitter
import AWSXRayRecorder
import AWSXRayRecorderSDK
import AWSXRayUDPEmitter
import NIO

func env(_ name: String) -> String? {
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
}

let httpEmitter = env("AWS_XRAY_DAEMON_ADDRESS")?.starts(with: "http") ?? false
precondition(env("AWS_ACCESS_KEY_ID") != nil, "AWS_ACCESS_KEY_ID not set")
precondition(env("AWS_SECRET_ACCESS_KEY") != nil, "AWS_SECRET_ACCESS_KEY not set")

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer {
    try? group.syncShutdownGracefully()
}

let httpClient = HTTPClient(eventLoopGroupProvider: .shared(group.next()))
defer {
    try? httpClient.syncShutdown()
}

let emitter: XRayEmitter
if httpEmitter {
    emitter = XRayHTTPEmitter()
} else {
    emitter = XRayUDPEmitter()
}

let recorder = XRayRecorder()

// TODO: WIP

let s3 = S3(middlewares: [XRayMiddleware(recorder: recorder, name: "S3")],
            httpClientProvider: .shared(httpClient))

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
        emitter.send(segments: recorder.removeAll())
    }.wait()

exit(0)
