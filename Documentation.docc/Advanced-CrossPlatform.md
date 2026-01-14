# Cross-Platform Development

Build applications that work on macOS, Linux, and Windows.

## Overview

TermKit runs on macOS, Linux, and Windows. This guide covers platform differences and best practices for cross-platform development.

## Platform Support

| Platform | Drivers Available | Notes |
|----------|------------------|-------|
| macOS | CursesDriver, UnixDriver | Best support |
| Linux | UnixDriver, CursesDriver | Wide terminal compatibility |
| Windows | WindowsDriver | Windows 10+ recommended |

## Driver Selection

### Automatic Selection

By default, TermKit chooses the best driver:

```swift
Application.prepare()  // Auto-selects appropriate driver
```

### Manual Selection

Force a specific driver for testing:

```swift
#if os(macOS)
Application.prepare(driverType: .curses)
#elseif os(Windows)
Application.prepare(driverType: .windows)
#else
Application.prepare(driverType: .unix)
#endif
```

### Environment Variable

Override at runtime:

```bash
TERMKIT_DRIVER=unix ./myapp
```

## Platform-Specific Code

Use conditional compilation:

```swift
#if os(macOS)
let documentsPath = FileManager.default
    .homeDirectoryForCurrentUser
    .appendingPathComponent("Documents")
#elseif os(Windows)
let documentsPath = FileManager.default
    .homeDirectoryForCurrentUser
    .appendingPathComponent("Documents")
#elseif os(Linux)
let documentsPath = FileManager.default
    .homeDirectoryForCurrentUser
    .appendingPathComponent("Documents")
#endif
```

## Terminal Differences

### Color Support

Not all terminals support all colors:

```swift
// Safe: 16 standard colors work everywhere
let safeAttr = Application.makeAttribute(
    fore: .white,
    back: .blue
)

// Bright colors: most terminals
let brightAttr = Application.makeAttribute(
    fore: .brightWhite,
    back: .brightBlue
)
```

### Cell Flags

Some flags may not render on all terminals:

```swift
// Universal support
CellFlags.bold
CellFlags.underline
CellFlags.inverse

// Variable support
CellFlags.italic        // May not work
CellFlags.strikethrough // Limited support
CellFlags.blink         // Often disabled
```

### Unicode Support

Test with basic ASCII fallbacks:

```swift
// Preferred (Unicode box drawing)
let fancyBorder = "╭─╮│╰─╯"

// Fallback (ASCII)
let asciiBorder = "+-+|+-+"

// Check terminal capability
let useFancy = terminalSupportsUnicode()
view.border = useFancy ? .rounded : .single
```

## File Paths

Handle path differences:

```swift
import Foundation

// Use FileManager for cross-platform paths
let homeDir = FileManager.default.homeDirectoryForCurrentUser

// Use URL APIs
let configDir = homeDir.appendingPathComponent(".config")
    .appendingPathComponent("myapp")

// Path separators are handled automatically
let configFile = configDir.appendingPathComponent("settings.json")
```

## Keyboard Handling

Some keys behave differently:

```swift
override func processKey(event: KeyEvent) -> Bool {
    switch event.key {
    // Universal
    case .enter, .tab, .escape:
        handleKey(event.key)
        return true

    // May vary by platform
    case .delete:
        // macOS: Forward delete
        // Windows/Linux: Usually backspace
        handleDelete()
        return true

    // Control keys work similarly
    case .controlC, .controlV:
        handleControl(event.key)
        return true

    default:
        return super.processKey(event: event)
    }
}
```

## Testing Across Platforms

### Local Testing

Use environment variables for driver testing:

```bash
# Test Unix driver on macOS
TERMKIT_DRIVER=unix swift run

# Test TTY driver for output capture
TERMKIT_DRIVER=tty swift run > output.txt
```

### CI/CD Testing

Configure GitHub Actions for multi-platform:

```yaml
strategy:
  matrix:
    os: [macos-latest, ubuntu-latest, windows-latest]

steps:
  - uses: actions/checkout@v2
  - name: Build
    run: swift build
  - name: Test
    run: swift test
```

## Common Issues

### Terminal Size

Handle small terminals gracefully:

```swift
let minWidth = 80
let minHeight = 24

if Application.driver.size.width < minWidth ||
   Application.driver.size.height < minHeight {
    print("Terminal too small. Need \(minWidth)x\(minHeight)")
    exit(1)
}
```

### Resize Handling

Terminal resize is automatic, but you can hook into it:

```swift
// Views automatically re-layout on resize
// For custom handling, override layoutSubviews:
override func layoutSubviews() throws {
    try super.layoutSubviews()
    // Custom resize logic
}
```

### Signal Handling

TermKit handles SIGWINCH (resize) automatically. For other signals:

```swift
import Foundation

signal(SIGINT) { _ in
    DispatchQueue.main.async {
        Application.requestStop()
    }
}
```

## Best Practices

1. **Test on all target platforms** early and often
2. **Use standard colors** for maximum compatibility
3. **Provide ASCII fallbacks** for Unicode characters
4. **Use FileManager APIs** for file paths
5. **Handle terminal resize** gracefully
6. **Test with TTY driver** for automated testing
7. **Document platform requirements** in your README

## Building for Distribution

### macOS

```bash
swift build -c release
# Binary at .build/release/YourApp
```

### Linux

```bash
swift build -c release
# May need: apt-get install libncurses-dev
```

### Windows

```powershell
swift build -c release
# Requires Swift for Windows toolchain
```

## See Also

- <doc:Architecture-Drivers>
- ``ConsoleDriver``
- ``CursesDriver``
- ``UnixDriver``
- ``WindowsDriver``
