//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 12/26/20.
//

import Foundation

/**
 * The drawing context tracks the cursor position, and attribute in use
 * during the View's draw method, it enforced clipping on the view bounds.
 *
 * Instances of this class are passed to a `View`'s redraw method to
 * paint
 */
public class Painter {
    var driver: ConsoleDriver
    var view: View
    
    /// The current drawing column
    public private(set) var pos: Point
    
    // The origin for this painter, describes the offset in global coordinates
    public var origin: Point
    
    // The visible region in the screen, in global coordinates
    public var visible: Rect
    
    /// The attribute used to draw
    public var attribute: Attribute {
        didSet {
            attrSet = false
        }
    }
    
    var posSet = false
    var attrSet = false
    var isTop = false
    
    private init (from view: View, isTop: Bool = false)
    {
        self.view = view
        attribute = view.colorScheme!.normal
        origin = view.frame.origin
        visible = view.frame
        driver = isTop ? TopDriver (Application.driver,  top: view as! Toplevel) : Application.driver
        pos = Point.zero
        self.isTop = isTop
    }
    
    /// This creates a painter, that renders into the Toplevel backing buffer
    public static func createTopPainter (from top: Toplevel) -> Painter {
        top.ensureLayer()
        return Painter (from: top, isTop: true)
    }
    
    /// Creates a new painter for the specified view, use this method when you want to create a painter to pass to
    /// the child view `view`, when you are in a redraw method, and you have been given the `parent` painter
    ///
    /// This creates the nested painter
    public init (from view: View, parent: Painter)
    {
        self.view = view
        attribute = view.colorScheme!.normal
        pos = Point.zero
        driver = parent.driver
        
        origin = parent.origin + view.frame.origin
        visible = parent.visible.intersection(Rect (origin: origin, size: view.bounds.size))
    }
    
    deinit {
        applyContext()
    }
    
    public func colorNormal ()
    {
        attribute = view.colorScheme!.normal
    }
    
    public func colorSelection ()
    {
        attribute = view.hasFocus ? view.colorScheme!.focus : view.colorScheme!.normal
    }
    
    /**
     * Moves the drawing cursor position to the specified column and row.
     *
     * These values can be beyond the view's frame and will be updated as print commands are done
     *
     * - Parameter col: the new column where the cursor will be.
     * - Parameter row: the new row where the cursor will be.
     */
    public func goto (col: Int, row: Int)
    {
        self.pos = Point(x: col, y: row)
        posSet = false
    }
    
    /**
     * Moves the drawing cursor position to the specified point.
     *
     * These values can be beyond the view's frame and will be updated as print commands are done
     *
     * - Parameter to: the point that contains the new cursor position
     */
    public func go (to: Point)
    {
        self.pos = to
        posSet = false
    }

    // if necessary, sets the current attribute
    func applyContext ()
    {
        if !attrSet {
            if isTop == false {
                driver.setAttribute(attribute)
            }
            attrSet = true
        }
    }
    
    func add (rune: UnicodeScalar, maxWidth: Int)
    {
        if rune.value == 10 {
            pos.x = 0
            pos.y += 1
            return
        }
        // TODO: optimize, we can handle the visibility for rows before and later just do
        // columns rather than testing both.
        let len = Int32 (wcwidth(wchar_t (bitPattern: rune.value)))
        let npos = pos.x + Int (len)

        if npos > maxWidth {
            // We are out of bounds, but the width might be larger than 1 cell
            // so we should draw a space
            while pos.x < maxWidth {
                driver.addStr(" ")
                pos.x += 1
            }
        } else {
            if visible.contains(pos+origin) {
                if !posSet {
                    let cursor = pos + origin
                    driver.moveTo(col: cursor.x, row: cursor.y)
                    posSet = true
                }

                driver.addRune (rune)
            }
            pos.x += Int (len)
        }
    }
    
    public func add (str: String)
    {
        let strScalars = str.unicodeScalars
        let maxWidth = view.bounds.width
        
        applyContext ()
        for uscalar in strScalars {
            add (rune: uscalar, maxWidth: maxWidth)
        }
    }

