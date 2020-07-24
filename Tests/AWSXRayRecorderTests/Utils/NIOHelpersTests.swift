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

import NIO
import XCTest

@testable import AWSXRayRecorder

final class NIOHelpersTests: XCTestCase {
    func testSocketAddressParsingPositive() {
        let validEndpoints = [
            ("127.0.0.1:2000", "127.0.0.1", 2000),
            ("192.168.0.1:4000", "192.168.0.1", 4000),
        ]
        for (endpoint, ipAddress, port) in validEndpoints {
            let address = try! SocketAddress(string: endpoint)
            XCTAssertNotNil(address)
            XCTAssertEqual(ipAddress, address.ipAddress)
            XCTAssertEqual(port, address.port)
        }
    }

    func testSocketAddressParsingInvalidIpAddress() {
        let invalidIp = [
            "300.0.0.1:2000",
            "168.0.1:4000",
        ]
        for endpoint in invalidIp {
            let segments = endpoint.split(separator: ":")
            let ipAddress = String(segments[0])
            XCTAssertThrowsError(try SocketAddress(string: endpoint)) { error in
                if case SocketAddressError.failedToParseIPString(let invalidValue) = error {
                    XCTAssertEqual(invalidValue, ipAddress)
                } else {
                    XCTFail()
                }
            }
        }
    }

    func testSocketAddressParsingNoPort() {
        let noPort = [
            "127.0.0.1",
            "168.0.1",
        ]
        for endpoint in noPort {
            XCTAssertThrowsError(try SocketAddress(string: endpoint)) { error in
                if case SocketAddressExtError.invalidEndpoint(let invalidValue) = error {
                    XCTAssertEqual(invalidValue, endpoint)
                } else {
                    XCTFail()
                }
            }
        }
    }

    func testSocketAddressParsingInvalidPort() {
        let invalidPort = [
            "127.0.0.1:a",
        ]
        for endpoint in invalidPort {
            let segments = endpoint.split(separator: ":")
            let port = String(segments[1])
            XCTAssertThrowsError(try SocketAddress(string: endpoint)) { error in
                if case SocketAddressExtError.invalidPort(let invalidValue) = error {
                    XCTAssertEqual(invalidValue, port)
                } else {
                    XCTFail()
                }
            }
        }
    }
}
