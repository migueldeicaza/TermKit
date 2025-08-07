//
//  UnixDriver.swift
//  TermKit
//
//  Created by TermKit on 2025-08-04.
//

import Foundation
import Darwin

/**
 * Unix terminal driver that directly controls the terminal without using curses.
 * This driver uses ANSI escape sequences to control the terminal.
 */
class UnixDriver: ConsoleDriver {
    private var originalTermios: termios = termios()
    private var rawTermios: termios = termios()
    private let capabilities: TerminalCapability
    private var currentAttribute: Attribute = Attribute(0)
    private var colorPairs: [Int: (fore: Color, back: Color)] = [:]
    private var nextColorPair: Int = 1
    
    // Input handling
    private var inputBuffer = Data()
    private let inputQueue = DispatchQueue(label: "termkit.unixdriver.input")
    
    // Screen buffer for optimized updates
    private var screenBuffer: [[Cell]] = []
    private var cursorRow: Int = 0
    private var cursorCol: Int = 0
    
    struct Cell: Equatable {
        static func == (lhs: UnixDriver.Cell, rhs: UnixDriver.Cell) -> Bool {
            lhs.ch == rhs.ch && lhs.attr == rhs.attr
        }
        
        var ch: Character
        var attr: Attribute
        
        init(ch: Character = " ", attr: Attribute = Attribute(0)) {
            self.ch = ch
            self.attr = attr
        }
    }
    
    init(capabilities: TerminalCapability = XtermCapability()) {
        self.capabilities = capabilities
        super.init()
        setlocale(LC_CTYPE, "")
        // Get terminal size
        var ws = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 {
            size = Size(width: Int(ws.ws_col), height: Int(ws.ws_row))
        } else {
            // Default size if ioctl fails
            size = Size(width: 80, height: 24)
        }
        
        // Initialize screen buffer
        initializeScreenBuffer()
        
        // Save original terminal settings
        tcgetattr(STDIN_FILENO, &originalTermios)
        
        // Setup raw mode
        rawTermios = originalTermios
        cfmakeraw(&rawTermios)
        
        // Keep some useful flags
        rawTermios.c_iflag |= UInt(ICRNL) // Convert CR to NL
        rawTermios.c_oflag |= UInt(OPOST) // Enable output processing
        
        // Apply raw mode
        tcsetattr(STDIN_FILENO, TCSANOW, &rawTermios)
        
        // Setup terminal
        print(capabilities.alternateScreenBuffer, terminator: "")
        print(capabilities.clearScreen, terminator: "")
        print(capabilities.cursorHome, terminator: "")
        print(capabilities.enableSGRMouse, terminator: "")
        print(capabilities.enableMouseMotionTracking, terminator: "")
        fflush(stdout)
        
        // Setup input handling
        setupInput()
        
        // Setup signal handling for terminal resize
        setupSignalHandlers()
        
        if let value = ProcessInfo.processInfo.environment["COLORTERM"] {
            if value == "truecolor" || value == "24bit" {
                colorSupport = .rgbColors
            }
        } else {
            // Use terminfo to detect color capabilities
            if let colorCount = TerminfoParser.getColorCount() {
                switch colorCount {
                case 0...1:
                    colorSupport = .blackAndWhite
                case 2...16:
                    colorSupport = .ansi16
                case 17...256:
                    colorSupport = .ansi256
                default:
                    // For terminals claiming more than 256 colors, assume RGB support
                    colorSupport = .rgbColors
                }
            } else {
                // Fallback to TERM environment variable parsing
                if let term = ProcessInfo.processInfo.environment["TERM"] {
                    if term.range(of: "-256") != nil {
                        colorSupport = .ansi256
                    } else if term.hasPrefix("xterm") {
                        colorSupport = .ansi16
                    } else {
                        colorSupport = .blackAndWhite
                    }
                } else {
                    colorSupport = .blackAndWhite
                }
            }
        }
        
        // Initialize color schemes
        selectColors()
    }
    
