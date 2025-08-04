//
//  main.swift - Example demonstrating the UnixDriver
//  TermKit
//
//  Created by TermKit on 2025-08-04.
//

import Foundation
import TermKit

// Example demonstrating how to use the new UnixDriver
// You can switch between drivers by changing the parameter below

// Use the Unix driver (new direct terminal control)
Application.prepare(driverType: .unix)

// Or use the traditional curses driver
// Application.prepare(driverType: .curses)

// Create a window
let win = Window("Unix Driver Demo")
win.x = Pos.center()
win.y = Pos.center()
win.width = Dim.percent(80)
win.height = Dim.percent(80)

// Add a label
let label = Label("This application is running with the Unix terminal driver!")
label.x = Pos.center()
label.y = Pos.at(2)
win.addSubview(label)

// Add some colored text to show color support
let colorLabel = Label("Colors are supported!")
colorLabel.x = Pos.center()
colorLabel.y = Pos.at(4)
colorLabel.colorScheme = Colors.error
win.addSubview(colorLabel)

// Add a text field
let textField = TextField("Type here...")
textField.x = Pos.center()
textField.y = Pos.at(6)
textField.width = Dim.sized(30)
win.addSubview(textField)

// Add some buttons
let button1 = Button("Test Button")
button1.x = Pos.center() - 15
button1.y = Pos.at(8)
button1.clicked = {
    MessageBox.query("Test", "Button was clicked!", "OK")
}
win.addSubview(button1)

let quitButton = Button("Quit")
quitButton.x = Pos.center() + 5
quitButton.y = Pos.at(8)
quitButton.clicked = {
    Application.requestStop()
}
win.addSubview(quitButton)

// Add a frame with list view
let frame = Frame("Features")
frame.x = Pos.at(2)
frame.y = Pos.at(10)
frame.width = Dim.fill() - 4
frame.height = Dim.fill() - 2

let features = [
    "Direct terminal control",
    "No curses dependency",
    "ANSI escape sequences",
    "Mouse support",
    "Color support",
    "Input handling",
    "Terminal resize support"
]

let listView = ListView(items: features)
frame.addSubview(listView)
win.addSubview(frame)

// Add the window to the application
Application.top.addSubview(win)

// Run the application
Application.run()

print("Application terminated successfully")