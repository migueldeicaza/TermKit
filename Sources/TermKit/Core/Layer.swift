//
//  Layer.swift
//  
//
//  Created by Miguel de Icaza on 4/14/21.
//

import Foundation

struct Cell {
    var ch: Character
    var attr: Attribute
}

public class Layer {
    static var empty: Layer = Layer (size: Size (width: 0, height: 0))
    static var emptyCell = Cell (ch: " ", attr: Colors.base.normal)
    var store: [Cell]
    var size: Size
    var dirtyRows: [Bool]
    
    public init (size: Size) {
        // Clamp to non-negative dimensions to avoid invalid allocations
        let w = max(0, size.width)
        let h = max(0, size.height)
        self.size = Size(width: w, height: h)
        self.store = Array.init(repeating: Layer.emptyCell, count: w*h)
        self.dirtyRows = Array.init (repeating: true, count: h)
    }
    
    func add (cell: Cell, col: Int, row: Int) {
        if col < size.width && row < size.height {
            store [col + row * size.width] = cell
//            if !dirtyRows [row] {
//                log ("New dirty row \(row)")
//            }
            dirtyRows [row] = true
        }
    }
    
    func clearDirty () {
        for x in 0..<dirtyRows.count {
            dirtyRows [x] = false
        }
    }
}
