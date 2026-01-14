# Dialogs

Modal dialog boxes for user interaction.

## Overview

TermKit provides pre-built dialog classes for common user interactions like confirmations, messages, text input, and file selection.

## Dialog

``Dialog`` is the base class for modal dialogs with buttons.

### Basic Usage

```swift
let dialog = Dialog(
    title: "Confirm",
    width: 40,
    height: 10,
    buttons: [
        Button("OK") { Application.requestStop() },
        Button("Cancel") { Application.requestStop() }
    ]
)

// Add content
let label = Label("Are you sure you want to continue?")
label.x = Pos.center()
label.y = Pos.at(2)
dialog.addSubview(label)

// Show the dialog
Application.present(top: dialog)
```

### Adding Buttons After Creation

```swift
let dialog = Dialog(title: "Settings", width: 50, height: 15, buttons: [])

let saveButton = Button("Save")
saveButton.clicked = { _ in
    saveSettings()
    Application.requestStop()
}
dialog.addButton(saveButton)

let cancelButton = Button("Cancel")
cancelButton.clicked = { _ in Application.requestStop() }
dialog.addButton(cancelButton)
```

### Dialog Closure Callback

```swift
dialog.closedCallback = {
    // Called when dialog is closed with ESC
    print("Dialog was cancelled")
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `buttons` | `[Button]` | Dialog buttons |
| `closedCallback` | `(() -> ())?` | ESC/cancel handler |

### Keyboard

- **Tab**: Move between buttons and controls
- **Enter**: Activate focused button
- **Escape** / **Ctrl+C**: Close dialog

---

## MessageBox

``MessageBox`` displays messages with pre-configured button options.

### Information Message

```swift
MessageBox.info(
    "Information",
    "The operation completed successfully."
)
```

### Error Message

```swift
MessageBox.error(
    "Error",
    "Failed to save the file. Please check permissions."
)
```

### Query with Buttons

```swift
let result = MessageBox.query(
    "Confirm Delete",
    "Are you sure you want to delete this file?",
    buttons: ["Delete", "Cancel"]
)

if result == 0 {  // First button (Delete)
    deleteFile()
}
```

### Methods

| Method | Description |
|--------|-------------|
| `info(title:message:)` | Show informational message |
| `error(title:message:)` | Show error message |
| `query(title:message:buttons:)` | Show dialog with custom buttons, returns index |

---

## InputBox

``InputBox`` prompts the user for text input.

### Basic Usage

```swift
let result = InputBox.show(
    title: "Enter Name",
    message: "Please enter your name:",
    text: ""  // Initial text
)

if let name = result {
    print("User entered: \(name)")
} else {
    print("User cancelled")
}
```

### With Default Value

```swift
let result = InputBox.show(
    title: "Rename File",
    message: "Enter new name:",
    text: existingFileName
)
```

### Methods

| Method | Description |
|--------|-------------|
| `show(title:message:text:)` | Show input dialog, returns String? |

---

## FileDialog

``FileDialog`` allows file and directory selection.

### Open File

```swift
let dialog = FileDialog(
    title: "Open File",
    prompt: "Open",
    startPath: FileManager.default.currentDirectoryPath,
    filter: "*.txt"
)

Application.present(top: dialog)

if let path = dialog.selectedPath {
    openFile(at: path)
}
```

### Save File

```swift
let dialog = FileDialog(
    title: "Save As",
    prompt: "Save",
    startPath: FileManager.default.currentDirectoryPath,
    filter: nil
)
dialog.allowsOtherFileTypes = true

Application.present(top: dialog)

if let path = dialog.selectedPath {
    saveFile(to: path)
}
```

### Directory Selection

```swift
let dialog = FileDialog(
    title: "Choose Folder",
    prompt: "Select",
    startPath: "~",
    filter: nil
)
dialog.allowsDirectorySelection = true

Application.present(top: dialog)
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `selectedPath` | `String?` | Selected file/directory |
| `filter` | `String?` | File filter (e.g., "*.txt") |
| `allowsDirectorySelection` | `Bool` | Allow selecting directories |
| `allowsOtherFileTypes` | `Bool` | Allow non-matching files |

### Keyboard

- **Arrow keys**: Navigate files
- **Enter**: Select or enter directory
- **Tab**: Switch between file list and path field
- **Escape**: Cancel

---

## Common Patterns

### Confirmation Dialog

```swift
func confirmDelete(file: String, onConfirm: @escaping () -> Void) {
    let result = MessageBox.query(
        "Delete File",
        "Delete '\(file)'?\n\nThis cannot be undone.",
        buttons: ["Delete", "Cancel"]
    )

    if result == 0 {
        onConfirm()
    }
}
```

### Save Before Close

```swift
func promptSaveChanges() -> Bool {
    let result = MessageBox.query(
        "Unsaved Changes",
        "Do you want to save your changes?",
        buttons: ["Save", "Don't Save", "Cancel"]
    )

    switch result {
    case 0:  // Save
        saveDocument()
        return true
    case 1:  // Don't Save
        return true
    default:  // Cancel
        return false
    }
}
```

### Custom Form Dialog

```swift
func showSettingsDialog() {
    let dialog = Dialog(title: "Settings", width: 50, height: 15, buttons: [])

    // Name field
    let nameLabel = Label("Name:")
    nameLabel.x = Pos.at(2)
    nameLabel.y = Pos.at(2)
    dialog.addSubview(nameLabel)

    let nameField = TextField(currentName)
    nameField.x = Pos.at(12)
    nameField.y = Pos.at(2)
    nameField.width = Dim.fill(2)
    dialog.addSubview(nameField)

    // Email field
    let emailLabel = Label("Email:")
    emailLabel.x = Pos.at(2)
    emailLabel.y = Pos.at(4)
    dialog.addSubview(emailLabel)

    let emailField = TextField(currentEmail)
    emailField.x = Pos.at(12)
    emailField.y = Pos.at(4)
    emailField.width = Dim.fill(2)
    dialog.addSubview(emailField)

    // Buttons
    let saveButton = Button("Save")
    saveButton.clicked = { _ in
        saveName(nameField.text)
        saveEmail(emailField.text)
        Application.requestStop()
    }
    dialog.addButton(saveButton)

    let cancelButton = Button("Cancel")
    cancelButton.clicked = { _ in Application.requestStop() }
    dialog.addButton(cancelButton)

    Application.present(top: dialog)
}
```

### Error with Details

```swift
func showError(_ error: Error) {
    let message = """
    An error occurred:

    \(error.localizedDescription)

    Error code: \((error as NSError).code)
    """

    MessageBox.error("Error", message)
}
```

### File Picker with Preview

```swift
func showOpenDialog() {
    let dialog = Dialog(title: "Open", width: 70, height: 20, buttons: [])

    let fileDialog = FileDialog(
        title: "",
        prompt: "Open",
        startPath: "~",
        filter: "*.txt"
    )
    fileDialog.fill()
    dialog.addSubview(fileDialog)

    // Add preview pane
    let preview = TextView()
    preview.x = Pos.percent(n: 60)
    preview.y = Pos.at(0)
    preview.width = Dim.fill()
    preview.height = Dim.fill(3)
    preview.readOnly = true
    dialog.addSubview(preview)

    // Update preview on selection
    fileDialog.selectionChanged = { fd in
        if let path = fd.selectedPath {
            preview.text = String(contentsOfFile: path).prefix(1000)
        }
    }

    Application.present(top: dialog)
}
```

## See Also

- ``Dialog``
- ``MessageBox``
- ``InputBox``
- ``FileDialog``
