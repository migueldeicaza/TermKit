import XCTest

// Workaround for crash in SwiftLinux
#if !canImport(ObjectiveC) && !os(Linux)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(TermKitTests.allTests),
    ]
}
#endif
