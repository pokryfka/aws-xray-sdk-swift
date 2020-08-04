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

import AWSLambdaEvents
import AWSLambdaRuntime
import AWSXRaySDK
import NIO // usleep

// TODO: Implement AWS plugins https://github.com/pokryfka/aws-xray-sdk-swift/issues/26

private var metadata: XRayRecorder.Segment.Metadata? = {
//    let metadataKeys: [AWSLambdaEnv] = [.functionName, .funtionVersion, .memorySizeInMB]
//    let metadataKeyValues = zip(metadataKeys, metadataKeys.map(\.value))
//        .filter { $0.1 != nil }.map { ($0.0.rawValue, AnyEncodable($0.1)) }
//    return XRayRecorder.Segment.Metadata(uniqueKeysWithValues: metadataKeyValues)
    nil
}()

private struct ExampleLambdaHandler: EventLoopLambdaHandler {
    typealias In = Cloudwatch.ScheduledEvent
    typealias Out = Void

    private let recorder = XRayRecorder()

    private func doWork(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.submit { usleep(100_000) }.map { _ in }
    }

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Void> {
        let traceContext: XRayRecorder.TraceContext = (try? .init(tracingHeader: context.traceID)) ?? .init()
        return recorder.segment(name: "ExampleLambdaHandler", context: traceContext, metadata: metadata) {
            self.doWork(on: context.eventLoop)
        }.flatMap { // TODO: flash also, in fact especially when thare are errors, see testPropagatingError
            self.recorder.flush(on: context.eventLoop)
        }
    }
}

Lambda.run(ExampleLambdaHandler())
