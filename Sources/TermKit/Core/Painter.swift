//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 12/26/20.
//

import Foundation

/**
 * The drawing context trackst the cursor position and attribute in use
 * during the View's draw method, it enforced clipping on the view bounds.
 */
public class Painter {
    var view: View
    
    /// The current drawing column
    public private(set) var col: Int
    /// The current drawing row
    public private(set) var row: Int
    
    /// The attribute used to draw
    public var attribute: Attribute? {
        didSet {
            attrSet = false
        }
    }
    
    var posSet = false
    var attrSet = false
    
    init (from view: View)
    {
        self.view = view
        col = 0
        row = 0
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
            Application.driver.setAttribute(attribute ?? view.colorScheme.normal)
            attrSet = true
        }
    }
    
    public func add (str: String)
    {
        let strScalars = str.unicodeScalars
        let bounds = view.bounds
        let driver = Application.driver
        
        applyContext ()
        for uscalar in strScalars {
            if uscalar.value == 10 {
                col = 0
                row += 1
                continue
            }
            if row > bounds.height {
                return
            }
            let len = Int32 (wcwidth(wchar_t (bitPattern: uscalar.value)))
            let npos = col + Int (len)
            
            if npos > bounds.width {
                // We are out of bounds, but the width might be larger than 1 cell
                // so we should draw a space
                while col < bounds.width {
                    driver.addStr(" ")
                    col += 1
                }
            } else {
                driver.addRune (uscalar)
                col += Int (len)
            }
        }
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
        let driver = Application.driver
        let h = rect.height
        
        let lstr = String (repeating: " ", count: rect.width)
        
        for line in 0..<h {
            goto (col: rect.minX, row: line)
            driver.addRune (driver.space)
        }
    }
}
