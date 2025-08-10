//
//  DemoWindows.swift
//  TermKit
//
//  Demonstrates movable and resizable windows
//

import Foundation
import TermKit

func DemoWindows() -> Toplevel {
    // Create a window to contain our demo controls
    let top = Toplevel()
    top.fill()
    
    let topWindow = Window("StatusBar Demo")
    topWindow.fill()
    topWindow.y = Pos.at(1)
    topWindow.height = Dim.fill(1) // Leave space for status bar at bottom
    top.addSubview(topWindow)
    
    // Add the StatusBar at the bottom
    let statusBar = StatusBar()
    statusBar.addHotkeyPanel(id: "quit", hotkeyText: "Control-C", labelText: "Quit", hotkey: .controlC) {
        Application.requestStop()
    }
    top.addSubview(statusBar)
    
    // Create four windows with different positions and content
    let windows = [
        ("Window 1", 5, 3, "This is the first window.\nYou can drag and resize it!\n\nTry dragging by the title bar\nor resize by the corners."),
        ("Window 2", 45, 3, "Second window here.\nMove me around!\n\nWindows can overlap and\nbe repositioned freely."),
        ("Window 3", 5, 15, "Third window content.\nResize me!\n\nDrag the edges to make\nme bigger or smaller."),
        ("Window 4", 45, 15, "Fourth and final window.\nI'm movable too!\n\nAll windows support both\nmoving and resizing.")
    ]
    
    for (title, x, y, content) in windows {
        let window = Window(title)
        window.allowMove = true
        window.allowResize = true
        window.frame = Rect(x: x, y: y, width: 35, height: 8)
        
        // Add content to the window
        let textView = TextView()
        textView.text = content
        textView.fill()
        window.addSubview(textView)
        
        // Add close functionality
        window.closeClicked = { win in
            win.superview?.removeSubview(win)
        }
        
        topWindow.addSubview(window)
    }
    
    return top
}
