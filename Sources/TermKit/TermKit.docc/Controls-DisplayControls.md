# Display Controls

Controls for displaying information to users.

## Overview

TermKit provides controls for displaying text, progress, and specialized data formats.

## Label

``Label`` displays static or attributed text.

### Basic Usage

```swift
let title = Label("Welcome to My App")
title.x = Pos.center()
title.y = Pos.at(1)
container.addSubview(title)
```

### Multi-line Text

```swift
let message = Label("Line 1\nLine 2\nLine 3")
message.autoSize()  // Adjust size to content
```

### Text Alignment

```swift
let label = Label("Centered text", align: .centered)
label.width = Dim.fill()

// Options: .left, .right, .centered, .justified
```

### Attributed Text

Use colors and styles:

```swift
let attrText = AttributedString(text: "Hello")
// Add attributes for colors/styles
let label = Label(attrText)
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | Plain text content |
| `attributedText` | `AttributedString` | Styled content |
| `textAlignment` | `TextAlignment` | Alignment |
| `lineBreak` | `LineBreakMode` | How to handle long lines |

### Methods

- `autoSize()`: Resize to fit content

---

## ProgressBar

``ProgressBar`` shows operation progress.

### Basic Usage

```swift
let progress = ProgressBar()
progress.x = Pos.at(2)
progress.y = Pos.at(5)
progress.width = Dim.percent(n: 80)
progress.height = Dim.sized(1)
container.addSubview(progress)

// Update progress (0.0 to 1.0)
progress.fraction = 0.5  // 50%
```

### Indeterminate Mode

For operations with unknown duration:

```swift
progress.fraction = -1  // Shows animation
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `fraction` | `Float` | Progress 0.0-1.0, or -1 for indeterminate |

---

## Spinner

``Spinner`` shows an animated loading indicator.

### Basic Usage

```swift
let spinner = Spinner()
spinner.x = Pos.center()
spinner.y = Pos.center()
container.addSubview(spinner)

// Start animation
spinner.start()

// Stop when done
spinner.stop()
```

### Custom Styles

```swift
spinner.style = .dots      // ⣾⣽⣻⢿⡿⣟⣯⣷
spinner.style = .line      // -\|/
spinner.style = .circle    // ◐◓◑◒
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isSpinning` | `Bool` | Animation state |
| `style` | `SpinnerStyle` | Animation style |

---

## HexView

``HexView`` displays binary data in hexadecimal format.

### Basic Usage

```swift
let hexView = HexView()
hexView.fill()
hexView.source = Data(contentsOf: fileURL)
container.addSubview(hexView)
```

### Navigation

- **Arrow keys**: Move cursor
- **Page Up/Down**: Scroll pages
- **Home/End**: Go to start/end

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `source` | `Data?` | Binary data to display |
| `bytesPerLine` | `Int` | Bytes per row |

---

## MarkdownView

``MarkdownView`` renders Markdown-formatted text.

### Basic Usage

```swift
let markdown = MarkdownView()
markdown.fill()
markdown.content = """
# Heading

This is **bold** and *italic*.

- List item 1
- List item 2

```code
let x = 42
```
"""
container.addSubview(markdown)
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `content` | `String` | Markdown source |

### Supported Elements

- Headings (# ## ###)
- Bold, italic, strikethrough
- Lists (ordered and unordered)
- Code blocks and inline code
- Links (displayed, not clickable)
- Blockquotes

---

## StatusBar

``StatusBar`` displays status information at screen edge.

### Basic Usage

```swift
let statusBar = StatusBar(items: [
    StatusItem(title: "F1 Help", action: { showHelp() }),
    StatusItem(title: "F10 Quit", action: { Application.requestStop() })
])
statusBar.x = Pos.at(0)
statusBar.y = Pos.anchorEnd(margin: 0)
statusBar.width = Dim.fill()
container.addSubview(statusBar)
```

### Dynamic Updates

```swift
// Update item title
statusBar.items[0].title = "Modified"
statusBar.setNeedsDisplay()
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `items` | `[StatusItem]` | Status items |

---

## Common Patterns

### Loading State

```swift
let spinner = Spinner()
let label = Label("Loading...")

func startLoading() {
    spinner.start()
    label.text = "Loading..."
}

func finishLoading() {
    spinner.stop()
    label.text = "Complete"
}
```

### Progress with Label

```swift
let progress = ProgressBar()
let percentLabel = Label("0%")

func updateProgress(_ value: Float) {
    progress.fraction = value
    percentLabel.text = "\(Int(value * 100))%"
}
```

### Status Bar with Clock

```swift
let timeItem = StatusItem(title: "00:00")

Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    DispatchQueue.main.async {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeItem.title = formatter.string(from: Date())
        statusBar.setNeedsDisplay()
    }
}
```

## See Also

- ``Label``
- ``ProgressBar``
- ``Spinner``
- ``HexView``
- ``MarkdownView``
- ``StatusBar``
