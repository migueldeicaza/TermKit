//
//  Point.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

struct Point {
    var X : Int
    var Y : Int
    static var Zero = Point(x: 0, y: 0)
    
    init (x: Int, y : Int)
    {
        self.X = x
        self.Y = y
    }
    
    init (point : Size)
    {
        self.X = point.Width
        self.Y = point.Height
    }
    
    static func +(lhs: Point, rhs: Point) -> Point
    {
        return Point (x: lhs.X + rhs.X, y: lhs.Y + rhs.Y)
    }
    
    static func -(lhs: Point, rhs: Point) -> Point
    {
        return Point (x: lhs.X - rhs.X, y: lhs.Y - rhs.Y)
    }
    
    static func ==(lhs: Point, rhs: Point) -> Bool
    {
        return lhs.X == rhs.X && lhs.Y == rhs.Y
    }
    
    static func !=(lhs: Point, rhs: Point) -> Bool
    {
        return lhs.X != rhs.X || lhs.Y != rhs.Y
    }

}
