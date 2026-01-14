# Creating a Custom Control

Build a reusable color picker control from scratch.

## Overview

This tutorial teaches you how to create a custom TermKit control by subclassing `View`. You'll implement rendering, keyboard handling, mouse support, and focus management.

## What We're Building

A color picker control that:
- Displays available colors in a grid
- Allows selection via keyboard and mouse
- Fires an event when color changes
- Works properly with focus

## Step 1: Define the Control Class

Start with the basic structure:

```swift
import TermKit

/// A control for selecting from available terminal colors
public class ColorPicker: View {
    /// The currently selected color
    public var selectedColor: Color = .white {
        didSet {
            if oldValue != selectedColor {
                colorChanged?(self)
                setNeedsDisplay()
            }
        }
    }

    /// Called when the selected color changes
    public var colorChanged: ((ColorPicker) -> Void)?

    /// Available colors to choose from
    private let colors: [Color] = [
        .black, .red, .green, .yellow,
        .blue, .magenta, .cyan, .white,
        .brightBlack, .brightRed, .brightGreen, .brightYellow,
        .brightBlue, .brightMagenta, .brightCyan, .brightWhite
    ]

    /// Number of columns in the color grid
    private let columns = 8

    public override init() {
        super.init()
        canFocus = true
        height = Dim.sized(2)  // 16 colors / 8 columns = 2 rows
        width = Dim.sized(columns * 3)  // Each color is 3 chars wide
    }
}
```

## Step 2: Implement Rendering

Override `drawContent` to render the color grid:

```swift
public override func drawContent(in region: Rect, painter: Painter) {
    for (index, color) in colors.enumerated() {
        let col = (index % columns) * 3
        let row = index / columns

        // Create attribute for this color cell
        let isSelected = color == selectedColor
        var attr: Attribute

        if isSelected {
            // Show selection with inverted colors
            attr = Application.makeAttribute(
                fore: .black,
                back: color,
                flags: hasFocus ? [.bold] : []
            )
        } else {
            attr = Application.makeAttribute(
                fore: color,
                back: colorScheme.normal.background,
                flags: []
            )
        }

        painter.goto(col: col, row: row)
        painter.attribute = attr

        if isSelected {
            painter.add(str: "[█]")
        } else {
            painter.add(str: " █ ")
        }
    }
}
```

## Step 3: Handle Keyboard Input

Override `processKey` for arrow key navigation:

```swift
public override func processKey(event: KeyEvent) -> Bool {
    guard let currentIndex = colors.firstIndex(of: selectedColor) else {
        return super.processKey(event: event)
    }

    var newIndex = currentIndex

    switch event.key {
    case .cursorLeft:
        if currentIndex > 0 {
            newIndex = currentIndex - 1
        }
    case .cursorRight:
        if currentIndex < colors.count - 1 {
            newIndex = currentIndex + 1
        }
    case .cursorUp:
        if currentIndex >= columns {
            newIndex = currentIndex - columns
        }
    case .cursorDown:
        if currentIndex + columns < colors.count {
            newIndex = currentIndex + columns
        }
    case .home:
        newIndex = 0
    case .end:
        newIndex = colors.count - 1
    default:
        return super.processKey(event: event)
    }

    if newIndex != currentIndex {
        selectedColor = colors[newIndex]
        return true
    }

    return super.processKey(event: event)
}
```

## Step 4: Handle Mouse Input

Override `mouseEvent` for click selection:

```swift
public override func mouseEvent(event: MouseEvent) -> Bool {
    if event.flags.contains(.button1Clicked) {
        // Calculate which color was clicked
        let col = event.pos.x / 3
        let row = event.pos.y
        let index = row * columns + col

        if index >= 0 && index < colors.count {
            selectedColor = colors[index]

            // Take focus on click
            if !hasFocus {
                superview?.setFocus(self)
            }

            return true
        }
    }

    return super.mouseEvent(event: event)
}
```

## Step 5: Handle Focus

Update display when focus changes:

```swift
public override func becomeFirstResponder() -> Bool {
    setNeedsDisplay()
    return super.becomeFirstResponder()
}

public override func resignFirstResponder() -> Bool {
    setNeedsDisplay()
    return super.resignFirstResponder()
}
```

## Step 6: Position the Cursor

Show cursor at selected color:

```swift
public override func positionCursor() {
    if let index = colors.firstIndex(of: selectedColor) {
        let col = (index % columns) * 3 + 1
        let row = index / columns
        moveTo(col: col, row: row)
    }
}
```

## Complete Control

