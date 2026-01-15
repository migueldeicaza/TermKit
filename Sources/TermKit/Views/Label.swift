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
    case left
    /// Aligns the text to the right side of the frame.
    case right
    /// Centers the text in the frame.
    case centered
    /// Shows the line as justified text in the line.
    case justified
}

/// The technique used by the label to break up the content
public enum LineBreakMode {
    /// This mode will clip the text to the specified width
    case byClipping
}

/**
 * Label view, displays a string at a given position, can include multiple lines.
 *
 * When labels are initiallly created, they compute a default width and height,
 * and additional changes to the configuration of the label (the text, the lineBreak,
 * the text alignemtn) will not automatically change that.  You must call `autoSize()`
 * if you want to change those parameters.
 */
open class Label: View {
    /// Accesses the content of the label as a String, if you want to use colors or attributed, set the `attributedText` property instead
    public var text: String {
        get {
            attributedText.toString ()
        }
        set {
            attributedText = AttributedString(text: newValue)
        }
    }
    
    /// Access the contents of the label as an attributed string
    public var attributedText: AttributedString {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Controls the line breaking method of the label, changing it will redisplay the label.
    public var lineBreak: LineBreakMode {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Controls the text-alignment property of the label, changing it will redisplay the label.
    public var textAlignment: TextAlignment {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Initializes a Label with the provided string.
    /// - Parameters:
    ///   - text: The text to display in the label.
    ///   - align: The text alignment. Defaults to `.left`.
    ///   - lineBreak: The line breaking mode. Defaults to `.byClipping`.
    public convenience init (_ text: String,
                             align: TextAlignment = .left,
                             lineBreak: LineBreakMode = .byClipping)
    {
        self.init (AttributedString (text: text), align: align)
    }

    /// Initializes a Label with an attributed string.
    /// - Parameters:
    ///   - attrStr: The attributed string to display.
    ///   - align: The text alignment. Defaults to `.left`.
    ///   - lineBreak: The line breaking mode. Defaults to `.byClipping`.
    public init (_ attrStr: AttributedString,
                 align: TextAlignment = .left,
                 lineBreak: LineBreakMode = .byClipping)
    {
        attributedText = attrStr
        self.textAlignment = align
        self.lineBreak = lineBreak
        super.init ()
        coreAutoSize()
    }

    func naturalContentSize() -> Size {
        if lineBreak == .byClipping {
            let s = attributedText.getBounds()
            return Size(width: s.width, height: s.height)
        } else {
            return Size(width: text.cellCount(), height: 1)
        }
    }

    func coreAutoSize ()
    {
        let natural = naturalContentSize()
        let insets = border.edgeInsets + padding
        width = Dim.sized(natural.width + insets.horizontal)
        height = Dim.sized(natural.height + insets.vertical)
    }

    open override func layoutSubviews() throws {
        // If the current size matches the natural content size (i.e., was auto-sized
        // without chrome), expand it to include border+padding to ensure non-empty contentFrame.
        let natural = naturalContentSize()
        let insets = border.edgeInsets + padding
        if let absW = _width as? Dim.DimAbsolute, absW.n == natural.width {
            _width = Dim.sized(natural.width + insets.horizontal)
        }
        if let absH = _height as? Dim.DimAbsolute, absH.n == natural.height {
            _height = Dim.sized(natural.height + insets.vertical)
        }
        try super.layoutSubviews()
    }
    
    /// This function sets the View's width and height properties based on the
    /// lineBreak mode and the contents of the string.   This is called when the
    /// object is first constructed, but you must manually call it if you change
    /// the content of the label or other attributes, as those would not change
    /// the active size configuration.
    public func autoSize () {
        coreAutoSize ()
        setNeedsLayout()
    }
    
    open override func drawContent(in region: Rect, painter: Painter) {
        TermKitLog.logger.debug("Label.draw id=\(viewId) region=\(region) contentFrame=\(contentFrame) layerSize=\(layer.size)")
        switch lineBreak {
        case .byClipping:
            let lines = attributedText.split(separator: "\n")
            for line in 0..<lines.count {
                if line < region.top || line > region.bottom {
                    continue
                }
                let str = lines [line].align(to: textAlignment, width: contentFrame.width)
                painter.goto(col: 0, row: line)
                str.draw(on: painter)
            }
        }
    }
}

/// Label view, displays a string at a given position, can include multiple lines.
public class Label3 : View {
    var lines : [String] = []
    var recalcPending: Bool = true
    
    /// Controls the text-alignemtn property of the label, changing it will redisplay the label.
    public var textAlignment : TextAlignment {
        didSet {
            recalcPending = true
            setNeedsDisplay()
        }
    }

    /// Initializes a Label with the provided string
    public init (_ text : String)
    {
        self.text = text
        textAlignment = .left
        super.init ()
        height = Dim.sized(1)
        width = Dim.sized (text.cellCount())
    }
    
    /// The text displayed by this view
    public var text : String {
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
        if align == .justified {
            let words = str.split (whereSeparator: {$0 == " " || $0 == "\t"})
            let textCount = words.reduce(0, {x, y in  x + y.count })
            let spaces = (width - textCount) / (words.count-1)
            var extras = (width - textCount) % (words.count-1)
            
            var result = ""
            for w in 0..<words.count {
                let x = words [w]
                result.append(String (x))
                if w + 1 < words.count {
                    for _ in 0..<spaces {
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
        
        var buffer = ""
        for c in textStr {
            if c == "\n" {
                lineResult.append(clipAndJustify(str: buffer, width: width, align: align))
                buffer = ""
            } else {
                buffer.append(c)
            }
        }
        lineResult.append(clipAndJustify(str: buffer, width: width, align: align))
    }
    
    func recalc ()
    {
        recalcPending = false
        Label3.recalc (text, lineResult: &lines, width: frame.width, align: textAlignment)
    }
    
    open override func drawContent(in region: Rect, painter: Painter) {
        if recalcPending {
            recalc ()
        }

        painter.attribute = textAttribute ?? colorScheme.normal
        painter.goto(col: 0, row: 0)
        for line in 0..<lines.count {
            if line < region.top || line > region.bottom {
                continue
            }
            let str = lines [line]
            var x = 0
            let width = contentFrame.width
            switch textAlignment {
            case .centered:
                x = max(0, (width - str.cellCount())/2)
            case .justified, .left:
                x = 0
            case .right:
                x = max(0, width - str.cellCount())
            }
            painter.goto (col: x, row: line)
            painter.add(str: str)
        }
    }
    
    /**
     * Computes the number of lines needed to render the specified text by the Label control
     * - Paramter str: Text, may contain newlines.
     * - The width for the text.
     */
    public static func measureString (text: String, width: Int) -> Int
    {
        var result : [String] = []
        recalc (text, lineResult: &result, width: width, align: .left)
        return result.count
    }
    
    /**
     * Computes the the max width of a line or multilines needed to render by the Label control.
     * - Parameter text: text to measure
     * - Parameter width: optional, the maximum width desired, it will clamp to that value.
     */
    public static func maxWidth (text: String, width : Int = INTPTR_MAX) -> Int
    {
        var result : [String] = []
        recalc (text, lineResult: &result, width: width, align: .left)
        if let max = result.max (by: { x, y in x.cellCount() < y.cellCount ()}) {
            return max.cellCount()
        } else {
            return 0
        }
    }
    
    open override var debugDescription: String {
        return "Label (text=\"\(text)\", \(super.debugDescription))"
    }
}
