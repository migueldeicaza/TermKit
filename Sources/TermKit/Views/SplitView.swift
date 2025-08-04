//
//  SplitView.swift - A view that splits its area between two subviews
//  TermKit
//
//  Created for TermKit
//

import Foundation

/// Defines how the split position is calculated
public enum SplitPosition {
    /// Fixed number of rows/columns for the first view
    case fixed(Int)
    /// Percentage of available space for the first view (0.0 to 1.0)
    case percentage(Double)
}

/// Orientation of the split
public enum SplitOrientation {
    /// Split horizontally (views are side by side)
    case horizontal
    /// Split vertically (views are stacked)
    case vertical
}

/// A view that contains two subviews separated by a draggable or fixed separator
public class SplitView: View {
    private var _firstView: View?
    private var _secondView: View?
    private var _orientation: SplitOrientation = .horizontal
    private var _splitPosition: SplitPosition = .percentage(0.5)
    private var _isDraggable = true
    private var _minimumPaneSize = 1
    private var _isResizing = false
    private var _dragStartPosition: Point?
    private var _dragStartSplitPosition: Int = 0
    
    /// The first (left/top) view
    public var firstView: View? {
        get { _firstView }
        set {
            if let oldView = _firstView {
                removeSubview(oldView)
            }
            _firstView = newValue
            if let newView = newValue {
                addSubview(newView)
            }
            setNeedsLayout()
        }
    }
    
    /// The second (right/bottom) view
    public var secondView: View? {
        get { _secondView }
        set {
            if let oldView = _secondView {
                removeSubview(oldView)
            }
            _secondView = newValue
            if let newView = newValue {
                addSubview(newView)
            }
            setNeedsLayout()
        }
    }
    
    /// The orientation of the split
    public var orientation: SplitOrientation {
        get { _orientation }
        set {
            _orientation = newValue
            setNeedsLayout()
        }
    }
    
    /// The position of the split
    public var splitPosition: SplitPosition {
        get { _splitPosition }
        set {
            _splitPosition = newValue
            setNeedsLayout()
        }
    }
    
    /// Whether the separator can be dragged to resize the panes
    public var isDraggable: Bool {
        get { _isDraggable }
        set {
            _isDraggable = newValue
        }
    }
    
    /// Minimum size for each pane when dragging
    public var minimumPaneSize: Int {
        get { _minimumPaneSize }
        set {
            _minimumPaneSize = max(1, newValue)
        }
    }
    
    /// Event raised when the split position changes
    public var splitPositionChanged: (() -> Void)?
    
    public override init(frame: Rect) {
        super.init(frame: frame)
        canFocus = false
        wantMousePositionReports = true
        wantContinuousButtonPressed = true
    }
    
    public override init() {
        super.init()
        canFocus = false
        wantMousePositionReports = true
        wantContinuousButtonPressed = true
    }
    
    /// Convenience initializer with first and second views
    public convenience init(first: View?, second: View?, orientation: SplitOrientation = .horizontal) {
        self.init()
        self.orientation = orientation
        self.firstView = first
        self.secondView = second
    }
    
    /// Calculate the actual split position in rows/columns
    private func calculateSplitPosition() -> Int {
        let totalSize = orientation == .horizontal ? frame.width : frame.height
        
        switch splitPosition {
        case .fixed(let value):
            return min(max(value, minimumPaneSize), totalSize - minimumPaneSize - 1)
        case .percentage(let pct):
            let position = Int(Double(totalSize) * max(0.0, min(1.0, pct)))
            return min(max(position, minimumPaneSize), totalSize - minimumPaneSize - 1)
        }
    }
    
    public override func layoutSubviews() throws {
        try super.layoutSubviews()
        
        let splitPos = calculateSplitPosition()
        
        switch orientation {
        case .horizontal:
            layoutHorizontal(splitPos: splitPos)
        case .vertical:
            layoutVertical(splitPos: splitPos)
        }
    }
    
    private func layoutHorizontal(splitPos: Int) {
        if let first = firstView {
            first.frame = Rect(x: 0, y: 0, width: splitPos, height: frame.height)
        }
        
        if let second = secondView {
            let secondX = splitPos + 1  // +1 for the separator
            second.frame = Rect(x: secondX, y: 0, width: frame.width - secondX, height: frame.height)
        }
    }
    
    private func layoutVertical(splitPos: Int) {
        if let first = firstView {
            first.frame = Rect(x: 0, y: 0, width: frame.width, height: splitPos)
        }
        
        if let second = secondView {
            let secondY = splitPos + 1  // +1 for the separator
            second.frame = Rect(x: 0, y: secondY, width: frame.width, height: frame.height - secondY)
        }
    }
    
    public override func redraw(region: Rect, painter p: Painter) {
        super.redraw(region: region, painter: p)
        
        let splitPos = calculateSplitPosition()
        
        p.attribute = colorScheme.normal
        
        switch orientation {
        case .horizontal:
            drawVerticalSeparator(at: splitPos, painter: p)
        case .vertical:
            drawHorizontalSeparator(at: splitPos, painter: p)
        }
    }
    
