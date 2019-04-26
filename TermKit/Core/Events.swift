//
//  Events.swift - Core definitions for events
//  TermKit
//
//  Created by Miguel de Icaza on 4/9/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * The Key enumeration contains special encoding for some keys, but can also
 * encode all the unicode values that can be passed.
 *
 * If the SpecialMask is set, then the value is that of the special mask,
 * otherwise, the value is the one of the lower bits (as extracted by CharMask)
 *
 *  Control keys are the values between 1 and 26 corresponding to Control-A to Control-Z
 *
 * UnicodeScalars are also stored here, the letter 'A" for example is encoded as a value 65 (not surfaced in the enum).
 */
public enum Key {
    case ControlSpace
    /// The key code for the user pressing Control-A
    case ControlA
    /// The key code for the user pressing Control-B
    case ControlB
    /// The key code for the user pressing Control-C
    case ControlC
    /// The key code for the user pressing Control-D
    case ControlD
    /// The key code for the user pressing Control-E
    case ControlE
    /// The key code for the user pressing Control-F
    case ControlF
    /// The key code for the user pressing Control-G
    case ControlG
    /// The key code for the user pressing Control-H
    case ControlH
    static var Backspace : Key {
        get {
            return ControlH
        }
    }

    /// The key code for the user pressing Control-I
    case ControlI
    /// The key code for the user pressing Control-J
    case ControlJ
    
    static var Return : Key {
        get {
            return ControlJ
        }
    }
    /// The key code for the user pressing Control-K
    case ControlK
    /// The key code for the user pressing Control-L
    case ControlL
    /// The key code for the user pressing Control-M
    case ControlM
    /// The key code for the user pressing Control-N
    case ControlN
    /// The key code for the user pressing Control-O
    case ControlO
    /// The key code for the user pressing Control-P
    case ControlP
    /// The key code for the user pressing Control-Q
    case ControlQ
    /// The key code for the user pressing Control-R
    case ControlR
    /// The key code for the user pressing Control-S
    case ControlS
    /// The key code for the user pressing Control-T
    case ControlT
    /// The key code for the user pressing Control-U
    case ControlU
    /// The key code for the user pressing Control-V
    case ControlV
    /// The key code for the user pressing Control-W
    case ControlW
    /// The key code for the user pressing Control-X
    case ControlX
    /// The key code for the user pressing Control-Y
    case ControlY
    /// The key code for the user pressing Control-Z
    case ControlZ
    
    /// The  key code for the user pressing the ESC key
    case Esc
    
    // Value 28, Field Separator, ^\
    case FS
    
    // Value 29, Group Separator, ^]
    case GS
    
    // Value 30, Record Separator ^^
    case RS
    
    // Value 31, Unit Separator, ^_
    case US
    
    /// The keycode for the user pressing the delete key
    case Delete
    
    /// Cursor up key pressed
    case CursorUp
    /// Cursor down key pressed
    case CursorDown
    /// Cursor left key pressed
    case CursorLeft
    /// Cursor right key pressed
    case CursorRight
    /// Page up key pressed
    case PageUp
    /// Page down key pressed
    case PageDown
    /// Home key pressed
    case Home
    /// End key pressed
    case End
    /// Delete character key
    case DeleteChar
    /// Insert character key
    case InsertChar
    /// The F1 Key
    case F1
    /// The F2 Key
    case F2
    /// The F3 Key
    case F3
    /// The F4 Key
    case F4
    /// The F5 Key
    case F5
    /// The F6 Key
    case F6
    /// The F7 Key
    case F7
    /// The F8 Key
    case F8
    /// The F9 Key
    case F9
    /// The F10 Key
    case F10
    /// The shift-tab key
    case Backtab
    
    case Letter (Character)
    case Unknown
}

/**
 * Describes a key event, this includes the key value, and there are two convenience properties isAlt and isControl
 */
public struct KeyEvent {
    /// Symbolic definition of the key
    public var key : Key
    var _isControl, _isAlt : Bool
    
    /// Gets a value indicating whether the Alt key was pressed (real or synthesized)
    public var isAlt : Bool {
        get {
            return  _isAlt
        }
    }
    
    /// Determines whether the value is a control key (a shortcut to avoid testing all the Control values)
    public var isControl : Bool {
        get {
            return _isControl
        }
    }
    
    /// Initializes the KeyEvent structure
    init (key : Key, isAlt: Bool = false, isControl : Bool = false)
    {
        self.key = key
        self._isAlt = isAlt
        self._isControl = isControl
    }
}

/**
 * Flags for a mouse event
 */
public struct MouseFlags : OptionSet {
    public let rawValue : UInt
    
    public init (rawValue :UInt)
    {
        self.rawValue = rawValue
    }
    
    static let button1Pressed        = MouseFlags(rawValue: 0x2)
    static let button1Released       = MouseFlags(rawValue: 0x1)
    static let button1Clicked        = MouseFlags(rawValue: 0x4)
    static let button1DoubleClicked  = MouseFlags(rawValue: 0x8)
    static let button1TripleClicked  = MouseFlags(rawValue: 0x10)
    static let button2Pressed        = MouseFlags(rawValue: 0x80)
    static let button2Released       = MouseFlags(rawValue: 0x40)
    static let button2Clicked        = MouseFlags(rawValue: 0x100)
    static let button2DoubleClicked  = MouseFlags(rawValue: 0x200)
    static let button2TrippleClicked = MouseFlags(rawValue: 0x400)
    static let button3Pressed        = MouseFlags(rawValue: 0x2000)
    static let button3Released       = MouseFlags(rawValue: 0x1000)
    static let button3Clicked        = MouseFlags(rawValue: 0x4000)
    static let button3DoubleClicked  = MouseFlags(rawValue: 0x8000)
    static let button3TripleClicked  = MouseFlags(rawValue: 0x10000)
    static let button4Pressed        = MouseFlags(rawValue: 0x80000)
    static let button4Released       = MouseFlags(rawValue: 0x40000)
    static let button4Clicked        = MouseFlags(rawValue: 0x100000)
    static let button4DoubleClicked  = MouseFlags(rawValue: 0x200000)
    static let button4TripleClicked = MouseFlags(rawValue:  0x400000)
    
    /// The shift key was pressed when the mouse event was produced
    static let buttonShift = MouseFlags(rawValue: 0x2000000)
    /// The control key was pressed when the mouse event was produced
    static let buttonCtrl  = MouseFlags(rawValue: 0x1000000)
    /// The alt key was pressed when the mouse event was produced
    static let buttonAlt   = MouseFlags(rawValue: 0x4000000)
    
    static let mousePosition = MouseFlags (rawValue: 0x8000000)
}

/**
 * Describes a mouse event
 */
public struct MouseEvent {
    /// The X (column) location for the mouse event
    public var x : Int
    /// The Y (row) location for the mouse event
    public var y : Int
    
    /// The event flags
    public var flags : MouseFlags

    init (x: Int, y:Int, flags: MouseFlags)
    {
        self.x = x
        self.y = y
        self.flags = flags
    }
}
