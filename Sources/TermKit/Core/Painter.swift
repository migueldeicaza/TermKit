//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 12/26/20.
//

import Foundation

/**
 * The drawing context tracks the cursor position, and attribute in use
 * during the View's draw method, it enforced clipping on the view bounds.
 *
 * Instances of this class are passed to a `View`'s redraw method to
 * paint
 */
public class Painter {
    // Target layer to render into
    private var targetLayer: Layer
    // Console driver is used only for attribute creation and line-drawing runes
    private var driver: ConsoleDriver = Application.driver
    var view: View
    
    /// The current drawing column
    public private(set) var pos: Point 
    
    // The origin for this painter, describes the offset in global coordinates
    public var origin: Point
    
    // The visible region in the screen, in global coordinates
    public var visible: Rect
    
    /// The attribute used to draw
    public var attribute: Attribute {
        didSet {
            attrSet = false
        }
    }
    
    private var posSet = false
    private var attrSet = false

    /// Creates a painter that targets the provided view's own layer
    public init(for view: View) {
        self.view = view
        self.attribute = view.colorScheme.normal
        self.targetLayer = view.layer
        self.origin = Point.zero
        self.visible = Rect(origin: .zero, size: view.bounds.size)
        self.pos = .zero
    }
    
    /**
     * This method takes the platform-agnostic Color enumeration for foreground and background and produces an attribute
     */
    public func makeAttribute(fore: Color, back: Color, flags: CellFlags = []) -> Attribute {
        driver.makeAttribute(fore: fore, back: back, flags: flags)
    }
    
    /// Creates a new painter for the specified view, use this method when you want to create a painter to pass to
    /// the child view `view`, when you are in a redraw method, and you have been given the `parent` painter
    ///
    /// This creates the nested painter
    public init (from view: View, parent: Painter)
    {
        self.view = view
        self.attribute = view.colorScheme.normal
        self.pos = .zero
        // Share the same target layer as the parent for composition
        self.targetLayer = parent.targetLayer
        // Child painter is offset by the child's frame within the parent's coordinate space
        self.origin = parent.origin + view.frame.origin
        self.visible = parent.visible.intersection(Rect(origin: origin, size: view.bounds.size))
    }
    
    deinit {
        applyContext()
    }
    
    public func colorNormal()
    {
        attribute = view.colorScheme.normal
    }
    
    public func colorSelection()
    {
        attribute = view.hasFocus ? view.colorScheme.focus : view.colorScheme.normal
    }
    
    /**
     * Moves the drawing cursor position to the specified column and row.
     *
     * These values can be beyond the view's frame and will be updated as print commands are done
     *
     * - Parameter col: the new column where the cursor will be.
     * - Parameter row: the new row where the cursor will be.
     */
    public func goto(col: Int, row: Int)
    {
        self.pos = Point(x: col, y: row)
        posSet = false
    }
    
    /**
     * Moves the drawing cursor position to the specified point.
     *
     * These values can be beyond the view's frame and will be updated as print commands are done
     *
     * - Parameter to: the point that contains the new cursor position
     */
    public func go(to: Point)
    {
        self.pos = to
        posSet = false
    }
    
    // if necessary, sets the current attribute
    func applyContext()
    {
        // In the layer-backed model, attributes are applied per-cell during writes
        // We keep this to minimize changes; currently it is a no-op gate.
        if !attrSet { attrSet = true }
    }
    
