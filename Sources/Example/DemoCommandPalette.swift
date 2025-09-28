//
//  DemoCommandPalette.swift
//  TermKit
//
//  Created by Claude Code on 9/27/25.
//  Copyright © 2025 Miguel de Icaza. All rights reserved.
//

import Foundation
import TermKit

@MainActor
func DemoCommandPalette() -> Toplevel {
    // Create a text view to show command results
    let resultView = TextView()
    resultView.x = Pos.at(1)
    resultView.y = Pos.at(1)
    resultView.width = Dim.fill(1)
    resultView.height = Dim.fill(1)
    resultView.text = """
    Command Palette Demo

    Press Ctrl+P to open the command palette.

    Available commands:
    • File Operations (New, Open, Save, Quit)
    • Edit Operations (Copy, Cut, Paste, Find)
    • View Operations (Zoom In, Zoom Out, Toggle Theme)
    • Demo Commands (Show Message, Clear Text, Add Sample Text)

    Try searching for commands by typing part of their name.

    """

    // Create command providers first
    let fileProvider = createFileCommandProvider(resultView: resultView)
    let editProvider = createEditCommandProvider(resultView: resultView)
    let viewProvider = createViewCommandProvider(resultView: resultView)
    let demoProvider = createDemoCommandProvider(resultView: resultView)

    // Override processKey to handle Ctrl+P
    class CommandPaletteWindow: Window {
        let fileProvider: CommandProvider
        let editProvider: CommandProvider
        let viewProvider: CommandProvider
        let demoProvider: CommandProvider

        init(fileProvider: CommandProvider, editProvider: CommandProvider, viewProvider: CommandProvider, demoProvider: CommandProvider) {
            self.fileProvider = fileProvider
            self.editProvider = editProvider
            self.viewProvider = viewProvider
            self.demoProvider = demoProvider
            super.init("Command Palette Demo")
        }

        override func processKey(event: KeyEvent) -> Bool {
            if event.key == Key.controlP {
                // Show a larger command palette (caller can specify custom size)
                Application.showCommandPalette(
                    providers: [fileProvider, editProvider, viewProvider, demoProvider],
                    placeholder: "Type to search commands...",
                    width: 90,      // Wider than default (70)
                    height: 24,     // Taller than default (18)
                    onDismiss: { executed in
                        // Could add logging or other actions here
                    }
                )
                return true
            }
            return super.processKey(event: event)
        }
    }

    let commandWin = CommandPaletteWindow(fileProvider: fileProvider, editProvider: editProvider, viewProvider: viewProvider, demoProvider: demoProvider)
    commandWin.set(x: 0, y: 0, width: 80, height: 24)
    commandWin.addSubview(resultView)


    return commandWin
}

@MainActor
private func showCommandPalette(providers: [CommandProvider]) {
    Application.showCommandPalette(
        providers: providers,
        placeholder: "Type to search commands...",
        onDismiss: { executed in
            // Could add logging or other actions here
        }
    )
}

// MARK: - File Command Provider

private func createFileCommandProvider(resultView: TextView) -> CommandProvider {
    let commands: [(String, String?, () -> Void)] = [
        ("New File", "Create a new file", {
            appendToResultView(resultView, "📄 New file created")
        }),
        ("Open File", "Open an existing file", {
            appendToResultView(resultView, "📂 File opened")
        }),
        ("Save File", "Save the current file", {
            appendToResultView(resultView, "💾 File saved")
        }),
        ("Save As", "Save file with a new name", {
            appendToResultView(resultView, "💾 File saved as new name")
        }),
        ("Recent Files", "Show recently opened files", {
            appendToResultView(resultView, "📋 Recent files shown")
        }),
        ("Quit Application", "Exit the application", {
            appendToResultView(resultView, "👋 Goodbye!")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Application.shutdown()
            }
        })
    ]

    return SimpleCommandProvider(commands: commands)
}

// MARK: - Edit Command Provider