```swift
import TermKit

/// A control for selecting from available terminal colors
public class ColorPicker: View {
    /// The currently selected color
    public var selectedColor: Color = .white {
        didSet {
            if oldValue != selectedColor {
                colorChanged?(self)
                setNeedsDisplay()
            }
        }
    }

    /// Called when the selected color changes
    public var colorChanged: ((ColorPicker) -> Void)?

    private let colors: [Color] = [
        .black, .red, .green, .yellow,
        .blue, .magenta, .cyan, .white,
        .brightBlack, .brightRed, .brightGreen, .brightYellow,
        .brightBlue, .brightMagenta, .brightCyan, .brightWhite
    ]

    private let columns = 8

    public override init() {
        super.init()
        canFocus = true
        height = Dim.sized(2)
        width = Dim.sized(columns * 3)
    }

    public override func drawContent(in region: Rect, painter: Painter) {
        for (index, color) in colors.enumerated() {
            let col = (index % columns) * 3
            let row = index / columns

            let isSelected = color == selectedColor
            var attr: Attribute

            if isSelected {
                attr = Application.makeAttribute(
                    fore: .black,
                    back: color,
                    flags: hasFocus ? [.bold] : []
                )
            } else {
                attr = Application.makeAttribute(
                    fore: color,
                    back: colorScheme.normal.background,
                    flags: []
                )
            }

            painter.goto(col: col, row: row)
            painter.attribute = attr
            painter.add(str: isSelected ? "[█]" : " █ ")
        }
    }

    public override func processKey(event: KeyEvent) -> Bool {
        guard let currentIndex = colors.firstIndex(of: selectedColor) else {
            return super.processKey(event: event)
        }

        var newIndex = currentIndex

        switch event.key {
        case .cursorLeft:
            if currentIndex > 0 { newIndex = currentIndex - 1 }
        case .cursorRight:
            if currentIndex < colors.count - 1 { newIndex = currentIndex + 1 }
        case .cursorUp:
            if currentIndex >= columns { newIndex = currentIndex - columns }
        case .cursorDown:
            if currentIndex + columns < colors.count { newIndex = currentIndex + columns }
        case .home:
            newIndex = 0
        case .end:
            newIndex = colors.count - 1
        default:
            return super.processKey(event: event)
        }

        if newIndex != currentIndex {
            selectedColor = colors[newIndex]
            return true
        }

        return super.processKey(event: event)
    }

    public override func mouseEvent(event: MouseEvent) -> Bool {
        if event.flags.contains(.button1Clicked) {
            let col = event.pos.x / 3
            let row = event.pos.y
            let index = row * columns + col

            if index >= 0 && index < colors.count {
                selectedColor = colors[index]
                if !hasFocus { superview?.setFocus(self) }
                return true
            }
        }
        return super.mouseEvent(event: event)
    }

    public override func becomeFirstResponder() -> Bool {
        setNeedsDisplay()
        return super.becomeFirstResponder()
    }

    public override func resignFirstResponder() -> Bool {
        setNeedsDisplay()
        return super.resignFirstResponder()
    }

    public override func positionCursor() {
        if let index = colors.firstIndex(of: selectedColor) {
            moveTo(col: (index % columns) * 3 + 1, row: index / columns)
        }
    }
}
```

## Using the Control

```swift
Application.prepare()

let win = Window("Color Picker Demo")
win.fill()

let label = Label("Selected color preview:")
label.x = Pos.at(2)
label.y = Pos.at(2)
win.addSubview(label)

let preview = Label("████████████████")
preview.x = Pos.at(2)
preview.y = Pos.at(4)
win.addSubview(preview)

let picker = ColorPicker()
picker.x = Pos.at(2)
picker.y = Pos.at(6)
picker.colorChanged = { p in
    preview.textAttribute = Application.makeAttribute(
        fore: p.selectedColor,
        back: .black
    )
    preview.setNeedsDisplay()
}
win.addSubview(picker)

Application.top.addSubview(win)
Application.run()
```

## What You Learned

1. **Subclassing View** for custom controls
2. **drawContent** for rendering
3. **processKey** for keyboard handling
4. **mouseEvent** for mouse input
5. **Focus management** with becomeFirstResponder/resignFirstResponder
6. **Cursor positioning** with positionCursor
7. **Property observers** for state changes

## Best Practices

- Always call `setNeedsDisplay()` when state changes
- Return `true` from event handlers when you consume the event
- Call `super` for unhandled events
- Set `canFocus = true` for focusable controls
- Update display when focus changes

## See Also

- ``View``
- ``Painter``
- <doc:Architecture-Rendering>
- <doc:Architecture-Events>