    open override var driverName: String {
        "UnixDriver/\(capabilities.providerDescription)"
    }

    private func initializeScreenBuffer() {
        screenBuffer = Array(repeating: Array(repeating: Cell(), count: size.width), count: size.height)
    }
    
    private func setupInput() {
        FileHandle.standardInput.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                self?.inputQueue.async {
                    self?.processInputData(data)
                }
            }
        }
    }
    
    private func setupSignalHandlers() {
        signal(SIGWINCH) { _ in
            DispatchQueue.main.async {
                Application.terminalResized()
            }
        }
    }
    
    private func processInputData(_ data: Data) {
        inputBuffer.append(data)
        
        while !inputBuffer.isEmpty {
            if let event = parseInputEvent() {
                DispatchQueue.main.async {
                    switch event {
                    case .key(let keyEvent):
                        Application.processKeyEvent(event: keyEvent)
                    case .mouse(let mouseEvent):
                        Application.processMouseEvent(mouseEvent: mouseEvent)
                    }
                }
            } else {
                break
            }
        }
    }
    
    enum InputEvent {
        case key(KeyEvent)
        case mouse(MouseEvent)
    }
    
    private func parseInputEvent() -> InputEvent? {
        guard let firstByte = inputBuffer.first else {
            return nil
        }
        
        // ESC sequence
        if firstByte == 0x1b {
            return parseEscapeSequence()
        }
        
        // Control characters
        if firstByte < 32 {
            inputBuffer.removeFirst()
            return .key(KeyEvent(key: controlCharToKey(firstByte)))
        }
        
        // Regular character
        inputBuffer.removeFirst()
        let scalar = Unicode.Scalar(firstByte)
        if let ch = Character(String(scalar)) as Character? {
            return .key(KeyEvent(key: .letter(ch)))
        }
        
        return nil
    }
    
    private func parseEscapeSequence() -> InputEvent? {
        guard inputBuffer.count >= 2 else { return nil }
        
        // Check for mouse event
        if inputBuffer.count >= 3 && inputBuffer[inputBuffer.startIndex+1] == 0x5b && inputBuffer[inputBuffer.startIndex+2] == 0x3c {
            return parseSGRMouseEvent()
        }
        
        // Check for special keys
        if let key = parseSpecialKey() {
            return .key(KeyEvent(key: key))
        }
        
        // Alt+key combination
        if inputBuffer.count >= 2 {
            let secondByte = inputBuffer[inputBuffer.startIndex+1]
            inputBuffer.removeFirst(2)
            
            let scalar = Unicode.Scalar(secondByte)
            
            if  let ch = Character(String(scalar)) as Character? {
                return .key(KeyEvent(key: .letter(ch), isAlt: true))
            }
        }
        
        return nil
    }
    
    private func parseSGRMouseEvent() -> InputEvent? {
        // SGR mouse format: ESC[<button;x;y;M or m
        guard let endIndex = inputBuffer.firstIndex(where: { $0 == 0x4d || $0 == 0x6d }) else {
            return nil
        }
        
        let sequenceData = inputBuffer[inputBuffer.startIndex+3..<endIndex]
        guard let sequence = String(data: sequenceData, encoding: .utf8) else {
            inputBuffer.removeFirst(endIndex + 1)
            return nil
        }
        
        let parts = sequence.split(separator: ";")
        guard parts.count == 3,
              let button = Int(parts[0]),
              let x = Int(parts[1]),
              let y = Int(parts[2]) else {
            inputBuffer.removeFirst(endIndex + 1)
            return nil
        }
        
        let isRelease = inputBuffer[endIndex] == 0x6d // 'm' for release
        inputBuffer.removeFirst(endIndex-inputBuffer.startIndex + 1)
        
        var flags = MouseFlags()
        
        // Check if this is a motion event (bit 5 set)
        if button & 32 != 0 {
            // Mouse motion with or without button pressed
            flags = .mousePosition
            
            // Add button state for drag operations
            switch button & 3 {
            case 0:
                flags.insert(.button1Pressed)
            case 1:
                flags.insert(.button2Pressed)
            case 2:
                flags.insert(.button3Pressed)
            default:
                break
            }
        } else {
            // Regular button press/release
            switch button & 3 {
            case 0:
                if isRelease {
                    flags = .button1Released
                    // Generate button1Clicked on release
                    DispatchQueue.main.async {
                        let clickEvent = MouseEvent(x: x - 1, y: y - 1, flags: .button1Clicked)
                        Application.processMouseEvent(mouseEvent: clickEvent)
                    }
                } else {
                    flags = .button1Pressed
                }
            case 1:
                flags = isRelease ? .button2Released : .button2Pressed
            case 2:
                flags = isRelease ? .button3Released : .button3Pressed
            default:
                break
            }
        }
        
        return .mouse(MouseEvent(x: x - 1, y: y - 1, flags: flags))
    }
    
    private func parseSpecialKey() -> Key? {
        let sequences: [(Data, Key)] = [
            (Data([0x1b, 0x5b, 0x41]), .cursorUp),
            (Data([0x1b, 0x5b, 0x42]), .cursorDown),
            (Data([0x1b, 0x5b, 0x43]), .cursorRight),
            (Data([0x1b, 0x5b, 0x44]), .cursorLeft),
            (Data([0x1b, 0x5b, 0x48]), .home),
            (Data([0x1b, 0x5b, 0x46]), .end),
            (Data([0x1b, 0x5b, 0x35, 0x7e]), .pageUp),
            (Data([0x1b, 0x5b, 0x36, 0x7e]), .pageDown),
            (Data([0x1b, 0x5b, 0x32, 0x7e]), .insertChar),
            (Data([0x1b, 0x5b, 0x33, 0x7e]), .deleteChar),
            (Data([0x1b, 0x4f, 0x50]), .f1),
            (Data([0x1b, 0x4f, 0x51]), .f2),
            (Data([0x1b, 0x4f, 0x52]), .f3),
            (Data([0x1b, 0x4f, 0x53]), .f4),
            (Data([0x1b, 0x5b, 0x31, 0x35, 0x7e]), .f5),
            (Data([0x1b, 0x5b, 0x31, 0x37, 0x7e]), .f6),
            (Data([0x1b, 0x5b, 0x31, 0x38, 0x7e]), .f7),
            (Data([0x1b, 0x5b, 0x31, 0x39, 0x7e]), .f8),
            (Data([0x1b, 0x5b, 0x32, 0x30, 0x7e]), .f9),
            (Data([0x1b, 0x5b, 0x32, 0x31, 0x7e]), .f10),
        ]
        
        for (sequence, key) in sequences {
            if inputBuffer.starts(with: sequence) {
                inputBuffer.removeFirst(sequence.count)
                return key
            }
        }
        
        // Just ESC key
        if inputBuffer.count == 1 {
            inputBuffer.removeFirst()
            return .esc
        }
        
        return nil
    }
    
    private func controlCharToKey(_ byte: UInt8) -> Key {
        switch byte {
        case 0: return .controlSpace
        case 1: return .controlA
        case 2: return .controlB
        case 3: return .controlC
        case 4: return .controlD
        case 5: return .controlE
        case 6: return .controlF
        case 7: return .controlG
        case 8: return .controlH
        case 9: return .controlI
        case 10: return .controlJ
        case 11: return .controlK
        case 12: return .controlL
        case 13: return .controlM
        case 14: return .controlN
        case 15: return .controlO
        case 16: return .controlP
        case 17: return .controlQ
        case 18: return .controlR
        case 19: return .controlS
        case 20: return .controlT
        case 21: return .controlU
        case 22: return .controlV
        case 23: return .controlW
        case 24: return .controlX
        case 25: return .controlY
        case 26: return .controlZ
        case 27: return .esc
        case 127: return .delete
        default: return .Unknown
        }
    }
    
    // ConsoleDriver overrides
    
    public override func addRune(_ rune: rune) {
        if cursorCol < size.width && cursorRow < size.height {
            screenBuffer[cursorRow][cursorCol] = Cell(ch: rune == hLine ? "*" : Character(rune), attr: currentAttribute)
            cursorCol += 1
        }
    }
    
    public override func addCharacter(_ char: Character) {
        if cursorCol < size.width && cursorRow < size.height {
            screenBuffer[cursorRow][cursorCol] = Cell(ch: char, attr: currentAttribute)
            cursorCol += 1
        }
    }
    
    public override func moveTo(col: Int, row: Int) {
        cursorCol = col
        cursorRow = row
    }
    
    public override func setAttribute(_ attr: Attribute) {
        currentAttribute = attr
    }
    
    public override func makeAttribute(fore: Color, back: Color, flags: CellFlags = []) -> Attribute {
        let pairKey = nextColorPair
        colorPairs[pairKey] = (fore: fore, back: back)
        nextColorPair += 1
        return Attribute(Int32(pairKey), foreground: fore, background: back, flags: flags)
    }
    
    override func change(_ attribute: Attribute, foreground: Color) -> Attribute {
        return makeAttribute(fore: foreground, back: attribute.back ?? .black, flags: attribute.flags)
    }
    
    override func change(_ attribute: Attribute, background: Color) -> Attribute {
        return makeAttribute(fore: attribute.fore ?? .white, back: background, flags: attribute.flags)
    }
    
    override func change(_ attribute: Attribute, flags: CellFlags) -> Attribute {
        return makeAttribute(fore: attribute.fore ?? .white, back: attribute.back ?? .black, flags: flags)
    }

    public override func updateScreen() {
        refresh()
    }
    
    public override func refresh() {
        var output = ""
        
        // Hide cursor during update
        output += capabilities.hideCursor
        
        var lastAttr: Attribute?
        
        for row in 0..<size.height {
            output += String(format: capabilities.cursorPosition, row + 1, 1)
            
            for col in 0..<size.width {
                let cell = screenBuffer[row][col]
                
                // Only update attributes if they changed
                if lastAttr == nil || lastAttr!.value != cell.attr.value {
                    output += attributeToEscapeSequence(cell.attr)
                    lastAttr = cell.attr
                }
                
                output += String(cell.ch)
            }
        }
        
        // Restore cursor position
        output += String(format: capabilities.cursorPosition, cursorRow + 1, cursorCol + 1)
        output += capabilities.showCursor
        
        print(output, terminator: "")
        fflush(stdout)
    }
    
    private func attributeToEscapeSequence(_ attr: Attribute) -> String {
        var sequence = capabilities.reset
        
        // Apply text attributes
        if attr.flags.contains(.bold) {
            sequence += capabilities.bold
        }
        if attr.flags.contains(.dim) {
            sequence += capabilities.dim
        }
        if attr.flags.contains(.underline) {
            sequence += capabilities.underline
        }
        if attr.flags.contains(.blink) {
            sequence += capabilities.blink
        }
        if attr.flags.contains(.invert) {
            sequence += capabilities.reverse
        }
        
        // Apply colors
        if let colorPair = colorPairs[Int(attr.value)] {
            sequence += colorToForegroundSequence(colorPair.fore)
            sequence += colorToBackgroundSequence(colorPair.back)
        }
        
        return sequence
    }
    
    private func colorToForegroundSequence(_ color: Color) -> String {
        // Check if we can use terminfo parametrized sequences for better color support
        if let terminfoCapability = capabilities as? TerminfoCapability, colorSupport != .rgbColors {
            if let colorIndex = mapColorToIndex(color) {
                let sequence = terminfoCapability.setForegroundColor(colorIndex)
                if !sequence.isEmpty {
                    return sequence
                }
            }
        }
        
        // Fallback to hardcoded sequences
        switch color {
        case .black: return capabilities.foregroundBlack
        case .red: return capabilities.foregroundRed
        case .green: return capabilities.foregroundGreen
        case .cyan: return capabilities.foregroundCyan
        case .blue: return capabilities.foregroundBlue
        case .magenta: return capabilities.foregroundMagenta
        case .brown: return capabilities.foregroundYellow
        case .gray: return capabilities.foregroundWhite
        case .darkGray: return capabilities.foregroundBrightBlack
        case .brightRed: return capabilities.foregroundBrightRed
        case .brightGreen: return capabilities.foregroundBrightGreen
        case .brightCyan: return capabilities.foregroundBrightCyan
        case .brightBlue: return capabilities.foregroundBrightBlue
        case .brightMagenta: return capabilities.foregroundBrightMagenta
        case .brightYellow: return capabilities.foregroundBrightYellow
        case .white: return capabilities.foregroundBrightWhite
        case .rgb(let r, let g, let b): return capabilities.foregroundRGB(r, g, b)
        }
    }
    
    private func colorToBackgroundSequence(_ color: Color) -> String {
        // Check if we can use terminfo parametrized sequences for better color support
        if let terminfoCapability = capabilities as? TerminfoCapability, colorSupport != .rgbColors {
            if let colorIndex = mapColorToIndex(color) {
                let sequence = terminfoCapability.setBackgroundColor(colorIndex)
                if !sequence.isEmpty {
                    return sequence
                }
            }
        }
        
        // Fallback to hardcoded sequences
        switch color {
        case .black: return capabilities.backgroundBlack
        case .red: return capabilities.backgroundRed
        case .green: return capabilities.backgroundGreen
        case .cyan: return capabilities.backgroundCyan
        case .blue: return capabilities.backgroundBlue
        case .magenta: return capabilities.backgroundMagenta
        case .brown: return capabilities.backgroundYellow
        case .gray: return capabilities.backgroundWhite
        case .darkGray: return capabilities.backgroundBrightBlack
        case .brightRed: return capabilities.backgroundBrightRed
        case .brightGreen: return capabilities.backgroundBrightGreen
        case .brightCyan: return capabilities.backgroundBrightCyan
        case .brightBlue: return capabilities.backgroundBrightBlue
        case .brightMagenta: return capabilities.backgroundBrightMagenta
        case .brightYellow: return capabilities.backgroundBrightYellow
        case .white: return capabilities.backgroundBrightWhite
        case .rgb(let r, let g, let b): return capabilities.backgroundRGB(r, g, b)
        }
    }
    
    /**
     * Maps Color enum values to ANSI color indices for terminfo sequences.
     * This handles both 16-color and 256-color terminals.
     */
    private func mapColorToIndex(_ color: Color) -> Int? {
        switch color {
        // Standard ANSI colors (0-7)
        case .black: return 0
        case .red: return 1
        case .green: return 2
        case .brown: return 3  // Yellow
        case .blue: return 4
        case .magenta: return 5
        case .cyan: return 6
        case .gray: return 7   // White
        
        // Bright colors (8-15) for 16+ color terminals
        case .darkGray: return colorSupport == .blackAndWhite ? nil : 8
        case .brightRed: return colorSupport == .blackAndWhite ? nil : 9
        case .brightGreen: return colorSupport == .blackAndWhite ? nil : 10
        case .brightYellow: return colorSupport == .blackAndWhite ? nil : 11
        case .brightBlue: return colorSupport == .blackAndWhite ? nil : 12
        case .brightMagenta: return colorSupport == .blackAndWhite ? nil : 13
        case .brightCyan: return colorSupport == .blackAndWhite ? nil : 14
        case .white: return colorSupport == .blackAndWhite ? nil : 15
        
        // RGB colors - convert to 256-color index if supported
        case .rgb(let r, let g, let b):
            if colorSupport == .ansi256 {
                return rgbTo256ColorIndex(r: r, g: g, b: b)
            }
            return nil
        }
    }
    
    /**
     * Converts RGB values to the nearest 256-color palette index.
     * Uses the standard 256-color palette structure.
     */
    private func rgbTo256ColorIndex(r: Int, g: Int, b: Int) -> Int {
        // Clamp values to 0-255
        let r = max(0, min(255, r))
        let g = max(0, min(255, g))
        let b = max(0, min(255, b))
        
        // Check if it's a grayscale color
        if r == g && g == b {
            // Grayscale ramp (colors 232-255, 24 levels)
            if r < 8 {
                return 16  // Black from color cube
            } else if r > 247 {
                return 231 // White from color cube
            } else {
                return 232 + ((r - 8) * 23) / 239
            }
        }
        
        // Map to 6x6x6 color cube (colors 16-231)
        let rIndex = (r * 5) / 255
        let gIndex = (g * 5) / 255
        let bIndex = (b * 5) / 255
        
        return 16 + (36 * rIndex) + (6 * gIndex) + bIndex
    }
    
    public override func updateCursor() {
        print(String(format: capabilities.cursorPosition, cursorRow + 1, cursorCol + 1), terminator: "")
        fflush(stdout)
    }
    
    public override func suspend() -> Bool {
        // Restore terminal before suspending
        print(capabilities.disableMouseMotionTracking, terminator: "")
        print(capabilities.disableSGRMouse, terminator: "")
        fflush(stdout)
        
        // Send SIGTSTP to suspend
        kill(getpid(), SIGTSTP)
        
        // Re-enable mouse tracking after resume
        print(capabilities.enableSGRMouse, terminator: "")
        print(capabilities.enableMouseMotionTracking, terminator: "")
        fflush(stdout)
        
        return true
    }
    
    public override func end() {
        // Restore terminal settings
        print(capabilities.disableMouseMotionTracking, terminator: "")
        print(capabilities.disableSGRMouse, terminator: "")
        print(capabilities.normalScreenBuffer, terminator: "")
        print(capabilities.showCursor, terminator: "")
        fflush(stdout)
        
        // Restore original terminal mode
        tcsetattr(STDIN_FILENO, TCSANOW, &originalTermios)
        
        // Remove input handler
        FileHandle.standardInput.readabilityHandler = nil
    }
    
    private func selectColors() {
        let base = ColorScheme(normal:    makeAttribute(fore: .gray, back: .blue),
                               focus:     makeAttribute(fore: .black, back: .cyan),
                               hotNormal: makeAttribute(fore: .brightYellow, back: .blue),
                               hotFocus:  makeAttribute(fore: .brightYellow, back: .cyan))
        
        let menu = ColorScheme(normal:    makeAttribute(fore: .white, back: .cyan),
                               focus:     makeAttribute(fore: .white, back: .black),
                               hotNormal: makeAttribute(fore: .brightYellow, back: .cyan),
                               hotFocus:  makeAttribute(fore: .brightYellow, back: .black))

        let dialog = ColorScheme(normal:    makeAttribute(fore: .black, back: .gray),
                                 focus:     makeAttribute(fore: .black, back: .cyan),
                                 hotNormal: makeAttribute(fore: .blue, back: .gray),
                                 hotFocus:  makeAttribute(fore: .blue, back: .cyan))
        
        let error = ColorScheme(normal:   makeAttribute(fore: .white, back: .red),
                                focus:     makeAttribute(fore: .black, back: .white),
                                hotNormal: makeAttribute(fore: .brightYellow, back: .red),
                                hotFocus:  makeAttribute(fore: .brightYellow, back: .red))
     
        Colors._base = base
        Colors._menu = menu
        Colors._dialog = dialog
        Colors._error = error
    }
}
