//
//  CursesDriver.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/8/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

class CursesDriver : ConsoleDriver {
    var ccol : Int32 = 0
    var crow : Int32 = 0
    var needMove : Bool = false
    var sync : Bool = false
    
    override init ()
    {
        super.init ()
        
        ccol = 0
        crow = 0
        
        // Setup curses
        initscr ()
        start_color()
        noecho()
        curs_set (0)
        init_pair (0, Int16(COLOR_BLACK), Int16(COLOR_GREEN))
        keypad (stdscr, true)
        
        cols = Int (getmaxx (stdscr))
        rows = Int (getmaxy (stdscr))
        
        clear ();
        clip = Rect (x: 0, y: 0, width: cols, height: rows)
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
            addch(UInt32 (rune))
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
    
    public override func setAttribute (_ attr: Attribute)
    {
        attrset(attr.value)
    }
}
