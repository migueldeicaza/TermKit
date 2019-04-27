//
//  Menu.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/26/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * A menu item has a title, an associated help text, and an action to execute on activation.
 */
public struct MenuItem {
    /// Gets or sets the title for the menu item
    public var title : String
    
    /// Gets or sets the help text for the menu item, this is show next to the title
    public var help : String
    
    /// Gets or sets the action to be invoked when the menu is triggered
    public var action : () -> Void
    
    /// his is the global setting that can be used as a global shortcut to invoke the action on the menu.
    public var shortcut : Key
    
    /**
     * The hotkey is used when the menu is active, the shortcut can be triggered when the menu is not active.
     *
     * For example HotKey would be "N" when the File Menu is open (assuming there is a "_New" entry
     * if the ShortCut is set to "Control-N", this would be a global hotkey that would trigger as well
     */
    public var hotkey : Character?
    
    var width : Int {
        get {
            return title.cellCount() + help.cellCount() + 1
        }
    }
}

/**
 * A menu bar item contains other menu items.
 */
public class MenuBarItem {
    var title : String
    var titleLen : Int
    var children: [MenuItem]
    
    /**
     * Initializes a new instance of the menubar item with the specified title and children
     *
     * - Parameter title: The title to display, if the string contains an underscore, the next character
     * becomes the hotkey, for example "_File" would make "F" the hotkey for the menu entry.
     * - Parameter children: Array of menu items that describe the contents of the menu.
     */
    public init (title : String, children : [MenuItem])
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

public class Menu : View {
    var barItems: MenuBarItem
    var host: MenuBar
    
    static func makeFrame (_ x: Int, _ y: Int, _ items: [MenuItem]) -> Rect
    {
        var maxW = 0
        for item in items {
            let l = item.width
            maxW = max(l, maxW)
        }
        return Rect (x: x, y: y, width: maxW + 2, height: items.count + 2)
    }
    
    init (host: MenuBar, x: Int, y: Int, barItems: MenuBarItem)
    {
        self.barItems = barItems
        self.host = host
        super.init (frame: Menu.makeFrame (x, y, barItems.children))
        colorScheme = Colors.menu
        canFocus = true
    }
    
    // TODO this one
}

/**
 * A menubar for your application
 *
 * Example:
 * ```
 *
 * ```
 */
public class MenuBar : View {
    public var menus: [MenuBarItem]
    var selected : Int? = nil
    var action : () -> Void = {}

    public init (menus: [MenuBarItem])
    {
        self.menus = menus

        super.init ()
        x = Pos.at (0)
        y = Pos.at (0)
        width = Dim.fill()
        height = Dim(1)
        canFocus = false
        colorScheme = Colors.menu
    }
    
    public override func redraw(region: Rect) {
        moveTo (col: 0, row: 0)
        driver.setAttribute(Colors.base.focus)
        for _ in 0..<frame.width {
            driver.addRune(" ")
        }
        moveTo (col: 1, row: 0)
        var pos = 1
        for i in 0..<menus.count {
            let menu = menus [i]
            moveTo(col: pos, row: 0)
            var hotColor, normalColor: Attribute
            if i == selected {
                hotColor = colorScheme!.hotFocus
                normalColor = colorScheme!.focus
            } else {
                hotColor = Colors.base.focus
                normalColor = Colors.base.focus
            }
            drawHotString(text: " " + menu.title + " " + "   ", hotColor: hotColor, normalColor: normalColor)
            pos += menu.titleLen + 3
        }
    }
    
    public override func positionCursor() {
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
    
    func selected (item: MenuItem)
    {
        action = item.action
    }
    
    var openedMenu: Menu? = nil
    var previousFocused: View? = nil
    
    func openMenu (index: Int)
    {
        if let x = openedMenu {
            superview?.remove (view: x)
        }
        var pos = 0
        for i in 0..<index {
            pos += menus [i].titleLen + 3
        }
        openedMenu = Menu (host: self, x: pos, y: 1, barItems: menus [index])
        superview?.addSubview(openedMenu!)
        superview?.setFocus(openedMenu)
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
        openMenu (index: selected!)
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
    
    func closeMenu ()
    {
        selected = nil
        setNeedsDisplay()
        superview?.remove(view: openedMenu!)
        previousFocused?.superview?.setFocus(previousFocused)
        openedMenu = nil
    }
    
    func previousMenu ()
    {
        guard let sel = selected else {
            return
        }
        selected = sel <= 0 ? menus.count - 1 : sel - 1
        openMenu (index: selected!)
    }

    func nextMenu ()
    {
        if let sel = selected {
            selected = sel + 1 == menus.count ? 0 : sel+1
        } else {
            selected = 0
        }
        openMenu (index: selected!)
    }
    
    public override func processHotKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .F9:
            startMenu ()
            return true
        default:
            return super.processHotKey(event: event)
        }
    }
    
    public override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .CursorLeft, .ControlB:
            selected = selected! - 1
            if selected! < 0 {
                selected = menus.count - 1
            }
        
        case .CursorRight, .ControlF:
            selected = (selected! + 1) % menus.count
            
        case .Esc, .ControlC:
            // TODO: running = false
            break
            
        case let .Letter (x):
            let target = x.uppercased()
            if menus [selected!].children.count == 0 {
                return false
            }
            for mi in menus [selected!].children {
                if let p = mi.title.firstIndex(of: "_") {
                    if target == mi.title [mi.title.index(after: p)].uppercased() {
                        selected(item: mi)
                        return true
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
    
    public override func mouseEvent(event: MouseEvent) -> Bool {
        if event.flags == .button1Clicked {
            var pos = 1
            let cx = event.x
            for i in 0..<menus.count {
                if cx > pos && event.x < pos + 1 + menus [i].titleLen {
                    activate (index: i)
                    return true
                }
                pos += 2 + menus [i].titleLen + 1
            }
        }
        return false
    }
}
