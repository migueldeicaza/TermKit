//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 5/9/21.
//

import Foundation

/// Provides a Toplevel with a few common bits: a menubar, a statusbar and a desktop where Windows can
/// be added and managed by the StandardTopLevel.
///
/// You would typically create a StandardTopLevel, and then addSubView a MenuBar, and a StatusBar,
/// and these will be automatically placed and tracked.
///
/// To add child windows call the `manage (window:)` method that will start tracking
/// that window
open class StandardToplevel: Toplevel {
    /// Gets or sets the menu for this Toplevel
    public var menubar: MenuBar?
    
    /// Gets or sets the status bar for this Toplevel
    public var statusbar: View? // StatusBar?
    
    /// The view representing the desktop
    public private(set) var desk: View
    
    /// Windows currently managed by this toplevel
    public private(set) var windows: [Window] = []
    
    public override init ()
    {
        desk = Desktop()
        super.init ()
        let menu = MenuBar (menus: [
                            MenuBarItem (title: "File", children: [
                                            MenuItem (title: "Quit", action: { Application.requestStop() })])
                            ])
        let status = StatusBar ()
        status.colorScheme = Colors.dialog
        
        desk.x = Pos.at (0)
        desk.y = Pos.at (1)
        desk.width = Dim.fill ()
        desk.height = Dim.fill () - 1

        addSubviews ([desk, menu, status])
    }
    
    /// Use this to register a window that will be managed
    /// by the StandardToplevel, this allow things like tiling, moving and tile views,
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
    }
    
    /// This removes the window from the list of managed windows (`windows`) and
    /// also removes it from the subviews
    public func drop (window: Window) {
        if let idx = windows.firstIndex(of: window) {
            windows.remove(at: idx)
        }
        desk.removeSubview(window)
    }
    
    open override func addSubview(_ view: View) {
        if view is MenuBar {
            if let existing = menubar {
                removeSubview(existing)
            }
            view.x = Pos.at(0)
            view.y = Pos.at(0)
            view.height = Dim.sized(1)
            view.width = Dim.fill()
            
            self.menubar = (view as! MenuBar)
        }
        if view is StatusBar {
            if let existing = statusbar {
                removeSubview(existing)
            }
            view.x = Pos.at(0)
            view.y = Pos.anchorEnd()-1
            view.width = Dim.fill()
            self.statusbar = (view as! StatusBar)
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

}
