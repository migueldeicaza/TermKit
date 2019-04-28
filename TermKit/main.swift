//
//  main.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 3/6/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation
import Darwin.ncurses

func showEditor() {}
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
    ])
])

print ("starting")
let win = Window()
win.x = Pos.at (0)
win.y = Pos.at (0)
win.width = Dim(20)
win.height = Dim (20)
let l = Label ("Hello")

Application.top.addSubview(win)
Application.top.addSubview(menu)
Application.run()
print ("ending")
