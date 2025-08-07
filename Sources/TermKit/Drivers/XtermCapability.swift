//
//  XtermCapability.swift
//  TermKit
//
//  Created by TermKit on 2025-08-04.
//

import Foundation

/**
 * Xterm terminal capability implementation.
 * Provides ANSI/VT100 escape sequences compatible with xterm and most modern terminals.
 * Attempts to parse terminfo when available, falls back to hardcoded sequences.
 */
public class XtermCapability: TerminalCapability {
    public let providerDescription: String
    private let terminfoCapability: TerminalCapability?
    
    // Cursor movement
    public var cursorUp: String { terminfoCapability?.cursorUp ?? "\u{1b}[A" }
    public var cursorDown: String { terminfoCapability?.cursorDown ?? "\u{1b}[B" }
    public var cursorForward: String { terminfoCapability?.cursorForward ?? "\u{1b}[C" }
    public var cursorBackward: String { terminfoCapability?.cursorBackward ?? "\u{1b}[D" }
    public var cursorPosition: String { terminfoCapability?.cursorPosition ?? "\u{1b}[%d;%dH" }  // row;col
    public var cursorHome: String { terminfoCapability?.cursorHome ?? "\u{1b}[H" }
    public var saveCursorPosition: String { terminfoCapability?.saveCursorPosition ?? "\u{1b}7" }
    public var restoreCursorPosition: String { terminfoCapability?.restoreCursorPosition ?? "\u{1b}8" }
    
    // Screen clearing
    public var clearScreen: String { terminfoCapability?.clearScreen ?? "\u{1b}[2J" }
    public var clearToEndOfScreen: String { terminfoCapability?.clearToEndOfScreen ?? "\u{1b}[J" }
    public var clearToBeginningOfScreen: String { terminfoCapability?.clearToBeginningOfScreen ?? "\u{1b}[1J" }
    public var clearLine: String { terminfoCapability?.clearLine ?? "\u{1b}[2K" }
    public var clearToEndOfLine: String { terminfoCapability?.clearToEndOfLine ?? "\u{1b}[K" }
    public var clearToBeginningOfLine: String { terminfoCapability?.clearToBeginningOfLine ?? "\u{1b}[1K" }
    
    // Text attributes
    public var reset: String { terminfoCapability?.reset ?? "\u{1b}[0m" }
    public var bold: String { terminfoCapability?.bold ?? "\u{1b}[1m" }
    public var dim: String { terminfoCapability?.dim ?? "\u{1b}[2m" }
    public var underline: String { terminfoCapability?.underline ?? "\u{1b}[4m" }
    public var blink: String { terminfoCapability?.blink ?? "\u{1b}[5m" }
    public var reverse: String { terminfoCapability?.reverse ?? "\u{1b}[7m" }
    public var hidden: String { terminfoCapability?.hidden ?? "\u{1b}[8m" }
    public var strikethrough: String { terminfoCapability?.strikethrough ?? "\u{1b}[9m" }
    
    // Turn off specific attributes
    public var noBold: String { terminfoCapability?.noBold ?? "\u{1b}[22m" }
    public var noUnderline: String { terminfoCapability?.noUnderline ?? "\u{1b}[24m" }
    public var noBlink: String { terminfoCapability?.noBlink ?? "\u{1b}[25m" }
    public var noReverse: String { terminfoCapability?.noReverse ?? "\u{1b}[27m" }
    
    // Colors (3/4 bit)
    public var foregroundBlack: String { terminfoCapability?.foregroundBlack ?? "\u{1b}[30m" }
    public var foregroundRed: String { terminfoCapability?.foregroundRed ?? "\u{1b}[31m" }
    public var foregroundGreen: String { terminfoCapability?.foregroundGreen ?? "\u{1b}[32m" }
    public var foregroundYellow: String { terminfoCapability?.foregroundYellow ?? "\u{1b}[33m" }
    public var foregroundBlue: String { terminfoCapability?.foregroundBlue ?? "\u{1b}[34m" }
    public var foregroundMagenta: String { terminfoCapability?.foregroundMagenta ?? "\u{1b}[35m" }
    public var foregroundCyan: String { terminfoCapability?.foregroundCyan ?? "\u{1b}[36m" }
    public var foregroundWhite: String { terminfoCapability?.foregroundWhite ?? "\u{1b}[37m" }
    public var foregroundDefault: String { terminfoCapability?.foregroundDefault ?? "\u{1b}[39m" }
    
