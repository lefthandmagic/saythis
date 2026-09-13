import XCTest
@testable import SayThis

final class ArpabetTests: XCTestCase {
    func testChablis() {
        let result = Arpabet.transcribe("SH AH0 B L IY1")
        XCTAssertEqual(result?.ipa, "/ʃəˈbli/")
        XCTAssertEqual(result?.respell, "shuh-BLEE")
    }

    func testHello() {
        let result = Arpabet.transcribe("HH AH0 L OW1")
        XCTAssertEqual(result?.ipa, "/həˈloʊ/")
        XCTAssertEqual(result?.respell, "huh-LOH")
    }
}
