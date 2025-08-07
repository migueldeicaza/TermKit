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
 */
public class XtermCapability: TerminalCapability {
    public var providerDescription: String { "HardcodedXterm" }
    
    // Cursor movement
    public var cursorUp = "\u{1b}[A"
    public var cursorDown = "\u{1b}[B"
    public var cursorForward = "\u{1b}[C"
    public var cursorBackward = "\u{1b}[D"
    public var cursorPosition = "\u{1b}[%d;%dH"  // row;col
    public var cursorHome = "\u{1b}[H"
    public var saveCursorPosition = "\u{1b}7"
    public var restoreCursorPosition = "\u{1b}8"
    
    // Screen clearing
    public var clearScreen = "\u{1b}[2J"
    public var clearToEndOfScreen = "\u{1b}[J"
    public var clearToBeginningOfScreen = "\u{1b}[1J"
    public var clearLine = "\u{1b}[2K"
    public var clearToEndOfLine = "\u{1b}[K"
    public var clearToBeginningOfLine = "\u{1b}[1K"
    
    // Text attributes
    public var reset = "\u{1b}[0m"
    public var bold = "\u{1b}[1m"
    public var dim = "\u{1b}[2m"
    public var underline = "\u{1b}[4m"
    public var blink = "\u{1b}[5m"
    public var reverse = "\u{1b}[7m"
    public var hidden = "\u{1b}[8m"
    public var strikethrough = "\u{1b}[9m"
    
    // Turn off specific attributes
    public var noBold = "\u{1b}[22m"
    public var noUnderline = "\u{1b}[24m"
    public var noBlink = "\u{1b}[25m"
    public var noReverse = "\u{1b}[27m"
    
    // Colors (3/4 bit)
    public var foregroundBlack = "\u{1b}[30m"
    public var foregroundRed = "\u{1b}[31m"
    public var foregroundGreen = "\u{1b}[32m"
    public var foregroundYellow = "\u{1b}[33m"
    public var foregroundBlue = "\u{1b}[34m"
    public var foregroundMagenta = "\u{1b}[35m"
    public var foregroundCyan = "\u{1b}[36m"
    public var foregroundWhite = "\u{1b}[37m"
    public var foregroundDefault = "\u{1b}[39m"
    
    public var backgroundBlack = "\u{1b}[40m"
    public var backgroundRed = "\u{1b}[41m"
    public var backgroundGreen = "\u{1b}[42m"
    public var backgroundYellow = "\u{1b}[43m"
    public var backgroundBlue = "\u{1b}[44m"
    public var backgroundMagenta = "\u{1b}[45m"
    public var backgroundCyan = "\u{1b}[46m"
    public var backgroundWhite = "\u{1b}[47m"
    public var backgroundDefault = "\u{1b}[49m"
    
    // Bright colors
    public var foregroundBrightBlack = "\u{1b}[90m"
    public var foregroundBrightRed = "\u{1b}[91m"
    public var foregroundBrightGreen = "\u{1b}[92m"
    public var foregroundBrightYellow = "\u{1b}[93m"
    public var foregroundBrightBlue = "\u{1b}[94m"
    public var foregroundBrightMagenta = "\u{1b}[95m"
    public var foregroundBrightCyan = "\u{1b}[96m"
    public var foregroundBrightWhite = "\u{1b}[97m"
    
    // RGB color support
    /// Returns ANSI escape for true‑color foreground (24‑bit).
    public func foregroundRGB(_ r: Int, _ g: Int, _ b: Int) -> String {
        return "\u{1b}[38;2;\(r);\(g);\(b)m"
    }
    /// Returns ANSI escape for true‑color background (24‑bit).
    public func backgroundRGB(_ r: Int, _ g: Int, _ b: Int) -> String {
        return "\u{1b}[48;2;\(r);\(g);\(b)m"
    }

    public var backgroundBrightBlack = "\u{1b}[100m"
    public var backgroundBrightRed = "\u{1b}[101m"
    public var backgroundBrightGreen = "\u{1b}[102m"
    public var backgroundBrightYellow = "\u{1b}[103m"
    public var backgroundBrightBlue = "\u{1b}[104m"
    public var backgroundBrightMagenta = "\u{1b}[105m"
    public var backgroundBrightCyan = "\u{1b}[106m"
    public var backgroundBrightWhite = "\u{1b}[107m"
    
    // Terminal modes
    public var alternateScreenBuffer = "\u{1b}[?1049h"
    public var normalScreenBuffer = "\u{1b}[?1049l"
    public var hideCursor = "\u{1b}[?25l"
    public var showCursor = "\u{1b}[?25h"
    public var enableLineWrap = "\u{1b}[?7h"
    public var disableLineWrap = "\u{1b}[?7l"
    
    // Mouse tracking
    public var enableMouseTracking = "\u{1b}[?1000h"
    public var disableMouseTracking = "\u{1b}[?1000l"
    public var enableMouseMotionTracking = "\u{1b}[?1003h"
    public var disableMouseMotionTracking = "\u{1b}[?1003l"
    public var enableSGRMouse = "\u{1b}[?1006h"
    public var disableSGRMouse = "\u{1b}[?1006l"
    
    // Special keys input sequences (for recognition)
    public var keyUp = "\u{1b}[A"
    public var keyDown = "\u{1b}[B"
    public var keyRight = "\u{1b}[C"
    public var keyLeft = "\u{1b}[D"
    public var keyHome = "\u{1b}[H"
    public var keyEnd = "\u{1b}[F"
    public var keyPageUp = "\u{1b}[5~"
    public var keyPageDown = "\u{1b}[6~"
    public var keyInsert = "\u{1b}[2~"
    public var keyDelete = "\u{1b}[3~"
    public var keyF1 = "\u{1b}OP"
    public var keyF2 = "\u{1b}OQ"
    public var keyF3 = "\u{1b}OR"
    public var keyF4 = "\u{1b}OS"
    public var keyF5 = "\u{1b}[15~"
    public var keyF6 = "\u{1b}[17~"
    public var keyF7 = "\u{1b}[18~"
    public var keyF8 = "\u{1b}[19~"
    public var keyF9 = "\u{1b}[20~"
    public var keyF10 = "\u{1b}[21~"
    
    // Terminal query/response
    public var queryTerminalSize = "\u{1b}[18t"
    public var queryCursorPosition = "\u{1b}[6n"
    
    public init() {}
}
