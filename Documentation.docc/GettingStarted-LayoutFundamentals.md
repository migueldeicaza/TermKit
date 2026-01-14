# Layout Fundamentals

Master TermKit's flexible positioning and sizing system.

## Overview

TermKit provides a powerful layout system using `Pos` and `Dim` objects. These allow you to create responsive interfaces that adapt to terminal size changes without manual calculations.

## Layout Styles

Every view has a `layoutStyle` property that determines how its frame is computed:

### Fixed Layout

Use `View(frame:)` to create views with explicit positions and sizes:

```swift
let button = Button(frame: Rect(x: 10, y: 5, width: 15, height: 1))
// Position is absolute and won't change automatically
```

### Computed Layout

Use the default `View()` initializer and set `x`, `y`, `width`, and `height`:

```swift
let button = Button("Click Me")
button.x = Pos.center()
button.y = Pos.at(5)
button.width = Dim.sized(15)
button.height = Dim.sized(1)
// Position is recomputed when the container resizes
```

## Position with Pos

`Pos` objects describe where a view should be placed.

### Absolute Position

Place a view at a specific row or column:

```swift
view.x = Pos.at(10)   // Column 10
view.y = Pos.at(5)    // Row 5
```

### Percentage Position

Position relative to the container's size:

```swift
view.x = Pos.percent(n: 25)   // 25% from the left
view.y = Pos.percent(n: 50)   // 50% from the top (centered vertically)
```

### Centered Position

Center the view within its container:

```swift
view.x = Pos.center()   // Horizontally centered
view.y = Pos.center()   // Vertically centered
```

### Anchored to End

Position relative to the right or bottom edge:

```swift
view.x = Pos.anchorEnd(margin: 5)   // 5 columns from the right
view.y = Pos.anchorEnd(margin: 2)   // 2 rows from the bottom
```

### Relative to Another View

Position based on another view's coordinates:

```swift
let label = Label("Name:")
let field = TextField("")

// Position field to the right of the label
field.x = Pos.right(of: label) + 1   // 1 column after label ends
field.y = Pos.top(of: label)         // Same row as label
```

Available relative positions:
- `Pos.left(of:)` / `Pos.x(of:)` - Left edge (x coordinate)
- `Pos.top(of:)` / `Pos.y(of:)` - Top edge (y coordinate)
- `Pos.right(of:)` - Right edge
- `Pos.bottom(of:)` - Bottom edge

### Combining Positions

Use arithmetic operators to combine positions:

```swift
// Center minus 10 columns
view.x = Pos.center() - 10

// 5 columns after another view
view.x = Pos.right(of: otherView) + 5

// Percentage plus offset
view.y = Pos.percent(n: 75) - 2
```

## Dimensions with Dim

`Dim` objects describe how large a view should be.

### Absolute Size

Set an explicit size:

```swift
view.width = Dim.sized(30)    // 30 columns wide
view.height = Dim.sized(10)   // 10 rows tall
```

### Percentage Size

Size relative to the container:

```swift
view.width = Dim.percent(n: 80)    // 80% of container width
view.height = Dim.percent(n: 50)   // 50% of container height
```

### Fill Remaining Space

Expand to fill available space:

```swift
view.width = Dim.fill()        // Fill to the right edge
view.height = Dim.fill(2)      // Fill to bottom, leaving 2 rows margin
```

### Relative to Another View

Match another view's dimensions:

```swift
// Make field2 the same width as field1
field2.width = Dim.width(view: field1)

// Make panel half the height of another
panel.height = Dim.height(view: otherPanel) - Dim.sized(5)
```

### Combining Dimensions

```swift
// 80% width minus 4 columns for padding
view.width = Dim.percent(n: 80) - 4

// Same width as another view plus 10
view.width = Dim.width(view: other) + 10
```

## The fill() Convenience Method

For views that should occupy their entire container:

