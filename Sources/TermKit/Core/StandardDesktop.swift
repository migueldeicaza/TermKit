//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 5/9/21.
//

import Foundation

/// Provides a Toplevel with a few common bits: a menubar, a statusbar and a desktop where Windows can
/// be added and managed by the StandardDesktop.
///
/// You would typically create a StandardDesktop, and then addSubView a MenuBar, and a StatusBar,
/// and these will be automatically placed and tracked.
///
/// To add child windows call the `manage (window:)` method that will start tracking
/// that window
open class StandardDesktop: Toplevel {
    /// Gets or sets the menu for this Toplevel
    public var menubar: MenuBar?
    
    /// Gets or sets the status bar for this Toplevel
    public var statusbar: View? // StatusBar?
    
    /// The view representing the desktop
    public private(set) var desk: View
    
    /// Windows currently managed by this toplevel
    public private(set) var windows: [Window] = []
    // Track minimized windows by identifier
    private var minimizedWindows: Set<ObjectIdentifier> = []
    private var windowsMenuIndex: Int? = nil
    
    public override init ()
    {
        desk = SolidBackground()
        super.init ()
        // Build default menu with File and Window menus
        let fileMenu = MenuBarItem(title: "_File", children: [
            MenuItem(title: "_Quit", action: { Application.requestStop() })
        ])
        let windowMenu = MenuBarItem(title: "_Window", children: [])
        let menu = MenuBar(menus: [fileMenu, windowMenu])
        self.menubar = menu
        self.windowsMenuIndex = 1
        let status = StatusBar ()
        status.colorScheme = Colors.dialog
        
        desk.x = Pos.at (0)
        desk.y = Pos.at (1)
        desk.width = Dim.fill ()
        desk.height = Dim.fill () - 1

        addSubviews ([desk, menu, status])
        rebuildWindowsMenu()
    }
    
    /// Use this to register a window that will be managed
    /// by the StandardDesktop, this allow things like tiling, moving and tile views,
    /// to remove a window that is being managed, call `drop`
    public func manage (window: Window) {
        // Make sure this wont use the layout manager
        window.x = nil
        window.y = nil
        window.width = nil
        window.height = nil
        window.layoutStyle = .fixed
        
        windows.append(window)
        desk.addSubview(window)
        rebuildWindowsMenu()
    }
    
    /// This removes the window from the list of managed windows (`windows`) and
    /// also removes it from the subviews
    public func drop (window: Window) {
        if let idx = windows.firstIndex(of: window) {
            windows.remove(at: idx)
        }
        desk.removeSubview(window)
        minimizedWindows.remove(ObjectIdentifier(window))
        rebuildWindowsMenu()
    }
    
    open override func addSubview(_ view: View) {
        if let menuBarView = view as? MenuBar {
            if let existing = menubar {
                removeSubview(existing)
            }
            view.x = Pos.at(0)
            view.y = Pos.at(0)
            view.height = Dim.sized(1)
            view.width = Dim.fill()
            
            self.menubar = menuBarView
            // Try to locate a Window menu to manage
            if let idx = menuBarView.menus.firstIndex(where: { $0.title.localizedCaseInsensitiveContains("window") }) {
                windowsMenuIndex = idx
            } else {
                windowsMenuIndex = nil
            }
            rebuildWindowsMenu()
        }
        if let statusBarView = view as? StatusBar {
            if let existing = statusbar {
                removeSubview(existing)
            }
            view.x = Pos.at(0)
            view.y = Pos.anchorEnd()-1
            view.width = Dim.fill()
            self.statusbar = statusBarView
        }
        super.addSubview(view)
    }
    
    open override func removeSubview(_ view: View) {
        if view == self.menubar {
            self.menubar = nil
        }
        if view == self.statusbar {
            self.statusbar = nil
        }
        super.removeSubview(view)
    }

    // MARK: - Window management helpers
    private func activeWindow() -> Window? {
        guard let focused = Application.current?.focused else { return nil }
        for w in windows {
            if focused.isSubview(of: w) || w === focused { return w }
        }
        // Fallback: topmost non-minimized window
        for sub in desk.subviews.reversed() {
            if let w = sub as? Window, !minimizedWindows.contains(ObjectIdentifier(w)) {
                return w
            }
        }
        return nil
    }
    
    private func visibleWindows() -> [Window] {
        windows.filter { !minimizedWindows.contains(ObjectIdentifier($0)) && $0.superview === desk }
    }
    
    /// Moves focus to the next visible window in the list.
    public func focusNextWindow() {
        let vis = visibleWindows()
        guard !vis.isEmpty else { return }
        guard let current = activeWindow(), let idx = vis.firstIndex(of: current) else {
            desk.setFocus(vis.first)
            return
        }
        let next = vis[(idx + 1) % vis.count]
        desk.bringSubviewToFront(next)
        desk.setFocus(next)
    }
    
    /// Moves focus to the previous visible window in the list.
    public func focusPreviousWindow() {
        let vis = visibleWindows()
        guard !vis.isEmpty else { return }
        guard let current = activeWindow(), let idx = vis.firstIndex(of: current) else {
            desk.setFocus(vis.first)
            return
        }
        let prev = vis[(idx + vis.count - 1) % vis.count]
        desk.bringSubviewToFront(prev)
        desk.setFocus(prev)
    }
    
