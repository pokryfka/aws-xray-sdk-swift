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

@testable import AWSXRayUDPEmitter

private typealias Config = XRayUDPEmitter.Config

final class EmitterTests: XCTestCase {
    func testLifecycleWithSharedGroup() {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        let emitter = try! XRayUDPEmitter(encoding: .test, eventLoopGroupProvider: .shared(eventLoopGroup))

        let exp = expectation(description: "hasShutdown")
        emitter.shutdown { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func testLifecycleWithNewGroup() {
        let emitter = try! XRayUDPEmitter(encoding: .test, eventLoopGroupProvider: .createNew)

        let exp = expectation(description: "hasShutdown")
        emitter.shutdown { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
}
