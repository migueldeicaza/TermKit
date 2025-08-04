//
//  Size.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

public struct Size: CustomDebugStringConvertible, Codable, Equatable {
    var width = 0
    var height = 0
    static public var empty: Size = Size (width: 0, height: 0)
    public var IsEmpty: Bool {
        get {
            return width == 0 && height == 0
        }
    }
    
    public init (width: Int, height: Int)
    {
        self.width = width
        self.height = height
    }
    
    public init (point: Point)
    {
        self.width = point.x
        self.height = point.y
    }

    public static func + (lhs: Size, rhs: Size) -> Size
    {
        return Size (width: lhs.width + rhs.width, height: lhs.width + rhs.width)
    }

    public static func - (lhs: Size, rhs: Size) -> Size
    {
        return Size (width: lhs.width - rhs.width, height: lhs.width - rhs.width)
    }

    public static func == (lhs: Size, rhs: Size) -> Bool
    {
        return lhs.height == rhs.height && lhs.width == rhs.width
    }

    public static func != (lhs: Size, rhs: Size) -> Bool
    {
        return lhs.height != rhs.height || lhs.width != rhs.width
    }
    
    public var debugDescription: String {
        return "Size(width: \(width), height: \(height))"
    }
}
