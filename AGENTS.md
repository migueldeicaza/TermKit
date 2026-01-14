# TermKit Development Guide

This project is a console user interface toolkit (TUI) modeled on ideas
from UIKit, in terms of the Responder, the base View class and how it
nests subviews.

## Architecture Overview

- **Application**: Main coordinator - manages drivers, event loop, toplevel stack
- **View**: Base class for all UI elements - handles rendering, layout, events
- **Toplevel**: Root of a view hierarchy, supports modal stacking
- **Painter**: Drawing context for rendering to layers
- **Layer**: Pixel buffer for view content (layer-backed rendering)
- **ConsoleDriver**: Platform abstraction (CursesDriver, UnixDriver, WindowsDriver, TTYDriver)

## Implementing Custom Views

Custom views are implemented by overriding the `drawContent(in region: Rect, painter: Painter)` method (preferred) or `redraw(region: Rect, painter: Painter)` method. They handle input by overriding:
- `processKey(event:)` for regular keyboard input
- `processHotKey(event:)` for Alt+key combinations (processed first)
- `processColdKey(event:)` for fallback handling (e.g., default buttons)
- `mouseEvent(event:)` for mouse input

Views that can be focused should set `canFocus = true` in their initializer. Focus a specific view with `setFocus(_:)`.

When implementing views, since it is not always possible to hide the cursor, you must implement `positionCursor()` so that the cursor is placed where the view is, or in a place that is relevant to the view.

### Key Methods to Override

```swift
class MyView: View {
    override func drawContent(in region: Rect, painter: Painter) {
        // Render view content
        painter.attribute = colorScheme.normal
        painter.goto(col: 0, row: 0)
        painter.add(str: "Content")
    }

    override func processKey(event: KeyEvent) -> Bool {
        // Return true if event was consumed
        return super.processKey(event: event)
    }

    override func mouseEvent(event: MouseEvent) -> Bool {
        if event.flags.contains(.button1Clicked) {
            // Handle click
            return true
        }
        return super.mouseEvent(event: event)
    }

    override func positionCursor() {
        moveTo(col: cursorCol, row: cursorRow)
    }
}
```

## Layout System

Views use Pos and Dim for computed layout:

```swift
view.x = Pos.center()           // Centered
view.x = Pos.at(10)             // Absolute position
view.x = Pos.percent(n: 25)     // 25% from edge
view.x = Pos.right(of: other)   // Relative to another view

view.width = Dim.fill()         // Fill remaining space
view.width = Dim.sized(30)      // Absolute size
view.width = Dim.percent(n: 80) // 80% of container
```

## Testing

You can run `swift build`, but currently there is no way for you to test the visual results interactively.

You can set the environment variable `TERMKIT_DRIVER=stoptty` to run your programs in test mode. It will run with limited functionality and display the text rendering, but you won't be able to steer it in any direction - it will render and terminate within 2 seconds.

```bash
TERMKIT_DRIVER=stoptty swift run Example --demo=misc
```

Other driver options:
- `TERMKIT_DRIVER=tty` - Plain text output (good for capturing output)
- `TERMKIT_DRIVER=unix` - Raw ANSI escape sequences
- `TERMKIT_DRIVER=curses` - NCurses driver (macOS 15+)

## Example Code

When creating example code, for say testing the feature "Cat", create
a "DemoCat.swift" in the Example project, subclassing "DemoHost" and adding
your view there, and listing this in the `main.swift` file in the options array.

Available demos can be run with:
```bash
swift run Example --demo=<name>
```

Demo names: misc, boxmodel, dialogs, terminal, datatable, splitview, drawing, tabview, spinner, statusbar, windows, markdown, desktop, layer, cmdpalette

## Documentation

Documentation is in `Documentation.docc/` using Swift DocC format.

### Documentation Structure

```
Documentation.docc/
├── Documentation.md              # Main landing page
├── GettingStarted-*.md          # New user guides (4 files)
├── Architecture-*.md            # System design docs (5 files)
├── Controls-*.md                # Control reference (7 files)
├── Tutorial-*.md                # Step-by-step tutorials (3 files)
├── Advanced-*.md                # Advanced topics (3 files)
└── Examples.md                  # Demo catalog
```

### Building Documentation

```bash
# Generate documentation
swift package generate-documentation --target TermKit

# Preview locally
swift package --disable-sandbox preview-documentation --target TermKit
```

### Documentation Guidelines

When adding new features or controls:

1. **Add inline documentation** to public APIs using `///` comments
2. **Update control reference** in appropriate `Controls-*.md` file
3. **Add usage examples** showing common patterns
4. **Update Examples.md** if adding a new demo

Documentation style:
- Use DocC syntax: ```` ```swift ```` for code blocks
- Link to symbols with ``` ``SymbolName`` ```
- Link to articles with `<doc:ArticleName>`
- Include practical code examples
- Keep explanations concise

### Key Documentation Files

| Category | Files | Content |
|----------|-------|---------|
| Getting Started | 4 guides | QuickStart, HelloWorld, CoreConcepts, LayoutFundamentals |
| Architecture | 5 docs | Overview, ViewHierarchy, Rendering, Events, Drivers |
| Controls | 7 docs | Input, Display, Container, List/Table, Navigation, Dialogs, Specialized |
| Tutorials | 3 tutorials | BuildingAForm, CustomControl, Desktop |
| Advanced | 3 docs | Theming, CustomDrawing, CrossPlatform |

## Available Controls

**Input**: Button, TextField, TextView, Checkbox, RadioGroup
**Display**: Label, ProgressBar, Spinner, HexView, MarkdownView, StatusBar
**Container**: Window, Frame, ScrollView, SplitView, TabView, StandardDesktop
**List/Table**: ListView, DataTable
**Navigation**: Menu, MenuBar, CommandPalette
**Dialogs**: Dialog, MessageBox, InputBox, FileDialog
**Specialized**: Terminal, SolidBackground
