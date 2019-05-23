//
//  main.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 3/6/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation
import Darwin.ncurses

// Creates a nested editor
func showEditor() {
    let ntop = Toplevel()
    ntop.fill ()
    let menu = MenuBar(menus: [
        MenuBarItem (title: "_File", children: [
            MenuItem (title: "_Close", action: {
                Application.requestStop()
                
            } )
            ])
        ])
    ntop.addSubview (menu)
    let fname = "/etc/passwd"
    
    let win = Window ("fname", padding: 0)
    win.fill ()
    win.y = Pos.at(1)
    ntop.addSubview (win)
    
    let text = TextView()
    text.fill ()
    do {
        try text.text = String(contentsOfFile: fname)
    } catch {}
    
    win.addSubview (text)
    Application.run(top: ntop)
}

func newFile () {}
func openFile () {}
func showHex() {}
func closeApp() {}

Application.prepare()
var menu = MenuBar (menus: [
    MenuBarItem(title: "_File", children: [
        MenuItem(title: "Text Editor Demo", action: showEditor),
        MenuItem(title: "_New", help: "Creates new file", action: newFile),
        MenuItem(title: "_Open", action: openFile),
        MenuItem(title: "_Hex", action: showHex),
        MenuItem(title: "_Close", action: closeApp),
        nil,
        MenuItem(title: "_Quit", action: { Application.shutdown() }),
    ]),
    MenuBarItem(title: "_Edit", children: [
        MenuItem(title: "_Copy"),
        MenuItem(title: "C_ut"),
        MenuItem(title: "_Paste"),
    ])
])

print ("starting")
let win = Window()
win.x = Pos.at (0)
win.y = Pos.at (1)
//win.width = Dim.fill()
//win.height = Dim.fill ()
win.width = Dim (100)
win.height = Dim (80)

// Test the filling
if false {
    let another=TextField ("Another")
    another.x=Pos.at(0)
    another.y=Pos.at(0)
    another.width = Dim.fill()
    win.addSubview(another)
}

if true {
    let loginLabel = Label ("Login:")
    loginLabel.x = Pos.at (10)
    loginLabel.y = Pos.at (10)
    loginLabel.width = Dim(10)
    
    let loginField = TextField("")
    loginField.x = Pos.right(of: loginLabel) + 2
    loginField.y = Pos.top(of: loginLabel)
    loginField.width = Dim (30)
    
    let pass = Label ("Password")
    //pass.x = Pos.left(of: loginLabel)
    pass.x = Pos.at (10)
    //pass.y = Pos.bottom(of: loginLabel) + 1
    pass.y = Pos.at (12)
    pass.width = Dim(10)
    pass.height = Dim(1)
    
    let passField = TextField ("")
    //passField.x = Pos.left(of: loginField)
    passField.x = Pos.right(of: pass) + 2
    //passField.y = Pos.top(of: loginField)
    passField.y = Pos.top(of: pass)
    pass.width = Dim(10)
    pass.height = Dim(1)
    
    win.addSubviews([loginLabel, loginField, pass, passField])
}
Application.top.addSubview(win)
Application.top.addSubview(menu)
Application.run()
print ("ending")
