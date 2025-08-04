//
//  TerminalCapability.swift
//  TermKit
//
//  Created by TermKit on 2025-08-04.
//

import Foundation

/**
 * Protocol defining terminal escape sequences and capabilities.
 * Different terminal types can implement this protocol to provide
 * their specific escape sequences and capabilities.
 */
public protocol TerminalCapability {
    /// Human readable description of this terminal capability driver
    var providerDescription: String { get }
    
    // Cursor movement
    var cursorUp: String { get }
    var cursorDown: String { get }
    var cursorForward: String { get }
    var cursorBackward: String { get }
    var cursorPosition: String { get }  // Format string for row;col
    var cursorHome: String { get }
    var saveCursorPosition: String { get }
    var restoreCursorPosition: String { get }
    
    // Screen clearing
    var clearScreen: String { get }
    var clearToEndOfScreen: String { get }
    var clearToBeginningOfScreen: String { get }
    var clearLine: String { get }
    var clearToEndOfLine: String { get }
    var clearToBeginningOfLine: String { get }
    
    // Text attributes
    var reset: String { get }
    var bold: String { get }
    var dim: String { get }
    var underline: String { get }
    var blink: String { get }
    var reverse: String { get }
    var hidden: String { get }
    var strikethrough: String { get }
    
    // Turn off specific attributes
    var noBold: String { get }
    var noUnderline: String { get }
    var noBlink: String { get }
    var noReverse: String { get }
    
    // Colors (3/4 bit)
    var foregroundBlack: String { get }
    var foregroundRed: String { get }
    var foregroundGreen: String { get }
    var foregroundYellow: String { get }
    var foregroundBlue: String { get }
    var foregroundMagenta: String { get }
    var foregroundCyan: String { get }
    var foregroundWhite: String { get }
    var foregroundDefault: String { get }
    
    var backgroundBlack: String { get }
    var backgroundRed: String { get }
    var backgroundGreen: String { get }
    var backgroundYellow: String { get }
    var backgroundBlue: String { get }
    var backgroundMagenta: String { get }
    var backgroundCyan: String { get }
    var backgroundWhite: String { get }
    var backgroundDefault: String { get }
    
    // Bright colors
    var foregroundBrightBlack: String { get }
    var foregroundBrightRed: String { get }
    var foregroundBrightGreen: String { get }
    var foregroundBrightYellow: String { get }
    var foregroundBrightBlue: String { get }
    var foregroundBrightMagenta: String { get }
    var foregroundBrightCyan: String { get }
    var foregroundBrightWhite: String { get }
    
    var backgroundBrightBlack: String { get }
    var backgroundBrightRed: String { get }
    var backgroundBrightGreen: String { get }
    var backgroundBrightYellow: String { get }
    var backgroundBrightBlue: String { get }
    var backgroundBrightMagenta: String { get }
    var backgroundBrightCyan: String { get }
    var backgroundBrightWhite: String { get }
    
    // Terminal modes
    var alternateScreenBuffer: String { get }
    var normalScreenBuffer: String { get }
    var hideCursor: String { get }
    var showCursor: String { get }
    var enableLineWrap: String { get }
    var disableLineWrap: String { get }
    
    // Mouse tracking
    var enableMouseTracking: String { get }
    var disableMouseTracking: String { get }
    var enableMouseMotionTracking: String { get }
    var disableMouseMotionTracking: String { get }
    var enableSGRMouse: String { get }
    var disableSGRMouse: String { get }
    
    // Special keys input sequences (for recognition)
    var keyUp: String { get }
    var keyDown: String { get }
    var keyRight: String { get }
    var keyLeft: String { get }
    var keyHome: String { get }
    var keyEnd: String { get }
    var keyPageUp: String { get }
    var keyPageDown: String { get }
    var keyInsert: String { get }
    var keyDelete: String { get }
    var keyF1: String { get }
    var keyF2: String { get }
    var keyF3: String { get }
    var keyF4: String { get }
    var keyF5: String { get }
    var keyF6: String { get }
    var keyF7: String { get }
    var keyF8: String { get }
    var keyF9: String { get }
    var keyF10: String { get }
    
    // Terminal query/response
    var queryTerminalSize: String { get }
    var queryCursorPosition: String { get }
}
