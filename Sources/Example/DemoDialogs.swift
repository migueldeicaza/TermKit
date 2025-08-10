//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 3/22/21.
//

import Foundation
import TermKit

class FileDialogs: DemoHost {
    init() {
        super.init(title: "Dialogs")
    }
    
    override func setupDemo() {
        let resFrame = Frame ("Results: ")
        resFrame.set (x: 40, y: 1)
        resFrame.width = Dim.fill()
        resFrame.height = Dim.fill()
        
        let open = Button ("Open Dialog") {
            Application.present(top: OpenDialog (title: "Sample Open", message: "Pick a file to open"))
        }
        open.set (x: 1, y: 1)
        
        let save = Button ("Save Dialog") {
            Application.present(top: SaveDialog (title: "Sample Save", message: "Going to save your file"))
        }
        save.set (x: 1, y: 2)
        
        let quit = Button ("Quit") { Application.requestStop() }
        quit.set (x: 1, y: 3)
        
        topWindow.addSubviews([open, save, quit, resFrame])
    }
}
