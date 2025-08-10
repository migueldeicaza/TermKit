//
//  StatusBarDemo.swift
//  TermKit
//
//  A visual demo of the StatusBar functionality
//

import Foundation
import TermKit

@MainActor
func createStatusBarDemo() -> Toplevel {
    // Create a window to contain our demo controls
    let top = Toplevel()
    top.fill()
    
    let window = Window("StatusBar Demo")
    window.fill()
    window.closeOnControlC = true
    window.y = Pos.at(1)
    window.height = Dim.fill(1) // Leave space for status bar at bottom
    top.addSubview(window)
    
    // Add the StatusBar at the bottom
    let statusBar = StatusBar()
    top.addSubview(statusBar)
    
    // Create demo buttons and controls
    let instructionLabel = Label("Click buttons to test StatusBar features:")
    instructionLabel.x = Pos.at(2)
    instructionLabel.y = Pos.at(1)
    window.addSubview(instructionLabel)
    
    // Status message button
    let statusButton = Button("Set Status Message")
    statusButton.x = Pos.at(2)
    statusButton.y = Pos.at(3)
    statusButton.clicked = { _ in
        statusBar.pushStatus("This is a temporary status message", timeout: 3.0, priority: .default)
    }
    window.addSubview(statusButton)
    
    // Add permanent panel button
    let panelButton = Button("Add Panel")
    panelButton.x = Pos.at(25)
    panelButton.y = Pos.at(3)
    panelButton.clicked = { _ in
        statusBar.addPanel(id: "info", content: "Info: Ready", priority: .default)
    }
    window.addSubview(panelButton)
    
    // Update panel button  
    let updateButton = Button("Update Panel")
    updateButton.x = Pos.at(40)
    updateButton.y = Pos.at(3)
    updateButton.clicked = { _ in
        statusBar.updatePanel(id: "info", content: "Info: Updated \(Date().timeIntervalSince1970)")
    }
    window.addSubview(updateButton)
    
    // Remove panel button
    let removeButton = Button("Remove Panel")
    removeButton.x = Pos.at(58)
    removeButton.y = Pos.at(3)
    removeButton.clicked = { _ in
        statusBar.removePanel(id: "info")
    }
    window.addSubview(removeButton)
    
    // Spinner demo button
    let spinnerButton = Button("Show Spinner")
    spinnerButton.x = Pos.at(2)
    spinnerButton.y = Pos.at(5)
    spinnerButton.clicked = { _ in
        statusBar.showSpinner(id: "task", message: "Processing...", priority: .high, kind: Spinner.dot)
    }
    window.addSubview(spinnerButton)
    
    // Progress bar button
    let progressButton = Button("Show Progress")
    progressButton.x = Pos.at(25)
    progressButton.y = Pos.at(5)

    progressButton.clicked = { _ in
        var progress = 0
        statusBar.showProgressBar(id: "download", current: progress, total: 100, message: "Downloading", priority: .veryHigh)
        
        // Simulate progress updates
        Task { @MainActor in
            while !Task.isCancelled {
                try await Task.sleep(for: .milliseconds(100))
                progress += 5
                if progress <= 100 {
                    statusBar.updateProgressBar(id: "download", current: progress, total: 100, message: "Downloading")
                } else {
                    statusBar.hideIndicator(id: "download")
                    statusBar.pushStatus("Download completed!", timeout: 2.0, priority: .high)
                    break
                }
            }
        }
    }
    window.addSubview(progressButton)
    
    // Hide indicators button
    let hideButton = Button("Hide Indicators")
    hideButton.x = Pos.at(45)
    hideButton.y = Pos.at(5)
    hideButton.clicked = { _ in
        statusBar.hideIndicator(id: "task")
        statusBar.hideIndicator(id: "download")
    }
    window.addSubview(hideButton)
    
    // Priority demo buttons
    let priorityLabel = Label("Priority Demo (higher priority panels show first):")
    priorityLabel.x = Pos.at(2)
    priorityLabel.y = Pos.at(7)
    window.addSubview(priorityLabel)
    
    let lowPriorityButton = Button("Low Priority Panel")
    lowPriorityButton.x = Pos.at(2)
    lowPriorityButton.y = Pos.at(9)
    lowPriorityButton.clicked = { _ in
        statusBar.addPanel(id: "low", content: "Low Priority", priority: .low)
    }
    window.addSubview(lowPriorityButton)
    
    let highPriorityButton = Button("High Priority Panel")
    highPriorityButton.x = Pos.at(25)
    highPriorityButton.y = Pos.at(9)
    highPriorityButton.clicked = { _ in
        statusBar.addPanel(id: "high", content: "High Priority", priority: .high)
    }
    window.addSubview(highPriorityButton)
    
    let veryHighPriorityButton = Button("Very High Priority")
    veryHighPriorityButton.x = Pos.at(50)
    veryHighPriorityButton.y = Pos.at(9)
    veryHighPriorityButton.clicked = { _ in
        statusBar.addPanel(id: "veryhigh", content: "Very High Priority", priority: .veryHigh)
    }
    window.addSubview(veryHighPriorityButton)
    
    // Clear all button
    let clearButton = Button("Clear All")
    clearButton.x = Pos.at(2)
    clearButton.y = Pos.at(11)
    clearButton.clicked = { _ in
        statusBar.clearStatus()
        statusBar.removePanel(id: "info")
        statusBar.removePanel(id: "low")
        statusBar.removePanel(id: "high")
        statusBar.removePanel(id: "veryhigh")
        statusBar.hideIndicator(id: "task")
        statusBar.hideIndicator(id: "download")
    }
    window.addSubview(clearButton)
    
    // Instructions
    let instructionsLabel = TextView()
    instructionsLabel.text = """
    Instructions:
    • Click buttons above to test StatusBar functionality
    • Status messages disappear after timeout
    • Panels persist until removed
    • Higher priority items show first when space is limited
    • Progress bars and spinners integrate seamlessly
    • Try hotkeys: F1 (Help), F5 (Refresh), F10 (Quit)
    • Hotkeys work even when panels aren't visible
    • Press Ctrl+C to exit
    """
    instructionsLabel.x = Pos.at(2)
    instructionsLabel.y = Pos.at(13)
    instructionsLabel.width = Dim.percent(n: 90)
    instructionsLabel.height = Dim.sized(8)
    window.addSubview(instructionsLabel)
    
    // Add some hotkey panels to demonstrate the feature
    statusBar.addHotkeyPanel(
        id: "help",
        hotkeyText: "F1",
        labelText: " Help",
        hotkey: .f1,
        action: {
            statusBar.pushStatus("Help pressed! F1 hotkey works.", timeout: 3.0, priority: .high)
        },
        priority: .veryHigh,
        placement: .trailing
    )
    
    statusBar.addHotkeyPanel(
        id: "quit",
        hotkeyText: "F10",
        labelText: " Quit",
        hotkey: .f10,
        action: {
            Application.requestStop()
        },
        priority: .veryHigh,
        placement: .trailing
    )
    
    statusBar.addHotkeyPanel(
        id: "refresh",
        hotkeyText: "F5",
        labelText: " Refresh",
        hotkey: .f5,
        action: {
            statusBar.pushStatus("Refreshed! F5 hotkey triggered.", timeout: 2.0, priority: .high)
        },
        priority: .high,
        placement: .trailing
    )
    statusBar.addHotkeyPanel(
        id: "quit",
        hotkeyText: "Control-C",
        labelText: " Quit",
        hotkey: .controlC,
        action: {
            Application.requestStop()
        },
        priority: .high,
        placement: .trailing
    )

    // Initialize with a welcome message
    statusBar.pushStatus("Welcome to StatusBar Demo! Try hotkeys F1, F5, F10 or buttons above.", timeout: 5.0, priority: .default)

    return top
}
