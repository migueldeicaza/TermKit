//
//  Point.swift - Represents a point in the screen.
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

public struct Point : CustomDebugStringConvertible {
    var x : Int
    var y : Int
    static var zero = Point(x: 0, y: 0)
    
    init (x: Int, y : Int)
    {
        self.x = x
        self.y = y
    }
    
    init (point : Size)
    {
        self.x = point.width
        self.y = point.height
    }
    
    static func +(lhs: Point, rhs: Point) -> Point
    {
        return Point (x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func -(lhs: Point, rhs: Point) -> Point
    {
        return Point (x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func ==(lhs: Point, rhs: Point) -> Bool
    {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    static func !=(lhs: Point, rhs: Point) -> Bool
    {
        return lhs.x != rhs.x || lhs.y != rhs.y
    }

    public var debugDescription: String {
        return "Point(x: \(x), y: \(y))"
    }
}
