//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 3/27/21.
//

import Foundation
import TermKit
import SwiftTerm

class DemoTerminal: Window, TermKit.LocalProcessTerminalViewDelegate {
    func sizeChanged(source: TermKit.LocalProcessTerminalView, newCols: Int, newRows: Int) {
        //
    }
    
    func setTerminalTitle(source: TermKit.LocalProcessTerminalView, title: String) {
        self.title = title
    }
    
    func processTerminated(source: TermKit.LocalProcessTerminalView, exitCode: Int32?) {
        if let exitCode {
            term?.feed(text: "\nTerminal exited with code: \(exitCode), you can close the window.\n")
        } else {
            term?.feed(text: "\nTerminal exited due to an I/O error\n")
        }
    }
    
    var term: TermKit.LocalProcessTerminalView?
    @MainActor static var count = 0
    var id = 0
    // This is added to our window
    init() {
        super.init("Running Shell")
        let c = MainActor.assumeIsolated {
            DemoTerminal.count += 1
            return DemoTerminal.count
        }
        id = c
        title = "Terminal #\(c)"
        allowResize = true
        allowMove = true
        
        let term = LocalProcessTerminalView(delegate: self)
        addSubview(term)
        term.fill ()
        //term.frame = Rect (origin: Point (x: 0, y: 0), size: Size(width: 80, height: 25))
        let vars = Terminal.getEnvironmentVariables(termName: "xterm-color", trueColor: false)
        term.startProcess(executable: "/bin/zsh", environment: vars,execName: "-zsh")
        term.feed(text: "Welcome to SwiftTerm in TermKit")
        
        self.term = term
    }
    
    override func setFocus(_ view: View?) {
        superview?.bringSubviewToFront(self)
        super.setFocus(view)
    }
}

func openTerminal (_ on: View) {
    let w = DemoTerminal()
    w.closeClicked = { term in
        term.superview?.removeSubview(term)
    }
    
    on.addSubview(w)
}

// This one will be Application.presented
class TerminalDemo: DemoHost {
    var newDelta = 0
    
    init() {
        super.init(title: "Demo Terminal")
        setMenu(MenuBar(menus: [
            MenuBarItem(title: "File", children: [
                MenuItem(title: "_New Terminal", action: newTerminal),
                MenuItem(title: "_Quit", action: { Application.requestStop() })
            ])
        ]))
        statusBar.removePanel(id: "quit")
    }
    
    func newTerminal() {
        let frame = Rect(
            x: newDelta,
            y: newDelta,
            width: Int(Double(Application.terminalSize.width)*0.7),
            height: Int(Double(Application.terminalSize.height)*0.7)
        )
        newDelta += 2
        let terminal = DemoTerminal()
        terminal.frame = frame
        topWindow.addSubview(terminal)
        topWindow.bringForward(subview: terminal)
        topWindow.setFocus(terminal)
    }
    
    override func setupDemo() {
        newTerminal()
    }
}
