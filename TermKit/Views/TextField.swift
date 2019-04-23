//
//  TextField.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/22/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

public class TextField : View {
    var point = 0
    var layoutPending : Bool
    /// The contents of the text field
    public var text : String = "" {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// If set, the contents of the entry are masked, used for passwords for example.
    public var secret : Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Sets or gets the current cursor position.
    public var cursorPosition : Int = 0 {
        didSet {
            point = cursorPosition
            adjust ()
        }
    }
    
    func adjust ()
    {
            layoutPending = false
    }
    
    public init (initial : String = "")
    {
        text = initial
        point = initial.count
        layoutPending = true
        
        
        super.init ()
        canFocus = true
    }
    
    public override var frame : Rect {
        didSet {
            // TODO
            print ("Need to adjust position")
        }
    }
    
    public override func redraw(region: Rect) {
        driver.setAttribute(colorScheme!.focus)
        moveTo(col:0, row: 0)
        
    }
}
