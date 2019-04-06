//
//  Size.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

public struct Size {
    var Width = 0
    var Height = 0
    static public var Empty : Size = Size (width: 0, height: 0)
    public var IsEmpty : Bool {
        get {
            return Width == 0 && Height == 0
        }
    }
    
    init (width : Int, height : Int)
    {
        self.Width = width
        self.Height = height
    }
    
    init (point : Point)
    {
        self.Width = point.X
        self.Height = point.Y
    }

    static func +(lhs: Size, rhs: Size) -> Size
    {
        return Size (width: lhs.Width + rhs.Width, height: lhs.Width + rhs.Width)
    }

    static func -(lhs: Size, rhs: Size) -> Size
    {
        return Size (width: lhs.Width - rhs.Width, height: lhs.Width - rhs.Width)
    }

    static func ==(lhs: Size, rhs: Size) -> Bool
    {
        return lhs.Height == rhs.Height && lhs.Width == rhs.Width
    }

    static func !=(lhs: Size, rhs: Size) -> Bool
    {
        return lhs.Height != rhs.Height || lhs.Width != rhs.Width
    }
}
