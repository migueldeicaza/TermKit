//
// Desktop.swift
//
// Shows a background stipple desktop
//
//  Created by Miguel de Icaza on 3/24/21.
//

import Foundation

class Desktop: View {
    open override func drawContent(in region: Rect, painter: Painter) {
        painter.clear(region, with: "░")
    }
}
