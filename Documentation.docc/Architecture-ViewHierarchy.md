# View Hierarchy

Deep dive into how views are organized and managed.

## Overview

TermKit organizes visual elements in a hierarchical tree structure. Understanding this hierarchy is essential for building complex interfaces and handling events correctly.

## The View Tree

Every TermKit application has a view tree rooted at `Application.top`:

```
Application.top (Toplevel)
├── Window "Main"
│   ├── MenuBar
│   ├── Frame "Content"
│   │   ├── Label
│   │   ├── TextField
│   │   └── Button
│   └── StatusBar
└── Dialog "Settings" (modal, on top)
    ├── Checkbox
    └── Button "OK"
```

### Parent-Child Relationships

Each view maintains references to its relatives:

```swift
view.superview    // Parent view (nil for root)
view.subviews     // Array of child views
```

### Adding and Removing Views

```swift
// Add a child
container.addSubview(child)
// child.superview == container

// Remove a child
container.removeSubview(child)
// child.superview == nil

// Remove all children
container.removeAllSubviews()
```

### Z-Order

Subviews are rendered in array order (back to front). Control z-order with:

```swift
container.bringSubviewToFront(view)  // Move to top
container.sendSubviewToBack(view)    // Move to bottom
container.bringForward(subview: view)   // Move up one level
container.sendBackwards(subview: view)  // Move down one level
```

## Coordinate Systems

Each view has its own coordinate system:

### Frame

The view's rectangle in its superview's coordinate system:

```swift
view.frame = Rect(x: 10, y: 5, width: 30, height: 10)
// Positioned at column 10, row 5 within the parent
```

### Bounds

The view's own coordinate system, always starting at (0, 0):

```swift
view.bounds  // Rect(x: 0, y: 0, width: 30, height: 10)
```

### Content Frame

The area available for content, after accounting for border and padding:

```swift
view.border = .single
view.padding = EdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
view.contentFrame  // Inset by border and padding
```

### Coordinate Conversion

Convert between coordinate systems:

```swift
// View coordinates to screen coordinates
let screenPoint = view.viewToScreen(Point(x: 5, y: 3))

// Screen coordinates to view coordinates
let localPoint = view.screenToView(loc: screenPoint)
```

## Toplevel Views

``Toplevel`` is a special view that serves as the root of a view tree. The application maintains a stack of toplevels:

```swift
Application.top      // The root toplevel
Application.current  // The currently active toplevel
```

### Modal Presentation

Present new toplevels modally:

```swift
let dialog = Dialog("Confirm", width: 40, height: 10)
Application.present(top: dialog)
// Dialog is now on top and receives all input

Application.requestStop()
// Dialog is dismissed, previous toplevel becomes active
```

### Toplevel Stack

```
┌─────────────────────────────────┐
│ Dialog "Confirm" (current)      │  ← Receives input
├─────────────────────────────────┤
│ Window "Preferences"            │  ← Visible but not active
├─────────────────────────────────┤
│ Application.top (root)          │  ← Main window
└─────────────────────────────────┘
```

## Windows

``Window`` provides a titled, bordered container:

```swift
let win = Window("Document Editor")
win.fill()
win.allowMove = true    // Enable dragging
win.allowResize = true  // Enable resizing

Application.top.addSubview(win)
```

Windows support:
- Title bar with text
- Border styles
- Move and resize handles
- Minimize/maximize controls

## Focus Management

The focus system determines which view receives keyboard input.

### Focus Properties

```swift
view.canFocus   // Can this view receive focus?
view.hasFocus   // Does this view currently have focus?
view.focused    // Which subview has focus (if any)?
view.tabStop    // Include in tab navigation?
```

### Setting Focus

```swift
container.setFocus(view)  // Focus a specific view
container.focusFirst()    // Focus first focusable child
container.focusLast()     // Focus last focusable child
container.focusNext()     // Tab to next view
container.focusPrev()     // Shift-tab to previous view
```

### Focus Chain

Focus flows through nested containers:

```swift
window.focused          // → frame
frame.focused           // → textField
textField.hasFocus      // → true
textField.mostFocused() // Returns the leaf focused view
```

## Layout

Views are laid out in one of two modes:

### Fixed Layout

Frame is set explicitly:

```swift
let view = View(frame: Rect(x: 0, y: 0, width: 20, height: 5))
view.layoutStyle  // .fixed
```

### Computed Layout

Frame is computed from Pos/Dim properties:

```swift
let view = View()
view.x = Pos.center()
view.y = Pos.at(5)
view.width = Dim.percent(n: 80)
view.height = Dim.fill()
view.layoutStyle  // .computed
```

### Layout Triggers

```swift
view.setNeedsLayout()    // Mark for layout
try view.layoutSubviews() // Compute immediately
```

### Layout Lifecycle

1. Parent's `layoutSubviews()` is called
2. Dependencies between views are analyzed
3. Views are sorted topologically
4. Each view's frame is computed
5. Child `layoutSubviews()` is called recursively

## View Lifecycle

### Creation

```swift
let view = MyView()
// or
let view = MyView(frame: Rect(...))
```

### Addition to Hierarchy

```swift
parent.addSubview(view)
// view.superview is set
// subviewAdded(_:) is called
// Layout is triggered
```

### Display

```swift
view.setNeedsDisplay()  // Request redraw
// Later: redraw(region:painter:) is called
```

### Removal

```swift
parent.removeSubview(view)
// view.superview is cleared
// subviewRemoved(_:from:) is called
```

## Common View Types

| Type | Purpose |
|------|---------|
| ``View`` | Base class for all views |
| ``Toplevel`` | Root of a view tree |
| ``Window`` | Titled, bordered container |
| ``Dialog`` | Modal window for user interaction |
| ``Frame`` | Container with optional title and border |
| ``ScrollView`` | Scrollable container |
| ``SplitView`` | Resizable split panels |

## Best Practices

1. **Prefer computed layout** for responsive UIs
2. **Use containers** (Frame, ScrollView) to group related views
3. **Set canFocus appropriately** for keyboard navigation
4. **Override subviewAdded/subviewRemoved** to respond to hierarchy changes
5. **Use setNeedsDisplay()** instead of direct drawing

## See Also

- ``View``
- ``Toplevel``
- ``Window``
- ``Dialog``
- ``Frame``
