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

final class RandomTests: XCTestCase {
    func testRandom32() {
        // the value should be in hexadecimal digits
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        let numTests = 1000
        var values = Set<String>()
        for _ in 0 ..< numTests {
            let value = String.random32()
            XCTAssertEqual(8, value.count)
            XCTAssertNil(value.rangeOfCharacter(from: invalidCharacters))
            values.insert(value)
        }
        // check that the generated values are different
        XCTAssertEqual(numTests, values.count)
    }

    func testRandom64() {
        // the value should be in hexadecimal digits
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        let numTests = 1000
        var values = Set<String>()
        for _ in 0 ..< numTests {
            let value = String.random64()
            XCTAssertEqual(16, value.count)
            XCTAssertNil(value.rangeOfCharacter(from: invalidCharacters))
            values.insert(value)
        }
        // check that the generated values are different
        XCTAssertEqual(numTests, values.count)
    }

    func testRandom96() {
        // the value should be in hexadecimal digits
        let invalidCharacters = CharacterSet(charactersIn: "abcdef0123456789").inverted
        let numTests = 1000
        var values = Set<String>()
        for _ in 0 ..< numTests {
            let value = String.random96()
            XCTAssertEqual(24, value.count)
            XCTAssertNil(value.rangeOfCharacter(from: invalidCharacters))
            values.insert(value)
        }
        // check that the generated values are different
        XCTAssertEqual(numTests, values.count)
    }
}
