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

import AsyncHTTPClient
import AWSS3
import AWSXRayRecorder
import NIO

func env(_ name: String) -> String? {
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
}

precondition(env("AWS_ACCESS_KEY_ID") != nil, "AWS_ACCESS_KEY_ID not set")
precondition(env("AWS_SECRET_ACCESS_KEY") != nil, "AWS_SECRET_ACCESS_KEY not set")

// share the event loop group
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer {
    try? group.syncShutdownGracefully()
}

let eventLoop = group.next()

let httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoop))
defer {
    try? httpClient.syncShutdown()
}

let recorder = XRayRecorder(
    config: .init(enabled: true,
                  daemonEndpoint: "127.0.0.1:2000",
                  logLevel: .debug,
                  serviceVersion: "aws-xray-sdk-swift-example-sdk"),
    eventLoopGroup: group
)

// TODO: WIP https://github.com/pokryfka/aws-xray-sdk-swift/issues/19

// let awsClient = AWSClient(
//    //    middlewares: [XRayMiddleware(recorder: recorder, name: "S3")],
//    httpClientProvider: .shared(httpClient)
// )
// let s3 = S3(client: awsClient)
//
// let aFuture = recorder.segment(name: "Segment 1", context: context) {
//    group.next().submit { usleep(100_000) }.map { _ in }
// }
//
// let s3futures = recorder.beginSegment(name: "Segment 2", context: context, body: { segment in
//    segment.subsegment(name: "List Buckets") {
//        s3.listBuckets().map { _ in }
//    }
// })
//    .flatMap { segment, _ in
//        segment.subsegment(name: "Get Invalid Object") {
//            s3.getObject(.init(bucket: "invalidBucket", key: "invalidKey")).map { _ in }
//        }
//        .recover { _ in }
//        .map { (segment, $0) } // pass the segment
//    }
//    .map { $0.0.end() } // end the segment
//
// _ = try aFuture.and(s3futures).wait()
//
// try recorder.flush(on: eventLoop).wait()
//
// exit(0)