```swift
let win = Window("Full Screen")
win.fill()  // Equivalent to:
// win.x = Pos.at(0)
// win.y = Pos.at(0)
// win.width = Dim.fill()
// win.height = Dim.fill()

// With padding
win.fill(padding: 2)  // 2-character margin on all sides
```

## Box Model

Views support margin, border, and padding:

```swift
view.margin = EdgeInsets(top: 1, left: 2, bottom: 1, right: 2)
view.border = .single   // Or .double, .rounded, etc.
view.padding = EdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
```

The `contentFrame` property gives you the area available for content after accounting for these.

## Common Layout Patterns

### Form Layout

Align labels and fields in a form:

```swift
let nameLabel = Label("Name:")
nameLabel.x = Pos.at(2)
nameLabel.y = Pos.at(1)

let nameField = TextField("")
nameField.x = Pos.right(of: nameLabel) + 1
nameField.y = Pos.top(of: nameLabel)
nameField.width = Dim.fill(2)

let emailLabel = Label("Email:")
emailLabel.x = Pos.at(2)
emailLabel.y = Pos.bottom(of: nameLabel) + 1

let emailField = TextField("")
emailField.x = Pos.right(of: emailLabel) + 1
emailField.y = Pos.top(of: emailLabel)
emailField.width = Dim.fill(2)
```

### Centered Dialog Content

```swift
let message = Label("Are you sure?")
message.x = Pos.center()
message.y = Pos.at(2)

let okButton = Button("OK")
okButton.x = Pos.center() - 8
okButton.y = Pos.anchorEnd(margin: 2)

let cancelButton = Button("Cancel")
cancelButton.x = Pos.center() + 2
cancelButton.y = Pos.anchorEnd(margin: 2)
```

### Side-by-Side Panels

```swift
let leftPanel = Frame("Left")
leftPanel.x = Pos.at(0)
leftPanel.y = Pos.at(0)
leftPanel.width = Dim.percent(n: 50)
leftPanel.height = Dim.fill()

let rightPanel = Frame("Right")
rightPanel.x = Pos.right(of: leftPanel)
rightPanel.y = Pos.at(0)
rightPanel.width = Dim.fill()
rightPanel.height = Dim.fill()
```

### Bottom-Anchored Status Bar

```swift
let statusBar = StatusBar()
statusBar.x = Pos.at(0)
statusBar.y = Pos.anchorEnd(margin: 0)
statusBar.width = Dim.fill()
statusBar.height = Dim.sized(1)
```

## Layout Dependencies

TermKit automatically resolves layout dependencies using topological sorting. You can reference other views without worrying about order:

```swift
// These can be added in any order
let a = Label("A")
let b = Label("B")
let c = Label("C")

b.x = Pos.right(of: a) + 1   // B depends on A
c.x = Pos.right(of: b) + 1   // C depends on B

// TermKit will compute them in the correct order: A, then B, then C
```

> Warning: Circular dependencies will cause an error. Don't create cycles like A references B which references A.

## Triggering Layout

Layout is computed automatically, but you can request it explicitly:

```swift
view.setNeedsLayout()   // Schedule layout for next update
try view.layoutSubviews()   // Compute layout immediately
```

## Summary

| Pos Method | Description |
|------------|-------------|
| `Pos.at(n)` | Absolute position |
| `Pos.percent(n:)` | Percentage of container |
| `Pos.center()` | Centered |
| `Pos.anchorEnd(margin:)` | From right/bottom edge |
| `Pos.left/right/top/bottom(of:)` | Relative to another view |

| Dim Method | Description |
|------------|-------------|
| `Dim.sized(n)` | Absolute size |
| `Dim.percent(n:)` | Percentage of container |
| `Dim.fill(margin)` | Fill remaining space |
| `Dim.width/height(view:)` | Match another view |

## See Also

- ``Pos``
- ``Dim``
- ``View``
- ``EdgeInsets``
- ``BorderStyle``
