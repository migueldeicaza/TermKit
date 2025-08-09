import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
    #if !os(Linux)
        testCase(TermKitTests.allTests),
#endif
]
}
#endif
