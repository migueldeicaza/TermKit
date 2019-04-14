//
//  Window.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/14/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * A toplevel view that draws a frame around its region and has a "ContentView" subview where the contents are added.
 * with an optional title that is displayed at the top
 */
public class Window : Toplevel {
    var contentView : View
    var padding : Int
    
    /// The title to be displayed for this window.
    public var title : String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    class ContentView : View {
    
    }
    
    public override convenience init ()
    {
        self.init (nil, padding: 0)
    }
    
    public init (_ title : String? = nil, padding : Int = 0)
    {
        self.padding = padding
        self.title = title
        contentView = ContentView()
        contentView.x = Pos.at (padding)
        contentView.y = Pos.at (padding)
        contentView.width = Dim.fill(padding * 2)
        contentView.height = Dim.fill(padding * 2)
        super.init ()
        super.addSubview(contentView)
    }
    
    func drawFrame()
    {
        drawFrame(bounds, padding: padding, fill: true)
    }
    
    public override func addSubview(_ view: View) {
         contentView.addSubview(view)
        if view.canFocus {
            canFocus = true
        }
    }
    
    // TODO: remove
    
    // TODO: removeAll
    
    public override func redraw(region: Rect) {
        if !needDisplay.isEmpty {
            driver.setAttribute(colorScheme!.normal)
            drawFrame ()
            if hasFocus {
                driver.setAttribute(colorScheme!.normal)
            }
            let width = frame.width
            if let t = title, width > 4 {
                moveTo (col: padding+1, row: padding)
                driver.addRune (Unicode.Scalar(32))
                let str = t.count > (width+4) ? t : String (t.prefix (width-4))
                driver.addStr (str)
                driver.addRune (Unicode.Scalar(32))
            }
            driver.setAttribute(colorScheme!.normal)
        }
        contentView.redraw(region: contentView.bounds)
        clearNeedsDisplay()
    }
    
    
}
