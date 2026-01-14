# Custom Drawing

Master the Painter API for custom rendering.

## Overview

TermKit's ``Painter`` class provides methods for drawing text, lines, and shapes. This guide covers all drawing capabilities for creating custom views.

## The Painter Class

When implementing `drawContent` or `redraw`, you receive a Painter:

```swift
override func drawContent(in region: Rect, painter: Painter) {
    // Draw using painter
}
```

## Basic Drawing

### Positioning and Text

```swift
// Move to position
painter.goto(col: 5, row: 2)

// Add text
painter.add(str: "Hello, World!")

// Add single character
painter.add(ch: Character("★"))

// Add rune (character with specific width)
painter.add(rune: "界")  // CJK character
```

### Setting Colors

```swift
// Set attribute before drawing
painter.attribute = Application.makeAttribute(
    fore: .yellow,
    back: .blue,
    flags: [.bold]
)

painter.goto(col: 0, row: 0)
painter.add(str: "Colored text")
```

## Drawing Primitives

### Horizontal Lines

```swift
// Draw a horizontal line
painter.drawHorizontalLine(
    row: 5,
    col: 0,
    width: 20,
    rune: "─"
)

// Using default line character
painter.drawHorizontalLine(row: 5, col: 0, width: 20)
```

### Vertical Lines

```swift
painter.drawVerticalLine(
    row: 0,
    col: 10,
    height: 5,
    rune: "│"
)
```

### Borders

```swift
// Draw a border around a rectangle
painter.drawBorder(
    Rect(x: 0, y: 0, width: 20, height: 10),
    style: .single
)

// Available styles
BorderStyle.single   // ┌─┐│└─┘
BorderStyle.double   // ╔═╗║╚═╝
BorderStyle.rounded  // ╭─╮│╰─╯
BorderStyle.heavy    // ┏━┓┃┗━┛
```

## Clearing Areas

```swift
// Clear a rectangle (fills with spaces)
painter.clear(Rect(x: 0, y: 0, width: 10, height: 5))

// Clear using current attribute
painter.clearRegion(Rect(x: 5, y: 5, width: 20, height: 3))
```

## Hotstrings

Draw text with highlighted hotkey:

```swift
// Underscore marks the hotkey
painter.drawHotString(
    text: "_Save Document",
    focused: hasFocus,
    scheme: colorScheme
)
// Renders: Save Document (with S highlighted)
```

## Clipping

Create a clipped painter for a subregion:

```swift
// Clip to a rectangle
let clipped = painter.clipped(to: Rect(x: 5, y: 5, width: 30, height: 10))

// Drawing is now relative to and clipped by the rectangle
clipped.goto(col: 0, row: 0)  // Actually (5, 5) on screen
clipped.add(str: "Clipped content")
```

## Layer Composition

Draw one layer onto another:

```swift
painter.draw(layer: sourceLayer, at: Point(x: 10, y: 5))
```

## Attributed Strings

Draw styled text:

```swift
let attrStr = AttributedString(text: "Styled text")
// Add formatting to attrStr...

painter.goto(col: 0, row: 0)
attrStr.draw(on: painter)
```

## Custom View Example

A complete custom gauge view:

```swift
class Gauge: View {
    var value: Float = 0.5 {
        didSet {
            value = max(0, min(1, value))
            setNeedsDisplay()
        }
    }

    var label: String = "Progress"

    override init() {
        super.init()
        height = Dim.sized(3)
    }

    override func drawContent(in region: Rect, painter: Painter) {
        let width = contentFrame.width

        // Draw label
        painter.attribute = colorScheme.normal
        painter.goto(col: 0, row: 0)
        painter.add(str: label)

        // Draw gauge background
        painter.goto(col: 0, row: 1)
        painter.attribute = Application.makeAttribute(
            fore: .white,
            back: .brightBlack
        )
        painter.add(str: String(repeating: " ", count: width))

        // Draw filled portion
        let filled = Int(Float(width) * value)
        painter.goto(col: 0, row: 1)
        painter.attribute = Application.makeAttribute(
            fore: .white,
            back: .green
        )
        painter.add(str: String(repeating: " ", count: filled))

        // Draw percentage
        let percent = "\(Int(value * 100))%"
        let percentX = (width - percent.count) / 2
        painter.goto(col: percentX, row: 1)
        painter.attribute = Application.makeAttribute(
            fore: .brightWhite,
            back: filled > percentX ? .green : .brightBlack,
            flags: [.bold]
        )
        painter.add(str: percent)

        // Draw border
        painter.attribute = colorScheme.normal
        painter.goto(col: 0, row: 2)
        painter.drawHorizontalLine(row: 2, col: 0, width: width, rune: "─")
    }
}
```

## Box Characters

Unicode box drawing characters for custom borders:

```swift
// Single line
"─" "│" "┌" "┐" "└" "┘" "├" "┤" "┬" "┴" "┼"

// Double line
"═" "║" "╔" "╗" "╚" "╝" "╠" "╣" "╦" "╩" "╬"

// Rounded corners
"╭" "╮" "╰" "╯"

// Heavy line
"━" "┃" "┏" "┓" "┗" "┛" "┣" "┫" "┳" "┻" "╋"

// Mixed (double horizontal, single vertical)
"╒" "╕" "╘" "╛" "╞" "╡" "╤" "╧" "╪"
```

## Block Characters

For graphical elements:

```swift
// Full blocks
"█" "▓" "▒" "░"

// Partial blocks
"▀" "▄" "▌" "▐"

// Quadrants
"▖" "▗" "▘" "▝" "▚" "▞"
```

## Best Practices

1. **Always set attribute before drawing**
2. **Use clipping for subregions** to avoid drawing outside bounds
3. **Cache computed values** outside the draw loop
4. **Only redraw what changed** using the region parameter
5. **Use colorScheme** for consistent theming

## See Also

- ``Painter``
- ``Attribute``
- ``BorderStyle``
- ``AttributedString``
- <doc:Architecture-Rendering>
