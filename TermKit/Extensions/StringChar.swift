//
//  String.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/20/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

extension String {
    // TODO
    // this should use wcwidth on each Character to determine how many terminal cells the character uses.
    // For example, this one uses 2 cells: "ማ" on a console.
    func cellCount () -> Int
    {
        return self.count
    }
}

extension Character {
    // TODO
    // this should use wcwidth on the character to determine how many cell it uses
    //
    func cellSize () -> Int
    {
        if let ascii = self.asciiValue {
            if ascii < 32 {
                return 0
            }
        }
        return 1
    }
}
