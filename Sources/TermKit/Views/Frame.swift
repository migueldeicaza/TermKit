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
open class Frame: View {
    var contentView: View
    
    /// The title to be displayed for this window.
    public var title: String? = nil {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     * Initializes a the `FrameView` class with a specified title, and is suitable
     * for having its dimensions participate in x, y, width, height 
     */
    public init (_ title: String? = nil)
    {
        contentView = ContentView()
        contentView.canFocus = true
        self.title = title
        
        super.init ()
        // Use the new box model: contentView fills the contentFrame
        // Set our default border to a thin solid line.
        self.border = .solid
        contentView.x = Pos.at(0)
        contentView.y = Pos.at(0)
        contentView.width = Dim.fill()
        contentView.height = Dim.fill()
        
        super.addSubview(contentView)
    }
    
    open override func addSubview(_ view: View) {
        contentView.addSubview(view)
        if view.canFocus {
            canFocus = true
        }
    }
    
    // TODO: implement remove
    // TODO: implement removeAll
    
    open override func redraw(region: Rect, painter: Painter) {
        // Draw default chrome (background + border)
        super.redraw(region: region, painter: painter)
        // Title overlay on the top border line (between corners)
        let w = frame.width
        if let title, w > 4 {
            painter.attribute = hasFocus ? colorScheme.focus : colorScheme.normal
            painter.goto(col: 1, row: 0)
            painter.add(str: " ")
            painter.add(str: title.getVisibleString(w - 4))
            painter.add(str: " ")
            painter.attribute = colorScheme.normal
        }
        clearNeedsDisplay()
    }
    
    open override var frame: Rect {
        didSet {
            try? layoutSubviews()
        }
    }
    
    open override var debugDescription: String {
        return "Frame (\(super.debugDescription))"
    }
}
