//
//  MarkupString.swift
//  
//
//  Created by Miguel de Icaza on 3/11/21.
//
// TODO:
// - Add an API to return the lenght of the string
// - Add an API to left, center, right, justify a line of text
//

import Foundation

// Temporary: just for testing the MarkupString
public class MarkupView: View {
    var s: AttributedString
    
    public init (_ txt: String){
        s = AttributedString(markup: txt)
        super.init ()
    }
    open override func drawContent(in region: Rect, painter p: Painter) {
        s.draw(on: p)
    }
}

/**
 * AttributedString offers a simple way to markup strings to annotate them
 * with terminal attributes and colors.
 *
 * A convenient `init (markup:)` method is provided to create these
 * easily using a simple markup system, inspired by the Spectre.Console
 * markup, which is in turn inspired by BBCode.  Unlike BBCode,
 * does not use the word on the closing tag, it merely auto-closes.
 *
 */
public class AttributedString: CustomDebugStringConvertible {
    typealias AttrCell = (ch: Character,styleRequest: [StyleRequest])
    enum StyleRequest {
        case bold
        case standout
        case dim
        case underline
        case blink
        case invert
        case foreground(color: Color)
        case background(color: Color)
        
        // Colors from the ColorScheme
        case normal
        case focus
        case hotNormal
        case hotFocus
        
        // Colors derived from ColorScheme + focus state
        case base
        case hotBase
        
        // Future
        //case foregroundRgb(red: UInt8, green: UInt8, blue: UInt8)
        //case backgroundRgb(red: UInt8, green: UInt8, blue: UInt8)
    }
    
    var expanded: [AttrCell] = []
    
    init (cells: [AttrCell])
    {
        self.expanded = cells
    }
    
    func extractTag (_ array: [Character], start: inout Int) -> String {
        var res: [Character] = []
        let top = array.count
        while start < top {
            let c = array [start]
            if c == "]" {
                return String(res)
            }
            res.append(c)
            start += 1
        }
        return String (res)
    }

    func createPlain (source: String)
    {
        let noStyle: [StyleRequest] = []
        
        for c in Array (source) {
            expanded.append ((c, noStyle))
        }
    }
    
    /// Splits the attributed string using the specified separator character
    /// - Parameter separator: The character to use to split
    /// - Returns: An array of AttributedStrings
    public func split (separator: Character) -> [AttributedString]
    {
        var res: [AttributedString] = []
        var line: [AttrCell] = []
        
        for x in expanded {
            if x.ch == separator {
                res.append (AttributedString (cells: line))
                line = []
            } else {
                line.append(x)
            }
        }
        res.append (AttributedString (cells: line))
        return res
        
    }

    /// Splits the attributed string using the specified separator character
    /// - Parameter separator: The character to use to split
    /// - Returns: An array of AttributedStrings
    func split (whereSeparator: (AttrCell) -> Bool) -> [AttributedString]
    {
        var res: [AttributedString] = []
        var line: [AttrCell] = []
        
        for x in expanded {
            if whereSeparator (x) {
                res.append (AttributedString (cells: line))
                line = []
            } else {
                line.append(x)
            }
        }
        return res
    }

    func createFromMarkup (source: String)
    {
        expanded = []
        var styleRequest: [StyleRequest] = []
        var closeStack: [Int] = []
        let split = Array (source)
        let top = split.count
        
        var i = 0
        while i < top {
            let c = split [i]
            defer { i += 1 }
            if c == "[" && (i+1 < split.count && split [i+1] != "[") {
                i += 1
                let word = extractTag (split, start: &i)
                var close = 1
                switch word {
                case "/":
                    if let n = closeStack.last {
                        closeStack.removeLast()
                        if styleRequest.count >= n {
                            styleRequest.removeLast(n)
                        } else {
                            log ("Closing tag mismatch, \(source)")
                        }
                    } else {
                        log ("Invalid markup string, unbalanced close \(source)")
                    }
                case "bold":
                    styleRequest.append (.bold)
                case "standout":
                    styleRequest.append (.standout)
                case "dim":
                    styleRequest.append (.dim)
                case "underline":
                    styleRequest.append (.underline)
                case "blink":
                    styleRequest.append (.blink)
                case "invert":
                    styleRequest.append (.invert)
                case "base":
                    styleRequest.append (.base)
                case "hotBase":
                    styleRequest.append (.hotBase)
                case "normal":
                    styleRequest.append (.normal)
                case "focus":
                    styleRequest.append (.focus)
                case "hotNormal":
                    styleRequest.append (.hotNormal)
                case "hotFocus":
                    styleRequest.append (.hotFocus)

                default:
                    if let color = Color.parse (word) {
                        styleRequest.append (.foreground(color: color))
                    } else {
                        if let r = word.range(of: " on ") {
                            if let fg = Color.parse (String (word [word.startIndex..<r.lowerBound])) {
                                styleRequest.append(.foreground(color: fg))
                            }
                            if let bg = Color.parse (String (word [r.upperBound...])) {
                                styleRequest.append(.background(color: bg))
                            }
                            close = 2
                        } else if word.starts(with: "bg=") {
                            // [bg="
                            if let color = Color.parse (String (word.dropFirst(3))) {
                                styleRequest.append(.background(color: color))
                            }
                        } else {
                            log ("Invalid markup string \(source), tag: \(word)")
                        }
                    }
                }
                closeStack.append(close)
            } else {
                expanded.append ((c, styleRequest))
            }
        }
    }
    
