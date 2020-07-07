import XCTest

@testable import AWSXRayRecorder

final class RandomTests: XCTestCase {
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
