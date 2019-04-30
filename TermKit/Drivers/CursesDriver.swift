//
//  CursesDriver.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/8/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

// This is a lame hack to call into a global that has a name that clashes with a class member name
class LameHack {
    static func doRefresh ()
    {
        refresh ();
    }
}

class CursesDriver : ConsoleDriver {
    var ccol : Int32 = 0
    var crow : Int32 = 0
    var needMove : Bool = false
    var sync : Bool = false
    var cursesWindow : OpaquePointer!
    
    
    // Swift ncurses does not bind these
    let A_NORMAL    : Int32 = 0x0;
    let A_STANDOUT  : Int32 = 0x10000;
    let A_UNDERLINE : Int32 = 0x20000
    let A_REVERSE   : Int32 = 0x40000
    let A_BLINK     : Int32 = 0x80000
    let A_DIM       : Int32 = 0x100000
    let A_BOLD      : Int32 = 0x200000
    let A_PROTECT   : Int32 = 0x1000000
    let A_INVIS     : Int32 = 0x800000
    
    let cursesButton1Pressed : Int32 = 0x2
    let cursesButton1Released : Int32 = 0x1
    let cursesButton1Clicked : Int32 = 0x4
    let cursesButton1DoubleClicked : Int32 = 0x8
    let cursesButton1TripleClicked : Int32 = 0x10
    let cursesButton2Pressed : Int32 = 0x80
    let cursesButton2Released : Int32 = 0x40
    let cursesButton2Clicked : Int32 = 0x100
    let cursesButton2DoubleClicked : Int32 = 0x200
    let cursesButton2TrippleClicked : Int32 = 0x400
    let cursesButton3Pressed : Int32 = 0x2000
    let cursesButton3Released : Int32 = 0x1000
    let cursesButton3Clicked : Int32 = 0x4000
    let cursesButton3DoubleClicked : Int32 = 0x8000
    let cursesButton3TripleClicked : Int32 = 0x10000
    let cursesButton4Pressed : Int32 = 0x80000
    let cursesButton4Released : Int32 = 0x40000
    let cursesButton4Clicked : Int32 = 0x100000
    let cursesButton4DoubleClicked : Int32 = 0x200000
    let cursesButton4TripleClicked : Int32 = 0x400000
    let cursesButtonShift : Int32 = 0x2000000
    let cursesButtonCtrl : Int32 = 0x1000000
    let cursesButtonAlt : Int32 = 0x4000000
    let cursesReportMousePosition : Int32 = 0x8000000
    let cursesAllEvents : Int32 = 0x7ffffff

    var oldMouseEvents : mmask_t
    var mouseEvents : mmask_t

    typealias get_wch_def = @convention(c) (UnsafeMutablePointer<Int32>) -> Int
    
    // This is wrong
    typealias add_wch_def = @convention(c) (UnsafeMutablePointer<CLong>) -> CInt
    
    // Dynamically loaded definitions, because Darwin.ncurses does not bring these
    var get_wch_fn : get_wch_def? = nil
    var add_wch_fn : add_wch_def? = nil
    

    override init ()
    {
        oldMouseEvents = 0
        mouseEvents = 0
        super.init ()
        
        ccol = 0
        crow = 0
        
        setlocale(LC_ALL, "")
        // Setup curses
        cursesWindow = initscr()
        raw ()
        noecho ()
        keypad(cursesWindow, true)
    
        mouseEvents = mousemask (mmask_t (UInt (cursesAllEvents | cursesReportMousePosition)), &oldMouseEvents)
        if (mouseEvents & UInt (cursesReportMousePosition)) != 0 {
            startReportingMouseMoves()
        }
        start_color()
        noecho()
        curs_set (0)
        init_pair (0, Int16(COLOR_BLACK), Int16(COLOR_GREEN))
        keypad (stdscr, true)
        setupInput ()
        
        cols = Int (getmaxx (stdscr))
        rows = Int (getmaxy (stdscr))
        
        clear ();
        clip = Rect (x: 0, y: 0, width: cols, height: rows)

        let rtld_default = UnsafeMutableRawPointer(bitPattern: -2)
        
        let get_wch_ptr = dlsym (rtld_default, "get_wch")
        get_wch_fn = unsafeBitCast(get_wch_ptr, to: get_wch_def.self)
        
        let add_wch_ptr = dlsym (rtld_default, "add_wch")
        add_wch_fn = unsafeBitCast(get_wch_ptr, to: add_wch_def.self)
        selectColors()
    }
    
