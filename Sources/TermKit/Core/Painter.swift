//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 12/26/20.
//

import Foundation

/**
 * The drawing context tracks the cursor position and attribute in use
 * during the View's draw method, it enforced clipping on the view bounds.
 */
public class Painter {
    var view: View
    
    /// The current drawing column
    public private(set) var col: Int
    /// The current drawing row
    public private(set) var row: Int
    
    /// The attribute used to draw
    public var attribute: Attribute {
        didSet {
            attrSet = false
        }
    }
    
    var posSet = false
    var attrSet = false
    
    init (from view: View)
    {
        self.view = view
        attribute = view.colorScheme!.normal
        col = 0
        row = 0
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
        self.col = col
        self.row = row
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
        self.col = to.x
        self.row = to.y
        posSet = false
    }

    // if necessary, calls the driver goto method, and sets the current attribute
    func applyContext ()
    {
        if !posSet {
            let (rcol, rrow) = view.viewToScreen(col: col, row: row)
            Application.driver.moveTo(col: rcol, row: rrow)
            posSet = true
        }
        if !attrSet {
            Application.driver.setAttribute(attribute)
            attrSet = true
        }
    }
    
    func add (rune: UnicodeScalar, bounds: Rect, driver: ConsoleDriver)
    {
        if rune.value == 10 {
            col = 0
            row += 1
            return
        }
        if row > bounds.height {
            return
        }
        let len = Int32 (wcwidth(wchar_t (bitPattern: rune.value)))
        let npos = col + Int (len)
        
        if npos > bounds.width {
            // We are out of bounds, but the width might be larger than 1 cell
            // so we should draw a space
            while col < bounds.width {
                driver.addStr(" ")
                col += 1
            }
        } else {
            driver.addRune (rune)
            col += Int (len)
        }
    }
    
    public func add (str: String)
    {
        let strScalars = str.unicodeScalars
        let bounds = view.bounds
        let driver = Application.driver
        
        applyContext ()
        for uscalar in strScalars {
            add (rune: uscalar, bounds: bounds, driver: driver)
        }
    }

    public func add (ch: Character)
    {
        let strScalars = ch.unicodeScalars
        let bounds = view.bounds
        let driver = Application.driver
        
        applyContext ()
        for uscalar in strScalars {
            add (rune: uscalar, bounds: bounds, driver: driver)
        }
    }

    public func add (rune: UnicodeScalar)
    {
        add (str: String (rune))
    }
    
    /**
     * Clears the view region with the current color.
     */
    public func clear ()
    {
        clear (view.frame)
    }
    
    public func clear (_ rect: Rect)
    {
        //let driver = Application.driver
        let h = rect.height
        
        let lstr = String (repeating: " ", count: rect.width)
        
        for line in 0..<h {
            goto (col: rect.minX, row: line)
            
            // OPTIMIZATION: if the driver clips, we could call the driver directly, as we know the string is spaces
            // and wont have any odd sizing issues
            add (str: lstr)
        }
    }
    
    /// Clears a region of the view with spaces
    func clearRegion (left: Int, top: Int, right: Int, bottom: Int)
    {
        //let driver = Application.driver
        let lstr = String (repeating: " ", count: right-left)
        for row in top..<bottom {
            goto(col: left, row: row)
            // OPTIMIZATION: if the driver clips, we could call the driver directly, as we know the string is spaces
            // and wont have any odd sizing issues
            add (str: lstr)
        }
    }

    /**
     * Draws a frame on the specified region with the specified padding around the frame.
     * - Parameter region: Region where the frame will be drawn, in view coordinates
     * - Parameter padding: Padding to add on the sides
     * - Parameter fill: If set to `true` it will clear the contents with the current color, otherwise the contents will be left untouched.
     */
    public func drawFrame (_ region: Rect, padding : Int, fill : Bool)
    {
        applyContext ()
        let (rcol, rrow) = view.viewToScreen(col: region.minX, row: region.minY)
        let globalRegion = Rect(origin: Point (x: rcol, y: rrow),
                                size: region.size)
        Application.driver.drawFrame (globalRegion, padding: padding, fill: fill)
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
    
}
