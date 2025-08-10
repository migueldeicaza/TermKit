//
//  DemoHost.swift
//  TermKit
//
//  Created by Miguel de Icaza on 8/10/25.
//

import TermKit
///
/// Sample toplevel with some common behavior for most demos

class DemoHost: Toplevel {
    public let topWindow: Window
    public let statusBar: StatusBar
    public var menu: MenuBar?
    
    init(title: String) {
        topWindow = Window(title)
        statusBar = StatusBar()
        super.init()

        menu = MenuBar(menus: [
            MenuBarItem(title: "_File", children: [
                MenuItem(title: "_Close", action: {
                    Application.requestStop()
                })
                  ])])
        

        topWindow.closeClicked = { _ in
            Application.requestStop()
        }
        fill()
        
        // Setup our container
        topWindow.fill()
        topWindow.y = Pos.at(1)
        topWindow.height = Dim.fill(1) // Leave space for status bar at bottom
        addSubview(topWindow)
        
        // Default statusbar
        statusBar.addHotkeyPanel(id: "quit", hotkeyText: "Control-C", labelText: "Quit", hotkey: .controlC) {
            Application.requestStop()
        }
        addSubview(statusBar)
        if let menu {
            addSubview(menu)
        }
        
        setupDemo()
    }
    
    func setMenu(_ menu: MenuBar) {
        removeSubview(menu)
        self.menu = menu
        addSubview(menu)
    }
    
    /// Subclasses fill the 'topWindow' with their demo
    func setupDemo() {}
}
