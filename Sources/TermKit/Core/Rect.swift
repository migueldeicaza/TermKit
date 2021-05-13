//
//  Rect.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

public struct Rect: CustomDebugStringConvertible, Codable, Equatable {
    public var origin: Point
    public var size: Size
    
    static public var zero = Rect (origin: Point.zero, size: Size.empty)
    
    public init (origin: Point, size: Size)
    {
        self.origin = origin
        self.size = size
    }
    
    public init (x: Int, y: Int, width: Int, height: Int)
    {
        origin = Point(x: x, y: y)
        size = Size (width: width, height: height)
    }
    
    public init (left: Int, top: Int, right: Int, bottom: Int)
    {
        origin = Point(x: left, y: top)
        size = Size (width: right-left, height: bottom-top)
    }
    
    public var isEmpty: Bool {
        get {
            return size.IsEmpty
        }
    }
    
    public var minX: Int {
        get {
            return origin.x
        }
    }

    public var midX: Int {
        get {
            return origin.x + (size.width/2)
        }
    }
    
    public var maxX: Int {
        get {
            return origin.x+size.width
        }
    }

    public var minY: Int {
        get {
            return origin.y
        }
    }
    
    public var midY: Int {
        get {
            return origin.y + (size.height/2)
        }
    }
    
    public var maxY: Int {
        get {
            return origin.y + size.height
        }
    }
    
    public var width: Int {
        get {
            return size.width
        }
    }
    
    public var height: Int {
        get {
            return size.height
        }
    }
    
    public var left: Int {
        get {
            return origin.x
        }
    }

    public var right: Int {
        get {
            return origin.x+size.width
        }
    }
    
    public var top: Int {
        get {
            return origin.y
        }
    }

    public var bottom: Int {
        get {
            return origin.y + size.height
        }
    }

    public func intersection (_ rect2: Rect) -> Rect
    {
        let left = max (origin.x, rect2.origin.x)
        let right = min (self.right, rect2.right)
        let top = max (origin.y, rect2.origin.y)
        let bottom = min (self.bottom, rect2.bottom)
        
        if right >= left && bottom >= top {
            return Rect (left: left, top: top, right: right, bottom: bottom)
        } else {
            return Rect.zero
        }
    }
    
    public func intersects (_ rect2: Rect) -> Bool
    {
        return !intersection(rect2).isEmpty
    }
    
    public func contains (x: Int, y: Int) -> Bool
    {
        return x >= left && x < right && y >= top && y < bottom
    }
    
    public func contains (_ point: Point) -> Bool
    {
        return contains (x: point.x, y: point.y)
    }
    
    public func contains (_ rect: Rect) -> Bool {
        if rect.origin.x < origin.x || rect.right > right {
            return false
        }
        if rect.origin.y < origin.y || rect.bottom > bottom {
            return false
        }
        return true
    }
    public var debugDescription: String {
        return "Rect(origin: \(origin), size: \(size))"
    }
}

