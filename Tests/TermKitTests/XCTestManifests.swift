import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
#if !os(Linux)
    return [
        testCase(TermKitTests.allTests)
    ]
#else 
    return []
#endif    
}
#endif
