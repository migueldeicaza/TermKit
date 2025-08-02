//
//  Point.swift - Represents a point in the screen.
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * Point represents a position in the screen using an x and y coordinate for the column and row respectively.
 */
public struct Point: CustomDebugStringConvertible, Codable, Equatable {
    /// The x (column) component of this point
    public var x: Int
    
    /// The y (row) component of this point
    public var y: Int
    
    /// The point at the origin (0, 0)
    public static var zero: Point { Point(x: 0, y: 0) }
    
    /// Initializes a new Point with the specified x and y coordinates
    public init (x: Int, y: Int)
    {
        self.x = x
        self.y = y
    }
    
    /// Initializes a new Point from a Size structure using width for the x component and height for the y component
    public init (point: Size)
    {
        self.x = point.width
        self.y = point.height
    }
    
    public static func +(lhs: Point, rhs: Point) -> Point
    {
        return Point (x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    public static func -(lhs: Point, rhs: Point) -> Point
    {
        return Point (x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    public static func ==(lhs: Point, rhs: Point) -> Bool
    {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    public static func !=(lhs: Point, rhs: Point) -> Bool
    {
        return lhs.x != rhs.x || lhs.y != rhs.y
    }

    public var debugDescription: String {
        return "Point(x: \(x), y: \(y))"
    }
}
