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

import AWSXRaySDK
//import AWSXRayTesting // uses Foundation JSON encoder
import NIO // usleep

enum ExampleError: Error {
    case test
    case test2
}

let recorder = XRayRecorder()
//let recorder = XRayRecorder(emitter: XRayLogEmitter())

let context = XRayRecorder.TraceContext()

// begin and end (sub)segments explicitly
let segment = recorder.beginSegment(name: "Segment 1", context: context)
segment.setAnnotation(98101, forKey: "zip_code")
segment.setMetadata(["debug": ["test": "Metadata string"]])
_ = segment.beginSubsegment(name: "Subsegment 1.1 in progress")
usleep(100_000)
let subsegment = segment.beginSubsegment(name: "Subsegment 1.2 async")
usleep(100_000)
segment.addError(ExampleError.test)
segment.addError(ExampleError.test2)
segment.end()

// subsegment may end after parent
usleep(100_000)
subsegment.end()

// use closures for convenience
recorder.segment(name: "Segment 2", context: context) { segment in
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
