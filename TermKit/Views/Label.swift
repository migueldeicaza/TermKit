//
//  Label.swift - implements text labels
//  TermKit
//
//  Created by Miguel de Icaza on 4/20/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/// Text alignment enumeration, controls how text is displayed.
public enum TextAlignment {
    /// Aligns the text to the left of the frame.
    case Left
    /// Aligns the text to the right side of the frame.
    case Right
    /// Centers the text in the frame.
    case Centered
    /// Shows the line as justified text in the line.
    case Justified
}

/// Label view, displays a string at a given position, can include multiple lines.
public class Label : View {
    var lines : [String] = []
    var recalcPending: Bool = true
    
    /// The text displayed by this view
    public var text : String {
        didSet {
            recalcPending = true
            setNeedsDisplay()
        }
    }
    
    /// Controls the text-alignemtn property of the label, changing it will redisplay the label.
    public var textAlignment : TextAlignment {
        didSet {
            recalcPending = true
            setNeedsDisplay()
        }
    }
    
    /// The color used for the label, if not set, it will use the normal color from the `ColorScheme` in use
    public var textAttribute: Attribute? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // In the absence of limits, computes the dimension for displaying the given text
    // TODO: needs to compute the actual character width
    func CalcRect (text : String) -> (cols : Int, lines: Int)
    {
        var cols = 0
        var mw = 0
        var lines = 1
        for c in text {
            if c == "\n" {
                lines += 1
                if cols > mw {
                    mw = cols
                }
                cols = 0
            } else {
                cols += 1
            }
        }
        if cols > mw {
            mw = cols
        }
        return (mw, lines)
    }

    static func clipAndJustify (str: String, width : Int, align : TextAlignment) -> String
    {
        let slen = str.cellCount()
        if slen > width {
            var result = ""
            var resultLen = 0
            for c in str {
                let l = c.cellSize()
                if resultLen + l < width {
                    resultLen += l
                    result.append(c)
                }
            }
            return result
        }
        if align == .Justified {
            let words = str.split (whereSeparator: {$0 == " " || $0 == "\t"})
            let textCount = words.reduce(0, {x, y in  x + y.count })
            let spaces = (width - textCount) / (words.count-1)
            var extras = (width - textCount) % (words.count-1)
            
            var result = ""
            for w in 0..<words.count {
                let x = words [w]
                result.append(String (x))
                if w + 1 < words.count {
                    for i in 0..<spaces {
                        result.append (" ")
                    }
                }
                if extras > 0 {
                    result.append ("_")
                    extras -= 1
                }
            }
            return result
        }
        return str
    }
    
    static func recalc (_ textStr: String, lineResult: inout [String], width: Int, align: TextAlignment)
    {
        lineResult = []
        if textStr.firstIndex(of: "\n") == nil {
            lineResult.append (clipAndJustify(str: textStr, width: width, align: align))
            return
        }
        let len = textStr.count
        var lp = 0
        for i in 0..<len {
            
        }
    }
    
    func recalc ()
    {
        recalcPending = false
        Label.recalc (text, lineResult: &lines, width: frame.width, align: textAlignment)
    }
    
    /// Initializes a Label with the provided string
    public init (text : String)
    {
        self.text = text
        self.textAlignment = .Left
    }
    
    
}
