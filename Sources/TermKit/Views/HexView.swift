//
//  HexView.swift - A hexadecimal viewer
//  TermKit
//
//  Ported from Terminal.Gui C# implementation
//

import Foundation

public class HexView: View {
    private static let defaultAddressWidth = 8
    private static let numBytesPerHexColumn = 4
    private static let hexColumnWidth = numBytesPerHexColumn * 3 + 2
    
    private var _firstNibble = true
    private var _leftSideHasFocus = true
    private static let spaceChar = Character(" ")
    private static let periodChar = Character("·")
    private static let columnSeparator = Character("│")
    
    private var _source: Data?
    private var _address: Int64 = 0
    private var _addressWidth = defaultAddressWidth
    private var _bytesPerLine = 0
    private var _edits: [Int64: UInt8] = [:]
    private var _firstLineAddress: Int64 = 0
    
    public var isReadOnly = false
    
    public var source: Data? {
        get { _source }
        set {
            guard let newValue = newValue else { return }
            discardEdits()
            _source = newValue
            setBytesPerLine()
            _firstLineAddress = 0
            
            if _address > Int64(newValue.count) {
                _address = 0
            }
            clampViewportToBounds()
            
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    public var bytesPerLine: Int {
        get { _bytesPerLine }
        set {
            _bytesPerLine = newValue
            positionChanged?()
        }
    }
    
    public var address: Int64 {
        get { _address }
        set {
            if _address == newValue { return }
            
            let newAddress = max(0, min(newValue, getEditedSize()))
            let offsetToNewCursor = getCursor(for: newAddress)
            
            _address = newAddress
            
            scrollToMakeCursorVisible(offsetToNewCursor)
            positionChanged?()
        }
    }
    
    public var addressWidth: Int {
        get { _addressWidth }
        set {
            if _addressWidth == newValue { return }
            _addressWidth = newValue
            setNeedsDisplay()
            setNeedsLayout()
        }
    }
    
    public var edits: [Int64: UInt8] { _edits }
    
    public var edited: ((Int64, UInt8) -> Void)?
    public var positionChanged: (() -> Void)?
    
    public override init(frame: Rect) {
        super.init(frame: frame)
        setupView()
    }
    
    public override init() {
        super.init()
        setupView()
    }
    
    public convenience init(source: Data?) {
        self.init()
        self.source = source
    }
    
    private func setupView() {
        canFocus = true
        _leftSideHasFocus = true
        _firstNibble = true
    }
    
    public func getPosition(for address: Int64) -> Point {
        guard _source != nil, bytesPerLine > 0 else { return Point.zero }
        
        let line = Int((address - _firstLineAddress) / Int64(bytesPerLine))
        let item = Int(address % Int64(bytesPerLine))
        
        return Point(x: item, y: line)
    }
    
    public func getCursor(for address: Int64) -> Point {
        var position = getPosition(for: address)
        
        if _leftSideHasFocus {
            let block = position.x / HexView.numBytesPerHexColumn
            let column = position.x % HexView.numBytesPerHexColumn
            
            position.x = block * HexView.hexColumnWidth + column * 3 + (_firstNibble ? 0 : 1)
        } else {
            position.x += bytesPerLine / HexView.numBytesPerHexColumn * HexView.hexColumnWidth - 1
        }
        
        position.x += getLeftSideStartColumn()
        
        return position
    }
    
    private func scrollToMakeCursorVisible(_ offsetToNewCursor: Point) {
        let visibleRows = max(0, contentFrame.height)
        if visibleRows <= 0 || bytesPerLine <= 0 { return }

        // Current line index of the address
        let lineIndex = Int(_address / Int64(bytesPerLine))

        var targetTopLineIndex: Int? = nil
        if offsetToNewCursor.y < 0 {
            targetTopLineIndex = lineIndex
        } else if offsetToNewCursor.y >= visibleRows {
            targetTopLineIndex = max(0, lineIndex - (visibleRows - 1))
        }

        if let top = targetTopLineIndex {
            let maxTop = maxTopLineIndex()
            let clampedTop = min(max(0, top), maxTop)
            _firstLineAddress = Int64(clampedTop * bytesPerLine)
            setNeedsDisplay()
        }
    }
    
    public override func positionCursor() {
        let position = getCursor(for: address)
        
        if hasFocus && position.x >= 0 && position.x < frame.width && position.y >= 0 && position.y < frame.height {
            moveTo(col: position.x, row: position.y)
        }
    }
    
    private func getEditedSize() -> Int64 {
        guard let source = _source else { return 0 }
        
        if _edits.isEmpty {
            return Int64(source.count)
        }
        
        let maxEditAddress = _edits.keys.max() ?? 0
        return max(Int64(source.count), maxEditAddress + 1)
    }
    
    public func applyEdits(to stream: inout Data?) {
        guard let source = _source else { return }
        
        var mutableSource = source
        for (offset, value) in _edits {
            if offset < mutableSource.count {
                mutableSource[Int(offset)] = value
            }
        }
        _source = mutableSource
        
        if stream != nil {
            stream = mutableSource
        }
        
        _edits.removeAll()
        setNeedsDisplay()
    }
    
    public func discardEdits() {
        _edits.removeAll()
    }
    
    private func getLeftSideStartColumn() -> Int {
        return addressWidth == 0 ? 0 : addressWidth + 1
    }
    
    private func setBytesPerLine() {
        bytesPerLine = HexView.numBytesPerHexColumn
        
        let availableWidth = frame.width - getLeftSideStartColumn()
        if availableWidth >= HexView.hexColumnWidth {
            bytesPerLine = max(
                HexView.numBytesPerHexColumn,
                HexView.numBytesPerHexColumn * (availableWidth / (HexView.hexColumnWidth + HexView.numBytesPerHexColumn))
            )
        }
    }
    
    public override func drawContent(in region: Rect, painter p: Painter) {
        guard let source = _source else { return }
        
        let addressOfFirstLine = _firstLineAddress
        let nBlocks = bytesPerLine / HexView.numBytesPerHexColumn
        
        let editingAttribute = colorScheme.normal
        let selectedAttribute = colorScheme.focus
        let editedAttribute = colorScheme.hotNormal
        let addressAttribute = hasFocus ? colorScheme.hotNormal : colorScheme.normal
        
        let h = contentFrame.height
        for line in 0..<h {
            p.goto(col: 0, row: line)
            let addressOfLine = addressOfFirstLine + Int64(line * bytesPerLine)
            
            if addressOfLine <= getEditedSize() {
                p.attribute = addressAttribute
            } else {
                p.attribute = colorScheme.normal // TODO: .disabled
            }
            
            let addressStr = String(format: "%0\(addressWidth)llx", addressOfLine)
            p.add(str: addressStr)
            
            p.attribute = editingAttribute
            
            if addressWidth > 0 {
                p.add(str: " ")
            }
            
            for block in 0..<nBlocks {
                for b in 0..<HexView.numBytesPerHexColumn {
                    let offset = line * bytesPerLine + block * HexView.numBytesPerHexColumn + b
                    let globalOffset = addressOfFirstLine + Int64(offset)
                    
                    let (value, edited) = getData(at: globalOffset)
                    
                    if globalOffset == address {
                        p.attribute = _leftSideHasFocus ? editingAttribute : (edited ? editedAttribute : selectedAttribute)
                    } else {
                        p.attribute = edited ? editedAttribute : editingAttribute
                    }
                    
                    if globalOffset < Int64(source.count) || edited {
                        p.add(str: String(format: "%02x", value))
                    } else {
                        p.add(str: "  ")
                    }
                    
                    p.attribute = editingAttribute
                    p.add(ch: HexView.spaceChar)
                }
                
                p.add(str: block + 1 == nBlocks ? " " : "\(HexView.columnSeparator) ")
            }
            
            for byteIndex in 0..<bytesPerLine {
                let globalOffset = addressOfFirstLine + Int64(line * bytesPerLine + byteIndex)
                let (value, edited) = getData(at: globalOffset)
                
                let ch: Character
                if globalOffset >= Int64(source.count) && !edited {
                    ch = HexView.spaceChar
                } else {
                    ch = (value >= 32 && value < 127) ? Character(UnicodeScalar(value)) : HexView.periodChar
                }
                
                if globalOffset == address {
                    p.attribute = _leftSideHasFocus ? editingAttribute : (edited ? editedAttribute : selectedAttribute)
                } else {
                    p.attribute = edited ? editedAttribute : editingAttribute
                }
                
                p.add(ch: ch)
            }
            
            p.attribute = editingAttribute
            
            for _ in (getLeftSideStartColumn() + nBlocks * HexView.hexColumnWidth + bytesPerLine)..<frame.width {
                p.add(ch: " ")
            }
        }
    }
    
    private func getData(at offset: Int64) -> (value: UInt8, edited: Bool) {
        if let editedValue = _edits[offset] {
            return (editedValue, true)
        }
        
        guard let source = _source, offset >= 0, offset < source.count else {
            return (0, false)
        }
        
        return (source[Int(offset)], false)
    }
    
    public override func processKey(event: KeyEvent) -> Bool {
        if isReadOnly || _source == nil {
            return super.processKey(event: event)
        }
        
        switch event.key {
        case .controlB, .cursorLeft:
            return moveLeft()
        case .controlF, .cursorRight:
            return moveRight()
        case .cursorDown:
            return moveDown(bytesPerLine)
        case .cursorUp:
            return moveUp(bytesPerLine)
        case .pageUp:
            return moveUp(bytesPerLine * contentFrame.height)
        case .pageDown:
            return moveDown(bytesPerLine * contentFrame.height)
        case .home:
            return moveHome()
        case .end:
            return moveEnd()
        case .tab:
            _leftSideHasFocus = !_leftSideHasFocus
            _firstNibble = true
            setNeedsDisplay()
            return true
        default:
            if _leftSideHasFocus {
                return handleHexInput(event)
            } else {
                return handleAsciiInput(event)
            }
        }
    }
    
    private func handleHexInput(_ event: KeyEvent) -> Bool {
        guard case let Key.letter(ch) = event.key else { return false }
        
        let value: Int
        if let ascii = ch.asciiValue {
            if ch >= "0" && ch <= "9" {
                value = Int(ascii - (Character("0").asciiValue ?? 48))
            } else if ch >= "A" && ch <= "F" {
                value = Int(ascii - (Character("A").asciiValue ?? 65) + 10)
            } else if ch >= "a" && ch <= "f" {
                value = Int(ascii - (Character("a").asciiValue ?? 97) + 10)
            } else {
                return false
            }
        } else {
            return false
        }
        
        var b = getData(at: address).value
        
        if _firstNibble {
            _firstNibble = false
            b = UInt8((Int(b) & 0x0F) | (value << 4))
            _edits[address] = b
            edited?(address, b)
        } else {
            b = UInt8((Int(b) & 0xF0) | value)
            _edits[address] = b
            edited?(address, b)
            _ = moveRight()
        }
        
        setNeedsDisplay()
        return true
    }
    
    private func handleAsciiInput(_ event: KeyEvent) -> Bool {
        guard case  let Key.letter(ch) = event.key,
              let scalar = ch.unicodeScalars.first,
              scalar.value < 256 else { return false }
        
        _edits[address] = UInt8(scalar.value)
        edited?(address, UInt8(scalar.value))
        _ = moveRight()
        setNeedsDisplay()
        return true
    }
    
    private func moveLeft() -> Bool {
        if _leftSideHasFocus {
            if !_firstNibble {
                _firstNibble = true
                return true
            }
            _firstNibble = false
        }
        
        if address == 0 {
            return true
        }
        
        address -= 1
        return true
    }
    
    private func moveRight() -> Bool {
        if _leftSideHasFocus {
            if _firstNibble {
                _firstNibble = false
                return true
            }
            _firstNibble = true
        }
        
        if address < getEditedSize() {
            address += 1
        }
        
        return true
    }
    
    private func moveDown(_ bytes: Int) -> Bool {
        if address + Int64(bytes) < getEditedSize() {
            address += Int64(bytes)
        } else {
            var p = address
            while p + Int64(bytesPerLine) <= getEditedSize() {
                p += Int64(bytesPerLine)
            }
            address = p
        }
        return true
    }
    
    private func moveUp(_ bytes: Int) -> Bool {
        address -= Int64(bytes)
        return true
    }
    
    private func moveHome() -> Bool {
        address = 0
        return true
    }
    
    private func moveEnd() -> Bool {
        address = getEditedSize()
        return true
    }
    
    public override func layoutSubviews() throws {
        try super.layoutSubviews()
        setBytesPerLine()
        clampViewportToBounds()
    }

    private func maxTopLineIndex() -> Int {
        let visibleRows = max(1, contentFrame.height)
        if bytesPerLine <= 0 { return 0 }
        let totalLines = Int(max(0, (getEditedSize() + Int64(bytesPerLine) - 1) / Int64(bytesPerLine)))
        return max(0, totalLines - visibleRows)
    }

    private func clampViewportToBounds() {
        if bytesPerLine <= 0 { return }
        let topLineIndex = Int(max(0, _firstLineAddress) / Int64(bytesPerLine))
        let clampedTop = min(max(0, topLineIndex), maxTopLineIndex())
        _firstLineAddress = Int64(clampedTop * bytesPerLine)
    }
}