    /**
     * Constructs a new AttributedString from a marked-up string.
     * - Parameter text: A string containing markup sequences
     *
     * The syntax allowed is:
     *  `[color]` - to specify the use of a color.
     *  `[color on color]` to specify the foreground and background colors.
     *  `[bg=color]` to specify a background color.
     *
     * Colors:
     *  `black`
     *  `blue`
     *  `green`
     *  `cyan`
     *  `red`
     *  `magenta`
     *  `brown`
     *  `gray`
     *  `darkGray`
     *  `brightBlue`
     *  `brightGreen`
     *  `brightCyan`
     *  `brightRed`
     *  `brightMagenta`
     *  `brightYellow`
     *  `white`
     *  
     * Attributes:
     *  `bold` to specify the attribute should be bolded, on ANSI terminals this might merely make the color brighter.
     *  `standout` terminal-specific, it chooses a color that will standout.
     *  `dim` terminal-specific, it will choose a dimmer color.
     *  `underline` underlines the text.
     *  `blink` the character will be blinking.
     *  `invert` the character attributed will be inverted.
     *
     * Requests to use the colors define by the current color scheme:
     *  `base` the `ColorScheme.normal` if unfocused, or `ColorScheme.focus` if focused.
     *  `hotBase` the `ColorScheme.hotNormal` if unfocused, or `ColorScheme.hotFocus` if focused.
     *  `normal` the `ColorScheme.normal` attribute.
     *  `focus` the `ColorScheme.focus` attribute.
     *  `hotNormal` the `ColorSchem.hotNormal` attribute.
     *  `hotFocus` the `ColorScheme.hotFocus` attribute.
     *
     * Example:
     * `[red]This is Red[/][white on red]This looks like a warning[/][underline]this has a line under it[/]`
     */
    public init (markup text: String)
    {
        createFromMarkup (source: text)
    }
    
    /// Creates an attributed string with no attributes defined
    /// - Parameter text: the text to use as the source of the attributes
    public init (text: String)
    {
        createPlain (source: text)
    }
    
    /// Returns the number of cells consumed by this attributed string
    func cellCount () -> Int {
        return expanded.reduce(0, { acc, cell in acc + cell.ch.cellSize() })
    }
    
    /// Returns a new AttributedString that has been aligned given the specified width
    /// - Parameters:
    ///   - to: the desired text alignment
    ///   - width: the witdth to which the text should be rendered
    /// - Returns: a new attributed string with the specified alignment
    public func align (to: TextAlignment, width: Int) -> AttributedString {
        let slen = cellCount()
        if slen > width {
            var result: [AttrCell] = []
            var resultLen = 0
            for (c, style) in expanded {
                let l = c.cellSize()
                if resultLen + l < width {
                    resultLen += l
                    result.append((c, style))
                }
            }
            return AttributedString (cells: result)
        }
        var copy = expanded
        
        func fillRight (count: Int) {
            let lastStyle: [StyleRequest] = copy.last?.styleRequest ?? []
            for _ in 0..<(count) {
                copy.append((" ", lastStyle))
            }
        }
        func fillLeft (count: Int) {
            let firstStyle: [StyleRequest] = expanded.first?.styleRequest ?? []
            
            for _ in 0..<count {
                copy.insert((Character (" "), firstStyle), at: 0)
            }
        }
        
        switch to {
        case .centered:
            let pad = (width - slen) / 2
            fillLeft(count: pad)
            fillRight(count: width - (slen + pad))

        case .right:
            fillLeft(count: width - slen)

        case .left:
            fillRight(count: width - slen)

        case .justified:
            copy = []
            let words = expanded.split (whereSeparator: {$0.ch == " " || $0.ch == "\t"})
            let textCount = words.reduce(0, {acc, text in acc + text.reduce (0, { acc2, b in acc2 + b.ch.cellSize()}) })
            let spaces = (width - textCount) / (words.count-1)
            var extras = (width - textCount) % (words.count-1)
            
            for w in 0..<words.count {
                let x = words [w]
                copy.append(contentsOf: x)
                if w + 1 < words.count {
                    let lastStyle = copy.last?.styleRequest ?? []
                    for _ in 0..<spaces {
                        copy.append ((" ", lastStyle))
                    }
                }
                if extras > 0 {
                    let lastStyle = copy.last?.styleRequest ?? []
                    copy.append ((" ", lastStyle))
                    extras -= 1
                }
            }
        }
        return AttributedString(cells: copy)
    }
    
