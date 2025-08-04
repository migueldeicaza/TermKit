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

// So the debugger can attach
sleep (1)

var driver: Application.DriverType = .curses

for arg in CommandLine.arguments.dropFirst() {
    switch arg {
    case "--driver=unix":
        driver = .unix
    case "--driver=curses":
        driver = .curses
    default:
        print("Unknown argument: \(arg), usage is:")
        print("Example [--driver=[unix|curses]")
        exit(1)
    }
}

// Use the Unix driver (new direct terminal control)
Application.prepare(driverType: driver)

Application.prepare()
let win = Window()
win.x = Pos.at (0)
win.y = Pos.at (1)

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
        try text.text = String(contentsOfFile: fname, encoding: .utf8)
    } catch {}
    
    win.addSubview (text)
    Application.present (top: ntop)
}

func newFile () {}
func openFile () {}
func showHex() {}

func closeTop() {
    Application.requestStop()
}

func makeMenu () -> MenuBar {
    return MenuBar (menus: [
        MenuBarItem(title: "_File", children: [
            MenuItem(title: "Text _Editor Demo", action: showEditor),
            MenuItem(title: "Open _Terminal", action: { openTerminal (win) } ),
            MenuItem(title: "_New", help: "[help: no-op]", action: newFile),
            MenuItem(title: "_Open", help: "[help: no-op]", action: openFile),
            MenuItem(title: "_Close", action: closeTop),
            nil,
            MenuItem(title: "_Quit", action: { Application.shutdown() }),
        ]),
        MenuBarItem(title: "_Edit", children: [
            MenuItem(title: "_Copy (no-op)"),
            MenuItem(title: "C_ut (no-op)"),
            MenuItem(title: "_Paste (no-op)"),
        ])
    ])
}

var frame = Frame ("Samples")
frame.set (x: 10, y: 10, width: 60, height: 20)

var options: [(text: String, func: () -> Toplevel)] = [
    ("Assorted",     { Assorted () }),
    ("File Dialogs", { FileDialogs () }),
    ("Terminal",     { TerminalDemo () }),
    ("DataTable",    { DataTableDialogs () }),
    ("SplitView",    { DemoSplitView () }),
    ("Editor",       { DemoDesktop () }),
    ("Quit",         { Application.shutdown(); return Window () })
]

var list = ListView (items: options.map { $0.0 })
frame.addSubview(list)

list.activate = { item in
    let win = (options [item].func)()
    var newTop: Toplevel
    if win is Window {
        if win.x == nil || win.y == nil {
            win.set (x: 1, y: 1)
        }

        newTop = Toplevel ()
        newTop.addSubviews([makeMenu (), win])
    } else {
        newTop = win
    }
    Application.present(top: newTop)

    return true
}
win.addSubview(frame)

// Create a floating window
let subwin = Window()
subwin.addSubview(Label("Close me"))
subwin.allowResize = true
subwin.set (x: 2, y: 2, width: 10, height: 3)
subwin.closeClicked = { win in
    win.superview?.removeSubview (win)
}

Application.top.addSubview(win)
Application.top.addSubview(subwin)
Application.top.addSubview(makeMenu ())
Application.run()
print ("ending")
