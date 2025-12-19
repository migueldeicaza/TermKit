
[![Build, test, and docs](https://github.com/migueldeicaza/TermKit/actions/workflows/build.yml/badge.svg)](https://github.com/migueldeicaza/TermKit/actions/workflows/build.yml)

# TermKit - Terminal UI Toolkit for Swift

This is a simple UI Toolkit for Swift, a port of my [gui.cs library
for .NET](https://github.com/migueldeicaza/gui.cs).  While I
originally wrote gui.cs, it has evolved significantly by the
contributions of Charlie Kindel (@tig), @BDisp and various other
contributors - this version started as an effort to bring this to
Swift, but diverted as a result of a more Unix-centric/UIKit-centric
design view.

This toolkit contains various controls for build text user interfaces
using Swift. It works on Mac, Linux and Windows.

## Controls

The following controls are currently implemented:

- **Button** - Clickable buttons with text
- **Checkbox** - Checkboxes for boolean input
- **DataTable** - Tabular data display
- **Frame** - Container with optional border and title
- **HexView** - Hexadecimal data viewer
- **Label** - Text display
- **ListView** - Lists with selection and scrolling
- **MarkupView** - Rich text with markup support
- **Menu/MenuBar** - Menus and menu bars
- **ProgressBar** - Progress indicators
- **RadioGroup** - Radio button groups
- **ScrollView** - Scrollable containers
- **Spinner** - Loading spinners
- **SplitView** - Resizable split containers
- **StatusBar** - Status information display
- **TabView** - Tabbed interfaces
- **Terminal/TerminalView** - Terminal emulation
- **TextField** - Single-line text input
- **TextView** - Multi-line text editing
- **MarkdownView** - Markdown viewer
- **CommandPalette** - Command search and execution interface
- **Toplevel** - Top-level windows
- **StandardDesktop** - Desktop-style top-level with MenuBar, StatusBar, and managed windows

## Desktop

Use `StandardDesktop` to build a desktop-style TUI with a menu bar at
the top, a status bar at the bottom, and a desktop surface for
overlapping `Window` instances. The desktop surface uses a simple
stippled background via `SolidBackground`.

Quick start:

```swift
import TermKit

Application.prepare()

let desktop = StandardDesktop()
desktop.fill()

// Optional: replace the default menu by adding a new MenuBar
let customMenu = MenuBar(menus: [
    MenuBarItem(title: "_File", children: [
        MenuItem(title: "_New", action: { /* create new */ }),
        MenuItem(title: "_Quit", action: { Application.requestStop() })
    ]),
    MenuBarItem(title: "_Window", children: []),
    MenuBarItem(title: "_Help", children: [
        MenuItem(title: "_About", action: { /* show dialog */ })
    ])
])
desktop.addSubview(customMenu)

// Add a couple of windows
let win1 = Window("Notes")
win1.frame = Rect(x: 2, y: 2, width: 40, height: 12)
win1.allowMove = true
win1.allowResize = true
desktop.manage(window: win1)

let win2 = Window("Logs")
win2.frame = Rect(x: 20, y: 8, width: 50, height: 14)
win2.allowMove = true
win2.allowResize = true
desktop.manage(window: win2)

Application.top.addSubview(desktop)
Application.run()
```

Window menu actions (maximize, minimize, tile, dock, next/previous) are provided automatically and enable/disable based on state. Disabled entries render dim to indicate they are inactive.

## Command Palette

The **CommandPalette** provides a modern command search and execution interface similar to those found in VS Code, Sublime Text, and other editors. It enables users to quickly find and execute commands through fuzzy search.

### Features

- **Fuzzy Search** - Intelligent search with character-level matching and highlighting
- **Multiple Providers** - Support for different command sources (file operations, editing commands, etc.)
- **Discoverable Commands** - Shows available commands when no search query is entered
- **Keyboard Navigation** - Full keyboard control with arrow keys and Enter
- **Customizable** - Configurable size, position, caption, and placeholder text

### Quick Start

```swift
// Create command providers
let fileProvider = SimpleCommandProvider(commands: [
    ("New File", "Create a new file", { /* action */ }),
    ("Open File", "Open an existing file", { /* action */ }),
    ("Save File", "Save the current file", { /* action */ })
])

// Show the command palette
Application.showCommandPalette(
    providers: [fileProvider],
    caption: "Command:",
    placeholder: "Type to search commands..."
)
```

### Command Providers

Create custom command providers by implementing the `CommandProvider` protocol:

```swift
class MyCommandProvider: CommandProvider {
    weak var view: View?

    func startup() async { }

    func search(query: String) async -> [CommandHit] {
        // Return matching commands for the query
    }

    func discover() async -> [DiscoveryHit] {
        // Return commands to show when no query is entered
    }

    func shutdown() async { }
}
```

Or use the built-in `SimpleCommandProvider` for static command lists:

```swift
let provider = SimpleCommandProvider(commands: [
    ("Command Name", "Optional help text", { /* action closure */ })
])
```

### Variants

- `Application.showCommandPalette()` - Standard size, centered
- `Application.showCompactCommandPalette()` - Smaller, compact version
- `Application.showFullCommandPalette()` - Large, full-screen version

### Integration

The command palette is designed to be easily integrated into any TermKit application. See `DemoCommandPalette.swift` for a complete working example.

## Dialogs

- **Dialog** - Base dialog class
- **FileDialog** - File selection dialog
- **InputBox** - Text input dialog
- **MessageBox** - Message display dialog

## Drivers

TermKit supports multiple console drivers to provide flexibility
across different platforms and use cases. The driver can be selected
automatically, programmatically, or via environment variable.

### Available Drivers

- **CursesDriver** (`curses`) - NCurses-based driver for Unix systems with full terminal capabilities
- **UnixDriver** (`unix`) - Raw Unix terminal driver using ANSI escape sequences
- **TTYDriver** (`tty`) - Basic TTY driver for testing and debugging (plain text output)
- **WindowsDriver** (`windows`) - Windows console driver (Windows platform only)

### Driver Selection

#### Environment Variable

You can set the `TERMKIT_DRIVER` environment variable to force a specific driver:

```bash
# Use the TTY driver for testing/debugging
export TERMKIT_DRIVER=tty
swift run

# Use the Unix driver
export TERMKIT_DRIVER=unix
swift run

# Use the Curses driver (default on supported platforms)
export TERMKIT_DRIVER=curses
swift run
```

#### Programmatic Selection

You can also specify the driver when calling `Application.prepare()`:

```swift
// Automatic driver selection (default)
Application.prepare()

// Force a specific driver
Application.prepare(driverType: .unix)
Application.prepare(driverType: .tty)
Application.prepare(driverType: .curses)
```

#### Driver Selection Logic

1. If `TERMKIT_DRIVER` environment variable is set, use that driver
2. Otherwise, use automatic selection based on platform capabilities:
   - macOS 15.0+: CursesDriver (falls back to UnixDriver if not operational)
   - Other platforms: UnixDriver

### Testing and Debugging

The TTY driver is particularly useful for testing and debugging as it provides plain text output that can be captured and inspected:

```bash
TERMKIT_DRIVER=tty ./your-app > output.txt
```

This allows you to see exactly what your application would render without the complexity of terminal escape sequences.

You can [checkout the documentation](https://migueldeicaza.github.io/TermKit/documentation/termkit/) which is automatically generated and published using DocC.

<img width="1222" alt="Screen Shot 2021-03-13 at 12 44 05 PM" src="https://user-images.githubusercontent.com/36863/111039012-d6df8400-83f9-11eb-9215-88549635a33f.png">

# Running this

From the command line:

```
$ swift build
$ swift run
```

From Xcode, if you want to debug, it is best to make sure that the
application that you want to Debug (in this project, the "Example"
target is what you want) has its Scheme for Running configured
like this:

     * Run/Info: Launch "Wait for Executable to be launched"

Then, when you run, switch to a console, and run the executable, I have my
global settings for DerivedData to be relative to the current directory,
so I can run it like this:

```
$ DerivedData/TermKit/Build/Products/Debug/Example
```

The location for where your executable is produced is configured in Xcode/Preferences/Locations,
I just happen to like project-relative output like the example above shows.

# Debugging

While debugging is useful, sometimes it can be obnoxious to single step or debug over
code that is called too many times in a row, so printf-like debugging is convenient.

Except that prints go to the same console where your application is running, making this
experience painful.

In that case, you can call `Application.log` with a message, and this message will use
MacOS `os_log`, which you can then either look for in the Console.app, or you can monitor from 
a terminal window like this:

```
$ log stream --style compact --predicate 'subsystem == "termkit"'
```

# Documentation

This project uses Swift DocC for documentation generation. The documentation is automatically built and published to GitHub Pages via GitHub Actions.

## Building Documentation Locally

To generate and preview documentation locally:

```bash
# Generate documentation
swift package generate-documentation --target TermKit

# Preview documentation with a local server
swift package --disable-sandbox preview-documentation --target TermKit
```

The documentation source files are located in the `Documentation.docc/` directory.

