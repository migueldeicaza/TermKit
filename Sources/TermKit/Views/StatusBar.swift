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
    
    public override func redraw(region: Rect, painter: Painter) {
        painter.attribute = Colors.dialog.normal
        painter.clear ()
        painter.goto(col: 0, row: 0)
        painter.add(str: "Statusbar")
    }
}
