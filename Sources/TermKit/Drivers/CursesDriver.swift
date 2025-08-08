//
//  CursesDriver.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/8/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation
import Curses

/// Turn this on to debug rendering problems, makes screen updates sync
var sync: Bool = false

// This is a lame hack to call into a global that has a name that clashes with a class member name
@available(macOS 15.0, *)
class LameHack {
    static func doRefresh ()
    {
        refresh ()
    }
}

@available(macOS 15.0, *)
class CursesDriver: ConsoleDriver {
    var ccol: Int32 = 0
    var crow: Int32 = 0
    var needMove: Bool = false
    
    var cursesWindow: OpaquePointer?
    
    // Swift ncurses does not bind these
    let A_NORMAL    : Int32 = 0x0
    let A_STANDOUT  : Int32 = 0x10000
    let A_UNDERLINE : Int32 = 0x20000
    let A_REVERSE   : Int32 = 0x40000
    let A_BLINK     : Int32 = 0x80000
    let A_DIM       : Int32 = 0x100000
    let A_BOLD      : Int32 = 0x200000
    let A_PROTECT   : Int32 = 0x1000000
    let A_INVIS     : Int32 = 0x800000
    
    let cursesButton1Pressed: Int32 = 0x2
    let cursesButton1Released: Int32 = 0x1
    let cursesButton1Clicked: Int32 = 0x4
    let cursesButton1DoubleClicked: Int32 = 0x8
    let cursesButton1TripleClicked: Int32 = 0x10
    let cursesButton2Pressed: Int32 = 0x80
    let cursesButton2Released: Int32 = 0x40
    let cursesButton2Clicked: Int32 = 0x100
    let cursesButton2DoubleClicked: Int32 = 0x200
    let cursesButton2TrippleClicked: Int32 = 0x400
    let cursesButton3Pressed: Int32 = 0x2000
    let cursesButton3Released: Int32 = 0x1000
    let cursesButton3Clicked: Int32 = 0x4000
    let cursesButton3DoubleClicked: Int32 = 0x8000
    let cursesButton3TripleClicked: Int32 = 0x10000
    let cursesButton4Pressed: Int32 = 0x80000
    let cursesButton4Released: Int32 = 0x40000
    let cursesButton4Clicked: Int32 = 0x100000
    let cursesButton4DoubleClicked: Int32 = 0x200000
    let cursesButton4TripleClicked: Int32 = 0x400000
    let cursesButtonShift: Int32 = 0x2000000
    let cursesButtonCtrl: Int32 = 0x1000000
    let cursesButtonAlt: Int32 = 0x4000000
    let cursesReportMousePosition: Int32 = 0x8000000
    let cursesAllEvents: Int32 = 0x7ffffff

    var oldMouseEvents: mmask_t
    var mouseEvents: mmask_t

    typealias get_wch_def = @convention(c) (UnsafeMutablePointer<Int32>) -> Int
    
    // Dynamically loaded definitions, because Darwin.ncurses does not bring these
    var get_wch_fn: get_wch_def? = nil

    var operational: Bool {
        get_wch_fn != nil
    }
    
    override init ()
    {
        oldMouseEvents = 0
        mouseEvents = 0
        super.init()
        
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
        curs_set (1)
        init_pair (0, Int16(COLOR_BLACK), Int16(COLOR_GREEN))
        keypad (stdscr, true)
        setupInput ()
        
        size = Size (width: Int (getmaxx (stdscr)), height: Int (getmaxy (stdscr)))
        
        clear ()

        let rtld_default = UnsafeMutableRawPointer(bitPattern: -2)

        // Fetch the pointers to get_wch and add_wch as the NCurses binding in Swift is missing them
        let get_wch_ptr = dlsym (rtld_default, "get_wch")
        if get_wch_ptr != nil {
            get_wch_fn = unsafeBitCast(get_wch_ptr, to: get_wch_def.self)
        }
        if has_colors() {
            if can_change_color() {
                colorSupport = .rgbColors
            } else {
                colorSupport = .ansi16
            }
        } else {
            colorSupport = .blackAndWhite
        }

        selectColors()
        UnixDriver.setupSigwinch {
            self.inputReadCallback(input: FileHandle.standardInput)
        }
    }
    
