//
//  Driver.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/8/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

public typealias rune = UnicodeScalar

/**
 * Basic colors that can be used to set the foreground and background colors in console applications.
 */
public enum Color {
    case Black
    case Blue
    case Green
    case Cyan
    case Red
    case Magenta
    case Brown
    case Gray
    case DarkGray
    case BrightBlue
    case BrightGreen
    case BrightCyan
    case BrightRed
    case BrightMagenta
    case BrightYellow
    case White
}

/**
 * Attributes are used as elements that contain both a foreground and a background or platform specific features
 *
 * Attributes are needed to map colors to terminal capabilities that might lack colors, on color
 * scenarios, they encode both the foreground and the background color and are used in the ColorScheme
 * class to define color schemes that can be used in your application.
 */
public struct Attribute {
    var value: Int32
    
    public init (_ val: Int32)
    {
        value = val
    }
    
    public static func make (fore : Color, back : Color) -> Attribute
    {
        return Application.Shared.driver.makeAttribute(fore: fore, back: back);
    }
}

public extension Int32 {
    init (_ attr: Attribute)
    {
        self = attr.value
    }
}

/**
 * Color scheme definitions, cover the four colors that are typically needed
 * by views in a console applications to display text and show the focused state.
 * They include the regular attribute (normal), the attribute used when the
 * view is focused (focus) and the attributes use to highlight the hotkeys
 * in a view both in normal mode and focused mode.
 */
public class ColorScheme {
    /// The default color for text, when the view is not focused.
    public var normal : Attribute
    /// The color for text when the view has the focus.
    public var focus : Attribute
    /// The color for the hotkey when a view is not focused
    public var hotNormal : Attribute
    /// The color for the hotkey when the view is focused.
    public var hotFocus : Attribute
    
    public init (normal: Attribute, focus: Attribute, hotNormal: Attribute, hotFocus: Attribute)
    {
        self.normal = normal
        self.focus = focus
        self.hotFocus = hotFocus
        self.hotNormal = hotNormal
    }
}

/**
 * The default ColorSchemes for the application.
 */
public class Colors {
    static var _base, _dialog, _menu, _error : ColorScheme?
    
    public static var base : ColorScheme {
        get {
            return _base!
        }
    }
    public static var dialog : ColorScheme {
        get {
            return _dialog!
        }
    }
    public static var menu : ColorScheme {
        get {
            return _menu!
        }
    }
    public static var error : ColorScheme {
        get {
            return _error!
        }
    }
}

/**
 * Base class for implementing text drivers.
 *
 * Currently there is a Curses implementation, but an implementation that does not rely on Curses and
 * that purely uses Terminfo would be desirable, as well as a Windows console one
 */
public class ConsoleDriver {
    init ()
    {
        cols = 0
        rows = 0
        clip = Rect.zero
    }
    
    var cols : Int
    var rows : Int
    let ulCorner = Unicode.Scalar (0x250c)!
    let llCorner = Unicode.Scalar (0x2514)!
    let hLine = Unicode.Scalar (0x2500)!
    let urCorner = Unicode.Scalar (0x2510)!
    let lrCorner = Unicode.Scalar (0x2518)!
    let space = Unicode.Scalar (32)!
    let vLine = Unicode.Scalar (0x2502)!
    public var clip : Rect
    
    /**
     * Adds a rune at the current cursor position, not expected to work with graphemes, use when you know that the value being added will not compose
     */
    public func addRune (_ rune: rune) {}

    /**
     * Adds a specified character at the current cursor position
     */
    public func addCharacter (_ char: Character) {}
    
    /**
     * Moves the cursor to the screen to the specified column and row
     */
    public func moveTo (col : Int, row : Int) {}
    
    /**
     * Draws a frame on the specified region with the specified padding around the frame.
     * - Parameter region: Region where the frame will be drawn.
     * - Parameter padding: Padding to add on the sides
     * - Parameter fill: If set to `true` it will clear the contents with the current color, otherwise the contents will be left untouched.
     */
    public func drawFrame (_ region: Rect, padding : Int, fill : Bool)
    {
        let width = region.width;
        let height = region.height;

        let fwidth = width - padding * 2;
        let fheight = height - 1 - padding;
        
        moveTo (col: region.minX, row: region.minY);
        if (padding > 0) {
            for _ in 0..<padding {
                for _ in 0..<width {
                    addRune (space)
                }
            }
        }
        moveTo (col: region.minX, row: region.minY + padding);
        for _ in 0..<padding {
            addRune (space)
        }
        addRune (ulCorner)
        for _ in 0..<(fwidth-2) {
            addRune (hLine);
        }
        addRune (urCorner);
        for _ in 0..<padding {
            addRune (space)
        }
        
        for b in (1+padding)..<fheight {
            moveTo (col: region.minX, row: region.minY + b);
            for _ in 0..<padding {
                addRune (space)
            }
            addRune (vLine);
            if fill {
                for _ in 1..<(fwidth-1){
                    addRune (space)
                }
            } else {
                moveTo (col: region.minX + fwidth - 1, row: region.minY + b)
            }
            addRune (vLine);
            for _ in 0..<padding {
                addRune (space)
            }
        }
        moveTo (col: region.minX, row: region.minY + fheight)
        for _ in 0..<padding {
            addRune (space)
        }
        addRune (llCorner);
        for _ in 0..<(fwidth - 2) {
            addRune (hLine);
        }
        addRune (lrCorner);
        for _ in 0..<padding {
            addRune (space)
        }
        if padding > 0 {
            moveTo (col: region.minX, row: region.minY + height - padding);
            for _ in 0..<padding {
                for _ in 0..<width {
                    addRune (space)
                }
            }
        }
    }
    
    /**
     * This method takes the platform-agnostic Color enumeration for foreground and background and produces an attribute
     */
    public func makeAttribute (fore: Color, back: Color) -> Attribute
    {
        return Attribute(0)
    }
    
    public enum ColorSupport {
        /// The terminal only supports black and white - generally, they are expected to at least have the VT100 capabilities: bold, italics, inverse, blink
        case BlackAndWhite
        /// The terminal supports 16 colors, usually the top 8 are bright colors
        case SixteenColors
        /// The terminal can configure colors based on R, G, B values
        case RgbColors
    }
    
    /**
     * Returns the available color options for the current driver
     *
     * On some Unix terminals, there is only black and white available, others support 16 colors, others can
     * support a larger range by setting the colors using an RGB set of properties.
     */
    public func colorSupport () -> ColorSupport
    {
        return .BlackAndWhite
    }
    
    /**
     * Sets the current attribute used to draw, any subsequence text output will use the specified attribute
     */
    public func setAttribute (_ attr: Attribute)
    {
    }
    
}
