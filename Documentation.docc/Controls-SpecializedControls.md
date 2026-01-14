# Specialized Controls

Controls for specific use cases.

## Overview

TermKit includes specialized controls for terminal emulation and visual backgrounds.

## Terminal

``Terminal`` provides embedded terminal emulation with PTY support.

### Basic Usage

```swift
let terminal = Terminal()
terminal.fill()
container.addSubview(terminal)

// Start a shell
terminal.startProcess(executable: "/bin/bash", args: [])
```

### Running Commands

```swift
// Start with a specific command
terminal.startProcess(
    executable: "/usr/bin/python3",
    args: ["script.py"]
)
```

### Custom Environment

```swift
terminal.startProcess(
    executable: "/bin/bash",
    args: [],
    environment: [
        "TERM": "xterm-256color",
        "PATH": "/usr/local/bin:/usr/bin:/bin"
    ]
)
```

### Working Directory

```swift
terminal.startProcess(
    executable: "/bin/bash",
    args: [],
    currentDirectory: "/path/to/project"
)
```

### Terminal Events

```swift
// Handle process completion
terminal.processExited = { exitCode in
    print("Process exited with code: \(exitCode)")
}

// Handle output
terminal.dataReceived = { data in
    // Process terminal output
}
```

### Sending Input

```swift
// Send text to the terminal
terminal.send(text: "ls -la\n")

// Send raw data
terminal.send(data: Data([0x1b, 0x5b, 0x41]))  // Up arrow
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isRunning` | `Bool` | Process is active |
| `columns` | `Int` | Terminal width |
| `rows` | `Int` | Terminal height |

### Features

- Full VT100/ANSI support
- 256 color support
- Mouse support
- Selection and copy
- Scrollback buffer

---

## SolidBackground

``SolidBackground`` fills its area with a pattern or color.

### Basic Usage

```swift
let background = SolidBackground()
background.fill()
background.pattern = "·"  // Stippled pattern
container.addSubview(background)
```

### Used in StandardDesktop

The `StandardDesktop` uses `SolidBackground` for the desktop surface behind windows.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `pattern` | `Character` | Fill character |
| `attribute` | `Attribute?` | Custom colors |

---

## Common Patterns

### Embedded Terminal in Application

```swift
class EditorWithTerminal: View {
    let editor: TextView
    let terminal: Terminal
    let split: SplitView

    init() {
        split = SplitView()
        split.orientation = .vertical
        split.position = 0.7

        editor = TextView()
        terminal = Terminal()

        split.addArrangedSubview(editor)
        split.addArrangedSubview(terminal)

        super.init()
        addSubview(split)
        fill()
    }

    func runBuild() {
        terminal.startProcess(
            executable: "/usr/bin/make",
            args: [],
            currentDirectory: projectPath
        )
    }
}
```

### Terminal with Custom Shell

```swift
let terminal = Terminal()
terminal.fill()

// Use fish shell with custom config
terminal.startProcess(
    executable: "/usr/local/bin/fish",
    args: ["--init-command", "set -g fish_greeting ''"],
    environment: [
        "TERM": "xterm-256color",
        "COLORTERM": "truecolor"
    ]
)
```

### Output-Only Terminal

For showing command output without interaction:

```swift
let output = Terminal()
output.fill()
output.canFocus = false  // Disable keyboard input

// Run command and display output
output.startProcess(
    executable: "/bin/sh",
    args: ["-c", "tail -f /var/log/system.log"]
)
```

### Desktop Background

```swift
let desktop = StandardDesktop()

// The desktop automatically uses SolidBackground
// You can customize the pattern
if let bg = desktop.background as? SolidBackground {
    bg.pattern = "░"
    bg.attribute = Application.makeAttribute(
        fore: .brightBlue,
        back: .blue
    )
}
```

## See Also

- ``Terminal``
- ``SolidBackground``
- ``StandardDesktop``