    // Converts an NCurses MEVENT to TermKit.MouseEvent
    func toAppMouseEvent (_ me: MEVENT) -> MouseEvent
    {
        // We conveniently made all of the MouseEvent defines match the curses defines
        return MouseEvent (x: Int(me.x), y: Int(me.y), flags: MouseFlags (rawValue: UInt(me.bstate)))
    }
    
    // Converts an NCurses key event into an application Key
    func toAppKeyEvent (_ ck: Int32) -> Key
    {
        switch (ck){
            // Control sequences
        case 0: return Key.ControlSpace
        case 1: return Key.ControlA
        case 2: return Key.ControlB
        case 3: return Key.ControlC
        case 4: return Key.ControlD
        case 5: return Key.ControlE
        case 6: return Key.ControlF
        case 7: return Key.ControlG
        case 8: return Key.ControlH
        case 9: return Key.ControlI
        case 10: return Key.ControlJ
        case 11: return Key.ControlK
        case 12: return Key.ControlL
        case 13: return Key.ControlM
        case 14: return Key.ControlN
        case 15: return Key.ControlO
        case 16: return Key.ControlP
        case 17: return Key.ControlQ
        case 18: return Key.ControlR
        case 19: return Key.ControlS
        case 20: return Key.ControlT
        case 21: return Key.ControlU
        case 22: return Key.ControlV
        case 23: return Key.ControlW
        case 24: return Key.ControlX
        case 25: return Key.ControlY
        case 26: return Key.ControlZ
        case 27: return Key.Esc
        case 28: return Key.FS
        case 29: return Key.GS
        case 30: return Key.RS
        case 31: return Key.US
        case 127: return Key.Delete
        case KEY_F0+1: return Key.F1
        case KEY_F0+2: return Key.F2
        case KEY_F0+3: return Key.F3
        case KEY_F0+4: return Key.F4
        case KEY_F0+5: return Key.F5
        case KEY_F0+6: return Key.F6
        case KEY_F0+7: return Key.F7
        case KEY_F0+8: return Key.F8
        case KEY_F0+9: return Key.F9
        case KEY_F0+10: return Key.F10
        case KEY_UP: return Key.CursorUp
        case KEY_DOWN: return Key.CursorDown
        case KEY_LEFT: return Key.CursorLeft
        case KEY_RIGHT: return Key.CursorRight
        case KEY_HOME: return Key.Home
        case KEY_END: return Key.End
        case KEY_NPAGE: return Key.PageDown
        case KEY_PPAGE: return Key.PageUp
        case KEY_DC: return Key.DeleteChar
        case KEY_IC: return Key.InsertChar
        case KEY_BTAB: return Key.Backtab
        case KEY_BACKSPACE: return Key.Backspace
        default:
            if let us = Unicode.Scalar (UInt32 (ck)) {
                return Key.Letter(Character.init(us))
            } else {
                return Key.Unknown
            }
        }
    }
    
    //
    // Invoked when there is data available on standard input, takes the ncurses input
    // and creates a mouse or keyboard event and feeds it to the Application
    
