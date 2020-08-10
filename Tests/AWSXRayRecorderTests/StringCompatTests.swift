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

import XCTest

@testable import AWSXRayRecorder

final class StringCompatTests: XCTestCase {
    func testNegative() {
        XCTAssertFalse("1234abcdQXYZ".contains(""))
        XCTAssertFalse("1234abcdQXYZ".contains("12345"))
        XCTAssertFalse("1234abcdQXYZ".contains("2345"))
        XCTAssertFalse("1234abcdQXYZ".contains("BCD"))
        XCTAssertFalse("1234abcdQXYZ".contains("xyz"))
        XCTAssertFalse("1234abcdQXYZ".contains("1234abcdQXYZ1234abcdQXYZ"))
    }

    func testPositive() {
        XCTAssertTrue("1234abcdQXYZ".contains("123"))
        XCTAssertTrue("1234abcdQXYZ".contains("bcd"))
        XCTAssertTrue("1234abcdQXYZ".contains("XYZ"))
        XCTAssertTrue("1234abcdQXYZ".contains("dQX"))
        XCTAssertTrue("1234abcdQXYZcde0".contains("cde"))
        XCTAssertTrue("1234abcdQXYZcde0cde0".contains("cde"))
        XCTAssertTrue("1234abcdQXYZcde0cde0".contains("c"))
        XCTAssertTrue("".contains(""))
    }
}
