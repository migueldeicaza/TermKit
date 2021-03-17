//
//  Frame.swift - frame control
//  TermKit
//
//  Created by Miguel de Icaza on 4/22/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 *  The FrameView is a container frame that draws a frame around the contents
 */
public class FrameView : View {
    var contentView : View
    
    /// The title to be displayed for this window.
    public var title : String? = nil {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     * Initializes a the `FrameView` class with a specified title, and is suitable
     * for having its dimensions participate in x, y, width, height 
     */
    public init (title: String? = nil)
    {
        contentView = View()
        self.title = title
        
        super.init ()
        
        contentView.x = Pos.at(1)
        contentView.y = Pos.at(1)
        contentView.width = Dim.fill(2)
        contentView.height = Dim.fill(2)
        
        super.addSubview(contentView)
    }
    
    public override func addSubview(_ view: View) {
        contentView.addSubview(view)
        if view.canFocus {
            canFocus = true
        }
    }
    
    // TODO: implement remove
    // TODO: implement removeAll
    
    public override func redraw(region: Rect, painter: Painter) {
        if !needDisplay.isEmpty {
            painter.attribute = colorScheme!.normal
            painter.drawFrame (bounds, padding: 0, fill: true)
            if hasFocus {
                painter.attribute = colorScheme!.focus
            }
            let w = frame.width
            if title != nil && w > 4 {
                painter.goto(col: 1, row: 0)
                painter.add(str: " ")
                let t = title!
                painter.add(str: t.getVisibleString(w - 4))
                painter.add(str: " ")
            }
            painter.attribute = colorScheme!.normal
        }
        contentView.redraw(region: contentView.bounds, painter: Painter (from: contentView, parent: painter))
        clearNeedsDisplay()
    }
    
    public override var debugDescription: String {
        return "Frame (\(super.debugDescription))"
    }
}
