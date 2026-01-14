# Navigation Controls

Controls for menus, command palettes, and navigation.

## Overview

TermKit provides controls for building navigation structures including menus, command palettes, and status bars.

## Menu and MenuBar

``MenuBar`` provides a horizontal menu bar, typically at the top of the screen.

### Basic Usage

```swift
let menuBar = MenuBar(menus: [
    MenuBarItem(title: "_File", children: [
        MenuItem(title: "_New", shortcut: "^N", action: { newDocument() }),
        MenuItem(title: "_Open", shortcut: "^O", action: { openDocument() }),
        MenuItem(title: "_Save", shortcut: "^S", action: { saveDocument() }),
        nil,  // Separator
        MenuItem(title: "_Quit", shortcut: "^Q", action: { Application.requestStop() })
    ]),
    MenuBarItem(title: "_Edit", children: [
        MenuItem(title: "_Undo", shortcut: "^Z", action: { undo() }),
        MenuItem(title: "_Redo", shortcut: "^Y", action: { redo() }),
        nil,
        MenuItem(title: "Cu_t", shortcut: "^X", action: { cut() }),
        MenuItem(title: "_Copy", shortcut: "^C", action: { copy() }),
        MenuItem(title: "_Paste", shortcut: "^V", action: { paste() })
    ]),
    MenuBarItem(title: "_Help", children: [
        MenuItem(title: "_About", action: { showAbout() })
    ])
])

menuBar.x = Pos.at(0)
menuBar.y = Pos.at(0)
menuBar.width = Dim.fill()

container.addSubview(menuBar)
```

### Hotkeys

Underscores mark hotkeys:
- `_File` → Alt+F opens the menu
- `_New` → N activates when menu is open

### Shortcuts

Display keyboard shortcuts:

```swift
MenuItem(title: "_Save", shortcut: "^S", action: { ... })
// Shows: Save    ^S
```

### Submenus

Create nested menus:

```swift
MenuBarItem(title: "_View", children: [
    MenuItem(title: "_Zoom", children: [
        MenuItem(title: "Zoom _In", action: { zoomIn() }),
        MenuItem(title: "Zoom _Out", action: { zoomOut() }),
        MenuItem(title: "_Reset", action: { resetZoom() })
    ]),
    MenuItem(title: "_Theme", children: [
        MenuItem(title: "_Light", action: { setTheme(.light) }),
        MenuItem(title: "_Dark", action: { setTheme(.dark) })
    ])
])
```

### Keyboard

- **Alt+hotkey**: Open menu
- **Arrow keys**: Navigate menus
- **Enter**: Activate item
- **Escape**: Close menu

---

## CommandPalette

``CommandPalette`` provides VS Code-style fuzzy command search.

### Basic Usage

```swift
// Create a simple command provider
let commands = SimpleCommandProvider(commands: [
    ("New File", "Create a new file", { newFile() }),
    ("Open File", "Open an existing file", { openFile() }),
    ("Save", "Save current file", { save() }),
    ("Find", "Search in file", { showSearch() }),
    ("Replace", "Find and replace", { showReplace() })
])

// Show the palette
Application.showCommandPalette(
    providers: [commands],
    caption: "Command:",
    placeholder: "Type to search commands..."
)
```

### Custom Command Provider

For dynamic commands, implement `CommandProvider`:

```swift
class MyCommandProvider: CommandProvider {
    weak var view: View?

    func startup() async {
        // Initialize resources
    }

    func search(query: String) async -> [CommandHit] {
        // Return matching commands
        return myCommands.filter { $0.name.contains(query) }
            .map { cmd in
                CommandHit(
                    title: cmd.name,
                    help: cmd.description,
                    action: cmd.action
                )
            }
    }

    func discover() async -> [DiscoveryHit] {
        // Return default commands (when query is empty)
        return myCommands.prefix(10).map { cmd in
            DiscoveryHit(title: cmd.name, help: cmd.description)
        }
    }

    func shutdown() async {
        // Cleanup resources
    }
}
```

