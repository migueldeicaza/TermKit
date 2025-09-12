//
//  BorderStyle.swift
//  TermKit
//
//  Created by Miguel de Icaza on 9/11/25.
//

/// The various borders supported in the app
public enum BorderStyle {
    /// Uses no space
    case none
    /// Uses spaces for the border
    case blank
    case ascii
    case round
    case solid
    case double
    case dashed
    case heavy
    case inner
    case outer
    case thick
    case hkey
    case vkey
    case tall
    case panel
    case tab
    case wide

    /// Describes how much space this kind of border uses
    public var edgeInsets: EdgeInsets {
        switch self {
        case .none:
            return EdgeInsets.zero
        default:
            return EdgeInsets(all: 1)
        }
    }
    
    // We will be able to use InlineArray once the new Swift is out
    public var characters: [Character] {
        switch self {
        case .none: [
            " ", " ", " ",
            " ", " ", " ",
            " ", " ", " "
        ]
        case .blank: [
            " ", " ", " ",
            " ", " ", " ",
            " ", " ", " "
        ]
        case .ascii: [
            "+", "-", "+",
            "|", " ", "|",
            "+", "-", "+"
        ]
        case .round: [
            "╭", "─", "╮",
            "│", " ", "│",
            "╰", "─", "╯"
        ]
        case .solid: [
            "┌", "─", "┐",
            "│", " ", "│",
            "└", "─", "┘"
        ]
        case .double: [
            "╔", "═", "╗",
            "║", " ", "║",
            "╚", "═", "╝"
        ]
        case .dashed: [
            "┏", "╍", "┓",
            "╏", " ", "╏",
            "┗", "╍", "┛"
        ]
        case .heavy: [
            "┏", "━", "┓",
            "┃", " ", "┃",
            "┗", "━", "┛"
        ]
        case .inner: [
            "▗", "▄", "▖",
            "▐", " ", "▌",
            "▝", "▀", "▘"
        ]
        case .outer: [
            "▛", "▀", "▜",
            "▌", " ", "▐",
            "▙", "▄", "▟"
        ]
        case .thick: [
            "█", "▀", "█",
            "█", " ", "█",
            "█", "▄", "█"
        ]
        case .hkey: [
            "▔", "▔", "▔",
            " ", " ", " ",
            "▁", "▁", "▁"
        ]
        case .vkey: [
            "▏", " ", "▕",
            "▏", " ", "▕",
            "▏", " ", "▕"
        ]
        case .tall: [
            "▊", "▔", "▎",
            "▊", " ", "▎",
            "▊", "▁", "▎"
        ]
        case .panel: [
            "▊", "█", "▎",
            "▊", " ", "▎",
            "▊", "▁", "▎"
        ]
        case .tab: [
            "▁", "▁", "▁",
            "▎", " ", "▊",
            "▔", "▔", "▔"
        ]
        case .wide: [
            "▁", "▁", "▁",
            "▎", " ", "▊",
            "▔", "▔", "▔"
        ]
        }
    }

    private static func makeRunes(from chars: [Character]) -> (UnicodeScalar, UnicodeScalar, UnicodeScalar, UnicodeScalar, UnicodeScalar, UnicodeScalar, UnicodeScalar, UnicodeScalar) {
        return (
            chars[0].unicodeScalars.first!,  // topLeft
            chars[1].unicodeScalars.first!,  // top
            chars[2].unicodeScalars.first!,  // topRight
            chars[3].unicodeScalars.first!,  // left
            chars[5].unicodeScalars.first!,  // right
            chars[6].unicodeScalars.first!,  // bottomLeft
            chars[7].unicodeScalars.first!,  // bottom
            chars[8].unicodeScalars.first!   // bottomRight
        )
    }
    
    private static let noneRunes = makeRunes(from: BorderStyle.none.characters)
    private static let blankRunes = makeRunes(from: BorderStyle.blank.characters)
    private static let asciiRunes = makeRunes(from: BorderStyle.ascii.characters)
    private static let roundRunes = makeRunes(from: BorderStyle.round.characters)
    private static let solidRunes = makeRunes(from: BorderStyle.solid.characters)
    private static let doubleRunes = makeRunes(from: BorderStyle.double.characters)
    private static let dashedRunes = makeRunes(from: BorderStyle.dashed.characters)
    private static let heavyRunes = makeRunes(from: BorderStyle.heavy.characters)
    private static let innerRunes = makeRunes(from: BorderStyle.inner.characters)
    private static let outerRunes = makeRunes(from: BorderStyle.outer.characters)
    private static let thickRunes = makeRunes(from: BorderStyle.thick.characters)
    private static let hkeyRunes = makeRunes(from: BorderStyle.hkey.characters)
    private static let vkeyRunes = makeRunes(from: BorderStyle.vkey.characters)
    private static let tallRunes = makeRunes(from: BorderStyle.tall.characters)
    private static let panelRunes = makeRunes(from: BorderStyle.panel.characters)
    private static let tabRunes = makeRunes(from: BorderStyle.tab.characters)
    private static let wideRunes = makeRunes(from: BorderStyle.wide.characters)
    
    public var runes: (topLeft: UnicodeScalar,
                       top: UnicodeScalar,
                       topRight: UnicodeScalar,
                       left: UnicodeScalar,
                       right: UnicodeScalar,
                       bottomLeft: UnicodeScalar,
                       bottom: UnicodeScalar,
                       bottomRight: UnicodeScalar) {
        switch self {
        case .none: return Self.noneRunes
        case .blank: return Self.blankRunes
        case .ascii: return Self.asciiRunes
        case .round: return Self.roundRunes
        case .solid: return Self.solidRunes
        case .double: return Self.doubleRunes
        case .dashed: return Self.dashedRunes
        case .heavy: return Self.heavyRunes
        case .inner: return Self.innerRunes
        case .outer: return Self.outerRunes
        case .thick: return Self.thickRunes
        case .hkey: return Self.hkeyRunes
        case .vkey: return Self.vkeyRunes
        case .tall: return Self.tallRunes
        case .panel: return Self.panelRunes
        case .tab: return Self.tabRunes
        case .wide: return Self.wideRunes
        }
    }
}