    func inputReadCallback (input: FileHandle)
    {
        var result : Int32 = 0
        let status = get_wch_fn! (&result)
        if status == ERR {
            return
        }
        if status == KEY_CODE_YES {
            if result == KEY_RESIZE {
                if LINES != rows || COLS != cols {
                    Application.terminalResized()
                    return
                }
            }
            if result == KEY_MOUSE {
                var mouseEvent : MEVENT = MEVENT(id: 0, x: 0, y: 0, z: 0, bstate: 0)
                getmouse(&mouseEvent);
                Application.processMouseEvent(mouseEvent: toAppMouseEvent (mouseEvent))
                return
            }
            Application.processKeyEvent(event: KeyEvent(key: toAppKeyEvent (result)))
            return
        }
        
        // Special handling for ESC, we want to try to catch ESC+letter to simulate alt-letter, as well as alt-FKey
        if result == 27 {
            timeout (200)
            let status2 = get_wch_fn! (&result)
            timeout (-1)
            var ke : KeyEvent
            let isControl = result >= 0 && result < 32
            
            if status2 == KEY_CODE_YES {
                ke = KeyEvent (key: toAppKeyEvent(result), isAlt: true, isControl: isControl)
            } else {
                if status2 == 0 {
                    switch result {
                    case 48: // ESC-0 is F10
                        ke = KeyEvent (key: Key.F10)
                    case 49: // ESC-1 is F1
                        ke = KeyEvent (key: Key.F1)
                    case 50:
                        ke = KeyEvent (key: Key.F2)
                    case 51:
                        ke = KeyEvent (key: Key.F3)
                    case 52:
                        ke = KeyEvent (key: Key.F4)
                    case 53:
                        ke = KeyEvent (key: Key.F5)
                    case 54:
                        ke = KeyEvent (key: Key.F6)
                    case 55:
                        ke = KeyEvent (key: Key.F7)
                    case 56:
                        ke = KeyEvent (key: Key.F8)
                    case 57:
                        ke = KeyEvent (key: Key.F9)
                    case 27: // ESC+ESC is just ESC
                        ke = KeyEvent (key: Key.Esc)
                    default:
                        ke = KeyEvent (key: toAppKeyEvent(result), isAlt: true, isControl: isControl)
                    }
                } else {
                    // Got nothing, just pass the escape
                    ke = KeyEvent (key: Key.Esc)
                }
            }
            Application.processKeyEvent(event: ke)
        } else {
            // Pass the rest of the keystrokes
            Application.processKeyEvent(event: KeyEvent(key: toAppKeyEvent(result)))
        }
        
    }
    
    func setupInput ()
    {
        timeout (-1)
        FileHandle.standardInput.readabilityHandler = inputReadCallback(input:)
    }
    
    public override func moveTo (col :Int, row: Int)
    {
        ccol = Int32 (col)
        crow = Int32 (row)
        if clip.contains (x: col, y: row) {
            move (Int32 (row), Int32 (col))
            needMove = false
        } else {
            move (Int32 (clip.minY), Int32 (clip.minX))
            needMove = true
        }
    }
    
    //
    // Should only be used with non-composed runes, when in doubt, use addCharacter
    //
    public override func addRune (_ rune: rune)
    {
        if clip.contains (x: Int (ccol), y: Int (crow)) {
            if needMove {
                move (crow, ccol)
                needMove = false
            }
            addstr(String (rune))
        } else {
            needMove = true
        }
        if sync {
            refresh ()
        }
        ccol += 1
    }
    
    public override func addCharacter (_ char: Character)
    {
        if clip.contains (x: Int (ccol), y: Int (crow)) {
            if needMove {
                move (crow, ccol)
                needMove = false
            }
            for rune in char.unicodeScalars {
                addch (UInt32 (rune))
            }
        } else {
            needMove = true
        }
        if sync {
            refresh ()
        }
        ccol += 1
    }
    
    func selectBwColors ()
    {
        let base = ColorScheme(normal: Attribute (A_NORMAL), focus: Attribute(A_REVERSE), hotNormal: Attribute(A_BOLD), hotFocus: Attribute (A_BOLD | A_REVERSE))
        let menu = ColorScheme(normal: Attribute (A_REVERSE), focus: Attribute (A_NORMAL), hotNormal: Attribute(A_BOLD), hotFocus: Attribute(A_NORMAL))
        let dialog = ColorScheme(normal: Attribute(A_REVERSE), focus: Attribute(A_NORMAL), hotNormal: Attribute(A_BOLD), hotFocus: Attribute(A_NORMAL))
        let error = ColorScheme(normal: Attribute(A_BOLD), focus: Attribute(A_BOLD|A_REVERSE), hotNormal: Attribute(A_BOLD|A_REVERSE), hotFocus: Attribute (A_REVERSE))
        
        Colors._base = base
        Colors._menu = menu
        Colors._dialog = dialog
        Colors._error = error
    }
    
    public override func colorSupport () -> ColorSupport
    {
        if (!has_colors()) {
            return .BlackAndWhite
        }
        if can_change_color() {
            return .RgbColors
        }
        return .SixteenColors
    }
    
    static var lastColorPair : Int16 = 16
    
    func mkAttr (_ colors : (Int32, Int32), bold : Bool = false) -> Attribute
    {
        CursesDriver.lastColorPair += 1
        init_pair(CursesDriver.lastColorPair, Int16(colors.0), Int16(colors.1))
        return Attribute(Int32 (CursesDriver.lastColorPair * 256) | (bold ? A_BOLD : 0));

    }
    
