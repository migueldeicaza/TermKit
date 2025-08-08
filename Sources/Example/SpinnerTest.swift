//
//  SpinnerTest.swift
//  TermKit
//
//  A simple test for the Spinner functionality
//

import Foundation
import TermKit

func testSpinner() {
    print("Testing Spinner creation and basic functionality...")
    
    // Test creation with different definitions
    let lineSpinner = Spinner(definition: Spinner.line)
    let dotSpinner = Spinner(definition: Spinner.dot) 
    let miniDotSpinner = Spinner(definition: Spinner.miniDot)
    
    // Test that they have the correct properties
    assert(lineSpinner.definition.frames.count == 4, "Line spinner should have 4 frames")
    assert(dotSpinner.definition.frames.count == 8, "Dot spinner should have 8 frames")
    assert(miniDotSpinner.definition.frames.count == 10, "Mini dot spinner should have 10 frames")
    
    // Test frame rates
    assert(abs(lineSpinner.definition.frameRate - 0.1) < 0.001, "Line spinner frame rate should be 0.1")
    assert(abs(dotSpinner.definition.frameRate - 0.1) < 0.001, "Dot spinner frame rate should be 0.1")
    assert(abs(miniDotSpinner.definition.frameRate - 1.0/12.0) < 0.001, "Mini dot spinner frame rate should be 1/12")
    
    // Test animation state
    assert(!lineSpinner.isAnimating, "Spinner should not be animating initially")
    
    // Test starting/stopping
    lineSpinner.start()
    assert(lineSpinner.isAnimating, "Spinner should be animating after start()")
    
    lineSpinner.stop()
    assert(!lineSpinner.isAnimating, "Spinner should not be animating after stop()")
    
    print("✅ All Spinner tests passed!")
}