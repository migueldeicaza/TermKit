//
//  Size.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/// A structure that represents a width and height.
///
/// Size is used throughout TermKit to represent dimensions of views,
/// content areas, and terminal screens.
public struct Size: CustomDebugStringConvertible, Codable, Equatable {
    /// The width component of the size.
    public var width = 0

    /// The height component of the size.
    public var height = 0

    /// A size with zero width and height.
    static public var empty: Size = Size (width: 0, height: 0)

    /// Returns `true` if both width and height are zero.
    public var IsEmpty: Bool {
        get {
            return width == 0 && height == 0
        }
    }

    /// Creates a size with the specified width and height.
    /// - Parameters:
    ///   - width: The width value.
    ///   - height: The height value.
    public init (width: Int, height: Int)
    {
        self.width = width
        self.height = height
    }

    /// Creates a size from a point, using x as width and y as height.
    /// - Parameter point: The point to convert.
    public init (point: Point)
    {
        self.width = point.x
        self.height = point.y
    }

    /// Adds two sizes together.
    public static func + (lhs: Size, rhs: Size) -> Size
    {
        return Size (width: lhs.width + rhs.width, height: lhs.width + rhs.width)
    }

    /// Subtracts one size from another.
    public static func - (lhs: Size, rhs: Size) -> Size
    {
        return Size (width: lhs.width - rhs.width, height: lhs.width - rhs.width)
    }

    /// Returns whether two sizes are equal.
    public static func == (lhs: Size, rhs: Size) -> Bool
    {
        return lhs.height == rhs.height && lhs.width == rhs.width
    }

    /// Returns whether two sizes are not equal.
    public static func != (lhs: Size, rhs: Size) -> Bool
    {
        return lhs.height != rhs.height || lhs.width != rhs.width
    }

    /// A textual representation of the size for debugging.
    public var debugDescription: String {
        return "Size(width: \(width), height: \(height))"
    }
}
