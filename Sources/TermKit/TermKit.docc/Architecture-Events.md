# Event System

Understand how TermKit handles keyboard and mouse input.

## Overview

TermKit processes input events through a responder chain, similar to Cocoa's event handling. Events flow from the application through the view hierarchy until handled.

## Event Types

### Keyboard Events

``KeyEvent`` represents a key press:

```swift
struct KeyEvent {
    let key: Key        // The key pressed
    let isAlt: Bool     // Alt/Option modifier
    let isControl: Bool // Control modifier
}
```

### Key Enumeration

```swift
enum Key {
    case letter(Character)    // Regular character
    case controlKey(Character) // Control+letter
    case f(Int)               // Function keys F1-F12
    case enter
    case tab
    case backTab              // Shift+Tab
    case escape
    case space
    case backspace
    case delete
    case cursorUp
    case cursorDown
    case cursorLeft
    case cursorRight
    case home
    case end
    case pageUp
    case pageDown
    case insertChar
    // ... and more
}
```

### Mouse Events

``MouseEvent`` represents mouse input:

```swift
struct MouseEvent {
    let pos: Point         // Position relative to receiving view
    let absPos: Point      // Absolute screen position
    let flags: MouseFlags  // Button state and modifiers
    let view: View?        // View that received the event
}
```

### Mouse Flags

```swift
struct MouseFlags: OptionSet {
    static let button1Pressed
    static let button1Released
    static let button1Clicked
    static let button1DoubleClicked
    static let button1TripleClicked
    static let button2Pressed
    static let button2Released
    static let button3Pressed
    static let button3Released
    static let mousePosition      // Mouse moved
    static let buttonShift        // Shift held
    static let buttonCtrl         // Control held
    static let buttonAlt          // Alt held
    static let reportMousePosition
    static let allEvents
}
```

## The Responder Chain

Events flow through the view hierarchy via the responder chain:

```
Keyboard Event
     ↓
Application.processKeyEvent()
     ↓
┌─── Hot Keys Phase ───┐
│  All toplevels       │
│  processHotKey()     │
└──────────────────────┘
     ↓ (if not handled)
┌─── Key Phase ────────┐
│  Focused view        │
│  processKey()        │
│  → Bubbles up        │
└──────────────────────┘
     ↓ (if not handled)
┌─── Cold Keys Phase ──┐
│  All toplevels       │
│  processColdKey()    │
└──────────────────────┘
```

## Handling Keyboard Events

### The Three Phases

**Hot Keys** - Processed first, for accelerators like Alt+F:

```swift
override func processHotKey(event: KeyEvent) -> Bool {
    if View.eventTriggersHotKey(event: event, hotKey: "S") {
        save()
        return true  // Consumed
    }
    return super.processHotKey(event: event)
}
```

**Key Events** - Normal key processing for focused views:

```swift
override func processKey(event: KeyEvent) -> Bool {
    switch event.key {
    case .letter("q") where event.isControl:
        quit()
        return true
    case .enter:
        activate()
        return true
    default:
        return super.processKey(event: event)
    }
}
```

**Cold Keys** - Fallback processing (e.g., default buttons):

```swift
override func processColdKey(event: KeyEvent) -> Bool {
    if isDefault && event.key == .enter {
        clicked?(self)
        return true
    }
    return super.processColdKey(event: event)
}
```

### Common Patterns

Handle specific keys:

```swift
override func processKey(event: KeyEvent) -> Bool {
    switch event.key {
    case .cursorUp:
        moveUp()
        return true
    case .cursorDown:
        moveDown()
        return true
    case .home:
        moveToStart()
        return true
    case .end:
        moveToEnd()
        return true
    default:
        break
    }
    return super.processKey(event: event)
}
```

Handle text input:

```swift
override func processKey(event: KeyEvent) -> Bool {
    switch event.key {
    case .letter(let ch):
        insertCharacter(ch)
        return true
    case .backspace:
        deleteBackward()
        return true
    default:
        return super.processKey(event: event)
    }
}
```

## Handling Mouse Events

Override `mouseEvent` to handle mouse input:

```swift
override func mouseEvent(event: MouseEvent) -> Bool {
    if event.flags.contains(.button1Clicked) {
        // Handle click at event.pos
        handleClick(at: event.pos)
        return true
    }
    if event.flags.contains(.button1DoubleClicked) {
        // Handle double-click
        handleDoubleClick(at: event.pos)
        return true
    }
    return super.mouseEvent(event: event)
}
```

### Mouse Enter/Leave

Track mouse hover:

```swift
override func mouseEnter(event: MouseEvent) -> Bool {
    isHovered = true
    setNeedsDisplay()
    return true
}

override func mouseLeave(event: MouseEvent) -> Bool {
    isHovered = false
    setNeedsDisplay()
    return true
}
```

### Continuous Button Pressed

For drag operations, enable continuous events:

```swift
init() {
    super.init()
    wantContinuousButtonPressed = true
}

override func mouseEvent(event: MouseEvent) -> Bool {
    if event.flags.contains(.button1Pressed) {
        // Called repeatedly while button is held
        handleDrag(at: event.pos)
        return true
    }
    return super.mouseEvent(event: event)
}
```

### Mouse Position Reports

Track mouse movement:

```swift
init() {
    super.init()
    wantMousePositionReports = true
}

override func mouseEvent(event: MouseEvent) -> Bool {
    if event.flags == .mousePosition {
        // Mouse moved to event.pos
        updateHighlight(at: event.pos)
        return true
    }
    return super.mouseEvent(event: event)
}
```

### Mouse Grab

Capture all mouse events:

```swift
func startDrag() {
    Application.grabMouse(from: self)
}

func endDrag() {
    Application.ungrabMouse()
}
```

While grabbed, all mouse events go to the grabbing view.

## Global Mouse Handlers

Register handlers that receive all mouse events:

```swift
let token = Application.addRootMouseHandler { event in
    // Called for every mouse event
    print("Mouse at: \(event.absPos)")
}

// Later, remove the handler
Application.removeRootMouseHandler(token)
```

## Focus and First Responder

### Becoming First Responder

```swift
override func becomeFirstResponder() -> Bool {
    // Called when view gains focus
    setNeedsDisplay()
    return true
}

override func resignFirstResponder() -> Bool {
    // Called when view loses focus
    setNeedsDisplay()
    return true
}
```

### Focus Navigation

Tab navigation is handled automatically. Customize with:

```swift
view.canFocus = true   // Enable focus for this view
view.tabStop = false   // Skip in tab order
```

Programmatic focus:

```swift
container.setFocus(view)
container.focusNext()
container.focusPrev()
```

## Hotkey Helper

Use the convenience method to check for hotkeys:

```swift
override func processHotKey(event: KeyEvent) -> Bool {
    if View.eventTriggersHotKey(event: event, hotKey: hotKey) {
        activate()
        return true
    }
    return super.processHotKey(event: event)
}
```

This checks for Alt+letter combinations, handling case insensitivity.

## Event Processing Best Practices

1. **Return true when handled** to stop propagation
2. **Call super** for unhandled events to continue the chain
3. **Use appropriate phase** (hot/key/cold) for your use case
4. **Update display** after state changes with `setNeedsDisplay()`
5. **Avoid blocking** in event handlers

## See Also

- ``KeyEvent``
- ``Key``
- ``MouseEvent``
- ``MouseFlags``
- ``Responder``
- ``View``
