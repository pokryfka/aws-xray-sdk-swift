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

// source: https://github.com/Flight-School/AnyCodable

import AWSXRayRecorder
import XCTest

class AnyDecodableTests: XCTestCase {
    func testJSONDecoding() throws {
        let json = """
        {
            "boolean": true,
            "integer": 1,
            "double": 3.141592653589793,
            "string": "string",
            "array": [1, 2, 3],
            "nested": {
                "a": "alpha",
                "b": "bravo",
                "c": "charlie"
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let dictionary = try decoder.decode([String: AnyDecodable].self, from: json)

        XCTAssertEqual(dictionary["boolean"]?.value as! Bool, true)
        XCTAssertEqual(dictionary["integer"]?.value as! Int, 1)
        XCTAssertEqual(dictionary["double"]?.value as! Double, 3.141592653589793, accuracy: 0.001)
        XCTAssertEqual(dictionary["string"]?.value as! String, "string")
        XCTAssertEqual(dictionary["array"]?.value as! [Int], [1, 2, 3])
        XCTAssertEqual(dictionary["nested"]?.value as! [String: String], ["a": "alpha", "b": "bravo", "c": "charlie"])
    }

//    static var allTests = [
//        ("testJSONDecoding", testJSONDecoding),
//    ]
}
