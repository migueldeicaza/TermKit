# Console Drivers

Understand how TermKit interfaces with different terminal implementations.

## Overview

Console drivers abstract the differences between terminal implementations and platforms. They handle raw input/output, color management, and terminal capabilities.

## Available Drivers

### CursesDriver

Uses the NCurses library for full terminal capabilities:

- Best color support
- Handles terminal resize
- Wide character support
- Available on macOS and Linux

```swift
Application.prepare(driverType: .curses)
```

### UnixDriver

Uses raw ANSI escape sequences:

- No NCurses dependency
- Works on any ANSI-compatible terminal
- Lightweight implementation
- Default fallback on Unix systems

```swift
Application.prepare(driverType: .unix)
```

### WindowsDriver

Uses the Windows Console API:

- Native Windows support
- Full color and input handling
- Only available on Windows

```swift
Application.prepare(driverType: .windows)
```

### TTYDriver

Plain text output for testing:

- No escape sequences
- Capturable output
- Useful for automated testing
- Debugging aid

```swift
Application.prepare(driverType: .tty)
```

## Driver Selection

### Automatic Selection

By default, TermKit chooses the best available driver:

```swift
Application.prepare()  // Auto-select
```

Selection logic:
1. Windows → WindowsDriver
2. macOS 15.0+ → CursesDriver (falls back to UnixDriver if not operational)
3. Other Unix → UnixDriver

### Environment Variable

Override driver selection with `TERMKIT_DRIVER`:

```bash
# Force specific driver
export TERMKIT_DRIVER=curses
export TERMKIT_DRIVER=unix
export TERMKIT_DRIVER=tty
export TERMKIT_DRIVER=windows

swift run MyApp
```

### Programmatic Selection

Specify the driver when initializing:

```swift
Application.prepare(driverType: .curses)
Application.prepare(driverType: .unix)
Application.prepare(driverType: .tty)
```

## Driver Capabilities

Each driver provides:

### Screen Management

```swift
driver.size        // Terminal dimensions (Size)
driver.moveTo(col:row:)  // Position cursor
driver.refresh()   // Update display
driver.updateScreen()  // Full repaint
driver.updateCursor()  // Update cursor position only
```

### Attributes

```swift
driver.makeAttribute(fore:back:flags:)  // Create attribute
driver.setAttribute(_:)   // Set current attribute
driver.addCharacter(_:)   // Output character
```

### Lifecycle

```swift
driver.end()  // Cleanup and restore terminal
```

## Colors

TermKit supports terminal colors through the ``Color`` enum:

### Standard Colors

```swift
Color.black
Color.red
Color.green
Color.yellow
Color.blue
Color.magenta
Color.cyan
Color.white
```

### Bright Colors

```swift
Color.brightBlack   // (gray)
Color.brightRed
Color.brightGreen
Color.brightYellow
Color.brightBlue
Color.brightMagenta
Color.brightCyan
Color.brightWhite
```

### Creating Attributes

```swift
let attr = Application.makeAttribute(
    fore: .white,
    back: .blue,
    flags: [.bold]
)
```

## Cell Flags

Text styling options:

```swift
CellFlags.bold
CellFlags.dim
CellFlags.italic
CellFlags.underline
CellFlags.blink
CellFlags.inverse
CellFlags.invisible
CellFlags.strikethrough
```

Combine flags:

```swift
let flags: CellFlags = [.bold, .underline]
```

## Terminal Resize

TermKit automatically handles terminal resize:

1. Driver detects resize signal (SIGWINCH)
2. `Application.terminalResized()` is called
3. All toplevels recompute layout
4. Screen is refreshed

## Testing with TTYDriver

The TTY driver is useful for testing:

```bash
# Run with TTY driver
TERMKIT_DRIVER=tty swift run MyApp > output.txt

# Inspect rendered output
cat output.txt
```

For automated testing:

```swift
// In tests
Application.prepare(driverType: .tty)
// ... setup UI ...
// TTY driver captures output without terminal interaction
```

### Timed Stop

The `stoptty` variant auto-stops after 2 seconds:

```bash
TERMKIT_DRIVER=stoptty swift run MyApp
# App runs briefly then exits
```

## Custom Drivers

To create a custom driver, subclass ``ConsoleDriver``:

```swift
class MyDriver: ConsoleDriver {
    override var size: Size {
        // Return terminal size
    }

    override func moveTo(col: Int, row: Int) {
        // Position cursor
    }

    override func setAttribute(_ attr: Attribute) {
        // Set current attribute
    }

    override func addCharacter(_ ch: Character) {
        // Output character at cursor
    }

    override func refresh() {
        // Flush output
    }

    override func end() {
        // Cleanup
    }
}
```

## Debugging

Monitor driver activity:

```swift
Application.log("Driver size: \(Application.driver.size)")
```

Watch logs:

```bash
log stream --style compact --predicate 'subsystem == "termkit"'
```

## Platform Considerations

### macOS

- CursesDriver requires macOS 15.0+ for best compatibility
- Ghostty terminal uses UnixDriver automatically
- Console.app shows Application.log output

### Linux

- UnixDriver works on most terminals
- CursesDriver requires ncurses library
- Test with various terminal emulators

### Windows

- WindowsDriver is the only option
- Requires Windows 10+ for best color support
- Legacy console mode has limited capabilities

## See Also

- ``ConsoleDriver``
- ``CursesDriver``
- ``UnixDriver``
- ``TTYDriver``
- ``Color``
- ``CellFlags``
- ``Attribute``
