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

// import AWSS3 // local
import AWSSDKSwiftCore
import AWSXRayInstrument
import AWSXRaySDK
import Instrumentation
import Logging
import NIO

func env(_ name: String) -> String? {
    guard let value = getenv(name) else { return nil }
    return String(cString: value)
}

precondition(env("AWS_ACCESS_KEY_ID") != nil, "AWS_ACCESS_KEY_ID not set")
precondition(env("AWS_SECRET_ACCESS_KEY") != nil, "AWS_SECRET_ACCESS_KEY not set")

let maxKeys: Int = 10

// share the event loop group
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
defer {
    try? eventLoopGroup.syncShutdownGracefully()
}

let eventLoop = eventLoopGroup.next()

// create and boostrap the instrument
let instrument = XRayRecorder(config: .init(logLevel: .debug))
defer { instrument.shutdown() }
InstrumentationSystem.bootstrap(instrument)

// create new context
var logger = Logger(label: "ExampleAWS")
logger.logLevel = .debug
var context = AWSClient.emptyContext(logger: logger)
context.baggage.xRayContext = XRayContext()

let example = instrument.beginSegment(name: "AWSXRaySDKExampleAWS", baggage: context.baggage)
context = context.with(baggage: example.baggage)

// create S3 client
let initSegment = example.beginSubsegment(name: "init")
let awsClient = AWSClient(httpClientProvider: .createNew, context: context.with(baggage: initSegment.baggage))
defer {
    try? awsClient.syncShutdown()
}

let s3 = S3(client: awsClient)
initSegment.end()

struct S3ObjectInfo {
    let bucket: String
    let key: String
    let sizeInBytes: Int64
}

func listBuckets(context: AWSClient.Context) -> EventLoopFuture<[String]> {
    instrument.segment(name: "listBuckets", baggage: context.baggage) { segment in
        s3.listBuckets(context: context.with(baggage: segment.baggage))
            .map(\.buckets).map { buckets in
                buckets?.compactMap(\.name) ?? [String]()
            }
    }
}

func listObjects(bucket: String, context: AWSClient.Context) -> EventLoopFuture<[S3ObjectInfo]> {
    instrument.segment(name: "listObjects in \(bucket)", baggage: context.baggage) { segment in
        s3.listObjectsV2(.init(bucket: bucket, maxKeys: maxKeys), context: context.with(baggage: segment.baggage))
            .map(\.contents).map { objects in
                objects?.compactMap { object in
                    guard let key = object.key, let size = object.size else { return nil }
                    return S3ObjectInfo(bucket: bucket, key: key, sizeInBytes: size)
                } ?? [S3ObjectInfo]()
            }
    }
}

try? instrument.segment(name: "run", baggage: context.baggage) { segment -> EventLoopFuture<Void> in
    let segmentContext = context.with(baggage: segment.baggage)
    return listBuckets(context: segmentContext)
        .flatMap { buckets in
            // TODO: segments are started when future is created
            let listBucketObjects = buckets.map { listObjects(bucket: $0, context: segmentContext) }
            return EventLoopFuture.andAllComplete(listBucketObjects, on: eventLoop)
        }
}.wait()

example.end()

instrument.wait()
