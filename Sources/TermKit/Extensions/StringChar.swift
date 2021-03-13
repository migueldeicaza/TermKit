//
//  String.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/20/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

//
// These are extension methods to measure characters in terminal-terms, based on
// the wcwidth function
//
extension String {
    /// this uses wcwidth on each Character to determine how many terminal cells the character uses.
    /// For example, this one uses 2 cells: "ማ" on a console.
    func cellCount () -> Int
    {
        var total = 0
        for c in self {
            total += c.cellSize()
        }
        return total
    }
    
    //
    // Returns a string that will fit in the "n" slots in the screen
    //
    func getVisibleString (_ n : Int) -> String
    {
        var slen = 0
        var res = ""
        for c in self {
            let clen = c.cellSize()
            if slen + clen > n {
                return res
            }
            res.append (c)
            slen += clen
        }
        return res
    }
    
    /// this uses wcwidth on each Character to determine how many terminal cells the character uses.
    /// But does not count cells with an underscrore.
    /// For example, this one uses 2 cells: "ማ" on a console, and "_File" would return 4, only the
    /// firsrt underscore is not counted
    func getCellCountWithoutMarkup () -> Int
    {
        var total = 0
        var seen = false
        for c in self {
            if c == "_" {
                if !seen {
                    seen = true
                    continue
                }
            }
            total += c.cellSize()
        }
        return total

    }
}

extension Character {
    func cellSize () -> Int
    {
        if let ascii = self.asciiValue {
            if ascii < 32 {
                return 0
            }
            return 1
        }
        let scalars = self.unicodeScalars
        var max = 0
        for s in scalars {
            let w = wcwidth(Int32(s.value))
            if w > max {
                max = Int (w)
            }
        }
        return max
    }
}
