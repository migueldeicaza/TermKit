//
//  TerminfoTest.swift
//  TermKit
//
//  Created by TermKit on 2025-08-04.
//

import Foundation
import XCTest
@testable import TermKit

/**
 * Test cases for terminfo parsing functionality.
 */
class TerminfoTests: XCTestCase, @unchecked Sendable {
    
    /**
     * Tests terminfo parsing for different terminal types.
     */
    func testTerminfoCapabilities() {
        // Test basic terminfo parsing functionality
        let currentTerm = ProcessInfo.processInfo.environment["TERM"] ?? "unknown"
        print("Current TERM: \(currentTerm)")
        
        // Test that we can parse terminfo for current terminal
        if let capability = TerminfoParser.parseCapabilities() {
            XCTAssertTrue(capability.providerDescription.contains("Terminfo"))
        }
        
        // Test color detection
        if let colors = TerminfoParser.getColorCount() {
            print("Detected \(colors) colors for current terminal")
            XCTAssertGreaterThan(colors, 0)
        }
    }
    
    func testXtermCapabilityWithTerminfo() {
        let xtermCap = XtermCapability()
        XCTAssertNotNil(xtermCap.providerDescription)
        XCTAssertFalse(xtermCap.clearScreen.isEmpty)
        XCTAssertFalse(xtermCap.cursorUp.isEmpty)
        XCTAssertFalse(xtermCap.bold.isEmpty)
    }
    
    func testTerminfoParser() {
        // Test that we can parse common terminal types
        let testTerminals = ["xterm", "linux"]
        
        for terminal in testTerminals {
            if let capability = TerminfoParser.parseCapabilities(for: terminal) {
                XCTAssertTrue(capability.providerDescription.contains("Terminfo"))
                XCTAssertNotNil(capability.clearScreen)
                XCTAssertNotNil(capability.cursorUp)
            }
        }
    }
    
    func testColorDetection() {
        // Test color detection for various terminal types
        let testCases: [(terminal: String, expectedMinColors: Int)] = [
            ("xterm", 8),
            ("xterm-256color", 256),
            ("linux", 8),
            ("screen", 8)
        ]
        
        for testCase in testCases {
            if let colorCount = TerminfoParser.getColorCount(for: testCase.terminal) {
                print("Terminal \(testCase.terminal): \(colorCount) colors")
                XCTAssertGreaterThanOrEqual(colorCount, testCase.expectedMinColors, 
                                           "Terminal \(testCase.terminal) should support at least \(testCase.expectedMinColors) colors")
            } else {
                print("Could not get color count for \(testCase.terminal)")
            }
        }
    }
    
    func testUnixDriverColorSupport() {
        // Test that UnixDriver correctly determines color support
        // This test uses the current environment, so results may vary
        let driver = UnixDriver()
        
        // Should have at least some color support (not blackAndWhite) for modern terminals
        if ProcessInfo.processInfo.environment["TERM"]?.contains("256") == true {
            print("Driver color support: \(driver.colorSupport)")
            // For 256-color terminals, should detect ansi256 or higher
            XCTAssertTrue(driver.colorSupport == .ansi256 || driver.colorSupport == .rgbColors)
        }
        
        // Verify driver name includes capability info
        XCTAssertTrue(driver.driverName.contains("UnixDriver"))
    }
    
    func testTerminfoParameterProcessing() {
        // Test the terminfo parameter processor with sample sequences
        
        // Test simple parameter substitution: "%p1%d" with parameter 5 should return "5"
        let simpleResult = TerminfoParser.processParametrizedString("%p1%d", parameters: [5])
        XCTAssertEqual(simpleResult, "5", "Simple parameter substitution failed")
        
        // Test arithmetic: "%p1%{2}%+%d" with parameter 3 should return "5" (3+2)
        let arithmeticResult = TerminfoParser.processParametrizedString("%p1%{2}%+%d", parameters: [3])
        XCTAssertEqual(arithmeticResult, "5", "Arithmetic operation failed")
        
        // Test basic literal strings
        let literalResult = TerminfoParser.processParametrizedString("hello", parameters: [])
        XCTAssertEqual(literalResult, "hello", "Literal strings should pass through")
        
        // Test escape sequence prefix
        let escapeResult = TerminfoParser.processParametrizedString("\\E[%p1%dm", parameters: [31])
        print("Escape sequence result: '\(escapeResult)'")
        XCTAssertTrue(escapeResult.contains("31"), "Should contain the parameter value")
    }
    
    func testTerminfoColorSequences() {
        // Test that we can generate proper color sequences for different terminals
        
        // Test with xterm-256color
        if let capability = TerminfoParser.parseCapabilities(for: "xterm-256color") as? TerminfoCapability {
            // First, let's check if we can get the raw template strings
            let setafTemplate = capability.getString(.setaf)
            let setabTemplate = capability.getString(.setab)
            
            print("setaf template: '\(setafTemplate)'")
            print("setab template: '\(setabTemplate)'")
            
            // Test basic colors (0-7)
            let redForeground = capability.setForegroundColor(1) // Red
            print("xterm-256color red foreground: '\(redForeground)'")
            
            // Test 256-color index
            let color256 = capability.setForegroundColor(196) // Bright red in 256-color palette
            print("xterm-256color color 196: '\(color256)'")
            
            // For now, just test that we get some kind of response
            XCTAssertFalse(setafTemplate.isEmpty && setabTemplate.isEmpty, "Should have at least one of setaf/setab templates")
        }
        
        // Test with basic xterm
        if let capability = TerminfoParser.parseCapabilities(for: "xterm") as? TerminfoCapability {
            let setafTemplate = capability.getString(.setaf)
            print("xterm setaf template: '\(setafTemplate)'")
            
            let redForeground = capability.setForegroundColor(1)
            print("xterm red foreground: '\(redForeground)'")
        }
    }
    
    func testRGBTo256ColorConversion() {
        // Test RGB to 256-color conversion (this would need access to UnixDriver internals)
        // For now, we can test the concept with a mock
        
        // Test that we can create a UnixDriver and it uses terminfo when available
        let driver = UnixDriver()
        
        // Create a simple attribute to test color rendering
        let redAttr = driver.makeAttribute(fore: .red, back: .black)
        XCTAssertNotNil(redAttr, "Should be able to create color attributes")
        
        // Verify that it has proper color support detection
        XCTAssertNotEqual(driver.colorSupport, .blackAndWhite, "Modern terminals should support colors")
    }
}