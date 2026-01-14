# Core Concepts

Understand the fundamental architecture of TermKit applications.

## Overview

TermKit is built on concepts familiar to developers who have used UIKit or AppKit. This guide explains the core abstractions that power every TermKit application.

## The Application Class

``Application`` is the central coordinator for your TermKit application. It manages:

- **Driver selection**: Choosing the appropriate console driver for your platform
- **Event loop**: Processing keyboard and mouse input
- **Toplevel stack**: Managing modal windows and dialogs
- **Rendering**: Coordinating screen updates

### Lifecycle

```swift
// 1. Initialize the framework
Application.prepare()

// 2. Build your UI
let win = Window("My App")
Application.top.addSubview(win)

// 3. Start the event loop (blocks until exit)
Application.run()
```

### Key Properties

- `Application.top` - The root toplevel view
- `Application.current` - The currently active toplevel (may be a dialog)
- `Application.driver` - The console driver in use

## Views

``View`` is the base class for all visual elements. Views can:

- Render themselves to the screen
- Contain nested subviews
- Respond to keyboard and mouse events
- Participate in the focus chain

### View Hierarchy

Views form a tree structure. Each view has:
- One **superview** (parent), except the root
- Zero or more **subviews** (children)

```swift
let container = View()
let child1 = Label("First")
let child2 = Label("Second")

container.addSubview(child1)
container.addSubview(child2)

// child1.superview == container
// container.subviews == [child1, child2]
```

### Coordinate System

Each view has its own coordinate system:

- **frame** - Position and size relative to the superview
- **bounds** - The view's own rectangle, always at origin (0, 0)
- **contentFrame** - Area available for content (inside border and padding)

```
+------ frame (in superview coordinates) ------+
|  margin                                       |
|  +-------- border ---------+                  |
|  |  padding                |                  |
|  |  +-- contentFrame --+   |                  |
|  |  |                  |   |                  |
|  |  |   (your content) |   |                  |
|  |  +------------------+   |                  |
|  +-------------------------+                  |
+-----------------------------------------------+
```

## The Responder Chain

TermKit uses a responder chain pattern for event handling, similar to Cocoa:

1. **First Responder**: The view that currently has focus
2. **Responder Chain**: Events bubble up through the view hierarchy
3. **Focus Management**: Tab navigation moves between focusable views

### Focus

Views can be focusable:

```swift
button.canFocus = true   // This view can receive focus
button.tabStop = true    // Include in tab navigation
```

The focused view receives keyboard events first. If it doesn't handle an event, the event propagates up the responder chain.

### Keyboard Event Processing

Events are processed in three phases:

1. **Hot Keys** (`processHotKey`) - Alt+key combinations, processed first
2. **Key Events** (`processKey`) - Normal key processing for focused view
3. **Cold Keys** (`processColdKey`) - Fallback processing (e.g., default buttons)

```swift
class MyView: View {
    override func processKey(event: KeyEvent) -> Bool {
        if event.key == .letter("q") {
            // Handle 'q' key
            return true  // Event was consumed
        }
        return super.processKey(event: event)  // Pass to parent
    }
}
```

## Toplevels

``Toplevel`` is a special view that can be the root of a view hierarchy. The application maintains a stack of toplevels:

- **Application.top**: The main application toplevel
- **Modal toplevels**: Dialogs and popups pushed onto the stack

```swift
// Present a modal dialog
let dialog = Dialog("Confirm", width: 40, height: 10)
Application.present(top: dialog)

// Dismiss it
Application.requestStop()  // Pops the current toplevel
```

## Color Schemes

``ColorScheme`` defines the colors used for rendering views:

```swift
let scheme = ColorScheme()
scheme.normal = Application.makeAttribute(fore: .white, back: .blue)
scheme.focus = Application.makeAttribute(fore: .black, back: .cyan)
scheme.hotNormal = Application.makeAttribute(fore: .yellow, back: .blue)
scheme.hotFocus = Application.makeAttribute(fore: .yellow, back: .cyan)

myView.colorScheme = scheme
```

Color schemes cascade down the view hierarchy. A view without an explicit scheme inherits from its superview.

## Layout Styles

Views support two layout modes:

### Fixed Layout

Position and size are explicitly set via the `frame` property:

```swift
let view = View(frame: Rect(x: 10, y: 5, width: 30, height: 10))
// view.layoutStyle == .fixed
```

### Computed Layout

Position and size are computed from `x`, `y`, `width`, and `height` properties:

```swift
let view = View()
view.x = Pos.center()
view.y = Pos.at(5)
view.width = Dim.percent(n: 80)
view.height = Dim.fill()
// view.layoutStyle == .computed
```

Computed layout is preferred for responsive applications.

## The Rendering Pipeline

TermKit uses a layer-based rendering system:

1. **setNeedsDisplay()** - Mark a view as needing redraw
2. **redraw()** - Render the view to its backing layer
3. **compose()** - Composite all layers into the final screen
4. **Driver refresh** - Send the buffer to the terminal

You typically only need to call `setNeedsDisplay()` when your view's state changes.

## Summary

| Concept | Purpose |
|---------|---------|
| Application | Manages lifecycle, drivers, and event loop |
| View | Base class for all visual elements |
| Toplevel | Root of a view tree, supports modal stacking |
| Responder | Protocol for event handling |
| ColorScheme | Defines rendering colors |
| Pos/Dim | Flexible positioning and sizing |

## Next Steps

- <doc:GettingStarted-LayoutFundamentals> - Master the layout system
- <doc:Architecture-ViewHierarchy> - Deep dive into view management
- <doc:Architecture-Events> - Understand the event system

## See Also

- ``Application``
- ``View``
- ``Toplevel``
- ``Responder``
- ``ColorScheme``
