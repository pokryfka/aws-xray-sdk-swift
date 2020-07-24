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

import AWSXRayRecorder
import NIO // usleep

enum ExampleError: Error {
    case test
    case test2
    case test3
}

let recorder = XRayRecorder()

// begin and end (sub)segments explicitly
let segment = recorder.beginSegment(name: "Segment 1")
segment.setAnnotation(98101, forKey: "zip_code")
segment.setMetadata(["debug": ["test": "Metadata string"]])
_ = segment.beginSubsegment(name: "Subsegment 1.1 in progress")
usleep(100_000)
let subsegment = segment.beginSubsegment(name: "Subsegment 1.2 async")
usleep(100_000)
segment.setError(ExampleError.test)
segment.setError(ExampleError.test2)
segment.setError(ExampleError.test3)
segment.end()

// subsegment may end after parent
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
