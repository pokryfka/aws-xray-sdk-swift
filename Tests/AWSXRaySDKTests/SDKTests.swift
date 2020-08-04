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

import Logging
import NIO
import XCTest

import AWSXRaySDK

final class SDKTests: XCTestCase {
    func testInitWithSharedGroup() {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        let recorder = XRayRecorder(eventLoopGroupProvider: .shared(eventLoopGroup))
        recorder.shutdown()
    }

    func testInitWithNewGroup() {
        let recorder = XRayRecorder(eventLoopGroupProvider: .createNew)
        recorder.shutdown()
    }
}
