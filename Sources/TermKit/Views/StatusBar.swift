//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 1/1/21.
//

import Foundation

open class StatusBar: View {
    public override init ()
    {
        super.init ()
    }
    
    open override func redraw(region: Rect, painter: Painter) {
        painter.attribute = Colors.menu.normal
        painter.clear(region)
        painter.goto(col: 0, row: 0)
        painter.add(str: "Statusbar")
    }
}
