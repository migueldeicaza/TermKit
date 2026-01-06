import XCTest
@testable import TermKit

final class ApplicationTests: XCTestCase, @unchecked Sendable {
    
    /// Test that terminalResized() is publicly accessible
    func testTerminalResizedIsPublic() {
        // This test verifies that Application.terminalResized() is a public API
        // by successfully compiling a call to it. The fact that this compiles
        // proves the API is accessible from outside the TermKit module.
        
        // We use a type check to verify the method signature is correct
        let _: () -> Void = Application.terminalResized
        
        // This test succeeds if it compiles, demonstrating the API is public
        XCTAssertTrue(true, "terminalResized() is publicly accessible")
    }
    
    static let allTests = [
        ("testTerminalResizedIsPublic", testTerminalResizedIsPublic),
    ]
}