private func createEditCommandProvider(resultView: TextView) -> CommandProvider {
    let commands: [(String, String?, () -> Void)] = [
        ("Copy", "Copy selected text", {
            appendToResultView(resultView, "📋 Text copied to clipboard")
        }),
        ("Cut", "Cut selected text", {
            appendToResultView(resultView, "✂️ Text cut to clipboard")
        }),
        ("Paste", "Paste from clipboard", {
            appendToResultView(resultView, "📋 Text pasted from clipboard")
        }),
        ("Find", "Search for text", {
            appendToResultView(resultView, "🔍 Find dialog opened")
        }),
        ("Find and Replace", "Search and replace text", {
            appendToResultView(resultView, "🔄 Find and replace dialog opened")
        }),
        ("Undo", "Undo last action", {
            appendToResultView(resultView, "↩️ Last action undone")
        }),
        ("Redo", "Redo last undone action", {
            appendToResultView(resultView, "↪️ Action redone")
        })
    ]

    return SimpleCommandProvider(commands: commands)
}

// MARK: - View Command Provider

private func createViewCommandProvider(resultView: TextView) -> CommandProvider {
    let commands: [(String, String?, () -> Void)] = [
        ("Zoom In", "Increase font size", {
            appendToResultView(resultView, "🔍➕ Zoomed in")
        }),
        ("Zoom Out", "Decrease font size", {
            appendToResultView(resultView, "🔍➖ Zoomed out")
        }),
        ("Reset Zoom", "Reset font size to default", {
            appendToResultView(resultView, "🔍🔄 Zoom reset")
        }),
        ("Toggle Theme", "Switch between light and dark theme", {
            appendToResultView(resultView, "🌓 Theme toggled")
        }),
        ("Toggle Full Screen", "Enter or exit full screen mode", {
            appendToResultView(resultView, "📺 Full screen toggled")
        }),
        ("Show Sidebar", "Toggle sidebar visibility", {
            appendToResultView(resultView, "📋 Sidebar toggled")
        })
    ]

    return SimpleCommandProvider(commands: commands)
}

// MARK: - Demo Command Provider

private func createDemoCommandProvider(resultView: TextView) -> CommandProvider {
    let commands: [(String, String?, () -> Void)] = [
        ("Show Success Message", "Display a success notification", {
            appendToResultView(resultView, "✅ Success! Command executed successfully.")
        }),
        ("Show Warning Message", "Display a warning notification", {
            appendToResultView(resultView, "⚠️ Warning: This is a test warning message.")
        }),
        ("Show Error Message", "Display an error notification", {
            appendToResultView(resultView, "❌ Error: This is a test error message.")
        }),
        ("Clear Text", "Clear all text from the view", {
            resultView.text = "Command Palette Demo\n\nText cleared! Press Ctrl+P to open command palette.\n\n"
        }),
        ("Add Sample Text", "Add some sample text", {
            let sampleText = """

            Sample text added:

            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor
            incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
            nostrud exercitation ullamco laboris.

            """
            appendToResultView(resultView, sampleText)
        }),
        ("Generate Random Number", "Generate and display a random number", {
            let randomNumber = Int.random(in: 1...1000)
            appendToResultView(resultView, "🎲 Random number generated: \(randomNumber)")
        }),
        ("Show Current Time", "Display the current time", {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .medium
            let timeString = formatter.string(from: Date())
            appendToResultView(resultView, "🕐 Current time: \(timeString)")
        })
    ]

    return SimpleCommandProvider(commands: commands)
}

// MARK: - Helper Functions

private func appendToResultView(_ resultView: TextView, _ text: String) {
    let timestamp = DateFormatter.timeFormatter.string(from: Date())
    resultView.text = (resultView.text ?? "") + "[\(timestamp)] \(text)\n"

    // Scroll to bottom - TextView may not have this method, so just update display
    resultView.setNeedsDisplay()
}

private extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}