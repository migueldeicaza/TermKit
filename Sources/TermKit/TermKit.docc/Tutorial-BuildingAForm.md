# Building a Form

Create a complete user registration form with validation.

## Overview

This tutorial walks you through building a form with multiple input fields, validation, and proper user feedback. You'll learn how to organize controls, handle user input, and create a polished user experience.

## What We're Building

A user registration form with:
- Name and email fields
- Password with confirmation
- Terms acceptance checkbox
- Real-time validation
- Submit and cancel buttons

## Step 1: Create the Application Structure

Start with the basic application setup:

```swift
import TermKit

Application.prepare()

let win = Window("User Registration")
win.fill()

Application.top.addSubview(win)
Application.run()
```

## Step 2: Create a Form Container

Use a Frame to visually group the form fields:

```swift
let formFrame = Frame("Registration Details")
formFrame.x = Pos.center()
formFrame.y = Pos.at(2)
formFrame.width = Dim.percent(n: 70)
formFrame.height = Dim.sized(14)
win.addSubview(formFrame)
```

## Step 3: Add Form Fields

Create labels and input fields with proper alignment:

```swift
// Row offset for each field
var row = 1
let labelWidth = 15

// Name field
let nameLabel = Label("Name:")
nameLabel.x = Pos.at(2)
nameLabel.y = Pos.at(row)
formFrame.addSubview(nameLabel)

let nameField = TextField("")
nameField.x = Pos.at(labelWidth)
nameField.y = Pos.at(row)
nameField.width = Dim.fill(2)
formFrame.addSubview(nameField)

row += 2

// Email field
let emailLabel = Label("Email:")
emailLabel.x = Pos.at(2)
emailLabel.y = Pos.at(row)
formFrame.addSubview(emailLabel)

let emailField = TextField("")
emailField.x = Pos.at(labelWidth)
emailField.y = Pos.at(row)
emailField.width = Dim.fill(2)
formFrame.addSubview(emailField)

row += 2

// Password field
let passwordLabel = Label("Password:")
passwordLabel.x = Pos.at(2)
passwordLabel.y = Pos.at(row)
formFrame.addSubview(passwordLabel)

let passwordField = TextField("")
passwordField.x = Pos.at(labelWidth)
passwordField.y = Pos.at(row)
passwordField.width = Dim.fill(2)
passwordField.secret = true  // Hide input
formFrame.addSubview(passwordField)

row += 2

// Confirm password field
let confirmLabel = Label("Confirm:")
confirmLabel.x = Pos.at(2)
confirmLabel.y = Pos.at(row)
formFrame.addSubview(confirmLabel)

let confirmField = TextField("")
confirmField.x = Pos.at(labelWidth)
confirmField.y = Pos.at(row)
confirmField.width = Dim.fill(2)
confirmField.secret = true
formFrame.addSubview(confirmField)
```

## Step 4: Add Terms Checkbox

```swift
row += 2

let termsCheckbox = Checkbox("I agree to the Terms of Service")
termsCheckbox.x = Pos.at(labelWidth)
termsCheckbox.y = Pos.at(row)
formFrame.addSubview(termsCheckbox)
```

## Step 5: Add Validation Feedback

Create a label to show validation messages:

```swift
let validationLabel = Label("")
validationLabel.x = Pos.at(2)
validationLabel.y = Pos.bottom(of: formFrame) + 1
validationLabel.width = Dim.fill(2)
validationLabel.textAlignment = .centered
win.addSubview(validationLabel)

// Validation state
var isFormValid = false

func validateForm() {
    var errors: [String] = []

    if nameField.text.isEmpty {
        errors.append("Name is required")
    }

    if emailField.text.isEmpty {
        errors.append("Email is required")
    } else if !emailField.text.contains("@") {
        errors.append("Invalid email format")
    }

    if passwordField.text.count < 8 {
        errors.append("Password must be 8+ characters")
    }

    if passwordField.text != confirmField.text {
        errors.append("Passwords don't match")
    }

    if !termsCheckbox.checked {
        errors.append("Must accept terms")
    }

    isFormValid = errors.isEmpty
    validationLabel.text = errors.first ?? "Ready to submit"
    submitButton.enabled = isFormValid
    validationLabel.setNeedsDisplay()
}
```

## Step 6: Wire Up Validation

Connect validation to field changes:

```swift
nameField.textChanged = { _, _ in validateForm() }
emailField.textChanged = { _, _ in validateForm() }
passwordField.textChanged = { _, _ in validateForm() }
confirmField.textChanged = { _, _ in validateForm() }
termsCheckbox.toggled = { _ in validateForm() }
```

## Step 7: Add Action Buttons

```swift
let buttonY = Pos.bottom(of: validationLabel) + 2

let submitButton = Button("Submit")
submitButton.x = Pos.center() - 12
submitButton.y = buttonY
submitButton.enabled = false
submitButton.isDefault = true
submitButton.clicked = { _ in
    if isFormValid {
        // Process registration
        let _ = MessageBox.info(
            "Success",
            "Account created for \(nameField.text)!"
        )
        Application.requestStop()
    }
}
win.addSubview(submitButton)

let cancelButton = Button("Cancel")
cancelButton.x = Pos.center() + 2
cancelButton.y = buttonY
cancelButton.clicked = { _ in
    let result = MessageBox.query(
        "Confirm",
        "Discard form data?",
        buttons: ["Yes", "No"]
    )
    if result == 0 {
        Application.requestStop()
    }
}
win.addSubview(cancelButton)
```

