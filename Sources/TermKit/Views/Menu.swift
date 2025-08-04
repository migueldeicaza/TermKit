//
//  Menu.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/26/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//
// TODO:
//  - Enable/disable menu item support
//  - Checkbox on menu items (with a style, so radios can be done too)
//  - nested menus

import Foundation

/// Specifies how a `MenuItem`shows selection state.
public enum MenuItemStyle {
    /// The menu item will be shown normally, with no check indicator.
    case plain
    /// The menu item will indicate checked/un-checked state
    case checked
    /// The menu item is part of a menu radio group 
    case radio
}

/**
 * A menu item has a title, an associated help text, and an action to execute on activation.
 */
public struct MenuItem {
    /// Gets or sets the title for the menu item
    public var title: String = ""
    
    /// Gets or sets the help text for the menu item, this is show next to the title
    public var help: String = ""
    
    /// Gets or sets the action to be invoked when the menu is triggered, can be nil
    public var action: (@MainActor () -> Void)? = nil
    
    /// This is the global setting that can be used as a global shortcut to invoke the action on the menu.
    public var shortcut: Key? = nil
    
    /// The style to use for rendering this menu
    public var style: MenuItemStyle = .plain
    
    /**
     * The hotkey is used when the menu is active, the shortcut can be triggered when the menu is not active.
     *
     * For example HotKey would be "N" when the File Menu is open (assuming there is a "_New" entry
     * if the ShortCut is set to "Control-N", this would be a global hotkey that would trigger as well
     */
    public var hotkey: Character?
    
    var width: Int {
        get {
            return title.cellCount() + help.cellCount() + 1 + 2 +
            (style == .plain ? 0 : 2)
        }
    }
    
    mutating func getHotKey ()
    {
        var nextIsHot = false
        for x in title {
            if x == "_" {
                nextIsHot = true;
            } else {
                if nextIsHot {
                    hotkey = x.uppercased().first
                    break
                }
                nextIsHot = false;
            }
        }
    }
                                            
    /**
     * - Parameters:
     *  - title: Title for the menu item
     *  - help: Help text to display
     *  - action: Method to invoke when the menu is triggered
     *  - shortcut: Global shortcut that can be used to invoke this menu
     *  - hotkey: Key used to activate the menu, when the menu is active
     */
    public init (title: String, help: String = "", action: (@MainActor ()->Void)? = nil, shortcut: Key? = nil, hotkey: Character? = nil, style: MenuItemStyle = .plain)
    {
        self.title = title
        self.help = help
        self.action = action
        self.shortcut = shortcut
        self.hotkey = hotkey
        self.style = style
        if hotkey == nil {
            getHotKey ()
        }
    }
}

/**
 * A menu bar item contains either `MenuBarItem` or `MenuItem`
 */
open class MenuBarItem {
    var title: String
    var titleLen: Int
    var children: [MenuItem?]
    
    /**
     * Initializes a new instance of the menubar item with the specified title and children
     *
     * - Parameters:
     *  - title: The title to display, if the string contains an underscore, the next character
     *    becomes the hotkey, for example "_File" would make "F" the hotkey for the menu entry.
     *  - children: Array of menu items that describe the contents of the menu.
     */
    public init (title: String, children: [MenuItem?], parent: MenuItem? = nil)
    {
       var len = 0
        for ch in title {
            if ch == "_" {
                continue
            }
            len += 1
        }
        titleLen = len
        self.title = title
        self.children = children
    }
}

/**
 * Menus are views displayed vertically that contain various menu items, and are attached to a menubar.
 */
public class Menu: View {
    var barItems: MenuBarItem
    var host: MenuBar
    
    // The current item in the list selected, if -1 it means that the are no selectable entries
    var current: Int
    
    static func makeFrame (_ x: Int, _ y: Int, _ items: [MenuItem?]) -> Rect
    {
        var maxW = 0
        for item in items {
            guard let item else {
                continue
            }
            let l = item.width
            maxW = max(l, maxW)
        }
        return Rect (x: x, y: y, width: maxW + 2, height: items.count + 2)
    }
    
    init (host: MenuBar, x: Int, y: Int, barItems: MenuBarItem)
    {
        self.barItems = barItems
        self.host = host
        self.current = -1
        
        // Find the first non-null entry, odd, but possible
        for i in 0..<barItems.children.count {
            if barItems.children [i] != nil {
                self.current = i
                break
            }
        }
        super.init (frame: Menu.makeFrame (x, y, barItems.children))
        colorScheme = Colors.menu
        canFocus = true
    }
    