    func add(rune: UnicodeScalar, maxWidth: Int)
    {
        if rune.value == 10 {
            pos.x = 0
            pos.y += 1
            return
        }
        // TODO: optimize, we can handle the visibility for rows before and later just do
        // columns rather than testing both.
        let wcw = termKitWcWidth(rune.value)
        let len = wcw >= 0 ? Int32(wcw) : 1
        let npos = pos.x + Int(len)
        
        if npos > maxWidth {
            // We are out of bounds, but the width might be larger than 1 cell
            // so we should draw a space
            while pos.x < maxWidth {
                // advance while filling with spaces within clipping
                if visible.contains(pos+origin) {
                    let abs = pos + origin
                    targetLayer.add(cell: Cell(ch: " ", attr: attribute), col: abs.x, row: abs.y)
                }
                pos.x += 1
            }
        } else {
            if visible.contains(pos+origin) {
                let abs = pos + origin
                let ch: Character = wcw == -1 ? "*" : Character(rune)
                targetLayer.add(cell: Cell(ch: ch, attr: attribute), col: abs.x, row: abs.y)
                // Handle double-width characters by inserting a null cell to the right if in bounds
                if wcw == 2 {
                    let nextCol = abs.x + 1
                    if nextCol < targetLayer.size.width {
                        targetLayer.add(cell: Cell(ch: "\u{0}", attr: attribute), col: nextCol, row: abs.y)
                    }
                }
                posSet = true
            }
            pos.x += Int(len)
        }
    }
    
    public func add(str: String)
    {
        let strScalars = str.unicodeScalars
        let maxWidth = view.bounds.width
        
        applyContext()
        for uscalar in strScalars {
            add(rune: uscalar, maxWidth: maxWidth)
        }
    }
    
    public func add(ch: Character)
    {
        let strScalars = ch.unicodeScalars
        let maxWidth = view.bounds.width
        
        applyContext()
        for uscalar in strScalars {
            add(rune: uscalar, maxWidth: maxWidth)
        }
    }
    
    public func add(rune: UnicodeScalar)
    {
        applyContext()
        add(rune: rune, maxWidth: view.bounds.width)
    }
    
    /**
     * Clears the view region with the current color.
     */
    public func clear(with: Character = " ")
    {
        applyContext()
        clear(view.bounds, with: with)
    }
    
    /// Clears the specified region in painter coordinates
    /// - Parameters:
    ///  - rect: the region to clear, the coordinates are relative to the view.
    ///  - with: Character to use to fill the cleared region, defaults to a whitespace.
    public func clear(_ rect: Rect, with: Character = " ")
    {
        let scalars = with.unicodeScalars
        applyContext()
        if scalars.count == 1, let s = scalars.first {
            let w = rect.width
            
            for line in rect.minY..<rect.maxY {
                goto(col: rect.minX, row: line)
                
                for _ in 0..<w {
                    add(rune: s, maxWidth: w)
                }
            }
        } else {
            let w = rect.width
            for line in rect.minY..<rect.maxY {
                goto(col: rect.minX, row: line)
                
                for _ in 0..<w {
                    add(ch: with)
                }
            }
        }
    }
    
    /// Clears a region of the view with spaces, the parameter are in view coordinates
    /// - Parameters:
    ///   - left: Left column
    ///   - top: Top row
    ///   - right: Right column
    ///   - bottom: Bottom row
    func clearRegion(left: Int, top: Int, right: Int, bottom: Int)
    {
        applyContext()
        let lstr = String(repeating: " ", count: right-left)
        for row in top..<bottom {
            goto(col: left, row: row)
            add(str: lstr)
        }
    }
    
