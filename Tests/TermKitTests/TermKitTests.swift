import XCTest
@testable import TermKit

final class TermKitTests: XCTestCase, @unchecked Sendable {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        //XCTAssertEqual(TermKit().text, "Hello, World!")
    }
    
    func testTextFieldPlaceholder() {
        let textField = TextField("")
        
        // Test setting placeholder
        textField.placeholder = "Enter your name"
        XCTAssertEqual(textField.placeholder, "Enter your name")
        
        // Test placeholder when text is empty
        XCTAssertEqual(textField.text, "")
        XCTAssertEqual(textField.placeholder, "Enter your name")
        
        // Test that placeholder doesn't affect text content
        textField.text = "John"
        XCTAssertEqual(textField.text, "John")
        XCTAssertEqual(textField.placeholder, "Enter your name")
        
        // Test placeholder shows again when text is cleared
        textField.text = ""
        XCTAssertEqual(textField.text, "")
        XCTAssertEqual(textField.placeholder, "Enter your name")
    }

    static let allTests = [
        ("testExample", testExample),
        ("testTextFieldPlaceholder", testTextFieldPlaceholder),
    ]
}
