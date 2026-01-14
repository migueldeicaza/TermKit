# Architecture Overview

Understand the high-level design of TermKit.

## Overview

TermKit is a Swift framework for building terminal user interfaces (TUIs). Its architecture draws inspiration from UIKit and AppKit, providing familiar patterns for Cocoa developers while adapting to the unique constraints of terminal environments.

## Core Architectural Layers

```
┌─────────────────────────────────────────────────┐
│                 Your Application                │
├─────────────────────────────────────────────────┤
│     Views: Button, TextField, ListView, etc.    │
├─────────────────────────────────────────────────┤
│         Core: View, Application, Toplevel       │
├─────────────────────────────────────────────────┤
│     Rendering: Painter, Layer, Composition      │
├─────────────────────────────────────────────────┤
│   Drivers: CursesDriver, UnixDriver, etc.       │
├─────────────────────────────────────────────────┤
│              Terminal / Console                 │
└─────────────────────────────────────────────────┘
```

### Application Layer

The ``Application`` class serves as the entry point and coordinator:

- Initializes the appropriate console driver
- Manages the toplevel stack
- Runs the main event loop using Grand Central Dispatch
- Coordinates rendering and screen updates

### View Layer

Views form a hierarchical tree structure:

- ``View`` is the base class for all UI elements
- ``Toplevel`` represents root-level containers
- ``Window``, ``Dialog``, and controls inherit from View
- Views handle their own rendering and event processing

### Rendering Layer

TermKit uses a layer-backed rendering system:

- Each view renders to its own ``Layer`` (a pixel buffer)
- ``Painter`` provides a drawing context with clipping
- Layers are composited bottom-up for correct z-ordering
- Only dirty regions are redrawn for efficiency

### Driver Layer

Console drivers abstract platform differences:

- ``CursesDriver`` - NCurses for Unix/macOS
- ``UnixDriver`` - Raw ANSI escape sequences
- ``WindowsDriver`` - Windows Console API
- ``TTYDriver`` - Plain text for testing

## Key Design Patterns

### View Hierarchy

Views form a tree, similar to UIKit:

```swift
Application.top           // Root Toplevel
└── Window                // Main window
    ├── Label             // Title
    ├── TextField         // Input
    └── Frame             // Container
        ├── Button        // OK
        └── Button        // Cancel
```

### Responder Chain

Events flow through the view hierarchy:

1. First responder receives the event
2. If unhandled, event propagates to superview
3. Process continues until handled or reaches root

### Computed Layout

The Pos/Dim system enables responsive layouts:

```swift
view.x = Pos.center()           // Computed position
view.width = Dim.percent(n: 80) // Computed dimension
```

Layout dependencies are resolved via topological sort.

### Modal Presentation

Dialogs and popups use a toplevel stack:

```swift
Application.present(top: dialog)  // Push modal
Application.requestStop()          // Pop modal
```

## Threading Model

TermKit is **not thread-safe**. All UI operations must occur on the main queue:

```swift
DispatchQueue.main.async {
    // Safe to modify views here
    label.text = "Updated"
}
```

The main event loop uses `dispatchMain()`, integrating with GCD.

## Module Organization

```
Sources/TermKit/
├── Core/           # Foundation classes
│   ├── Application.swift
│   ├── View.swift
│   ├── Toplevel.swift
│   ├── Painter.swift
│   ├── Layer.swift
│   ├── Pos.swift
│   ├── Dim.swift
│   └── ...
├── Views/          # UI controls
│   ├── Button.swift
│   ├── TextField.swift
│   ├── ListView.swift
│   └── ...
├── Dialogs/        # Dialog implementations
│   ├── Dialog.swift
│   ├── MessageBox.swift
│   └── ...
└── Drivers/        # Console drivers
    ├── ConsoleDriver.swift
    ├── CursesDriver.swift
    ├── UnixDriver.swift
    └── ...
```

## Data Flow

### Input Processing

```
Terminal Input
    ↓
Console Driver (decode escape sequences)
    ↓
Application (dispatch to current toplevel)
    ↓
Toplevel (hot keys → focused view → cold keys)
    ↓
View.processKey() / View.mouseEvent()
```

### Rendering Pipeline

```
view.setNeedsDisplay()
    ↓
postProcessEvent() scheduled
    ↓
renderDirtyViews() - views render to their layers
    ↓
compose() - layers composited to screen buffer
    ↓
updateDisplay() - buffer sent to driver
    ↓
driver.refresh() - terminal updated
```

## Extension Points

### Custom Views

Subclass ``View`` and override:

- `drawContent(in:painter:)` - Custom rendering
- `processKey(event:)` - Keyboard handling
- `mouseEvent(event:)` - Mouse handling

### Custom Drivers

Subclass ``ConsoleDriver`` to support new platforms or testing scenarios.

### Color Schemes

Create ``ColorScheme`` instances to theme your application.

## Dependencies

TermKit depends on:

- **TextBufferKit** - Efficient text buffer for TextView
- **SwiftTerm** - Terminal emulation for Terminal view
- **swift-markdown** - Markdown parsing for MarkdownView
- **swift-log** - Structured logging
- **Curses** - System library (NCurses)

## Performance Considerations

1. **Lazy rendering**: Only dirty views are redrawn
2. **Layer caching**: Views keep rendered content in layers
3. **Incremental updates**: Compose only changed regions
4. **Throttled updates**: Screen refresh is rate-limited

## Topics

### Architecture Deep Dives

- <doc:Architecture-ViewHierarchy>
- <doc:Architecture-Rendering>
- <doc:Architecture-Events>
- <doc:Architecture-Drivers>

## See Also

- ``Application``
- ``View``
- ``ConsoleDriver``
- ``Painter``
