# Rendering Pipeline

Understand how TermKit draws to the terminal.

## Overview

TermKit uses a sophisticated layer-based rendering system. Each view renders to its own backing layer, and these layers are composited together to produce the final screen output. This architecture enables efficient partial updates and correct z-ordering.

## Layer-Based Rendering

### What is a Layer?

A ``Layer`` is a 2D buffer of cells, where each cell contains:
- A character to display
- An attribute (colors and styles)

```swift
// Each view has its own layer
view.layer  // Layer instance

// Layer dimensions match view bounds
view.layer.size == view.bounds.size
```

### Why Layers?

1. **Isolation**: Views render independently
2. **Z-ordering**: Layers are composited in correct order
3. **Efficiency**: Only dirty views need to redraw
4. **Caching**: Rendered content persists until invalidated

## The Rendering Pipeline

```
┌─────────────────────────────────────────┐
│  1. setNeedsDisplay()                   │
│     Mark view as needing redraw         │
├─────────────────────────────────────────┤
│  2. renderDirtyViews()                  │
│     Views redraw to their layers        │
├─────────────────────────────────────────┤
│  3. compose()                           │
│     Composite layers into screen buffer │
├─────────────────────────────────────────┤
│  4. updateDisplay()                     │
│     Send buffer to console driver       │
├─────────────────────────────────────────┤
│  5. driver.refresh()                    │
│     Terminal displays the content       │
└─────────────────────────────────────────┘
```

### Step 1: Invalidation

When a view's state changes, mark it for redraw:

```swift
view.setNeedsDisplay()           // Entire view
view.setNeedsDisplay(region)     // Specific region
```

This sets the `needDisplay` rectangle and propagates up the hierarchy.

### Step 2: Rendering

Dirty views render to their layers:

```swift
// Called by the framework
view.redraw(region: dirtyRect, painter: painter)
```

The ``Painter`` provides a clipped drawing context targeting the view's layer.

### Step 3: Composition

Layers are composited bottom-up:

```swift
// Framework calls compose() on each view
view.compose(painter: parentPainter)
```

Child layers are drawn on top of parent layers.

### Step 4: Display Update

The composited screen buffer is sent to the driver:

```swift
// Framework handles this
Application.updateDisplay(screenLayer)
```

### Step 5: Terminal Refresh

The driver sends the appropriate escape sequences or API calls to update the terminal.

## The Painter Class

``Painter`` is your interface for drawing:

```swift
open func drawContent(in region: Rect, painter: Painter) {
    // Set drawing attribute
    painter.attribute = colorScheme.normal

    // Draw text
    painter.goto(col: 0, row: 0)
    painter.add(str: "Hello, World!")

    // Draw primitives
    painter.drawHorizontalLine(row: 2, col: 0, width: 20)
}
```

### Painter Properties

```swift
painter.attribute    // Current color/style attribute
painter.origin       // Offset from target layer origin
painter.clipRegion   // Current clipping rectangle
```

### Drawing Methods

```swift
// Positioning
painter.goto(col: Int, row: Int)

// Text
painter.add(str: String)
painter.add(ch: Character)
painter.add(rune: rune)

// Primitives
painter.drawHorizontalLine(row:col:width:rune:)
painter.drawVerticalLine(row:col:height:rune:)
painter.drawBorder(_:style:)

// Clearing
painter.clear(_: Rect)
painter.clearRegion(_: Rect)

// Layer blitting
painter.draw(layer: Layer, at: Point)
```

### Clipping

Create a clipped painter for drawing in a subregion:

```swift
let contentPainter = painter.clipped(to: contentFrame)
// Drawing is now clipped to contentFrame
```

## Custom View Rendering

Override `drawContent` to render your view:

```swift
class MyView: View {
    var message = "Custom content"

    override func drawContent(in region: Rect, painter: Painter) {
        painter.attribute = colorScheme.normal
        painter.goto(col: 0, row: 0)
        painter.add(str: message)
    }
}
```

### The redraw Method

For more control, override `redraw`:

```swift
override func redraw(region: Rect, painter: Painter) {
    // Call super to draw background and border
    super.redraw(region: region, painter: painter)

    // Add custom chrome (e.g., title in border)
    painter.attribute = colorScheme.hotNormal
    painter.goto(col: 2, row: 0)
    painter.add(str: "[\(title)]")
}
```

### Final Render Pass

For overlays like cursors, override `finalRenderPass`:

```swift
override func finalRenderPass(painter: Painter) {
    if hasFocus {
        // Draw cursor or focus indicator
        painter.attribute = colorScheme.focus
        painter.goto(col: cursorPosition, row: 0)
        painter.add(str: "█")
    }
}
```

## Attributes and Colors

``Attribute`` combines foreground color, background color, and cell flags:

```swift
let attr = Application.makeAttribute(
    fore: .brightWhite,
    back: .blue,
    flags: [.bold, .underline]
)
painter.attribute = attr
```

### Available Colors

```swift
// Standard colors
Color.black, .red, .green, .yellow, .blue, .magenta, .cyan, .white

// Bright variants
Color.brightBlack, .brightRed, .brightGreen, .brightYellow,
     .brightBlue, .brightMagenta, .brightCyan, .brightWhite
```

### Cell Flags

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

## Color Schemes

``ColorScheme`` provides consistent styling:

```swift
let scheme = ColorScheme()
scheme.normal    // Default state
scheme.focus     // When focused
scheme.hotNormal // Hotkey character, not focused
scheme.hotFocus  // Hotkey character, focused
scheme.disabled  // When disabled
```

Use in drawing:

```swift
painter.attribute = hasFocus ? colorScheme.focus : colorScheme.normal
```

## Borders and Boxes

Draw borders using built-in styles:

```swift
view.border = .single   // ┌─┐│└─┘
view.border = .double   // ╔═╗║╚═╝
view.border = .rounded  // ╭─╮│╰─╯
view.border = .heavy    // ┏━┓┃┗━┛
```

Or draw manually:

```swift
painter.drawBorder(bounds, style: .single)
```

## Performance Optimization

### Minimize Redraws

Only call `setNeedsDisplay()` when state actually changes:

```swift
var text: String = "" {
    didSet {
        if oldValue != text {
            setNeedsDisplay()
        }
    }
}
```

### Partial Updates

Invalidate only the changed region:

```swift
// Instead of
setNeedsDisplay()

// Do
setNeedsDisplay(Rect(x: changedCol, y: changedRow, width: 10, height: 1))
```

### Avoid Expensive Operations in redraw

Cache computed values instead of recalculating during render.

## Debugging Rendering

Enable debug drawing:

```swift
Application.debugDrawBounds = true
```

Use logging:

```swift
Application.log("Rendering: \(region)")
```

Monitor with Console.app:

```bash
log stream --style compact --predicate 'subsystem == "termkit"'
```

## See Also

- ``Painter``
- ``Layer``
- ``Attribute``
- ``ColorScheme``
- ``BorderStyle``
