//
//  WindowsDriver.swift
//  TermKit
//
//  Windows console driver implementation that uses Windows Console API
//  to provide terminal functionality on Windows platforms.
//

import Foundation

#if os(Windows)
import WinSDK

/**
 * Windows console driver that uses the Windows Console API to control the terminal.
 * This driver provides Windows-specific terminal functionality using Win32 Console APIs.
 */
class WindowsDriver: ConsoleDriver {
    private var hStdOut: HANDLE = INVALID_HANDLE_VALUE
    private var hStdIn: HANDLE = INVALID_HANDLE_VALUE
    private var originalConsoleMode: DWORD = 0
    private var originalInputMode: DWORD = 0
    private var currentAttribute: Attribute = Attribute(0)
    private var currentWinAttribute: WORD = FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE
    
    // Screen buffer for optimized updates
    private var screenBuffer: [[Cell]] = []
    private var cursorRow: Int = 0
    private var cursorCol: Int = 0
    
    struct Cell: Equatable {
        var ch: Character
        var attr: Attribute
        
        init(ch: Character = " ", attr: Attribute = Attribute(0)) {
            self.ch = ch
            self.attr = attr
        }
    }
    
    override init() {
        super.init()
        initializeConsole()
    }
    
    override var driverName: String {
        "Windows"
    }
    
    private func initializeConsole() {
        // Get handles to stdin and stdout
        hStdOut = GetStdHandle(STD_OUTPUT_HANDLE)
        hStdIn = GetStdHandle(STD_INPUT_HANDLE)
        
        guard hStdOut != INVALID_HANDLE_VALUE && hStdIn != INVALID_HANDLE_VALUE else {
            return
        }
        
        // Save original console modes
        GetConsoleMode(hStdOut, &originalConsoleMode)
        GetConsoleMode(hStdIn, &originalInputMode)
        
        // Enable virtual terminal processing for ANSI escape sequences
        let outputMode = originalConsoleMode | ENABLE_VIRTUAL_TERMINAL_PROCESSING | DISABLE_NEWLINE_AUTO_RETURN
        SetConsoleMode(hStdOut, outputMode)
        
        // Configure input mode for enhanced input
        let inputMode = originalInputMode | ENABLE_WINDOW_INPUT | ENABLE_MOUSE_INPUT | ENABLE_EXTENDED_FLAGS
        SetConsoleMode(hStdIn, inputMode & ~ENABLE_QUICK_EDIT_MODE & ~ENABLE_ECHO_INPUT & ~ENABLE_LINE_INPUT)
        
        // Get console screen buffer info for size
        updateScreenSize()
        initializeScreenBuffer()
    }
    
    private func updateScreenSize() {
        var csbi: CONSOLE_SCREEN_BUFFER_INFO = CONSOLE_SCREEN_BUFFER_INFO()
        if GetConsoleScreenBufferInfo(hStdOut, &csbi) {
            let width = Int(csbi.srWindow.Right - csbi.srWindow.Left + 1)
            let height = Int(csbi.srWindow.Bottom - csbi.srWindow.Top + 1)
            size = Size(width: width, height: height)
        }
    }
    
    private func initializeScreenBuffer() {
        screenBuffer = Array(repeating: Array(repeating: Cell(), count: size.width), count: size.height)
    }
    
    // MARK: - Color Support
    
    public override func colorSupport() -> ColorSupport {
        return .sixteenColors
    }
    
    private func colorToWinColor(_ color: Color, foreground: Bool) -> WORD {
        let base: WORD = foreground ? 0 : 0x10
        
        switch color {
        case .black:
            return base
        case .blue:
            return base | FOREGROUND_BLUE
        case .green:
            return base | FOREGROUND_GREEN
        case .cyan:
            return base | FOREGROUND_BLUE | FOREGROUND_GREEN
        case .red:
            return base | FOREGROUND_RED
        case .magenta:
            return base | FOREGROUND_RED | FOREGROUND_BLUE
        case .brown:
            return base | FOREGROUND_RED | FOREGROUND_GREEN
        case .gray:
            return base | FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE
        case .darkGray:
            return base | FOREGROUND_INTENSITY
        case .brightBlue:
            return base | FOREGROUND_BLUE | FOREGROUND_INTENSITY
        case .brightGreen:
            return base | FOREGROUND_GREEN | FOREGROUND_INTENSITY
        case .brightCyan:
            return base | FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_INTENSITY
        case .brightRed:
            return base | FOREGROUND_RED | FOREGROUND_INTENSITY
        case .brightMagenta:
            return base | FOREGROUND_RED | FOREGROUND_BLUE | FOREGROUND_INTENSITY
        case .brightYellow:
            return base | FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY
        case .white:
            return base | FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY
        case .rgb(_, _, _):
            // Fallback to white for RGB colors in 16-color mode
            return base | FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY
        }
    }
    
