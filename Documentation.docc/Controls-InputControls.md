# Input Controls

Controls for receiving user input.

## Overview

TermKit provides several controls for gathering user input, from single-line text entry to boolean toggles and option selection.

## Button

``Button`` is a clickable control that invokes an action.

### Basic Usage

```swift
let saveButton = Button("Save")
saveButton.clicked = { button in
    saveDocument()
}
container.addSubview(saveButton)
```

### Hotkeys

The first uppercase letter (or character after underscore) becomes the hotkey:

```swift
let button = Button("_Save")  // Alt+S activates
let button = Button("Save")   // Alt+S also works (first letter)
```

### Default Button

Mark a button as default to respond to Enter key:

```swift
let okButton = Button("OK")
okButton.isDefault = true  // Responds to Enter in dialogs
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | Button label |
| `isDefault` | `Bool` | Responds to Enter key |
| `clicked` | `((Button) -> ())?` | Click handler |

### Keyboard

- **Enter** / **Space**: Activate when focused
- **Alt+hotkey**: Activate from anywhere

---

## TextField

``TextField`` provides single-line text input with editing support.

### Basic Usage

```swift
let nameField = TextField("Initial text")
nameField.width = Dim.sized(30)
nameField.textChanged = { field, oldText in
    print("Changed to: \(field.text)")
}
container.addSubview(nameField)
```

### Password Entry

Hide input for sensitive data:

```swift
let passwordField = TextField("")
passwordField.secret = true  // Shows asterisks
```

### Read-Only Mode

```swift
let displayField = TextField("Read only")
displayField.readOnly = true
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | Current text content |
| `secret` | `Bool` | Mask input (for passwords) |
| `readOnly` | `Bool` | Prevent editing |
| `cursorPosition` | `Int` | Cursor position |
| `used` | `Bool` | Whether user has typed |
| `textChanged` | `((TextField, String) -> ())?` | Change handler |
| `onSubmit` | `((TextField) -> ())?` | Enter key handler |

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **Ctrl+A** / **Home** | Move to start |
| **Ctrl+E** / **End** | Move to end |
| **Ctrl+K** | Kill to end of line |
| **Ctrl+V** / **Ctrl+Y** | Paste |
| **Ctrl+C** / **Alt+W** | Copy selection |
| **Ctrl+X** / **Ctrl+W** | Cut selection |
| **Ctrl+Space** | Set mark |
| **Alt+B** | Word backward |
| **Alt+F** | Word forward |
| **Shift+Arrow** | Extend selection |

---

## Checkbox

``Checkbox`` provides a boolean on/off toggle.

### Basic Usage

```swift
let enableOption = Checkbox("Enable notifications", checked: true)
enableOption.toggled = { checkbox in
    print("Now: \(checkbox.checked)")
}
container.addSubview(enableOption)
```

### Hotkeys

Works like Button - first uppercase letter:

```swift
let checkbox = Checkbox("Show Warnings")  // Alt+W toggles
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | Label text |
| `checked` | `Bool` | Current state |
| `hotKey` | `Character?` | Override hotkey |
| `toggled` | `((Checkbox) -> ())?` | Toggle handler |

### Keyboard

- **Space**: Toggle when focused
- **Alt+hotkey**: Toggle from anywhere

---

## RadioGroup

``RadioGroup`` presents mutually exclusive options.

### Basic Usage

```swift
let options = RadioGroup(labels: ["Small", "Medium", "Large"])
options.selected = 1  // Select "Medium"
options.selectionChanged = { radio in
    print("Selected: \(radio.selected)")
}
container.addSubview(options)
```

### Horizontal Layout

```swift
let options = RadioGroup(labels: ["Yes", "No"], horizontal: true)
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `labels` | `[String]` | Option labels |
| `selected` | `Int` | Selected index |
| `horizontal` | `Bool` | Horizontal layout |
| `selectionChanged` | `((RadioGroup) -> ())?` | Change handler |

### Keyboard

- **Up/Down** or **Left/Right**: Change selection
- **Space**: Select focused option

---

## TextView

``TextView`` provides multi-line text editing.

### Basic Usage

```swift
let editor = TextView()
editor.text = "Initial content\nLine 2"
editor.fill()
container.addSubview(editor)
```

### Read-Only

```swift
let viewer = TextView()
viewer.readOnly = true
viewer.text = loadFileContents()
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | Content |
| `readOnly` | `Bool` | Prevent editing |
| `currentRow` | `Int` | Current cursor row |
| `currentColumn` | `Int` | Current cursor column |

### Keyboard

Standard text editing keys plus:
- **Ctrl+C** / **Ctrl+X** / **Ctrl+V**: Copy/Cut/Paste
- **Ctrl+A**: Select all
- **Ctrl+Z**: Undo (if supported)

---

## Common Patterns

### Form with Validation

```swift
let emailField = TextField("")
emailField.textChanged = { field, _ in
    let isValid = field.text.contains("@")
    submitButton.enabled = isValid
}
```

### Linked Controls

```swift
let enableCheckbox = Checkbox("Enable feature")
let optionField = TextField("")

enableCheckbox.toggled = { checkbox in
    optionField.enabled = checkbox.checked
}
```

### Submit on Enter

```swift
let searchField = TextField("")
searchField.onSubmit = { field in
    performSearch(field.text)
}
```

## See Also

- ``Button``
- ``TextField``
- ``Checkbox``
- ``RadioGroup``
- ``TextView``
