//
//  main.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 3/6/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation
import Darwin.ncurses
import TermKit
import OpenCombine
// So the debugger can attach
sleep (1)

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
//win.width = Dim.sized (100)
//win.height = Dim.sized (80)
var maybe = false

// Test the filling
if maybe {
    let another=TextField ("Another")
    another.x=Pos.at(0)
    another.y=Pos.at(0)
    another.width = Dim.fill()
    win.addSubview(another)
}
var c, d, e: AnyCancellable

if true {
    let loginLabel = Label ("Login:")
    loginLabel.x = Pos.at (10)
    loginLabel.y = Pos.at (10)
    loginLabel.width = Dim.sized(10)
    
    let loginField = TextField("")
    loginField.x = Pos.right(of: loginLabel) + 2
    loginField.y = Pos.top(of: loginLabel)
    loginField.width = Dim.sized (30)
    
    let pass = Label ("Password: ")
    //pass.x = Pos.left(of: loginLabel)
    pass.x = Pos.at (10)
    //pass.y = Pos.bottom(of: loginLabel) + 1
    pass.y = Pos.at (12)
    pass.width = Dim.sized(10)
    pass.height = Dim.sized(1)
    
    let passField = TextField ("")
    //passField.x = Pos.left(of: loginField)
    passField.x = Pos.right(of: pass) + 2
    //passField.y = Pos.top(of: loginField)
    passField.y = Pos.top(of: pass)
    passField.width = Dim.sized (30)
    pass.width = Dim.sized(10)
    pass.height = Dim.sized(1)
    
    let remember = Checkbox ("Remember")
    remember.x = Pos.left (of: loginLabel)
    remember.y = Pos.top(of: passField) + 1
    let rememberCount = Label ("Remember has not been toggled")
    rememberCount.y = Pos.top (of: passField) + 2
    rememberCount.x = remember.x!
    var count = 0
    c = remember.toggled.sink { view in
        count += 1
        rememberCount.text = "Remember has been toggled \(count) times"
    }
    
    let b1 = Button("Button1")
    b1.x = Pos.at (10)
    b1.y = Pos.at (15)
    b1.width = Dim.sized (12)
    d = b1.clicked.sink { v in
        rememberCount.text = "You clicked the Button1"
    }
    let b2 = Button ("Default")
    b2.x = Pos.at (10)
    b2.y = Pos.at (16)
    b2.width = Dim.sized (12)
    b2.isDefault = true
    e = b2.clicked.sink { v in
        rememberCount.text = "Default button was activated"
        MessageBox.query (
            "Default",
            message: "This is the question we pose ourselves",
            buttons: ["Yes", "No", "Maybe"],
            completion: { button in
                rememberCount.text = button == -1 ? "User canceled" : "User chose \(button)"
            }
        )
    }
    win.addSubviews([loginLabel, loginField, pass, passField, remember, rememberCount, b1, b2])
}
Application.top.addSubview(win)
Application.top.addSubview(menu)
Application.run()
print ("ending")
