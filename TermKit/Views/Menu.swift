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
    
    /// Gets or sets the action to be invoked when the menu is triggered, can be nil
    public var action : (() -> Void)?
    
    /// his is the global setting that can be used as a global shortcut to invoke the action on the menu.
    public var shortcut : Key?
    
    /**
     * The hotkey is used when the menu is active, the shortcut can be triggered when the menu is not active.
     *
     * For example HotKey would be "N" when the File Menu is open (assuming there is a "_New" entry
     * if the ShortCut is set to "Control-N", this would be a global hotkey that would trigger as well
     */
    public var hotkey : Character?
    
    var width : Int {
        get {
            return title.cellCount() + help.cellCount() + 1 + 2
        }
    }
    
    /**
     */
    public init (title: String, help: String = "", action: (()->Void)? = nil, shortcut: Key? = nil, hotkey: Character? = nil)
    {
        self.title = title
        self.help = help
        self.action = action
        self.shortcut = shortcut
        self.hotkey = hotkey
    }
}

/**
 * A menu bar item contains other menu items.
 */
public class MenuBarItem {
    var title : String
    var titleLen : Int
    var children: [MenuItem?]
    
    /**
     * Initializes a new instance of the menubar item with the specified title and children
     *
     * - Parameter title: The title to display, if the string contains an underscore, the next character
     * becomes the hotkey, for example "_File" would make "F" the hotkey for the menu entry.
     * - Parameter children: Array of menu items that describe the contents of the menu.
     */
    public init (title : String, children : [MenuItem?])
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

//
// Displays the menu list when it is activated
//
public class Menu : View {
    var barItems: MenuBarItem
    var host: MenuBar
    
    // The current item in the list selected, if -1 it means that the are no selectable entries
    var current: Int
    
    static func makeFrame (_ x: Int, _ y: Int, _ items: [MenuItem?]) -> Rect
    {
        var maxW = 0
        for item in items {
            if item == nil {
                continue
            }
            let l = item!.width
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
    
    public override func redraw(region: Rect) {
        driver.setAttribute(colorScheme!.normal)
        drawFrame(region, padding: 0, fill: true)
        
        for i in 0..<barItems.children.count {
            let item = barItems.children [i]
            
            // fill the background (white space) or draw the separator
            moveTo (col: 1, row: i+1)
            driver.setAttribute(item == nil ? colorScheme!.normal : (i == current ? colorScheme!.focus : colorScheme!.normal))
            for _ in 0..<frame.width-2 {
                driver.addRune (item == nil ? driver.hLine : driver.space)
            }
            if item == nil {
                continue
            }
            
            // Draw the menu title.
            moveTo (col: 2, row: i+1)
            
            drawHotString(text: item!.title,
                          hotColor: i == current ? colorScheme!.hotFocus : colorScheme!.hotNormal,
                          normalColor: i == current ? colorScheme!.focus : colorScheme!.normal)
            
            // Draw the help string
            let l = item!.help.cellCount ()
            moveTo(col: frame.width-l-2, row: i+1)
            driver.addStr(item!.help)
        }
    }
    
    public override func positionCursor() {
        moveTo (col: 2, row: 1+current)
    }
    
    // runs the aciton in the main queue
    func run (action: (()->Void)?)
    {
        if let callback = action {
            DispatchQueue.main.async(execute: callback)
        }
    }
    
    public override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .CursorUp, .ControlP:
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
            
        case .CursorDown, .ControlN:
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
            
        case .CursorLeft, .ControlB:
            host.previousMenu()
            
        case .CursorRight, .ControlF:
            host.nextMenu()
            
        case .Esc:
            host.closeMenu()
            
        case .ControlJ: // Return
            host.closeMenu()
            run (action: barItems.children [current]!.action)
            
        case let .Letter(x) where x.isLetter || x.isNumber:
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
            break
        }
        return true
    }
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
    var action : (() -> Void)? = nil

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
    
    // Invoked by the Menu class, when the menu is activated
    func closeMenu ()
    {
        selected = nil
        setNeedsDisplay()
        superview?.remove(view: openedMenu!)
        previousFocused?.superview?.setFocus(previousFocused)
        openedMenu = nil
    }
    
    // Invoked by the Menu class, when the menu is activated
    func previousMenu ()
    {
        guard let sel = selected else {
            return
        }
        selected = sel <= 0 ? menus.count - 1 : sel - 1
        openMenu (index: selected!)
    }

    // Invoked by the Menu class, when the menu is activated
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
            for cmi in menus [selected!].children {
                if let mi = cmi {
                    if let p = mi.title.firstIndex(of: "_") {
                        if target == mi.title [mi.title.index(after: p)].uppercased() {
                            selected(item: mi)
                            return true
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
    
    public override var debugDescription: String {
        return "Menubar (\(super.debugDescription))"
    }
}