    /// Maximizes the currently active window to fill the entire desktop area.
    public func maximizeActiveWindow() {
        guard let w = activeWindow() else { return }
        w.frame = desk.bounds
        desk.bringSubviewToFront(w)
        desk.setFocus(w)
    }
    
    /// Minimizes the currently active window, removing it from the desktop view.
    public func minimizeActiveWindow() {
        guard let w = activeWindow() else { return }
        minimizedWindows.insert(ObjectIdentifier(w))
        desk.removeSubview(w)
        rebuildWindowsMenu()
    }
    
    /// Specifies the position where a window should be docked on the desktop.
    public enum DockPosition {
        /// Dock to the left half of the desktop.
        case left
        /// Dock to the right half of the desktop.
        case right
        /// Dock to the top half of the desktop.
        case top
        /// Dock to the bottom half of the desktop.
        case bottom
    }

    /// Docks the currently active window to the specified position.
    /// - Parameter pos: The position where the window should be docked.
    public func dockActiveWindow(_ pos: DockPosition) {
        guard let w = activeWindow() else { return }
        let b = desk.bounds
        switch pos {
        case .left:
            w.frame = Rect(x: b.minX, y: b.minY, width: b.width/2, height: b.height)
        case .right:
            w.frame = Rect(x: b.minX + b.width/2, y: b.minY, width: b.width - b.width/2, height: b.height)
        case .top:
            w.frame = Rect(x: b.minX, y: b.minY, width: b.width, height: b.height/2)
        case .bottom:
            w.frame = Rect(x: b.minX, y: b.minY + b.height/2, width: b.width, height: b.height - b.height/2)
        }
        desk.bringSubviewToFront(w)
        desk.setFocus(w)
    }
    
    /// Arranges all visible windows in a grid pattern filling the desktop.
    public func tileWindows() {
        let vis = visibleWindows()
        guard !vis.isEmpty else { return }
        let n = vis.count
        // Simple grid layout
        let cols = Int(ceil(sqrt(Double(n))))
        let rows = Int(ceil(Double(n) / Double(cols)))
        let b = desk.bounds
        let cellW = max(1, b.width / cols)
        let cellH = max(1, b.height / rows)
        for (i, w) in vis.enumerated() {
            let r = i / cols
            let c = i % cols
            let x = b.minX + c*cellW
            let y = b.minY + r*cellH
            // Last col/row take remaining space
            let wWidth = (c == cols-1) ? (b.minX + b.width - x) : cellW
            let wHeight = (r == rows-1) ? (b.minY + b.height - y) : cellH
            w.frame = Rect(x: x, y: y, width: wWidth, height: wHeight)
        }
    }
    
    // Rebuild the Window menu to reflect current state and enablement
    private func rebuildWindowsMenu() {
        guard let menubar, let widx = windowsMenuIndex, widx < menubar.menus.count else { return }
        let hasAny = !windows.isEmpty
        let vis = visibleWindows()
        let hasFocus = activeWindow() != nil
        let hasMultiple = vis.count > 1
        var children: [MenuItem?] = [
            MenuItem(title: "_Maximize", action: { [weak self] in self?.maximizeActiveWindow() }, isEnabled: hasFocus),
            MenuItem(title: "Mi_nimize", action: { [weak self] in self?.minimizeActiveWindow() }, isEnabled: hasFocus),
            MenuItem(title: "_Tile", action: { [weak self] in self?.tileWindows() }, isEnabled: vis.count >= 2),
            MenuItem(title: "_Dock Left", action: { [weak self] in self?.dockActiveWindow(.left) }, isEnabled: hasFocus),
            MenuItem(title: "Dock _Right", action: { [weak self] in self?.dockActiveWindow(.right) }, isEnabled: hasFocus),
            MenuItem(title: "Dock _Top", action: { [weak self] in self?.dockActiveWindow(.top) }, isEnabled: hasFocus),
            MenuItem(title: "Dock _Bottom", action: { [weak self] in self?.dockActiveWindow(.bottom) }, isEnabled: hasFocus),
            nil,
            MenuItem(title: "_Next Window", action: { [weak self] in self?.focusNextWindow() }, isEnabled: hasMultiple),
            MenuItem(title: "_Previous Window", action: { [weak self] in self?.focusPreviousWindow() }, isEnabled: hasMultiple),
            nil
        ]
        // Append list of windows
        for w in windows {
            let isMin = minimizedWindows.contains(ObjectIdentifier(w))
            let title = (w.title ?? "Window") + (isMin ? " (minimized)" : "")
            children.append(MenuItem(title: title, action: { [weak self] in
                guard let self else { return }
                if isMin {
                    self.minimizedWindows.remove(ObjectIdentifier(w))
                    self.desk.addSubview(w)
                }
                self.desk.bringSubviewToFront(w)
                self.desk.setFocus(w)
            }, isEnabled: hasAny))
        }
        menubar.menus[widx] = MenuBarItem(title: "_Window", children: children)
        menubar.setNeedsDisplay()
    }
    
    // Keep Window menu enablement fresh on focus changes
    open override func setFocus(_ view: View?) {
        super.setFocus(view)
        rebuildWindowsMenu()
    }

}