    public var backgroundBlack: String { terminfoCapability?.backgroundBlack ?? "\u{1b}[40m" }
    public var backgroundRed: String { terminfoCapability?.backgroundRed ?? "\u{1b}[41m" }
    public var backgroundGreen: String { terminfoCapability?.backgroundGreen ?? "\u{1b}[42m" }
    public var backgroundYellow: String { terminfoCapability?.backgroundYellow ?? "\u{1b}[43m" }
    public var backgroundBlue: String { terminfoCapability?.backgroundBlue ?? "\u{1b}[44m" }
    public var backgroundMagenta: String { terminfoCapability?.backgroundMagenta ?? "\u{1b}[45m" }
    public var backgroundCyan: String { terminfoCapability?.backgroundCyan ?? "\u{1b}[46m" }
    public var backgroundWhite: String { terminfoCapability?.backgroundWhite ?? "\u{1b}[47m" }
    public var backgroundDefault: String { terminfoCapability?.backgroundDefault ?? "\u{1b}[49m" }
    
    // Bright colors
    public var foregroundBrightBlack: String { terminfoCapability?.foregroundBrightBlack ?? "\u{1b}[90m" }
    public var foregroundBrightRed: String { terminfoCapability?.foregroundBrightRed ?? "\u{1b}[91m" }
    public var foregroundBrightGreen: String { terminfoCapability?.foregroundBrightGreen ?? "\u{1b}[92m" }
    public var foregroundBrightYellow: String { terminfoCapability?.foregroundBrightYellow ?? "\u{1b}[93m" }
    public var foregroundBrightBlue: String { terminfoCapability?.foregroundBrightBlue ?? "\u{1b}[94m" }
    public var foregroundBrightMagenta: String { terminfoCapability?.foregroundBrightMagenta ?? "\u{1b}[95m" }
    public var foregroundBrightCyan: String { terminfoCapability?.foregroundBrightCyan ?? "\u{1b}[96m" }
    public var foregroundBrightWhite: String { terminfoCapability?.foregroundBrightWhite ?? "\u{1b}[97m" }
    
    // RGB color support
    /// Returns ANSI escape for true‑color foreground (24‑bit).
    public func foregroundRGB(_ r: Int, _ g: Int, _ b: Int) -> String {
        return terminfoCapability?.foregroundRGB(r, g, b) ?? "\u{1b}[38;2;\(r);\(g);\(b)m"
    }
    /// Returns ANSI escape for true‑color background (24‑bit).
    public func backgroundRGB(_ r: Int, _ g: Int, _ b: Int) -> String {
        return terminfoCapability?.backgroundRGB(r, g, b) ?? "\u{1b}[48;2;\(r);\(g);\(b)m"
    }

    public var backgroundBrightBlack: String { terminfoCapability?.backgroundBrightBlack ?? "\u{1b}[100m" }
    public var backgroundBrightRed: String { terminfoCapability?.backgroundBrightRed ?? "\u{1b}[101m" }
    public var backgroundBrightGreen: String { terminfoCapability?.backgroundBrightGreen ?? "\u{1b}[102m" }
    public var backgroundBrightYellow: String { terminfoCapability?.backgroundBrightYellow ?? "\u{1b}[103m" }
    public var backgroundBrightBlue: String { terminfoCapability?.backgroundBrightBlue ?? "\u{1b}[104m" }
    public var backgroundBrightMagenta: String { terminfoCapability?.backgroundBrightMagenta ?? "\u{1b}[105m" }
    public var backgroundBrightCyan: String { terminfoCapability?.backgroundBrightCyan ?? "\u{1b}[106m" }
    public var backgroundBrightWhite: String { terminfoCapability?.backgroundBrightWhite ?? "\u{1b}[107m" }
    