    public func add (ch: Character)
    {
        let strScalars = ch.unicodeScalars
        let maxWidth = view.bounds.width
        
        applyContext ()
        for uscalar in strScalars {
            add (rune: uscalar, maxWidth: maxWidth)
        }
    }

    public func add (rune: UnicodeScalar)
    {
        add (str: String (rune))
    }
    
    /**
     * Clears the view region with the current color.
     */
    public func clear (with: Character = " ")
    {
        clear (view.frame, with: with)
    }

    /// Clears the specified region in painter coordinates
    /// - Parameter rect: the region to clear, the coordinates are relative to the view
    public func clear (_ rect: Rect, with: Character = " ")
    {
        let w = rect.width
        
        for line in rect.minY..<rect.maxY {
            goto (col: rect.minX, row: line)

            for _ in 0..<w {
                add (rune: UnicodeScalar(" "), maxWidth: w)
            }
        }
    }
    
    /// Clears a region of the view with spaces, the parameter are in view coordinates
    /// - Parameters:
    ///   - left: Left column
    ///   - top: Top row
    ///   - right: Right column
    ///   - bottom: Bottom row
    func clearRegion (left: Int, top: Int, right: Int, bottom: Int)
    {
        let lstr = String (repeating: " ", count: right-left)
        for row in top..<bottom {
            goto(col: left, row: row)
            add (str: lstr)
        }
    }

    /**
     * Draws a frame on the specified region with the specified padding around the frame.
     * - Parameter region: Region where the frame will be drawn.
     * - Parameter padding: Padding to add on the sides
     * - Parameter fill: If set to `true` it will clear the contents with the current color, otherwise the contents will be left untouched.
     */
    public func drawFrame (_ region: Rect, padding: Int, fill: Bool, double: Bool = false)
    {
        let width = region.width;
        let height = region.height;

        let fwidth = width - padding * 2;
        let fheight = height - 1 - padding;
        
        goto(col: region.minX, row: region.minY)
        
        if (padding > 0) {
            for _ in 0..<padding {
                for _ in 0..<width {
                    add (ch: " ")
                }
            }
        }
        goto (col: region.minX, row: region.minY + padding);
        for _ in 0..<padding {
            add (ch: " ")
        }
        add (rune: double ? driver.doubleUlCorner : driver.ulCorner)
        for _ in 0..<(fwidth-2) {
            add (rune: double ? driver.doubleHLine : driver.hLine);
        }
        add (rune: double ? driver.doubleUrCorner : driver.urCorner);
        for _ in 0..<padding {
            add (ch: " ")
        }
        
        for b in (1+padding)..<fheight {
            goto (col: region.minX, row: region.minY + b);
            for _ in 0..<padding {
                add (ch: " ")
            }
            add (rune: double ? driver.doubleVLine : driver.vLine);
            if fill {
                for _ in 1..<(fwidth-1){
                    add (ch: " ")
                }
            } else {
                goto (col: region.minX + padding + fwidth - 1, row: region.minY + b)
            }
            add (rune: double ? driver.doubleVLine : driver.vLine);
            for _ in 0..<padding {
                add (ch: " ")
            }
        }
        goto (col: region.minX, row: region.minY + fheight)
        for _ in 0..<padding {
            add (ch: " ")
        }
        add (rune: double ? driver.doubleLlCorner : driver.llCorner);
        for _ in 0..<(fwidth - 2) {
            add (rune: double ? driver.doubleHLine : driver.hLine);
        }
        add (rune: double ? driver.doubleLrCorner : driver.lrCorner);
        for _ in 0..<padding {
            add (ch: " ")
        }
        if padding > 0 {
            goto (col: region.minX, row: region.minY + height - padding);
            for _ in 0..<padding {
                for _ in 0..<width {
                    add (ch: " ")
                }
            }
        }
    }
    
