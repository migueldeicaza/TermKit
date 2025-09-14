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
    nonisolated(unsafe) static var untitledCount = 0
    var filename: String?
    var textView: TextView
    
    init (filename: String?, contents: String = "")
    {
        self.filename = filename
        textView = TextView ()
        textView.text = contents
        super.init(filename ?? FileWindow.getUntitled())
        
        allowMove = true
        allowResize = true
        
        textView.fill ()
        addSubview(textView)
        _ = textView.becomeFirstResponder()
    }
    
    static func getUntitled () -> String {
        if FileWindow.untitledCount == 0 { return "Untitled" }
        FileWindow.untitledCount += 1
        return "Untitled-\(FileWindow.untitledCount)"
    }
    
    open override var debugDescription: String {
        get {
            return "FileWindow (\(filename ?? "Untitled"))"
        }
    }
    
    // expects filename to be set
    func saveFile (_ target: String) {
        do {
            try textView.text?.write(toFile: target, atomically: true, encoding: .utf8)
            isDirty = false
        } catch {
            MessageBox.error("Error", message: "Could not save the file to \(target)", buttons: ["Ok"]) { _ in }
        }
    }

    func saveAs (_ initial: String?) {
        let s = SaveDialog (title: "Save", message: "Choose file to save")
        s.filePath = initial ?? ""
        
        s.present {_ in
            guard let target = s.fileName else {
                return
            }
            self.filename = target
            self.saveFile (target)
        }
    }
    
    func save() {
        if let filename {
            saveFile (filename)
        } else {
            saveAs(nil)
        }
    }
    
    var isDirty: Bool {
        get { textView.isDirty }
        set { textView.isDirty = newValue }
    }
}

// Convenient place to track the open files - we have a 1:1 mapping, an open window is an open file
class HexWindow: Window {
    nonisolated(unsafe) static var untitledCount = 0
    var filename: String?
    var hexView: HexView
    
    init (filename: String?, contents: Data)
    {
        self.filename = filename
        self.hexView = HexView(source: contents)
        super.init(filename ?? HexWindow.getUntitled())
        
        allowMove = true
        allowResize = true
        
        addSubview(hexView)
        _ = hexView.becomeFirstResponder()
    }
    
    static func getUntitled () -> String {
        if FileWindow.untitledCount == 0 { return "Untitled" }
        FileWindow.untitledCount += 1
        return "Hex-\(FileWindow.untitledCount)"
    }
    
    open override var debugDescription: String {
        get {
            return "HexWindow (\(filename ?? "Untitled"))"
        }
    }
    
    // expects filename to be set
    func saveFile (_ target: String) {
        //
    }

    func saveAs (_ initial: String?) {
    }
    
    func save() {
    }
}

class SimpleEditor: StandardToplevel {
    
    func place (window: FileWindow) {
        window.frame = Rect (origin: Point.zero, size: desk.bounds.size)
        manage (window: window)
        window.closeClicked = handleClose
    }

    func place (window: HexWindow) {
        window.frame = Rect (origin: Point.zero, size: desk.bounds.size)
        manage (window: window)
        window.closeClicked = handleClose
    }

    func handleClose (w: Window)  {
        guard let filewin = w as? FileWindow else {
            return
        }
        if filewin.isDirty {
            filewin.save()
        }
        drop (window: w)
    }
    
    func newFile () {
        let file = FileWindow (filename: nil)
        place (window: file)
        _ = file.becomeFirstResponder()
    }
    
    func openFile () {
        let open = OpenDialog.init(title: "Open File", message: "Select a file to open")
        open.canChooseDirectories = false
        open.canChooseFiles = true
        open.allowsMultipleSelection = false
        open.present { d in
            if let file = d.filePaths?.first {
                if let contents = try? String(contentsOfFile: file, encoding: .utf8) {
                    let file = FileWindow (filename: file, contents: contents)
                    self.place (window: file)
                    _ = file.becomeFirstResponder()
                } else {
                    MessageBox.error("Error", message: "Could not read contents of file", buttons: ["Ok"]) { _ in }
                }
            }
        }
    }
    
    func openHex () {
        let open = OpenDialog.init(title: "Open File in Hex Editor", message: "Select a file to open")
        open.canChooseDirectories = false
        open.canChooseFiles = true
        open.allowsMultipleSelection = false
        open.present { d in
            if let file = d.filePaths?.first {
                let url: URL
                if #available(macOS 13.0, *) {
                    url = URL(filePath: file)
                } else {
                    url = URL(fileURLWithPath: file)
                }
                if let contents = try? Data(contentsOf: url) {
                    let file = HexWindow (filename: file, contents: contents)
                    self.place (window: file)
                    _ = file.becomeFirstResponder()
                } else {
                    MessageBox.error("Error", message: "Could not read contents of file", buttons: ["Ok"]) { _ in }
                }
            }
        }
    }
    
    func saveFile () {
        for win in windows {
            guard let fileWin = win as? FileWindow else {
                continue
            }
            if fileWin.hasFocus {
                fileWin.save ()
                return
            }
        }
        MessageBox.error("Error", message: "There is no current window selected", buttons: ["Ok"])
    }
    
    func saveAsFile () {
        for win in windows {
            guard let fileWin = win as? FileWindow else {
                continue
            }
            if fileWin.hasFocus {
                fileWin.saveAs (fileWin.filename)
                return
            }
        }
        MessageBox.error("Error", message: "There is no current window selected", buttons: ["Ok"])
    }
    
    override init () {
        super.init ()
        
        let menu = MenuBar (
            menus: [
                MenuBarItem (title: "_File", children: [
                    MenuItem (title: "_New", action: newFile),
                    MenuItem (title: "_Open", action: openFile),
                    MenuItem (title: "_Hex", action: openHex),
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
