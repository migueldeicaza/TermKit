//
//  EdgeInsets.swift
//  TermKit
//
//  Defines per-side thickness values for margins and padding.
//

import Foundation

/// Describes the thickness for the four sides of a rectangle.
public struct EdgeInsets: Equatable {
    public var top: Int
    public var left: Int
    public var bottom: Int
    public var right: Int

    /// Initializes all edges to the same value.
    public init(all: Int) {
        self.top = all
        self.left = all
        self.bottom = all
        self.right = all
    }

    /// Initializes the edges with specific values.
    public init(top: Int = 0, left: Int = 0, bottom: Int = 0, right: Int = 0) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    /// Zero insets (no thickness on any side).
    public static var zero: EdgeInsets { EdgeInsets(all: 0) }

    /// Combined horizontal thickness (left + right).
    public var horizontal: Int { left + right }

    /// Combined vertical thickness (top + bottom).
    public var vertical: Int { top + bottom }
}

public extension EdgeInsets {
    /// Adds two insets per-side.
    static func + (lhs: EdgeInsets, rhs: EdgeInsets) -> EdgeInsets {
        EdgeInsets(top: lhs.top + rhs.top,
                   left: lhs.left + rhs.left,
                   bottom: lhs.bottom + rhs.bottom,
                   right: lhs.right + rhs.right)
    }
}

