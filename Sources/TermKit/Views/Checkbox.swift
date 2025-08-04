//
//  Checkbox.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/22/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * The Checkbox View shows an on/off toggle that the user can set
 *
 * Example:
 * ```
 * c = Checkbox ("Toggle me")
 * c.x = Pos.at (0)
 * c.y = Pos.at (0)
 * c.width = Dim(30)
 * c.height = Dim (1)
 * c.toggled = { check in ... }
 *
 * // Alternatively, you can use Combine to track the event changes:
 * var cancellable = c.toggledSubject.sink { cbox in }
 *
 * ```
 */
open class Checkbox: View {
    /// The state of the checkbox.
    public var checked: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Callback to invoke when the checkbox has been toggled, this allows a single
    /// callback to be registered.   For more complex scenarios, use `toggledSubject`
    /// which is a Combine subject.
    public var toggled: ((_ sender: Checkbox) ->  ())? = nil
    
    func updateHotkeySettings() {
        var i = 0
        hotPos = -1
        _hotKey = nil
        for c in text {
            if c.isUppercase {
                hotPos = i
                _hotKey = c
                return
            }
            i += c.cellSize()
        }
    }
    var hotPos: Int = -1
    
    var _hotKey: Character? = nil
    /// Used to override the hotkey to use for this checkbox
    public var hotKey: Character? {
        get {
            return _hotKey
        }
        set {
            _hotKey = newValue
            guard let hk = _hotKey else {
                hotPos = -1
                return
            }
            var p = 0
            for c in text {
                if c == hk {
                    hotPos = p
                    setNeedsDisplay()
                    return
                }
                p += 1
            }
            setNeedsDisplay()
        }
    }

    /// Sets the text for the checkbox, and will automatically pick the HotKey as the first
    /// uppercased letter in the string.  This can be later overwritten by setting HotKey
    /// directly.
    public var text: String {
        didSet {
            updateHotkeySettings ()
        }
    }
    
    public init (_ text: String, checked: Bool = false)
    {
        self.text = text
        self.checked = checked
        super.init ()
        self.height = Dim.sized(1)
        self.width = Dim.sized (text.cellCount () + 4)
        canFocus = true
        updateHotkeySettings()
    }
    
    open override func redraw(region: Rect, painter: Painter) {
        painter.attribute = hasFocus ? colorScheme.focus : colorScheme.normal
        painter.goto(col: 0, row: 0)
        painter.add(str: checked ? "[x]" : "[ ]")
        painter.goto (col: 4, row: 0)
        painter.attribute = colorScheme.normal
        painter.add (str: text)
        if let c = hotKey, hotPos != -1 {
            painter.goto (col: hotPos+4, row: 0)
            painter.attribute = colorScheme.hotNormal
            painter.add(str: String(c))
        }
    }

    open override func positionCursor() {
        moveTo (col: 1, row: 0)
    }
    
    func toggle ()
    {
        checked.toggle()
        if let t = toggled {
            t (self)
        }
        setNeedsDisplay()
    }
    
    open override func processHotKey(event: KeyEvent) -> Bool {
        if View.eventTriggersHotKey(event: event, hotKey: hotKey) {
            superview?.setFocus(self)
            toggle ()
            return true
        }
        return false
    }
    
    open override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .letter(" "):
            toggle ()
            return true
        default:
            return super.processKey(event: event)
        }
    }
    
    open override func mouseEvent(event: MouseEvent) -> Bool {
        if !event.flags.contains(.button1Clicked) {
            return false
        }
        superview?.setFocus(self)
        toggle ()
        return true
    }
    
    open override var debugDescription: String {
        return "Checkbox (\(super.debugDescription))"
    }

}
