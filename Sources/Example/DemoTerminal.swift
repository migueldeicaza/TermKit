//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 3/27/21.
//

import Foundation
import TermKit
import SwiftTerm

// This is added to our window
func openTerminal (_ on: View) {
    let w = makeTerminalWindow()
    w.closeClicked = { term in
        term.superview?.removeSubview(term)
    }
    
    on.addSubview(w)
}

func makeTerminalWindow () -> Window {
    let w = Window ()
    w.allowClose = true
    w.allowResize = true
    w.fill(percentage: 70)
    let term = LocalProcessTerminalView()
    w.addSubview(term)
    term.fill ()
    term.frame = Rect (origin: Point (x: 0, y: 0), size: Size(width: 80, height: 25))
    let vars = Terminal.getEnvironmentVariables(termName: "xterm-color", trueColor: false)
    term.startProcess(executable: "/bin/zsh", environment: vars,execName: "-zsh")
    term.feed(text: "Welcome to SwiftTerm in TermKit")
    return w
}

// This one will be Application.presented
func TerminalDemo () -> Window {
    let w = makeTerminalWindow ()
    w.closeClicked = { _ in
        Application.requestStop()
    }
    return w
}
