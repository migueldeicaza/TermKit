
//
//  File.swift
//
//
//  Created by Miguel de Icaza on 3/27/21.
//

import Foundation
import TermKit

func DemoDesktop2 () -> Toplevel {
    let top = StandardToplevel ()
    
    let w = Window ()
    w.set(x: 1, y: 1, width: 20, height: 10)
    w.allowResize = true
    
    top.addSubview(w)

    let w2 = Window ()
    w2.set(x: 40, y: 1, width: 25, height: 12)
    w2.allowResize = true
    top.addSubview(w2)


    return top
}

// Convenient place to track the open files - we have a 1:1 mapping, an open window is an open file
class FileWindow: Window {
    var filename: String?
    var textView: TextView
    
    init (filename: String?, contents: String = "")
    {
        self.filename = filename
        textView = TextView ()
        textView.text = contents
        super.init(filename ?? "Untitled", padding: 0)
        
        allowMove = true
        allowClose = true
        allowResize = true
        
        textView.fill ()
        addSubview(textView)
        setFocus(textView)
    }
    
    open override var debugDescription: String {
        get {
            return "FileWindow (\(filename))"
        }
    }
}

class SimpleEditor: StandardToplevel {
    
    func place (window: Window) {
        window.frame = Rect (origin: Point.zero, size: desk.bounds.size)
        manage (window: window)
    }
    
    func newFile () {
        let file = FileWindow (filename: nil)
        addSubview(file)
        place (window: file)
    }
    
    func openFile () {
        let open = OpenDialog.init(title: "Open File", message: "Select a file to open")
        open.canChooseDirectories = false
        open.canChooseFiles = true
        open.allowsMultipleSelection = false
        open.present { d in
            if let file = d.filePaths?.first {
                if let contents = try? String(contentsOfFile: file) {
                    let file = FileWindow (filename: file, contents: contents)
                    self.place (window: file)
                } else {
                    MessageBox.error("Error", message: "Could not read contents of file", buttons: ["Ok"]) { _ in }
                }
            }
        }
    }
    
    func saveFile () {
        
    }
    func saveAsFile () {
        
    }
    override init () {
        super.init ()
        
        let menu = MenuBar (
            menus: [
                MenuBarItem (title: "_File", children: [
                    MenuItem (title: "_New", action: newFile),
                    MenuItem (title: "_Open", action: openFile),
                    MenuItem (title: "_Save", action: saveFile),
                    MenuItem (title: "S_ave as", action: saveAsFile),
                    nil,
                    MenuItem (title: "_Quit", action: { Application.requestStop() }),
                ]),
                MenuBarItem (title: "_Edit", children: []),
                MenuBarItem (title: "_Find", children: []),
                MenuBarItem (title: "_Window", children: [])])
        
        addSubview(menu)
    }
}

func DemoDesktop () -> Toplevel {
    let editor = SimpleEditor ()
    
    return editor
}
