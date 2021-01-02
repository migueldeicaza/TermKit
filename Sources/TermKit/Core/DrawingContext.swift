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
public class DrawingContext {
    var view: View
    
    /// The current drawing column
    public private(set) var col: Int
    /// The current drawing row
    public private(set) var row: Int
    
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
    }
    
}