### Palette Variants

```swift
// Standard size
Application.showCommandPalette(providers: [provider])

// Compact version
Application.showCompactCommandPalette(providers: [provider])

// Full screen
Application.showFullCommandPalette(providers: [provider])
```

### Multiple Providers

Combine commands from different sources:

```swift
let fileCommands = SimpleCommandProvider(commands: [...])
let editCommands = SimpleCommandProvider(commands: [...])
let viewCommands = SimpleCommandProvider(commands: [...])

Application.showCommandPalette(
    providers: [fileCommands, editCommands, viewCommands]
)
```

### Keyboard

- **Type**: Filter commands
- **Up/Down**: Navigate results
- **Enter**: Execute selected command
- **Escape**: Close palette

---

## StatusBar

``StatusBar`` displays status items, typically at the bottom of the screen.

### Basic Usage

```swift
let statusBar = StatusBar(items: [
    StatusItem(title: "F1 Help", action: { showHelp() }),
    StatusItem(title: "F2 Save", action: { save() }),
    StatusItem(title: "F10 Quit", action: { Application.requestStop() })
])

statusBar.x = Pos.at(0)
statusBar.y = Pos.anchorEnd(margin: 0)
statusBar.width = Dim.fill()
statusBar.height = Dim.sized(1)

container.addSubview(statusBar)
```

### Dynamic Updates

```swift
let modeItem = StatusItem(title: "INSERT")

func setMode(_ mode: String) {
    modeItem.title = mode
    statusBar.setNeedsDisplay()
}
```

### Click Handling

Status items can have actions:

```swift
StatusItem(title: "Click Me", action: {
    print("Status item clicked!")
})
```

---

## Common Patterns

### Application Menu Structure

```swift
let menuBar = MenuBar(menus: [
    MenuBarItem(title: "_File", children: [
        MenuItem(title: "_New", shortcut: "^N", action: { ... }),
        MenuItem(title: "_Open", shortcut: "^O", action: { ... }),
        MenuItem(title: "_Save", shortcut: "^S", action: { ... }),
        MenuItem(title: "Save _As...", action: { ... }),
        nil,
        MenuItem(title: "Recent Files", children: recentFiles.map { file in
            MenuItem(title: file.name, action: { open(file) })
        }),
        nil,
        MenuItem(title: "_Quit", shortcut: "^Q", action: { ... })
    ]),
    // ... more menus
])
```

### Command Palette with Keyboard Shortcut

```swift
// In your application's key handler
override func processHotKey(event: KeyEvent) -> Bool {
    // Ctrl+Shift+P opens command palette
    if event.key == .letter("P") && event.isControl {
        Application.showCommandPalette(providers: [commandProvider])
        return true
    }
    return super.processHotKey(event: event)
}
```

### Status Bar with File Info

```swift
func updateStatusBar(for file: File) {
    statusBar.items = [
        StatusItem(title: file.encoding),
        StatusItem(title: "Line \(cursor.line), Col \(cursor.column)"),
        StatusItem(title: file.modified ? "Modified" : ""),
        StatusItem(title: file.path)
    ]
    statusBar.setNeedsDisplay()
}
```

### Context Menu

```swift
func showContextMenu(at point: Point) {
    let menu = Menu(items: [
        MenuItem(title: "Cut", action: { cut() }),
        MenuItem(title: "Copy", action: { copy() }),
        MenuItem(title: "Paste", action: { paste() }),
        nil,
        MenuItem(title: "Select All", action: { selectAll() })
    ])
    menu.show(at: point)
}
```

## See Also

- ``MenuBar``
- ``MenuBarItem``
- ``MenuItem``
- ``CommandPalette``
- ``CommandProvider``
- ``SimpleCommandProvider``
- ``StatusBar``
- ``StatusItem``
