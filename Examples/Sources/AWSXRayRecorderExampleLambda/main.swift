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
import AWSXRayRecorder
import AWSXRayRecorderLambda
import NIO

private struct ExampleLambdaHandler: EventLoopLambdaHandler {
    typealias In = Cloudwatch.ScheduledEvent
    typealias Out = Void

    private let recorder = XRayRecorder()

    private func doWork(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.submit { usleep(100_000) }.map { _ in }
    }

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Void> {
        recorder.segment(name: "ExampleLambdaHandler", context: context) {
            self.doWork(on: context.eventLoop)
        }.flatMap {
            self.recorder.flush(on: context.eventLoop)
        }
    }
}

Lambda.run(ExampleLambdaHandler())
