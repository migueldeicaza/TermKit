//
//  RadioGroup.swift
//  
//
//  Created by Miguel de Icaza on 3/13/21.
//

import Foundation

/// Describes an orientation
public enum Orientation {
    /// Use horizontal orientation
    case horizontal
    /// Use vertical  orientation
    case vertical
}

open class RadioGroup: View {
    var _selected: Int? = nil
    var cursor: Int = 0
    
    /// The index of the currently selected item, or nil if none, to be called by the user
    /// invoking this method does not invoke the selection changed callback.
    public var selected: Int? {
        get {
            return _selected
        }
        set {
            guard let intv = newValue else {
                _selected = nil
                setNeedsDisplay()
                return
            }
            guard intv < radioLabels.count else {
                return
            }
            if _selected != intv {
                _selected = intv
                setNeedsDisplay()
            }
        }
    }
    
    func setSelected (new: Int)
    {
        if new == selected {
            return
        }
        let old = selected
        
        // this triggers setNeedsDisplay
        selected = new
        if let cb = selectionChanged {
            cb (self, old, new)
        }
    }
    

    /// The labels displayed for this radio group
    public private (set) var radioLabels: [String]
    /// The orientation in which this radio group is shown
    public private (set) var orientation: Orientation

    /// Callback invoked when the selection has changed, it passes the previous
    /// selection value, and the new selection value
    public var selectionChanged: ((_ source: RadioGroup, _ previousSelection: Int?, _ newSelection: Int?) -> ())? = nil
    
    /// Initializes a new instance of the `RadioGroup`
    /// - Parameters:
    ///   - labels: The radio labels; an array of strings that can contain hotkeys using an underscore before the letter.
    ///   - selected: The index of the item to be selected, the value is clamped to the number of items,
    ///   can be nil if no value should be selected by default
    ///   - The orientation to use for the view
    public init (labels: [String], selected: Int? = 0, orientation: Orientation = .vertical)
    {
        self.radioLabels = labels
        self._selected = selected
        self.cursor = selected ?? 0
        self.orientation = orientation
        super.init ()
        var maxLen = 0
        var linearLen = 0
        for lab in labels {
            // Approximation, should really count 
            let labLen = lab.getCellCountWithoutMarkup ()
            maxLen = max (maxLen, labLen)
            linearLen += 5 + labLen
        }
        switch orientation {
        case .horizontal:
            height = Dim.sized (1)
            width = Dim.sized (linearLen)
        case .vertical:
            height = Dim.sized (labels.count)
            width = Dim.sized (maxLen + 4) // "( ) " + text
        }
        
        canFocus = true
    }
    
    public override func redraw(region: Rect, painter: Painter) {
        painter.attribute = colorScheme!.normal
        painter.clear()
        
        switch  orientation {
        case .horizontal:
            print ("Need to implement redraw for horizontal")
            abort ()
            break
        case .vertical:
            for line in 0..<radioLabels.count {
                painter.goto(col: 0, row: line)

                painter.attribute = hasFocus && (line == cursor) ? colorScheme.focus : colorScheme.normal
                painter.add(str: line == selected ? "\(driver.radioOn) " : "\(driver.radioOff) ")
                painter.drawHotString(
                    text: radioLabels[line],
                    focused: hasFocus && line == cursor,
                    scheme: colorScheme!)
            }
        }
    }
    
    public override func positionCursor() {
        switch orientation {
        case .vertical:
            moveTo(col: 1, row: cursor)
        case .horizontal:
            print ("Need to implement positionCursor for horizontal")
            abort()
        }
    }

    public override func processColdKey(event: KeyEvent) -> Bool {
        switch event.key {
        case let .letter(char) where char.isLetter || char.isNumber:
            let upperChar = char.uppercased()
            
            for i in 0..<radioLabels.count {
                let label = radioLabels [i]
                var probe = false
                for ch in label {
                    if ch == "_" {
                        probe = true
                        continue
                    }
                    if probe && ch.uppercased() == upperChar {
                        setSelected(new: i)
                        return true
                    }
                    probe = false
                }
            }
            return false
        default:
            return false
        }
    }
    
    public override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .cursorUp:
            if cursor > 0 {
                cursor -= 1
                setNeedsDisplay()
                return true
            }
        case .cursorDown:
            if cursor + 1 < radioLabels.count {
                cursor += 1
                setNeedsDisplay()
                return true
            }
        case .letter(" "):
            setSelected(new: cursor)
            return true
        default:
            break
        }
        return super.processKey(event: event)
    }
    
    public override func mouseEvent(event: MouseEvent) -> Bool {
        if event.flags == .button1Clicked {
            if canFocus {
                if !hasFocus {
                    superview!.setFocus (self)
                    setNeedsDisplay()
                }
            }
            switch orientation {
            case .horizontal:
                print ("Need to implement mouseEvent for horizontal")
                abort()
            case .vertical:
                if event.pos.y < radioLabels.count {
                    setSelected(new: event.pos.y)
                    cursor = event.pos.y
                }
            }
            
            return true
        }
        return false
    }
    
    open override var debugDescription: String {
        return "ProgressBar (\(super.debugDescription))"
    }
}