## Step 8: Initial Validation and Focus

```swift
// Run initial validation
validateForm()

// Set initial focus to name field
win.setFocus(nameField)
```

## Complete Code

```swift
import TermKit

Application.prepare()

let win = Window("User Registration")
win.fill()

// Form container
let formFrame = Frame("Registration Details")
formFrame.x = Pos.center()
formFrame.y = Pos.at(2)
formFrame.width = Dim.percent(n: 70)
formFrame.height = Dim.sized(14)
win.addSubview(formFrame)

var row = 1
let labelWidth = 15

// Name
let nameLabel = Label("Name:")
nameLabel.x = Pos.at(2)
nameLabel.y = Pos.at(row)
formFrame.addSubview(nameLabel)

let nameField = TextField("")
nameField.x = Pos.at(labelWidth)
nameField.y = Pos.at(row)
nameField.width = Dim.fill(2)
formFrame.addSubview(nameField)

row += 2

// Email
let emailLabel = Label("Email:")
emailLabel.x = Pos.at(2)
emailLabel.y = Pos.at(row)
formFrame.addSubview(emailLabel)

let emailField = TextField("")
emailField.x = Pos.at(labelWidth)
emailField.y = Pos.at(row)
emailField.width = Dim.fill(2)
formFrame.addSubview(emailField)

row += 2

// Password
let passwordLabel = Label("Password:")
passwordLabel.x = Pos.at(2)
passwordLabel.y = Pos.at(row)
formFrame.addSubview(passwordLabel)

let passwordField = TextField("")
passwordField.x = Pos.at(labelWidth)
passwordField.y = Pos.at(row)
passwordField.width = Dim.fill(2)
passwordField.secret = true
formFrame.addSubview(passwordField)

row += 2

// Confirm
let confirmLabel = Label("Confirm:")
confirmLabel.x = Pos.at(2)
confirmLabel.y = Pos.at(row)
formFrame.addSubview(confirmLabel)

let confirmField = TextField("")
confirmField.x = Pos.at(labelWidth)
confirmField.y = Pos.at(row)
confirmField.width = Dim.fill(2)
confirmField.secret = true
formFrame.addSubview(confirmField)

row += 2

// Terms
let termsCheckbox = Checkbox("I agree to the Terms of Service")
termsCheckbox.x = Pos.at(labelWidth)
termsCheckbox.y = Pos.at(row)
formFrame.addSubview(termsCheckbox)

// Validation
let validationLabel = Label("")
validationLabel.x = Pos.at(2)
validationLabel.y = Pos.bottom(of: formFrame) + 1
validationLabel.width = Dim.fill(2)
validationLabel.textAlignment = .centered
win.addSubview(validationLabel)

var isFormValid = false

// Submit button (declared early for reference in validation)
let submitButton = Button("Submit")

func validateForm() {
    var errors: [String] = []

    if nameField.text.isEmpty { errors.append("Name is required") }
    else if emailField.text.isEmpty { errors.append("Email is required") }
    else if !emailField.text.contains("@") { errors.append("Invalid email format") }
    else if passwordField.text.count < 8 { errors.append("Password must be 8+ characters") }
    else if passwordField.text != confirmField.text { errors.append("Passwords don't match") }
    else if !termsCheckbox.checked { errors.append("Must accept terms") }

    isFormValid = errors.isEmpty
    validationLabel.text = errors.first ?? "Ready to submit"
    submitButton.enabled = isFormValid
    validationLabel.setNeedsDisplay()
}

// Wire validation
nameField.textChanged = { _, _ in validateForm() }
emailField.textChanged = { _, _ in validateForm() }
passwordField.textChanged = { _, _ in validateForm() }
confirmField.textChanged = { _, _ in validateForm() }
termsCheckbox.toggled = { _ in validateForm() }

// Buttons
let buttonY = Pos.bottom(of: validationLabel) + 2

submitButton.x = Pos.center() - 12
submitButton.y = buttonY
submitButton.enabled = false
submitButton.isDefault = true
submitButton.clicked = { _ in
    if isFormValid {
        let _ = MessageBox.info("Success", "Account created for \(nameField.text)!")
        Application.requestStop()
    }
}
win.addSubview(submitButton)

let cancelButton = Button("Cancel")
cancelButton.x = Pos.center() + 2
cancelButton.y = buttonY
cancelButton.clicked = { _ in
    let result = MessageBox.query("Confirm", "Discard form data?", buttons: ["Yes", "No"])
    if result == 0 { Application.requestStop() }
}
win.addSubview(cancelButton)

validateForm()
win.setFocus(nameField)

Application.top.addSubview(win)
Application.run()
```

## What You Learned

1. **Organizing forms** with Frame containers
2. **Aligning labels and fields** using Pos
3. **Password input** with `secret = true`
4. **Real-time validation** with text change handlers
5. **Enabling/disabling buttons** based on state
6. **Confirmation dialogs** before destructive actions

## Next Steps

- <doc:Tutorial-FileBrowser> - Build a file browser
- <doc:Controls-InputControls> - Learn more about input controls

## See Also

- ``TextField``
- ``Checkbox``
- ``Button``
- ``Frame``
- ``MessageBox``
