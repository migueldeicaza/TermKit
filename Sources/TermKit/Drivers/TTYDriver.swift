//
//  TTYDriver.swift
//  TermKit
//
//  A black and white driver for debugging that outputs plain text without escape sequences.
//

import Foundation
import Darwin

/**
 * TTY driver for debugging purposes that outputs plain text without any escape sequences.
 * This driver only supports black and white output and is intended for debugging to see
 * the raw character output without terminal formatting.
 */
class TTYDriver: ConsoleDriver {
    private var screenBuffer: [[Cell]] = []
    private var cursorRow: Int = 0
    private var cursorCol: Int = 0
    private var currentAttribute: Attribute = Attribute(0)
    
    struct Cell: Equatable {
        let ch: Character
        let attr: Attribute
        
        init(ch: Character = " ", attr: Attribute = Attribute(0)) {
            self.ch = ch
            self.attr = attr
        }
    }
    
    // Input handling (copied from UnixDriver)
    private var inputBuffer = Data()
    private let inputQueue = DispatchQueue(label: "termkit.ttydriver.input")
    
    enum InputEvent {
        case key(KeyEvent)
        case mouse(MouseEvent)
    }
    
    override init() {
        super.init()
        setlocale(LC_ALL, "")

        self.colorSupport = .blackAndWhite
        
        // Set a default size for debugging
        size = Size(width: 80, height: 24)
        initializeScreenBuffer()
        
        // Setup input handling
        setupInput()
    }
    
    override var driverName: String {
        "TTY"
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
    
    private func setupOutput() {
        initializeScreenBuffer()
    }
    
    private func initializeScreenBuffer() {
        let rows = Int(size.height)
        let cols = Int(size.width)
        
        screenBuffer = Array(repeating: Array(repeating: Cell(), count: cols), count: rows)
    }
    
    override func moveTo(col: Int, row: Int) {
        cursorCol = max(0, min(col, Int(size.width) - 1))
        cursorRow = max(0, min(row, Int(size.height) - 1))
    }
    
    override func addRune(_ rune: rune) {
        addCharacter(Character(rune))
    }
    
    override func addCharacter(_ char: Character) {
        guard cursorRow < screenBuffer.count && cursorCol < screenBuffer[cursorRow].count else {
            return
        }
        
        screenBuffer[cursorRow][cursorCol] = Cell(ch: char, attr: currentAttribute)
        cursorCol += 1
        
        // Wrap to next line if we exceed the width
        if cursorCol >= Int(size.width) {
            cursorCol = 0
            cursorRow += 1
        }
    }
    
    override func setAttribute(_ attr: Attribute) {
        currentAttribute = attr
    }
    
    override func makeAttribute(fore: Color, back: Color, flags: CellFlags = []) -> Attribute {
        // Return a simple attribute - colors are ignored in TTY mode
        return Attribute(0, foreground: fore, background: back, flags: flags)
    }
    
    override func updateScreen() {
        // Nothing to do - refresh() handles the output
    }
    
    override func refresh() {
        // Dump the screen buffer contents with escape sequences for inverted text
        for row in screenBuffer {
            var line = ""
            var isInverted = false
            
            for cell in row {
                let shouldBeInverted = cell.attr.flags.contains(.invert)
                
                // Toggle invert mode if needed
                if shouldBeInverted != isInverted {
                    if shouldBeInverted {
                        line += "\u{1B}[7m" // ANSI escape for reverse video
                    } else {
                        line += "\u{1B}[27m" // ANSI escape to turn off reverse video
                    }
                    isInverted = shouldBeInverted
                }
                
                line += String(cell.ch)
            }
            
            // Reset attributes at end of line if needed
            if isInverted {
                line += "\u{1B}[27m"
            }
            
            // Remove trailing whitespace
            line = line.trimmingCharacters(in: .whitespacesAndNewlines)
            print(line)
        }
    }
    
    override func updateCursor() {
        // TTY driver doesn't need cursor updates
    }
    
    override func end() {
        // Cleanup input handler
        FileHandle.standardInput.readabilityHandler = nil
    }
    
    // MARK: - Input Processing (copied from UnixDriver)
    
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
}
