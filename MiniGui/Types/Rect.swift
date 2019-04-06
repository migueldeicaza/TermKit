//
//  Rect.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

public struct Rect {
    var origin : Point;
    var size : Size;
    static public var Empty = Rect (origin: Point.Zero, size: Size.Empty)
    
    init (origin : Point, size : Size)
    {
        self.origin = origin
        self.size = size
    }
    
    init (x: Int, y: Int, width: Int, height: Int)
    {
        origin = Point(x: x, y: y)
        size = Size (width: width, height: height)
    }
    
    init (left: Int, right: Int, top: Int, bottom: Int)
    {
        origin = Point(x: left, y: right)
        size = Size (width: right-left, height: bottom-top)
    }
    
    var IsEmpty : Bool {
        get {
            return size.IsEmpty
        }
    }
    
    var X : Int {
        get {
            return origin.X
        }
    }

    var Y : Int {
        get {
            return origin.Y
        }
    }
    
    var Width : Int {
        get {
            return size.Width
        }
    }
    
    var Height : Int {
        get {
            return size.Height
        }
    }
    
    var Left : Int {
        get {
            return origin.X
        }
    }

    var Right : Int {
        get {
            return origin.X+size.Width
        }
    }

    var Top : Int {
        get {
            return origin.Y
        }
    }

    var Bottom : Int {
        get {
            return origin.Y + size.Height
        }
    }
    
}

