//
//  main.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 3/6/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation
#if os(macOS)
import Darwin.ncurses
import os
#endif
import TermKit

#if os(macOS)
@available(OSX 11.0, *)
private var logger: Logger = Logger(subsystem: "termkit", category: "TermKit")
#endif

@MainActor func log(_ s: String) {
#if os(macOS)
if #available(macOS 11.0, *) {
    logger.log("log: \(s, privacy: .public)")
    return
}
#endif
}
// So the debugger can attach
sleep (1)

var options: [(id: String, text: String, func: () -> Toplevel)] = [
    (id: "misc",      "Assorted",     { DemoAssorted() }),
    (id: "dialogs",   "File Dialogs", { FileDialogs() }),
    (id: "terminal",  "Terminal",     { TerminalDemo() }),
    (id: "datatable", "DataTable",    { DataTableDialogs() }),
    (id: "splitview", "SplitView",    { DemoSplitView() }),
    (id: "drawing",   "Drawing",      { DemoDrawing() }),
    (id: "tabview",   "TabView",      { DemoTabBar() }),
    (id: "spinner",   "Spinner",      { DemoSpinner() }),
    (id: "statusbar", "StatusBar",    { createStatusBarDemo() }),
    (id: "windows",   "Windows",      { DemoWindow() }),
    (id: "editor",    "Editor",       { DemoDesktop() }),
]
var demoToplevel: (() -> Toplevel)? = nil

// Check for --demo=value parameter
for arg in ProcessInfo.processInfo.arguments {
    if arg.hasPrefix("--demo=") {
        let demoId = String(arg.dropFirst(7)) // Remove "--demo=" prefix
        if let demo = options.first(where: { $0.id == demoId }) {
            demoToplevel = demo.func
        } else {
            print("Unknown demo: \(demoId)")
            print("Available demos: \(options.map { $0.id }.joined(separator: ", "))")
            exit(1)
        }
    }
}

// Use the Unix driver (new direct terminal control)
Application.prepare()
if let demoToplevel {
    showSingleDemo(demoToplevel())
    Application.run()
    exit(0)

}
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

func show(_ top: Toplevel) {
    var newTop: Toplevel
    if let win = top as? Window {
        if win.x == nil || win.y == nil {
            win.set (x: 1, y: 1)
        }
        
        newTop = Toplevel ()
        newTop.addSubviews([makeMenu (), win])
    } else {
        newTop = top
    }
    Application.present(top: newTop)
}

func showSingleDemo(_ top: Toplevel) {
    if let win = top as? Window {
        win.closeClicked = { _ in Application.shutdown() }
        win.set(x: 1, y: 1)
        Application.top.addSubview(win)
    } else {
        Application.top.addSubview(top)
    }
}

let win = Window()
win.x = Pos.at (0)
win.y = Pos.at (1)

var frame = Frame ("Samples")
frame.set (x: 10, y: 8, width: 60, height: 15)

var list = ListView (items: options.map { $0.1 } + ["Quit"])
frame.addSubview(list)

list.activate = { item in
    if item > options.count {
        // It is the appended quit option
        Application.shutdown()
        return true
    }
    let win = (options [item].func)()
    show(win)

    return true
}
win.addSubview(frame)

Application.top.addSubview(win)

Application.top.addSubview(makeMenu ())
let status = StatusBar()
Application.top.addSubview(status)
status.addHotkeyPanel(id: "quit", hotkeyText: "Control-C", labelText: "Quit", hotkey: .controlC) {
    Application.requestStop()
}
Application.run()
print ("ending")
