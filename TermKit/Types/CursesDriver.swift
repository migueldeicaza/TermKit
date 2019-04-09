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
}