    /**
     * Draws a frame on the specified region with the specified padding around the frame.
     * - Parameter region: Region where the frame will be drawn.
     * - Parameter padding: Padding to add on the sides
     * - Parameter fill: If set to `true` it will clear the contents with the current color, otherwise the contents will be left untouched.
     */
    public func drawFrame(_ region: Rect, padding: Int, fill: Bool, double: Bool = false)
    {
        let width = region.width;
        let height = region.height;
        
        let fwidth = width - padding * 2;
        let fheight = height - 1 - padding;
        
        goto(col: region.minX, row: region.minY)
        
        if padding > 0 {
            for _ in 0..<padding {
                for _ in 0..<width {
                    add(ch: " ")
                }
            }
        }
        goto(col: region.minX, row: region.minY + padding);
        for _ in 0..<padding {
            add(ch: " ")
        }
        add(rune: double ? driver.doubleUlCorner : driver.ulCorner)
        for _ in 0..<(fwidth-2) {
            add(rune: double ? driver.doubleHLine : driver.hLine);
        }
        add(rune: double ? driver.doubleUrCorner : driver.urCorner);
        for _ in 0..<padding {
            add(ch: " ")
        }
        
        if fheight > 1+padding {
            for b in (1+padding)..<fheight {
                goto(col: region.minX, row: region.minY + b);
                for _ in 0..<padding {
                    add(ch: " ")
                }
                add(rune: double ? driver.doubleVLine : driver.vLine);
                if fill {
                    for _ in 1..<(fwidth-1){
                        add(ch: " ")
                    }
                } else {
                    goto(col: region.minX + padding + fwidth - 1, row: region.minY + b)
                }
                add(rune: double ? driver.doubleVLine : driver.vLine);
                for _ in 0..<padding {
                    add(ch: " ")
                }
            }
        }
        goto(col: region.minX, row: region.minY + fheight)
        for _ in 0..<padding {
            add(ch: " ")
        }
        add(rune: double ? driver.doubleLlCorner : driver.llCorner);
        for _ in 0..<(fwidth - 2) {
            add(rune: double ? driver.doubleHLine : driver.hLine);
        }
        add(rune: double ? driver.doubleLrCorner : driver.lrCorner);
        for _ in 0..<padding {
            add(ch: " ")
        }
        if padding > 0 {
            goto(col: region.minX, row: region.minY + height - padding);
            for _ in 0..<padding {
                for _ in 0..<width {
                    add(ch: " ")
                }
            }
        }
    }
    
    /**
     * Utility function to draw strings that contains a hotkey using the two specified colors
     * - Parameter text: String to display, the underscoore before a letter flags the next letter as the hotkey.
     * - Parameter hotColor: the color to use for the hotkey
     * - Parameter normalColor: the color to use for the normal color
     */
    public func drawHotString(text: String, hotColor: Attribute, normalColor: Attribute)
    {
        attribute = normalColor
        
        for ch in text {
            if ch == "_" {
                attribute = hotColor
            } else {
                add(str: String(ch))
                attribute = normalColor
            }
        }
    }
    
    /**
     * Utility function to draw strings that contains a hotkey using a colorscheme and the "focused" state.
     * - Parameter text: String to display, the underscoore before a letter flags the next letter as the hotkey.
     * - Parameter focused: If set to `true` this uses the focused colors from the color scheme, otherwise the regular ones.
     * - Parameter scheme: The color scheme to use
     */
    public func drawHotString(text: String, focused: Bool, scheme: ColorScheme)
    {
        if focused {
            drawHotString(text: text, hotColor: scheme.hotFocus, normalColor: scheme.focus)
        } else {
            drawHotString(text: text, hotColor: scheme.hotNormal, normalColor: scheme.normal)
        }
    }
    
    public func debug() {
        // No-op in layer-backed painter; kept for API compatibility
    }

    /// Draws the contents of a source layer onto the painter's target layer at a specific origin.
    public func draw(layer sourceLayer: Layer, at origin: Point) {
        // Compute destination rect and clip against visible
        let srcSize = sourceLayer.size
        guard srcSize.width > 0 && srcSize.height > 0 else { return }
        let destRect = Rect(origin: origin, size: srcSize)
        let clip = visible.intersection(destRect)
        if clip.isEmpty { return }
        // Calculate source start offset for each row relative to clip
        let srcStart = Point(x: clip.minX - destRect.minX, y: clip.minY - destRect.minY)
        for row in 0..<clip.height {
            let destY = clip.minY + row
            let srcY = srcStart.y + row
            // Mark destination row dirty
            if destY >= 0 && destY < targetLayer.size.height {
                targetLayer.dirtyRows[destY] = true
            }
            let destOffset = destY * targetLayer.size.width + clip.minX
            let srcOffset = srcY * srcSize.width + srcStart.x
            let count = clip.width
            targetLayer.store.replaceSubrange(destOffset..<(destOffset+count), with: sourceLayer.store[srcOffset..<(srcOffset+count)])
        }
    }
}

// TopDriver proxy is no longer needed in the layer-backed rendering model