    func selectColors ()
    {
        let base = ColorScheme(normal:    mkAttr((COLOR_WHITE, COLOR_BLUE)),
                               focus:     mkAttr((COLOR_BLACK,COLOR_CYAN)),
                               hotNormal: mkAttr((COLOR_YELLOW, COLOR_BLUE), bold: true),
                               hotFocus:  mkAttr((COLOR_YELLOW, COLOR_CYAN), bold: true))
        
        let menu = ColorScheme(normal:    mkAttr((COLOR_YELLOW, COLOR_BLACK), bold: true),
                               focus:     mkAttr((COLOR_WHITE,  COLOR_BLACK), bold: true),
                               hotNormal: mkAttr((COLOR_YELLOW, COLOR_CYAN), bold: true),
                               hotFocus:  mkAttr((COLOR_WHITE,  COLOR_CYAN), bold: true))

        let dialog = ColorScheme(normal:    mkAttr((COLOR_BLACK, COLOR_WHITE)),
                                 focus:     mkAttr((COLOR_BLACK,COLOR_CYAN)),
                                 hotNormal: mkAttr((COLOR_BLUE, COLOR_WHITE)),
                                 hotFocus:  mkAttr((COLOR_BLUE, COLOR_CYAN)))
        
        let error = ColorScheme(normal:   mkAttr((COLOR_WHITE, COLOR_RED), bold: true),
                               focus:     mkAttr((COLOR_BLACK, COLOR_WHITE)),
                               hotNormal: mkAttr((COLOR_YELLOW, COLOR_RED), bold: true),
                               hotFocus:  mkAttr((COLOR_YELLOW, COLOR_RED), bold: true))
     
        Colors._base = base
        Colors._menu = menu
        Colors._dialog = dialog
        Colors._error = error
    }
    
    func mapColor (_ color: Color) -> (Int32, Bool)
    {
        switch color {
        case .Black:
            return (COLOR_BLACK, false)
        case .Blue:
            return (COLOR_BLUE, false)
        case .Green:
            return (COLOR_GREEN, false)
        case .Cyan:
            return (COLOR_CYAN, false)
        case .Red:
            return (COLOR_RED, false)
        case .Magenta:
            return (COLOR_MAGENTA, false)
        case .Brown:
            return (COLOR_YELLOW, false)
        case .Gray:
            return (COLOR_WHITE, false)
        case .DarkGray:
            return (COLOR_BLACK, true)
        case .BrightBlue:
            return (COLOR_BLUE, true)
        case .BrightGreen:
            return (COLOR_GREEN, true)
        case .BrightCyan:
            return (COLOR_CYAN, true)
        case .BrightRed:
            return (COLOR_RED, true)
        case .BrightMagenta:
            return (COLOR_MAGENTA, true)
        case .BrightYellow:
            return (COLOR_YELLOW, true)
        case .White:
            return (COLOR_WHITE, true)
        }
    }
    
    public override func makeAttribute(fore: Color, back: Color) -> Attribute
    {
        let (fa, bold) = mapColor (fore)
        let (ba, _) = mapColor (back)
        
        return mkAttr ((fa, ba), bold: bold)
    }
    public override func setAttribute (_ attr: Attribute)
    {
        attrset(attr.value)
    }
    
    public override func updateScreen ()
    {
        redrawwin(cursesWindow)
    }
    
    public override func refresh ()
    {
        LameHack.doRefresh()
    }
    
    public override func updateCursor() {
        LameHack.doRefresh()
    }
    
    public override func end ()
    {
        endwin()
    }
    
    func stopReportingMouseMoves ()
    {
        if (mouseEvents & UInt(cursesReportMousePosition)) != 0 {
            print ("\u{1b}[?1003l")
            fflush(stdout)
        }
    }
    
    func startReportingMouseMoves ()
    {
        if (mouseEvents & UInt (cursesReportMousePosition)) != 0 {
            print ("\u{1b}[?1003h")
            fflush (stdout)
        }
    }
    
    public override func suspend() -> Bool
    {
        stopReportingMouseMoves ()
        killpg (0, SIGTSTP)
        redrawwin(cursesWindow)
        LameHack.doRefresh()
        startReportingMouseMoves ()
        return true
    }
}
