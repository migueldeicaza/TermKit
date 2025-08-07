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
class TerminfoTests: XCTestCase {
    
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
}