//
//  PopupButton.swift
//  
//
//  Created by Miguel de Icaza on 3/23/21.
//

import Foundation

public class PopupButton: View {
    public var elements: [String] {
        didSet {
            selected = 0
            setNeedsDisplay()
        }
    }
    var _selected: Int
    public var selected: Int {
        get {
            return _selected
        }
        set {
            if newValue > 0 && newValue < elements.count {
                selected = newValue
                setNeedsDisplay()
            }
        }
    }
    
    public init (elements: [String], selected: Int = 0) {
        self.elements = elements
        self._selected = max (0, min (selected, elements.count-1))
        super.init ()
        canFocus = true
        
        width = Dim.sized (elements.reduce(0) { acc, v in max (acc, v.cellCount() )})
        height = Dim.sized(1)
    }
    
    public override func redraw(region: Rect, painter: Painter) {
        
        painter.colorSelection()
        painter.clear (region)
        painter.goto(col: 0, row: 0)
        painter.add(str: elements [selected])
    }
    
    public override func positionCursor() {
        moveTo(col: 0, row: 0)
    }
    
    public func makeFrame ()
    {
        let s = superview!
        let myframe = frame
        let f = Frame ()
        var l = ListView (items: elements)
        
        f.addSubview(l)
        let lines = min (elements.count, s.bounds.height-2)
        f.set(x: myframe.minX-1, y: myframe.minY-1, width: myframe.width+2, height: lines+2)
        l.set(x: 0, y: 0, width: myframe.width, height: lines)
        s.addSubview(f)
        try? s.layoutSubviews()
        s.setFocus(f)
    }
    
    public override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .cursorDown:
            makeFrame()
        default:
            return false
        }
        return true
    }
}
