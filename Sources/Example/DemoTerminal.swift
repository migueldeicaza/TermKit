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
    
    // This is added to our window
    init() {
        super.init("Demo")
        allowResize = true
        fill(percentage: 70)
        
        let term = LocalProcessTerminalView(delegate: self)
        addSubview(term)
        term.fill ()
        term.frame = Rect (origin: Point (x: 0, y: 0), size: Size(width: 80, height: 25))
        let vars = Terminal.getEnvironmentVariables(termName: "xterm-color", trueColor: false)
        term.startProcess(executable: "/bin/zsh", environment: vars,execName: "-zsh")
        term.feed(text: "Welcome to SwiftTerm in TermKit")
        
        self.term = term
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
func TerminalDemo () -> Window {
    let w = DemoTerminal()
    w.closeClicked = { _ in
        Application.requestStop()
    }
    return w
}