    private func drawVerticalSeparator(at x: Int, painter p: Painter) {
        // Draw the drag handle if draggable
        if isDraggable && frame.height > 0 {
            p.goto(col: x - 1, row: 0)
            p.add(str: "[o]")
        }
        
        // Draw the separator line
        for y in (isDraggable ? 1 : 0)..<frame.height {
            p.goto(col: x, row: y)
            p.add(ch: "│")
        }
    }
    
    private func drawHorizontalSeparator(at y: Int, painter p: Painter) {
        // Draw the drag handle if draggable
        if isDraggable && frame.width > 2 {
            p.goto(col: 0, row: y)
            p.add(str: _isResizing ? "[x]" : "[o]")
            
            // Draw the rest of the separator line
            for _ in 3..<frame.width {
                p.add(ch: "─")
            }
        } else {
            // Draw full separator line if not draggable
            p.goto(col: 0, row: y)
            for _ in 0..<frame.width {
                p.add(ch: "─")
            }
        }
    }
    
    public override func mouseEvent(event: MouseEvent) -> Bool {
        log("In MouseEvent \(isDraggable)")
        if !isDraggable {
            return super.mouseEvent(event: event)
        }
        
        let splitPos = calculateSplitPosition()
        let onSeparator = isPointOnSeparator(point: event.pos, splitPos: splitPos)
        log("Split: \(splitPos) onSep: \(onSeparator) flags: \(event.flags)")
        switch event.flags {
        case .button1Pressed:
            if onSeparator {
                _isResizing = true
                _dragStartPosition = event.pos
                _dragStartSplitPosition = splitPos
                return true
            }
            
        case .button1Released:
            if _isResizing {
                _isResizing = false
                _dragStartPosition = nil
                splitPositionChanged?()
                return true
            }
            
        case .mousePosition:
            if _isResizing {
                handleDrag(to: event.pos)
                return true
            } else if onSeparator {
                // TODO: Change cursor to resize cursor when hovering
                return true
            }
            
        default:
            break
        }
        
        return super.mouseEvent(event: event)
    }
    
    private func isPointOnSeparator(point: Point, splitPos: Int) -> Bool {
        switch orientation {
        case .horizontal:
            // Check if on separator line or on drag handle
            if point.x == splitPos {
                return true
            }
            // Check if clicking on drag handle [o] at the top
            if isDraggable && point.y == 0 && point.x >= splitPos - 1 && point.x <= splitPos + 1 {
                return true
            }
            return false
        case .vertical:
            // Check if on separator line or on drag handle
            if point.y == splitPos {
                return true
            }
            // Check if clicking on drag handle [o] at the left
            if isDraggable && point.x >= 0 && point.x <= 2 && point.y == splitPos {
                return true
            }
            return false
        }
    }
    
    private func handleDrag(to point: Point) {
        guard let startPos = _dragStartPosition else { return }
        
        let totalSize = orientation == .horizontal ? frame.width : frame.height
        let currentPos = orientation == .horizontal ? point.x : point.y
        let startDragPos = orientation == .horizontal ? startPos.x : startPos.y
        let delta = currentPos - startDragPos
        
        var newSplitPos = _dragStartSplitPosition + delta
        newSplitPos = max(minimumPaneSize, min(newSplitPos, totalSize - minimumPaneSize - 1))
        
        // Update the split position based on current type
        switch splitPosition {
        case .fixed(_):
            splitPosition = .fixed(newSplitPos)
        case .percentage(_):
            let newPercentage = Double(newSplitPos) / Double(totalSize)
            splitPosition = .percentage(newPercentage)
        }
        
        setNeedsLayout()
        setNeedsDisplay()
    }
    
    public override func setFocus(_ view: View?) {
        // If trying to focus this split view itself, focus one of the children
        if view == self || view == nil {
            // Try to focus the first view, then the second
            if let first = firstView, first.canFocus {
                super.setFocus(first)
            } else if let second = secondView, second.canFocus {
                super.setFocus(second)
            }
        } else {
            // Pass through to parent implementation
            super.setFocus(view)
        }
    }
    
    public override func processColdKey(event: KeyEvent) -> Bool {
        // Handle focus navigation between panes
        if event.key == .tab {
            if let focused = Application.current?.focused {
                if focused.isSubview(of: firstView), let secondView, secondView.canFocus == true {
                    secondView.setFocus(secondView)
                    return true
                } else if focused.isSubview(of: secondView), let firstView, firstView.canFocus == true {
                    firstView.setFocus(firstView)
                    return true
                }
            }
        }
        
        return super.processColdKey(event: event)
    }
}

// Helper extension to check if a view is a subview of another
extension View {
    func isSubview(of view: View?) -> Bool {
        guard let view = view else { return false }
        if self === view { return true }
        var current: View? = self
        while let parent = current?.superview {
            if parent === view { return true }
            current = parent
        }
        return false
    }
}