    // Terminal modes
    public var alternateScreenBuffer: String { terminfoCapability?.alternateScreenBuffer ?? "\u{1b}[?1049h" }
    public var normalScreenBuffer: String { terminfoCapability?.normalScreenBuffer ?? "\u{1b}[?1049l" }
    public var hideCursor: String { terminfoCapability?.hideCursor ?? "\u{1b}[?25l" }
    public var showCursor: String { terminfoCapability?.showCursor ?? "\u{1b}[?25h" }
    public var enableLineWrap: String { terminfoCapability?.enableLineWrap ?? "\u{1b}[?7h" }
    public var disableLineWrap: String { terminfoCapability?.disableLineWrap ?? "\u{1b}[?7l" }
    
    // Mouse tracking
    public var enableMouseTracking: String { terminfoCapability?.enableMouseTracking ?? "\u{1b}[?1000h" }
    public var disableMouseTracking: String { terminfoCapability?.disableMouseTracking ?? "\u{1b}[?1000l" }
    public var enableMouseMotionTracking: String { terminfoCapability?.enableMouseMotionTracking ?? "\u{1b}[?1003h" }
    public var disableMouseMotionTracking: String { terminfoCapability?.disableMouseMotionTracking ?? "\u{1b}[?1003l" }
    public var enableSGRMouse: String { terminfoCapability?.enableSGRMouse ?? "\u{1b}[?1006h" }
    public var disableSGRMouse: String { terminfoCapability?.disableSGRMouse ?? "\u{1b}[?1006l" }
    
    // Special keys input sequences (for recognition)
    public var keyUp: String { terminfoCapability?.keyUp ?? "\u{1b}[A" }
    public var keyDown: String { terminfoCapability?.keyDown ?? "\u{1b}[B" }
    public var keyRight: String { terminfoCapability?.keyRight ?? "\u{1b}[C" }
    public var keyLeft: String { terminfoCapability?.keyLeft ?? "\u{1b}[D" }
    public var keyHome: String { terminfoCapability?.keyHome ?? "\u{1b}[H" }
    public var keyEnd: String { terminfoCapability?.keyEnd ?? "\u{1b}[F" }
    public var keyPageUp: String { terminfoCapability?.keyPageUp ?? "\u{1b}[5~" }
    public var keyPageDown: String { terminfoCapability?.keyPageDown ?? "\u{1b}[6~" }
    public var keyInsert: String { terminfoCapability?.keyInsert ?? "\u{1b}[2~" }
    public var keyDelete: String { terminfoCapability?.keyDelete ?? "\u{1b}[3~" }
    public var keyF1: String { terminfoCapability?.keyF1 ?? "\u{1b}OP" }
    public var keyF2: String { terminfoCapability?.keyF2 ?? "\u{1b}OQ" }
    public var keyF3: String { terminfoCapability?.keyF3 ?? "\u{1b}OR" }
    public var keyF4: String { terminfoCapability?.keyF4 ?? "\u{1b}OS" }
    public var keyF5: String { terminfoCapability?.keyF5 ?? "\u{1b}[15~" }
    public var keyF6: String { terminfoCapability?.keyF6 ?? "\u{1b}[17~" }
    public var keyF7: String { terminfoCapability?.keyF7 ?? "\u{1b}[18~" }
    public var keyF8: String { terminfoCapability?.keyF8 ?? "\u{1b}[19~" }
    public var keyF9: String { terminfoCapability?.keyF9 ?? "\u{1b}[20~" }
    public var keyF10: String { terminfoCapability?.keyF10 ?? "\u{1b}[21~" }
    
    // Terminal query/response
    public var queryTerminalSize: String { terminfoCapability?.queryTerminalSize ?? "\u{1b}[18t" }
    public var queryCursorPosition: String { terminfoCapability?.queryCursorPosition ?? "\u{1b}[6n" }
    
    public init() {
        // Try to parse terminfo for current TERM, but only if it's NOT exactly "xterm" or "xterm-256color"
        let term = ProcessInfo.processInfo.environment["TERM"] ?? "xterm"
        
        if term != "xterm" && term != "xterm-256color" {
            self.terminfoCapability = TerminfoParser.parseCapabilities(for: term)
            self.providerDescription = "XtermWithTerminfo(\(term))"
        } else {
            self.terminfoCapability = nil
            self.providerDescription = "HardcodedXterm(\(term))"
        }
    }
}
