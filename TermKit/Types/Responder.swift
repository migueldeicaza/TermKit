//
//  Responder.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/9/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

public class Responder {
    public var canFocus : Bool = false
    public var hasFocus : Bool = false
    
    public func processHotKey (kb : KeyEvent) -> Bool
    {
        return false
    }
}
