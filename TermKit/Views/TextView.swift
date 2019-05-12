//
//  TextView.swift - multi-line text editing
//  TermKit
//
//  Created by Miguel de Icaza on 5/11/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

class TextModel {
    var lines: [[Character]]
    
    init ()
    {
        lines = [[]]
    }
    
    func loadFile (path: String) -> Bool
    {
        return true
    }
}
