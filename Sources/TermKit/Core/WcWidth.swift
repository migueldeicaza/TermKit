//
//  WcWidth.swift
//  TermKit
//
//  Cross-platform wcwidth implementation
//

import Foundation

#if os(macOS)
import Darwin
#else
import Glibc

// Direct access to wcwidth using @_silgen_name
@_silgen_name("wcwidth")
fileprivate func wcwidth_linux(_ c: wchar_t) -> Int32
#endif

/// Cross-platform wcwidth wrapper
/// Returns the number of columns needed to display a character
public func termKitWcWidth(_ char: wchar_t) -> Int32 {
    #if os(macOS)
    return wcwidth(char)
    #else
    return wcwidth_linux(char)
    #endif
}

/// Cross-platform wcwidth wrapper for UInt32 (UnicodeScalar value)
/// Only needed on macOS where wchar_t is Int32; on Linux wchar_t is UInt32
#if os(macOS)
public func termKitWcWidth(_ char: UInt32) -> Int32 {
    let intValue = Int(char)
    return termKitWcWidth(wchar_t(intValue))
}
#endif

/// Extension for Character to get display width
extension Character {
    /// Returns the display width of this character in terminal columns
    public var displayWidth: Int {
        var totalWidth = 0
        for scalar in self.unicodeScalars {
            let width = termKitWcWidth(scalar.value)
            if width > 0 {
                totalWidth += Int(width)
            }
        }
        return totalWidth > 0 ? totalWidth : 1
    }
}

/// Extension for String to get display width
extension String {
    /// Returns the display width of this string in terminal columns
    public var displayWidth: Int {
        var totalWidth = 0
        for char in self {
            totalWidth += char.displayWidth
        }
        return totalWidth
    }
}