    /// Formats an attributed string given the specified LineBreakMode
    public static func format (_ string: AttributedString, with: LineBreakMode, width: Int, height: Int) -> [AttributedString]
    {
        let ret: [AttributedString] = []
        return ret
    }
    
    /// Invoke this method to draw the attributed string at the current position on the painter.
    ///
    /// If the attributed string contains newlines the painter will go to the next line, preserving
    /// the initial column where this was called.
    /// 
    /// - Parameters:
    ///   - painter: The target painter where the string will be rendered
    public func draw (on painter: Painter) {
        let current = painter.attribute
        let view = painter.view
        
        func collapseAttr (styleList: [StyleRequest]) -> Attribute
        {
            var flags: CellFlags = []
            var fore: Color? = current.fore
            var back: Color? = current.back
            
            for x in styleList {
                switch x {
                case .bold:
                    flags.insert (.bold)
                case .standout:
                    flags.insert (.standout)
                case .dim:
                    flags.insert (.dim)
                case .underline:
                    flags.insert (.underline)
                case .blink:
                    flags.insert (.blink)
                case .invert:
                    flags.insert (.invert)
                case .base:
                    (fore, back) = view.hasFocus
                        ? (view.colorScheme.focus.fore, view.colorScheme.focus.back)
                        : (view.colorScheme.normal.fore, view.colorScheme.normal.back)
                case .hotBase:
                    (fore, back) = view.hasFocus
                        ? (view.colorScheme.hotFocus.fore, view.colorScheme.hotFocus.back)
                        : (view.colorScheme.hotNormal.fore, view.colorScheme.hotNormal.back)
                case .normal:
                    (fore, back) = (view.colorScheme.normal.fore, view.colorScheme.normal.back)
                case .focus:
                    (fore, back) = (view.colorScheme.focus.fore, view.colorScheme.focus.back)
                case .hotNormal:
                    (fore, back) = (view.colorScheme.hotNormal.fore, view.colorScheme.hotNormal.back)
                case .hotFocus:
                    (fore, back) = (view.colorScheme.hotFocus.fore, view.colorScheme.hotFocus.back)
                case .foreground(color: let color):
                    fore = color
                case .background(color: let color):
                    back = color
                }
            }
            if let f = fore, let b = back {
                return painter.makeAttribute(fore: f, back: b, flags: flags)
            }
            // Only needed in the path where fore and back are nil, meaning that we are using the B&W colors
            if let f = fore {
                return current.change(foreground: f).change(flags: flags)
            }
            if let b = back {
                return current.change (background: b).change (flags: flags)
            }
            return current
        }
        let startCol = painter.pos.x
        for x in expanded {
            let newAttr = collapseAttr (styleList: x.styleRequest)
            painter.attribute = newAttr
            if x.ch == "\n" {
                painter.goto(col: startCol, row: painter.pos.y+1)
            } else {
                painter.add(str: String (x.ch))
            }
        }
    }
    
    /// Returns the bounds for the provided attributed string
    func getBounds () -> Size {
        var lines = 1
        var cellCount = 0
        var maxWidth = 0
        
        for cell in expanded {
            if cell.ch == "\n" {
                maxWidth = max (maxWidth, cellCount)
                cellCount = 0
                lines += 1
            } else {
                cellCount += cell.ch.cellSize()
            }
        }
        maxWidth = max (maxWidth, cellCount)
        return Size(width: maxWidth, height: lines)
    }

    /// Returns the string, without attributes
    public func toString () -> String {
        var res = ""
        for x in expanded {
            res.append(x.ch)
        }
        return res
    }
    
    public var debugDescription: String {
        get {
            return toString ()
        }
    }
}
