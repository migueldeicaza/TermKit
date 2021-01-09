//
//  Window.swift - These are toplevel that are drawn with a border.
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
        public override var debugDescription: String {
            return "Window.ContentView (\(super.debugDescription))"
        }
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
        contentView.x = Pos.at (padding + 1)
        contentView.y = Pos.at (padding + 1)
        contentView.width = Dim.fill(padding+1)
        contentView.height = Dim.fill(padding+1)
        super.init ()
        super.addSubview(contentView)
    }
    
    func drawFrame()
    {
        drawFrame(bounds, padding: padding, fill: true)
    }
    
    public override func addSubview(_ view: View)
    {
        contentView.addSubview(view)
        if view.canFocus {
            canFocus = true
        }
    }
    
    // TODO: remove
    
    // TODO: removeAll
    
    public override func redraw(region: Rect) {
        //log ("Window.redraw: \(frame) and region to redraw is: \(region)")
        
        if !needDisplay.isEmpty {
            
            let p = getPainter ()
            p.attribute = colorScheme!.normal
            p.drawFrame (bounds, padding: padding, fill: true)
            
            if hasFocus {
                p.attribute = colorScheme!.normal
            }
            let width = frame.width
            if let t = title, width > 4 {
                p.goto (col: padding+1, row: padding)
                p.add (rune: Unicode.Scalar(32))
                let str = t.count > (width+4) ? t : String (t.prefix (width-4))
                p.add (str: str)
                p.add (rune: Unicode.Scalar(32))
            }
            p.attribute = colorScheme!.normal
        }
        contentView.redraw(region: contentView.bounds)
        clearNeedsDisplay()
    }
    
    public override var debugDescription: String {
        return "Window (\(super.debugDescription))"
    }
}
