//
//  EdgeInsets.swift
//  TermKit
//
//  Defines per-side thickness values for margins and padding.
//

import Foundation

/// Describes the thickness for the four sides of a rectangle.
///
/// EdgeInsets is used to define margins, padding, and border widths around views.
/// Each edge can have an independent thickness value.
///
/// ## Example
/// ```swift
/// // Create uniform insets
/// let padding = EdgeInsets(all: 2)
///
/// // Create asymmetric insets
/// let margins = EdgeInsets(top: 1, left: 2, bottom: 1, right: 2)
/// ```
public struct EdgeInsets: Equatable {
    /// The thickness of the top edge.
    public var top: Int

    /// The thickness of the left edge.
    public var left: Int

    /// The thickness of the bottom edge.
    public var bottom: Int

    /// The thickness of the right edge.
    public var right: Int

    /// Initializes all edges to the same value.
    public init(all: Int) {
        self.top = all
        self.left = all
        self.bottom = all
        self.right = all
    }

    /// Initializes the edges with specific values.
    /// - Parameters:
    ///   - top: The thickness of the top edge. Defaults to 0.
    ///   - left: The thickness of the left edge. Defaults to 0.
    ///   - bottom: The thickness of the bottom edge. Defaults to 0.
    ///   - right: The thickness of the right edge. Defaults to 0.
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
    /// Adds two insets together, combining each edge independently.
    /// - Parameters:
    ///   - lhs: The first set of insets.
    ///   - rhs: The second set of insets.
    /// - Returns: A new EdgeInsets where each edge is the sum of the corresponding edges.
    static func + (lhs: EdgeInsets, rhs: EdgeInsets) -> EdgeInsets {
        EdgeInsets(top: lhs.top + rhs.top,
                   left: lhs.left + rhs.left,
                   bottom: lhs.bottom + rhs.bottom,
                   right: lhs.right + rhs.right)
    }
}