    /**
     * Utility function to draw strings that contains a hotkey using the two specified colors
     * - Parameter text: String to display, the underscoore before a letter flags the next letter as the hotkey.
     * - Parameter hotColor: the color to use for the hotkey
     * - Parameter normalColor: the color to use for the normal color
     */
    public func drawHotString (text: String, hotColor: Attribute, normalColor: Attribute)
    {
        attribute = normalColor

        for ch in text {
            if ch == "_" {
                attribute = hotColor
            } else {
                add (str: String (ch))
                attribute = normalColor
            }
        }
    }
 
    /**
     * Utility function to draw strings that contains a hotkey using a colorscheme and the "focused" state.
     * - Parameter text: String to display, the underscoore before a letter flags the next letter as the hotkey.
     * - Parameter focused: If set to `true` this uses the focused colors from the color scheme, otherwise the regular ones.
     * - Parameter scheme: The color scheme to use
     */
    public func drawHotString (text: String, focused: Bool, scheme: ColorScheme)
    {
        if focused {
            drawHotString(text: text, hotColor: scheme.hotFocus, normalColor: scheme.focus)
        } else {
            drawHotString(text: text, hotColor: scheme.hotNormal, normalColor: scheme.normal)
        }
    }
 
    public func debug ()
    {
        if let topDriver = driver as? TopDriver {
            Application.updateDisplay (topDriver.top.layer)
        }
    }
}

// This is a ConsoleDriver that is used during the transition period
// to not touch the painter code too much, it acts as a proxy for
// attributes, but otherwise stores the data on the backing store
// in the Toplevel that is provided.
class TopDriver: ConsoleDriver {
    var top: Toplevel
    var backing: ConsoleDriver
    var col: Int = 0
    var row: Int = 0
    var topSize: Size
    var attribute: Attribute
    var nullCell: Cell
    
    init (_ backing: ConsoleDriver, top: Toplevel) {
        self.backing = backing
        self.top = top
        self.topSize = top.frame.size
        self.attribute = top.colorScheme.normal
        self.nullCell = Cell (ch: "\u{0}", attr: top.colorScheme.normal)
    }

    public override func moveTo (col: Int, row: Int) {
        let origin = top.frame.origin
        self.col = col-origin.x
        self.row = row-origin.y
    }
    
    public override func addRune(_ rune: rune) {
        let n = wcwidth(Int32(rune.value))
        if n == 0 { return }
        let cell = Cell (ch: Character(rune), attr: attribute)
        top.layer.add (cell: cell, col: col, row: row)
        col += 1
        if n == 2 && col < topSize.width {
            top.layer.add (cell: nullCell, col: col, row: row)
            col += 1
        }
    }
    
    public override func addCharacter(_ char: Character) {
        let s = top.frame
        let n = char.cellSize()
        if n == 0 { return }
        
        if col < s.width {
            top.layer.add (cell: Cell (ch: char, attr: attribute), col: col, row: row)
            col += 1
            if n == 2 && col < s.width {
                top.layer.add (cell: nullCell, col: col, row: row)
                col += 1
            }
        }
    }
    
    public override func change(_ attribute: Attribute, background: Color) -> Attribute {
        backing.change(attribute, background: background)
    }
    
    public override func change(_ attribute: Attribute, foreground: Color) -> Attribute {
        backing.change(attribute, foreground: foreground)
    }
    
    public override func change(_ attribute: Attribute, flags: CellFlags) -> Attribute {
        backing.change(attribute, flags: flags)
    }
    
    public override func colorSupport() -> ConsoleDriver.ColorSupport {
        backing.colorSupport()
    }
    
    public override func makeAttribute(fore: Color, back: Color, flags: CellFlags = []) -> Attribute {
        backing.makeAttribute(fore: fore, back: back, flags: flags)
    }
    
    public override func setAttribute(_ attr: Attribute) {
        attribute = attr
    }
    
    public override func cookMouse() {
        // this not necessary during painting ops
        abort ()
    }
    
    public override func uncookMouse() {
        // this not necessary during painting ops
    }
}