    open override var driverName: String {
        "CursesDriver"
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
        case 0: return Key.controlSpace
        case 1: return Key.controlA
        case 2: return Key.controlB
        case 3: return Key.controlC
        case 4: return Key.controlD
        case 5: return Key.controlE
        case 6: return Key.controlF
        case 7: return Key.controlG
        case 8: return Key.controlH
        case 9: return Key.controlI
        case 10: return Key.controlJ
        case 11: return Key.controlK
        case 12: return Key.controlL
        case 13: return Key.controlM
        case 14: return Key.controlN
        case 15: return Key.controlO
        case 16: return Key.controlP
        case 17: return Key.controlQ
        case 18: return Key.controlR
        case 19: return Key.controlS
        case 20: return Key.controlT
        case 21: return Key.controlU
        case 22: return Key.controlV
        case 23: return Key.controlW
        case 24: return Key.controlX
        case 25: return Key.controlY
        case 26: return Key.controlZ
        case 27: return Key.esc
        case 28: return Key.fs
        case 29: return Key.gs
        case 30: return Key.rs
        case 31: return Key.us
        case 127: return Key.delete
        case KEY_F0+1: return Key.f1
        case KEY_F0+2: return Key.f2
        case KEY_F0+3: return Key.f3
        case KEY_F0+4: return Key.f4
        case KEY_F0+5: return Key.f5
        case KEY_F0+6: return Key.f6
        case KEY_F0+7: return Key.f7
        case KEY_F0+8: return Key.f8
        case KEY_F0+9: return Key.f9
        case KEY_F0+10: return Key.f10
        case KEY_UP: return Key.cursorUp
        case KEY_DOWN: return Key.cursorDown
        case KEY_LEFT: return Key.cursorLeft
        case KEY_RIGHT: return Key.cursorRight
        case KEY_HOME: return Key.home
        case KEY_END: return Key.end
        case KEY_NPAGE: return Key.pageDown
        case KEY_PPAGE: return Key.pageUp
        case KEY_DC: return Key.deleteChar
        case KEY_IC: return Key.insertChar
        case KEY_BTAB: return Key.backtab
        case KEY_BACKSPACE: return Key.backspace
        case KEY_SLEFT: return Key.shiftCursorLeft
        case KEY_SRIGHT: return Key.shiftCursorRight
        default:
            if let us = Unicode.Scalar (UInt32 (ck)) {
                return Key.letter(Character.init(us))
            } else {
                return Key.Unknown
            }
        }
    }
    
    //
    // Invoked when there is data available on standard input, takes the ncurses input
    // and creates a mouse or keyboard event and feeds it to the Application
    var count = 0
    func inputReadCallback (input: FileHandle)
    {
        guard let get_wch_fn = get_wch_fn else {
            // Fallback to regular getch if get_wch is not available
            let ch = getch()
            if ch == ERR {
                return
            }
            // Since we don't have processInputChar, we'll create a basic key event
            let ke = KeyEvent(key: toAppKeyEvent(Int32(ch)))
            DispatchQueue.main.async {
                Application.processKeyEvent(event: ke)
            }
            return
        }
        var result: Int32 = 0
        let status = get_wch_fn (&result)
//        log("Key \(status) with result=\(result) at \(Date()) y=\(KEY_CODE_YES)")
        if status == ERR {
            return
        }
        if status == KEY_CODE_YES {
            if result == KEY_MAX {
                guard get_wch_fn(&result) == KEY_CODE_YES else { return }
            }
            if result == KEY_RESIZE {
                count += 1
                let newx = Int(getmaxx (stdscr))
                let newy = Int(getmaxy (stdscr))
//                log("Resize at \(count) git \(newx) and \(newy)")
                if newy != size.height || newx != size.width {
                    size = Size (width: newx, height: newy)
                    DispatchQueue.main.async {
                        Application.terminalResized()
                    }
                    return
                }
            }
            if result == KEY_MOUSE {
                var mouseEvent: MEVENT = MEVENT(id: 0, x: 0, y: 0, z: 0, bstate: 0)
                getmouse(&mouseEvent);
                if mouseEvent.bstate == MouseFlags.button1Pressed.rawValue {
                    //print ("here")
                }
                let me = toAppMouseEvent (mouseEvent)
                DispatchQueue.main.async {
                    Application.processMouseEvent(mouseEvent: me)
                }
                return
            }
            let ke = KeyEvent(key: toAppKeyEvent (result))
            DispatchQueue.main.async {
                Application.processKeyEvent(event: ke)
            }
            return
        }
        
        var ke: KeyEvent
        
        // Special handling for ESC, we want to try to catch ESC+letter to simulate alt-letter, as well as alt-FKey
        if result == 27 {
            timeout (200)
            let status2 = get_wch_fn (&result)
            timeout (-1)
            
            let isControl = result >= 0 && result < 32
            
            if status2 == KEY_CODE_YES {
                ke = KeyEvent (key: toAppKeyEvent(result), isAlt: true, isControl: isControl)
            } else {
                if status2 == 0 {
                    switch result {
                    case 48: // ESC-0 is F10
                        ke = KeyEvent (key: Key.f10)
                    case 49: // ESC-1 is F1
                        ke = KeyEvent (key: Key.f1)
                    case 50:
                        ke = KeyEvent (key: Key.f2)
                    case 51:
                        ke = KeyEvent (key: Key.f3)
                    case 52:
                        ke = KeyEvent (key: Key.f4)
                    case 53:
                        ke = KeyEvent (key: Key.f5)
                    case 54:
                        ke = KeyEvent (key: Key.f6)
                    case 55:
                        ke = KeyEvent (key: Key.f7)
                    case 56:
                        ke = KeyEvent (key: Key.f8)
                    case 57:
                        ke = KeyEvent (key: Key.f9)
                    case 27: // ESC+ESC is just ESC
                        ke = KeyEvent (key: Key.esc)
                    default:
                        ke = KeyEvent (key: toAppKeyEvent(result), isAlt: true, isControl: isControl)
                    }
                } else {
                    // Got nothing, just pass the escape
                    ke = KeyEvent (key: Key.esc)
                }
            }
        } else {
            // Pass the rest of the keystrokes
            ke = KeyEvent(key: toAppKeyEvent(result))
        }
        DispatchQueue.main.async {
            Application.processKeyEvent(event: ke)
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
        move (Int32 (row), Int32 (col))
        needMove = false
    }
    
    //
    // Should only be used with non-composed runes, when in doubt, use addCharacter
    //
    public override func addRune (_ rune: rune)
    {
        if needMove {
            move (crow, ccol)
            needMove = false
        }
        
        //var x = m_cchar_t(attr: currentAttr, chars: (wchar_t (rune.value), 0, 0, 0, 0))
        //let _ = add_wch_fn! (&x)
        addstr (String (rune))
        if sync {
            refresh ()
        }
        ccol += 1
    }
    
    public override func addCharacter (_ char: Character)
    {
        if needMove {
            move (crow, ccol)
            needMove = false
        }
        addstr (String (char))
        if sync {
            refresh ()
        }
        ccol += 1
    }
    
    func selectBwColors ()
    {
        let base = ColorScheme(normal: Attribute (A_NORMAL),
                               focus: Attribute(A_REVERSE),
                               hotNormal: Attribute(A_BOLD),
                               hotFocus: Attribute (A_BOLD | A_REVERSE))
        let menu = ColorScheme(normal: Attribute (A_REVERSE),
                               focus: Attribute (A_NORMAL),
                               hotNormal: Attribute(A_BOLD),
                               hotFocus: Attribute(A_NORMAL))
        let dialog = ColorScheme(normal: Attribute(A_REVERSE),
                                 focus: Attribute(A_NORMAL),
                                 hotNormal: Attribute(A_BOLD),
                                 hotFocus: Attribute(A_NORMAL))
        let error = ColorScheme(normal: Attribute(A_BOLD),
                                focus: Attribute(A_BOLD|A_REVERSE),
                                hotNormal: Attribute(A_BOLD|A_REVERSE),
                                hotFocus: Attribute (A_REVERSE))
        
        Colors._base = base
        Colors._menu = menu
        Colors._dialog = dialog
        Colors._error = error
    }
    
    static var lastColorPair: Int16 = 16
    
    func encodeCursesAttribute (_ colors: (Int32, Int32), bold: Bool = false) -> Int32
    {
        CursesDriver.lastColorPair += 1
        init_pair(CursesDriver.lastColorPair, Int16(colors.0), Int16(colors.1))
        return Int32 (CursesDriver.lastColorPair * 256) | (bold ? A_BOLD : 0)
    }
    
    func selectColors ()
    {
        let base = ColorScheme(normal:    makeAttribute(fore: .gray, back: .blue),
                               focus:     makeAttribute(fore: .black, back: .cyan),
                               hotNormal: makeAttribute(fore: .brightYellow, back: .blue),
                               hotFocus:  makeAttribute(fore: .brightYellow, back: .cyan))
        
        let menu = ColorScheme(normal:    makeAttribute(fore: .white, back: .cyan),
                               focus:     makeAttribute(fore: .white, back: .black),
                               hotNormal: makeAttribute(fore: .brightYellow, back: .cyan),
                               hotFocus:  makeAttribute(fore: .brightYellow, back: .black))

        let dialog = ColorScheme(normal:    makeAttribute(fore: .black, back: .gray),
                                 focus:     makeAttribute(fore: .black, back: .cyan),
                                 hotNormal: makeAttribute(fore: .blue, back: .gray),
                                 hotFocus:  makeAttribute(fore: .blue, back: .cyan))
        
        let error = ColorScheme(normal:   makeAttribute(fore: .white, back: .red),
                                focus:     makeAttribute(fore: .black, back: .white),
                                hotNormal: makeAttribute(fore: .brightYellow, back: .red),
                                hotFocus:  makeAttribute(fore: .brightYellow, back: .red))
     
        Colors._base = base
        Colors._menu = menu
        Colors._dialog = dialog
        Colors._error = error
    }
    
    // Maps a color to an ncurses value, and indicates whether we should flip the bold flag
    // (curses bright colors are achieved by adding the A_BOLD property to it)
    func mapColor (_ color: Color) -> (Int32, Bool)
    {
        switch color {
        case .black:
            return (COLOR_BLACK, false)
        case .blue:
            return (COLOR_BLUE, false)
        case .green:
            return (COLOR_GREEN, false)
        case .cyan:
            return (COLOR_CYAN, false)
        case .red:
            return (COLOR_RED, false)
        case .magenta:
            return (COLOR_MAGENTA, false)
        case .brown:
            return (COLOR_YELLOW, false)
        case .gray:
            return (COLOR_WHITE, false)
        case .darkGray:
            return (COLOR_BLACK, true)
        case .brightBlue:
            return (COLOR_BLUE, true)
        case .brightGreen:
            return (COLOR_GREEN, true)
        case .brightCyan:
            return (COLOR_CYAN, true)
        case .brightRed:
            return (COLOR_RED, true)
        case .brightMagenta:
            return (COLOR_MAGENTA, true)
        case .brightYellow:
            return (COLOR_YELLOW, true)
        case .white:
            return (COLOR_WHITE, true)
        case .rgb(_, _, _):
            print ("Unsupported .rgb(color)")
            abort()
        }
    }
    
    func cellFlagsToCurses (flags: CellFlags) -> Int32 {
        if flags.isEmpty { return 0 }
        var res: Int32 = 0
        if flags.contains(.blink) {
            res |= A_BLINK
        }
        if flags.contains (.bold) {
            res |= A_BOLD
        }
        if flags.contains (.dim) {
            res |= A_DIM
        }
        if flags.contains (.invert) {
            res |= A_REVERSE
        }
        if flags.contains (.standout) {
            res |= A_STANDOUT
        }
        if flags.contains (.underline) {
            res |= A_UNDERLINE
        }
        return res
    }
    struct AttrDef: Hashable {
        var fore: Color
        var back: Color
        var flags: CellFlags
    }
    // Old curses versions have a limit on the number of colors to create
    // so we need to keep them around
    var colorToAttribute: [AttrDef:Attribute] = [:]
    
    public override func makeAttribute(fore: Color, back: Color, flags: CellFlags = []) -> Attribute
    {
        let attrDef = AttrDef(fore: fore, back: back, flags: flags)
        if let v = colorToAttribute [attrDef] {
            return v
        }
        let (fa, bold) = mapColor (fore)
        let (ba, _) = mapColor (back)
        let cursesAttr = encodeCursesAttribute((fa, ba), bold: bold)
        
        let attr = Attribute(cursesAttr | cellFlagsToCurses(flags: flags), foreground: fore, background: back)
        colorToAttribute [attrDef] = attr
        return attr
    }
    
    public override func change (_ attribute: Attribute, foreground: Color) -> Attribute {
        // Returns a new attribute with the modified foreground, if it is not possible
        // due to the B&W default curses settings, we default to black background
        if let back = attribute.back {
            return makeAttribute(fore: foreground, back: back)
        }
        return makeAttribute(fore: foreground, back: .black)
    }

    public override func change (_ attribute: Attribute, background: Color) -> Attribute {
        // Returns a new attribute with the modified background, if it is not possible
        // due to the B&W default curses settings, we default to grey foreground
        if let fore = attribute.fore {
            return makeAttribute(fore: fore, back: background)
        }
        return makeAttribute(fore: .gray, back: background)
    }
    
    // Set when the method setAttribute is called
    var currentAttr: Int32 = 0
    
    public override func setAttribute (_ attr: Attribute)
    {
        currentAttr = attr.value
        attrset(attr.value)
    }
    
    public override func updateScreen ()
    {
        redrawwin(cursesWindow)
    }
    
    public override func refresh ()
    {
        dispatchPrecondition(condition: .onQueue(.main))
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
