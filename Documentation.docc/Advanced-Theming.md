# Theming and Color Schemes

Customize the visual appearance of your application.

## Overview

TermKit uses color schemes to provide consistent styling across your application. This guide covers how to create custom themes and apply them to your views.

## Color Schemes

A ``ColorScheme`` defines the colors used for different view states:

```swift
let scheme = ColorScheme()
scheme.normal    // Default appearance
scheme.focus     // When the view has focus
scheme.hotNormal // Hotkey characters (not focused)
scheme.hotFocus  // Hotkey characters (focused)
scheme.disabled  // When the view is disabled
```

## Creating Custom Color Schemes

### Basic Custom Scheme

```swift
let myScheme = ColorScheme()

myScheme.normal = Application.makeAttribute(
    fore: .white,
    back: .blue
)

myScheme.focus = Application.makeAttribute(
    fore: .black,
    back: .cyan
)

myScheme.hotNormal = Application.makeAttribute(
    fore: .yellow,
    back: .blue
)

myScheme.hotFocus = Application.makeAttribute(
    fore: .yellow,
    back: .cyan
)

myScheme.disabled = Application.makeAttribute(
    fore: .brightBlack,
    back: .blue
)

// Apply to a view
myView.colorScheme = myScheme
```

### Dark Theme

```swift
let darkTheme = ColorScheme()

darkTheme.normal = Application.makeAttribute(
    fore: .white,
    back: .black
)

darkTheme.focus = Application.makeAttribute(
    fore: .brightWhite,
    back: .brightBlack,
    flags: [.bold]
)

darkTheme.hotNormal = Application.makeAttribute(
    fore: .brightYellow,
    back: .black
)

darkTheme.hotFocus = Application.makeAttribute(
    fore: .brightYellow,
    back: .brightBlack,
    flags: [.bold]
)

darkTheme.disabled = Application.makeAttribute(
    fore: .brightBlack,
    back: .black
)
```

### Light Theme

```swift
let lightTheme = ColorScheme()

lightTheme.normal = Application.makeAttribute(
    fore: .black,
    back: .white
)

lightTheme.focus = Application.makeAttribute(
    fore: .white,
    back: .blue
)

lightTheme.hotNormal = Application.makeAttribute(
    fore: .red,
    back: .white
)

lightTheme.hotFocus = Application.makeAttribute(
    fore: .brightRed,
    back: .blue
)

lightTheme.disabled = Application.makeAttribute(
    fore: .brightBlack,
    back: .white
)
```

## Built-in Color Schemes

TermKit provides several built-in schemes:

```swift
Colors.base      // Default blue theme
Colors.dialog    // Dialog boxes
Colors.menu      // Menu bar and menus
Colors.error     // Error dialogs
```

## Applying Themes

### To Individual Views

```swift
let button = Button("Click Me")
button.colorScheme = myScheme
```

### To Containers (Cascading)

Color schemes cascade to child views:

```swift
let window = Window("Themed Window")
window.colorScheme = darkTheme
// All children inherit darkTheme unless overridden
```

### Application-Wide

Set on the top-level view:

```swift
Application.top.colorScheme = darkTheme
```

## Attributes

``Attribute`` combines colors and text styles:

### Creating Attributes

```swift
let attr = Application.makeAttribute(
    fore: .brightWhite,
    back: .blue,
    flags: [.bold, .underline]
)
```

### Available Colors

```swift
// Standard colors
Color.black, .red, .green, .yellow,
     .blue, .magenta, .cyan, .white

// Bright variants
Color.brightBlack, .brightRed, .brightGreen, .brightYellow,
     .brightBlue, .brightMagenta, .brightCyan, .brightWhite
```

### Cell Flags

```swift
CellFlags.bold          // Bold text
CellFlags.dim           // Dimmed text
CellFlags.italic        // Italic (terminal support varies)
CellFlags.underline     // Underlined
CellFlags.blink         // Blinking (use sparingly)
CellFlags.inverse       // Swapped fore/back colors
CellFlags.invisible     // Hidden text
CellFlags.strikethrough // Strikethrough
```

## Custom Drawing with Themes

When implementing custom views, use the color scheme:

```swift
class ThemedView: View {
    override func drawContent(in region: Rect, painter: Painter) {
        // Use scheme colors
        painter.attribute = hasFocus
            ? colorScheme.focus
            : colorScheme.normal

        // Draw content
        painter.goto(col: 0, row: 0)
        painter.add(str: "Content")

        // Use hotkey color for special characters
        painter.attribute = hasFocus
            ? colorScheme.hotFocus
            : colorScheme.hotNormal
        painter.add(str: "H")  // Hotkey
    }
}
```

## Theme Switching

Implement runtime theme switching:

```swift
var currentTheme: ColorScheme = lightTheme

func switchTheme(to theme: ColorScheme) {
    currentTheme = theme
    Application.top.colorScheme = theme
    Application.refresh()
}

// In menu
MenuItem(title: "_Light Theme", action: { switchTheme(to: lightTheme) }),
MenuItem(title: "_Dark Theme", action: { switchTheme(to: darkTheme) })
```

## Best Practices

1. **Use colorScheme properties** instead of hardcoded colors
2. **Consider accessibility** - ensure sufficient contrast
3. **Test with different terminals** - color support varies
4. **Provide theme options** - let users choose
5. **Keep themes consistent** - use related colors

## Terminal Color Support

Different terminals have varying color support:

- **16 colors**: All terminals (the Color enum values)
- **256 colors**: Most modern terminals
- **True color**: Recent terminals (not yet supported by TermKit)

Stick to the 16 standard colors for maximum compatibility.

## See Also

- ``ColorScheme``
- ``Attribute``
- ``Color``
- ``CellFlags``
- <doc:Architecture-Rendering>