    public override func makeAttribute(fore: Color, back: Color, flags: CellFlags) -> Attribute {
        let foreColor = colorToWinColor(fore, foreground: true)
        let backColor = colorToWinColor(back, foreground: false) << 4
        var winAttr = foreColor | backColor
        
        // Apply cell flags
        if flags.contains(.bold) {
            winAttr |= FOREGROUND_INTENSITY
        }
        if flags.contains(.underline) {
            winAttr |= COMMON_LVB_UNDERSCORE
        }
        if flags.contains(.standout) || flags.contains(.invert) {
            winAttr |= COMMON_LVB_REVERSE_VIDEO
        }
        
        return Attribute(Int32(winAttr), foreground: fore, background: back, flags: flags)
    }
    
    // MARK: - Attribute Management
    
    override func change(_ attribute: Attribute, foreground: Color) -> Attribute {
        guard let back = attribute.back else { return attribute }
        return makeAttribute(fore: foreground, back: back, flags: attribute.flags)
    }
    
    override func change(_ attribute: Attribute, background: Color) -> Attribute {
        guard let fore = attribute.fore else { return attribute }
        return makeAttribute(fore: fore, back: background, flags: attribute.flags)
    }
    
    override func change(_ attribute: Attribute, flags: CellFlags) -> Attribute {
        guard let fore = attribute.fore, let back = attribute.back else { return attribute }
        return makeAttribute(fore: fore, back: back, flags: flags)
    }
    
    public override func setAttribute(_ attr: Attribute) {
        currentAttribute = attr
        currentWinAttribute = WORD(attr.value)
        SetConsoleTextAttribute(hStdOut, currentWinAttribute)
    }
    
    // MARK: - Cursor Movement
    
    public override func moveTo(col: Int, row: Int) {
        cursorCol = max(0, min(col, size.width - 1))
        cursorRow = max(0, min(row, size.height - 1))
        
        let coord = COORD(X: SHORT(cursorCol), Y: SHORT(cursorRow))
        SetConsoleCursorPosition(hStdOut, coord)
    }
    
    public override func updateCursor() {
        let coord = COORD(X: SHORT(cursorCol), Y: SHORT(cursorRow))
        SetConsoleCursorPosition(hStdOut, coord)
    }
    
    // MARK: - Text Output
    
    public override func addRune(_ rune: rune) {
        addCharacter(Character(rune))
    }
    
    public override func addCharacter(_ char: Character) {
        if cursorRow >= 0 && cursorRow < size.height && cursorCol >= 0 && cursorCol < size.width {
            screenBuffer[cursorRow][cursorCol] = Cell(ch: char, attr: currentAttribute)
        }
        
        // Write character to console
        let string = String(char)
        var written: DWORD = 0
        WriteConsoleW(hStdOut, string, DWORD(string.utf16.count), &written, nil)
        
        cursorCol += 1
        if cursorCol >= size.width {
            cursorCol = 0
            cursorRow += 1
        }
    }
    
    // MARK: - Screen Updates
    
    public override func updateScreen() {
        // Force a complete redraw by clearing and rewriting
        clearScreen()
        redrawScreen()
    }
    
    public override func refresh() {
        // Optimized refresh - only update changed cells
        var csbi: CONSOLE_SCREEN_BUFFER_INFO = CONSOLE_SCREEN_BUFFER_INFO()
        GetConsoleScreenBufferInfo(hStdOut, &csbi)
        
        for row in 0..<size.height {
            for col in 0..<size.width {
                let cell = screenBuffer[row][col]
                let coord = COORD(X: SHORT(col), Y: SHORT(row))
                SetConsoleCursorPosition(hStdOut, coord)
                setAttribute(cell.attr)
                
                let string = String(cell.ch)
                var written: DWORD = 0
                WriteConsoleW(hStdOut, string, DWORD(string.utf16.count), &written, nil)
            }
        }
        
        updateCursor()
    }
    
    private func clearScreen() {
        let coord = COORD(X: 0, Y: 0)
        var written: DWORD = 0
        let screenSize = DWORD(size.width * size.height)
        
        FillConsoleOutputCharacterW(hStdOut, 32, screenSize, coord, &written) // 32 is space character
        FillConsoleOutputAttribute(hStdOut, currentWinAttribute, screenSize, coord, &written)
        SetConsoleCursorPosition(hStdOut, coord)
    }
    
    private func redrawScreen() {
        for row in 0..<size.height {
            for col in 0..<size.width {
                let cell = screenBuffer[row][col]
                let coord = COORD(X: SHORT(col), Y: SHORT(row))
                SetConsoleCursorPosition(hStdOut, coord)
                setAttribute(cell.attr)
                
                let string = String(cell.ch)
                var written: DWORD = 0
                WriteConsoleW(hStdOut, string, DWORD(string.utf16.count), &written, nil)
            }
        }
    }
    
    // MARK: - Cleanup
    
    public override func end() {
        // Restore original console modes
        if hStdOut != INVALID_HANDLE_VALUE {
            SetConsoleMode(hStdOut, originalConsoleMode)
        }
        if hStdIn != INVALID_HANDLE_VALUE {
            SetConsoleMode(hStdIn, originalInputMode)
        }
        
        // Reset text attributes
        SetConsoleTextAttribute(hStdOut, FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE)
    }
}

#else
// Stub implementation for non-Windows platforms
class WindowsDriver: ConsoleDriver {
    override var driverName: String {
        "Windows (Unavailable)"
    }
    
    override init() {
        super.init()
        fatalError("WindowsDriver is only available on Windows platforms")
    }
}
#endif