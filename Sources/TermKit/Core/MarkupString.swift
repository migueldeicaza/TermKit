//
//  MarkupString.swift
//  
//
//  Created by Miguel de Icaza on 3/11/21.
//

import Foundation

// Temporary: just for testing the MarkupString
public class MarkupView: View {
    var s: MarkupString
    
    public init (_ txt: String){
        s = MarkupString(txt)
        super.init ()
    }
    public override func redraw(region: Rect, painter p: Painter) {
        
        s.draw(on: p)
    }
}

/**
 * Markup string offers a simple way to markup strings to annotate them with terminal attributes and colors,
 * it is inspired by the Spectre.Console markup, which is in turn inspired by BBCode, but unlike BBCode,
 * does not use the word on the closing tag, it merely auto-closes.
 *
 * The syntax allowed is:
 *  `[color]` - to specify the use of a color
 *  `[color on color]` to specify the foreground and background colors
 *  `[bg=color]` to specify a background color
 *
 *  And then these attributes: `bold`, `standout`, `dim`, `underline`, `blink` and `invert`
 *
 * Example:
 * `[red]This is Red[/][white on red]This looks like a warning[/][underline]this has a line under it[/]`
 */
class MarkupString {
    enum StyleRequest {
        case bold
        case standout
        case dim
        case underline
        case blink
        case invert
        case foreground(color: Color)
        case background(color: Color)
        
        // Future
        //case foregroundRgb(red: UInt8, green: UInt8, blue: UInt8)
        //case backgroundRgb(red: UInt8, green: UInt8, blue: UInt8)
    }
    
    var source: String
    var expanded: [(ch: Character,styleRequest: [StyleRequest])] = []
    
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
    
    func updateMap ()
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
    
    public init (_ text: String)
    {
        self.source = text
        updateMap ()
    }
    
    func collapseAttr (_ current: Attribute, styleList: [StyleRequest]) -> Attribute
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
            case .foreground(color: let color):
                fore = color
            case .background(color: let color):
                back = color
            }
        }
        if let f = fore, let b = back {
            return Application.driver.makeAttribute(fore: f, back: b, flags: flags)
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
    
    public func draw (on painter: Painter) {
        let base = painter.attribute
        
        for x in expanded {
            let newAttr = collapseAttr (base, styleList: x.styleRequest)
            painter.attribute = newAttr
            painter.add(str: String (x.ch))
        }
    }
}