    open override func redraw(region: Rect, painter: Painter) {
        driver.setAttribute(colorScheme.normal)
        painter.clear(needDisplay)
        painter.drawFrame(region, padding: 0, fill: false)
        
        for i in 0..<barItems.children.count {
            let item = barItems.children [i]
            
            // fill the background (white space) or draw the separator
            painter.goto (col: 1, row: i+1)
            painter.attribute = item == nil ? colorScheme.normal : (i == current ? colorScheme.focus : colorScheme.normal)
            
            for _ in 0..<frame.width-2 {
                painter.add (rune: item == nil ? driver.hLine : driver.space)
            }
            guard let item else {
                continue
            }
            
            // Draw the menu title.
            painter.goto (col: 2, row: i+1)
            
            painter.drawHotString(text: item.title,
                          hotColor: i == current ? colorScheme.hotFocus : colorScheme.hotNormal,
                          normalColor: i == current ? colorScheme.focus : colorScheme.normal)
            
            // Draw the help string
            let l = item.help.cellCount ()
            painter.goto(col: frame.width-l-2, row: i+1)
            painter.add(str: item.help)
        }
    }
    
    open override func positionCursor() {
        moveTo (col: 2, row: 1+current)
    }
    
    // runs the aciton in the main queue
    func run (action: (@MainActor ()->Void)?)
    {
        if let callback = action {
            DispatchQueue.main.async(execute: callback)
        }
    }
    
    open override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .cursorUp, .controlP:
            if current == -1 {
                break
            }
            repeat {
                current -= 1
                if current < 0 {
                    current = barItems.children.count - 1
                }
            } while barItems.children [current] == nil
            setNeedsDisplay()
            
        case .cursorDown, .controlN:
            if current == -1 {
                break
            }

            repeat {
                current += 1
                if current == barItems.children.count {
                    current = 0
                }
            } while barItems.children [current] == nil
            setNeedsDisplay()
            
        case .cursorLeft, .controlB:
            host.previousMenu()
            
        case .cursorRight, .controlF:
            host.nextMenu()
            
        case .esc:
            host.closeMenu()
            
        case .controlJ: // Return
            host.closeMenu()
            if let child = barItems.children[current] {
                run (action: child.action)
            }
            
        case let .letter(x) where x.isLetter || x.isNumber:
            let upper = x.uppercased()
            for item in barItems.children {
                if let nnitem = item, let hotKey = nnitem.hotkey {
                    if String(hotKey) == upper {
                        host.closeMenu()
                        run (action: nnitem.action)
                        return true
                    }
                }
            }
        default:
            return false
        }
        return true
    }
     
    open override func mouseEvent(event: MouseEvent) -> Bool {
        guard event.pos.y >= 1 else { return true }
        let idx = event.pos.y - 1
        guard idx <= barItems.children.count else { return true }
        guard let item = barItems.children [idx] else { return true }

        if event.flags == .button1Clicked {
            host.closeMenu()
            run (action: item.action)
        }
        
        current = idx
        setNeedsDisplay()
        return true
    }
}

/**
 * A menubar for your application, defaults to be at the top of its container.
 */
open class MenuBar: View {
    public var menus: [MenuBarItem]
    var selected: Int? = nil
    var action: (@MainActor() -> Void)? = nil

    /**
     * Constructs the menubar with the specified array of MenuBarItems, which can contain nil values
     * Use the nil value in the array to get a horizontal line separator
     */
    public init (menus: [MenuBarItem])
    {
        self.menus = menus

        super.init ()
        x = Pos.at (0)
        y = Pos.at (0)
        width = Dim.fill()
        height = Dim.sized (1)
        canFocus = false
        colorScheme = Colors.menu
    }
    
