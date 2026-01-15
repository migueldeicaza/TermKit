//
//  Layer.swift
//  
//
//  Created by Miguel de Icaza on 4/14/21.
//

import Foundation

/// Represents a single cell in the terminal buffer with a character and its display attributes.
struct Cell {
    /// The character displayed in this cell.
    var ch: Character
    /// The visual attributes (colors, styling) for this cell.
    var attr: Attribute
}

/// A layer represents a 2D buffer of cells that can be rendered to the terminal.
///
/// Layers are the fundamental building blocks of TermKit's rendering system.
/// Each ``View`` has its own layer where it draws its content. Layers support
/// efficient dirty-region tracking to minimize redrawing.
///
/// ## Overview
/// Layers store a grid of ``Cell`` values, each containing a character and its
/// display attributes. When content changes, the affected rows are marked as dirty
/// and will be redrawn on the next render pass.
///
/// ## Usage
/// You typically don't create layers directly. Instead, views manage their own
/// layers internally. Use ``Painter`` to draw content into a view's layer.
public class Layer {
    /// An empty layer with zero dimensions.
    static var empty: Layer = Layer (size: Size (width: 0, height: 0))
    /// The default empty cell used to initialize new layers.
    static var emptyCell = Cell (ch: " ", attr: Colors.base.normal)
    /// The storage array containing all cells in row-major order.
    var store: [Cell]
    /// The dimensions of this layer.
    var size: Size
    /// Tracks which rows have been modified and need redrawing.
    var dirtyRows: [Bool]

    /// Creates a new layer with the specified dimensions.
    ///
    /// The layer is initialized with empty cells (spaces with the base color scheme's
    /// normal attribute). All rows are initially marked as dirty.
    ///
    /// - Parameter size: The width and height of the layer. Negative values are clamped to 0.
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
