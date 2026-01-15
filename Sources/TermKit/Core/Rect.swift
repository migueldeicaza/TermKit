//
//  Rect.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/// A structure that represents a rectangle with an origin point and size.
///
/// Rect is used throughout TermKit to define view frames, content areas,
/// clipping regions, and dirty regions for rendering.
public struct Rect: CustomDebugStringConvertible, Codable, Equatable {
    /// The origin point (top-left corner) of the rectangle.
    public var origin: Point

    /// The size (width and height) of the rectangle.
    public var size: Size

    /// A rectangle with zero origin and empty size.
    static public var zero = Rect (origin: Point.zero, size: Size.empty)

    /// Creates a rectangle with the specified origin and size.
    /// - Parameters:
    ///   - origin: The top-left corner of the rectangle.
    ///   - size: The width and height of the rectangle.
    public init (origin: Point, size: Size)
    {
        self.origin = origin
        self.size = size
    }

    /// Creates a rectangle with the specified position and dimensions.
    /// - Parameters:
    ///   - x: The x-coordinate of the top-left corner.
    ///   - y: The y-coordinate of the top-left corner.
    ///   - width: The width of the rectangle.
    ///   - height: The height of the rectangle.
    public init (x: Int, y: Int, width: Int, height: Int)
    {
        origin = Point(x: x, y: y)
        size = Size (width: width, height: height)
    }

    /// Creates a rectangle from edge coordinates.
    /// - Parameters:
    ///   - left: The x-coordinate of the left edge.
    ///   - top: The y-coordinate of the top edge.
    ///   - right: The x-coordinate of the right edge.
    ///   - bottom: The y-coordinate of the bottom edge.
    public init (left: Int, top: Int, right: Int, bottom: Int)
    {
        origin = Point(x: left, y: top)
        size = Size (width: right-left, height: bottom-top)
    }

    /// Returns `true` if the rectangle has zero width or height.
    public var isEmpty: Bool {
        get {
            return size.IsEmpty
        }
    }

    /// The minimum x-coordinate (left edge) of the rectangle.
    public var minX: Int {
        get {
            return origin.x
        }
    }

    /// The x-coordinate of the center of the rectangle.
    public var midX: Int {
        get {
            return origin.x + (size.width/2)
        }
    }

    /// The maximum x-coordinate (right edge) of the rectangle.
    public var maxX: Int {
        get {
            return origin.x+size.width
        }
    }

    /// The minimum y-coordinate (top edge) of the rectangle.
    public var minY: Int {
        get {
            return origin.y
        }
    }

    /// The y-coordinate of the center of the rectangle.
    public var midY: Int {
        get {
            return origin.y + (size.height/2)
        }
    }

    /// The maximum y-coordinate (bottom edge) of the rectangle.
    public var maxY: Int {
        get {
            return origin.y + size.height
        }
    }

    /// The width of the rectangle.
    public var width: Int {
        get {
            return size.width
        }
    }

    /// The height of the rectangle.
    public var height: Int {
        get {
            return size.height
        }
    }

    /// The x-coordinate of the left edge (alias for minX).
    public var left: Int {
        get {
            return origin.x
        }
    }

    /// The x-coordinate of the right edge (alias for maxX).
    public var right: Int {
        get {
            return origin.x+size.width
        }
    }

    /// The y-coordinate of the top edge (alias for minY).
    public var top: Int {
        get {
            return origin.y
        }
    }

    /// The y-coordinate of the bottom edge (alias for maxY).
    public var bottom: Int {
        get {
            return origin.y + size.height
        }
    }

    /// Returns the intersection of this rectangle with another rectangle.
    /// - Parameter rect2: The rectangle to intersect with.
    /// - Returns: A rectangle representing the overlapping area, or `Rect.zero` if they don't intersect.
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

    /// Returns whether this rectangle intersects with another rectangle.
    /// - Parameter rect2: The rectangle to test intersection with.
    /// - Returns: `true` if the rectangles overlap, `false` otherwise.
    public func intersects (_ rect2: Rect) -> Bool
    {
        return !intersection(rect2).isEmpty
    }

    /// Returns whether this rectangle contains the specified point.
    /// - Parameters:
    ///   - x: The x-coordinate to test.
    ///   - y: The y-coordinate to test.
    /// - Returns: `true` if the point is inside the rectangle.
    public func contains (x: Int, y: Int) -> Bool
    {
        return x >= left && x < right && y >= top && y < bottom
    }

    /// Returns whether this rectangle contains the specified point.
    /// - Parameter point: The point to test.
    /// - Returns: `true` if the point is inside the rectangle.
    public func contains (_ point: Point) -> Bool
    {
        return contains (x: point.x, y: point.y)
    }

    /// Returns whether this rectangle completely contains another rectangle.
    /// - Parameter rect: The rectangle to test.
    /// - Returns: `true` if the specified rectangle is entirely within this rectangle.
    public func contains (_ rect: Rect) -> Bool {
        if rect.origin.x < origin.x || rect.right > right {
            return false
        }
        if rect.origin.y < origin.y || rect.bottom > bottom {
            return false
        }
        return true
    }

    /// A textual representation of the rectangle for debugging.
    public var debugDescription: String {
        return "Rect(origin: \(origin), size: \(size))"
    }
}