    open override func redraw(region: Rect, painter p: Painter) {
        p.goto(col: 0, row: 0)
        p.attribute = Colors.base.focus
        
        p.add(str: " ".padding(toLength: frame.width, withPad: " ", startingAt: 0))
        p.goto(col: 1, row: 0)
        var pos = 1
        for i in 0..<menus.count {
            let menu = menus [i]
            p.goto(col: pos, row: 0)
            var hotColor, normalColor: Attribute
            if i == selected {
                hotColor = colorScheme.hotFocus
                normalColor = colorScheme.focus
            } else {
                hotColor = Colors.base.focus
                normalColor = Colors.base.focus
            }
            p.drawHotString(text: " " + menu.title + " " + "   ", hotColor: hotColor, normalColor: normalColor)
            pos += menu.titleLen + 3
        }
    }
    
    open override func positionCursor() {
        var pos = 0
        for i in 0..<menus.count {
            if i == selected {
                pos += 1
                moveTo (col: pos, row: 0)
                return
            } else {
                pos += menus [i].titleLen + 4
            }
        }
        moveTo (col: 0, row: 0)
    }
    
    func setSelected(item: MenuItem)
    {
        action = item.action
    }
    
    var openedMenu: Menu? = nil
    var previousFocused: View? = nil
    
    func openMenu (index: Int)
    {
        if let x = openedMenu {
            superview?.removeSubview(x)
        }
        var pos = 0
        for i in 0..<index {
            pos += menus [i].titleLen + 3
        }
        
        let openedMenu = Menu (host: self, x: pos, y: 1, barItems: menus [index])
        superview?.addSubview(openedMenu)
        superview?.setFocus(openedMenu)
        self.openedMenu = openedMenu
    }
    
    // Starts the menu from the hotkey
    func startMenu ()
    {
        if openedMenu != nil {
            return
        }
        selected = 0
        setNeedsDisplay()
        previousFocused = superview?.focused
        openMenu (index: 0)
    }
    
    // Activates the menu, handles either first focus, or activating an entry when it was already active
    // For mouse events.
    func activate (index: Int)
    {
        selected = index
        if openedMenu == nil {
            previousFocused = superview?.focused
        }
        openMenu(index: index)
        setNeedsDisplay()
    }
    
    // Invoked by the Menu class, when the menu is activated
    func closeMenu ()
    {
        selected = nil
        setNeedsDisplay()
        if let openedMenu {
            superview?.removeSubview(openedMenu)
        }
        previousFocused?.superview?.setFocus(previousFocused)
        openedMenu = nil
    }
    
    // Invoked by the Menu class, when the menu is activated
    func previousMenu ()
    {
        guard let sel = selected else {
            return
        }
        let open = sel <= 0 ? menus.count - 1 : sel - 1
        selected = open
        openMenu (index: open)
    }

    // Invoked by the Menu class, when the menu is activated
    func nextMenu ()
    {
        let openIdx: Int
        if let sel = selected {
            openIdx = sel + 1 == menus.count ? 0 : sel+1
        } else {
            openIdx = 0
        }
        selected = openIdx
        openMenu (index: openIdx)
    }
    
    open override func processHotKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .f9:
            startMenu ()
            return true
        default:
            return super.processHotKey(event: event)
        }
    }
    
    open override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .cursorLeft, .controlB:
            if let selected {
                self.selected = selected - 1
                if selected < 0 {
                    self.selected = menus.count - 1
                }
            } else {
                selected = 0
            }
        
        case .cursorRight, .controlF:
            if let selected {
                self.selected = (selected + 1) % menus.count
            } else {
                self.selected = 0
            }
            
        case .esc, .controlC:
            Application.requestStop()
            break
            
        case let .letter (x):
            let target = x.uppercased()
            if let selected, menus [selected].children.count == 0 {
                return false
            }
            if let selected {
                for cmi in menus [selected].children {
                    if let mi = cmi {
                        if let p = mi.title.firstIndex(of: "_") {
                            if target == mi.title [mi.title.index(after: p)].uppercased() {
                                setSelected(item: mi)
                                return true
                            }
                        }
                    }
                }
            }
            return false
            
        default:
            return false
        }
        setNeedsDisplay()
        return true
    }
    
    open override func mouseEvent(event: MouseEvent) -> Bool {
        if event.flags == .button1Clicked {
            var pos = 1
            let cx = event.pos.x
            for i in 0..<menus.count {
                if cx > pos && event.pos.x < pos + 1 + menus [i].titleLen {
                    activate (index: i)
                    return true
                }
                pos += 2 + menus [i].titleLen + 1
            }
        }
        return false
    }
    
    open override var debugDescription: String {
        return "Menubar (\(super.debugDescription))"
    }
}
