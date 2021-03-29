//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 3/27/21.
//

import Foundation
import TermKit
import SwiftTerm

func openTerminal () {
    let w = Window ()
    w.fill(percentage: 70)
    let t = LocalProcessTerminalView()
    w.addSubview(t)
    t.fill ()
    Application.top.addSubview(w)
}

func TerminalDemo () -> Window {
    let w = Window ()
    w.allowClose = true
    w.allowResize = true
    w.fill(percentage: 70)
    let term = LocalProcessTerminalView()
    w.addSubview(term)
    term.fill ()
    term.frame = Rect (origin: Point (x: 0, y: 0), size: Size(width: 80, height: 25))
    let vars = Terminal.getEnvironmentVariables(termName: "xterm-color")
    term.startProcess(executable: "/bin/bash", environment: vars,execName: "-bash")
    term.feed(text: "Welcome to SwiftTerm in TermKit")
    w.closeClicked = { _ in
        Application.requestStop()
    }
    return w
}
