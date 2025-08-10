//
//  SpinnerDemo.swift
//  TermKit
//
//  A visual demo of the Spinner functionality
//

import Foundation
import TermKit

func createSpinnerDemo() -> Toplevel {
    let top = Toplevel()
    top.fill()
    
    // Create a window to contain our spinners
    let window = Window("Spinner Demo")
    window.fill()
    window.y = Pos.at(1)
    top.addSubview(window)
    
    // Add menu bar
    let menu = MenuBar(menus: [
        MenuBarItem(title: "_File", children: [
            MenuItem(title: "_Close", action: {
                Application.requestStop()
            })
        ])
    ])
    top.addSubview(menu)
    
    // Create various spinners with labels
    let spinnerData: [(definition: Spinner.Definition, name: String)] = [
        (Spinner.line, "Line"),
        (Spinner.dot, "Dot"),
        (Spinner.miniDot, "Mini Dot"),
        (Spinner.jump, "Jump"),
        (Spinner.pulse, "Pulse"),
        (Spinner.points, "Points"),
        (Spinner.moon, "Moon"),
        (Spinner.meter, "Meter"),
        (Spinner.ellipsis, "Ellipsis")
    ]
    
    var yPos = 2
    for (_, data) in spinnerData.enumerated() {
        // Create label for spinner name
        let label = Label(data.name + ":")
        label.x = Pos.at(2)
        label.y = Pos.at(yPos)
        label.width = Dim.sized(15)
        window.addSubview(label)
        
        // Create the spinner
        let spinner = Spinner(definition: data.definition)
        spinner.x = Pos.at(18)
        spinner.y = Pos.at(yPos)
        window.addSubview(spinner)
        
        // Start the spinner animation
        spinner.start()
        
        yPos += 2
    }
    
    // Add a note
    let noteLabel = Label("Press Ctrl+C to exit")
    noteLabel.x = Pos.at(2)
    noteLabel.y = Pos.at(yPos + 1)
    window.addSubview(noteLabel)
    
    return top
}
