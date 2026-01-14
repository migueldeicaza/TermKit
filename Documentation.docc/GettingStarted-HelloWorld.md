# Hello World Tutorial

Build your first interactive TermKit application step by step.

## Overview

This tutorial guides you through creating a simple but complete TermKit application with user interaction. You'll learn how to create windows, add controls, handle events, and respond to user input.

## What We're Building

We'll create an application with:
- A main window with a title
- A text field for entering your name
- A button that displays a greeting
- Proper keyboard navigation

## Step 1: Set Up the Application

Every TermKit application starts by initializing the framework and creating a top-level container:

```swift
import TermKit

// Initialize TermKit - must be called before anything else
Application.prepare()

// Create a window that fills the screen
let win = Window("Hello World")
win.fill()

// Add the window to the application's top-level view
Application.top.addSubview(win)
```

## Step 2: Add a Label

Labels display static text. Let's add instructions for the user:

```swift
let promptLabel = Label("Enter your name:")
promptLabel.x = Pos.at(2)
promptLabel.y = Pos.at(1)
promptLabel.width = Dim.sized(20)
win.addSubview(promptLabel)
```

## Step 3: Add a Text Field

Text fields allow single-line text input:

```swift
let nameField = TextField("")
nameField.x = Pos.at(2)
nameField.y = Pos.at(2)
nameField.width = Dim.sized(30)
win.addSubview(nameField)
```

## Step 4: Add a Button

Buttons trigger actions when clicked or activated:

```swift
let greetButton = Button("Say Hello")
greetButton.x = Pos.at(2)
greetButton.y = Pos.at(4)

// Handle the button click
greetButton.clicked = { _ in
    let name = nameField.text.isEmpty ? "World" : nameField.text
    let _ = MessageBox.query(
        "Greeting",
        "Hello, \(name)!",
        buttons: ["OK"]
    )
}

win.addSubview(greetButton)
```

## Step 5: Add a Quit Button

Let's add a way to exit the application:

```swift
let quitButton = Button("Quit")
quitButton.x = Pos.at(2)
quitButton.y = Pos.at(6)

quitButton.clicked = { _ in
    Application.requestStop()
}

win.addSubview(quitButton)
```

## Step 6: Start the Application

Finally, start the event loop:

```swift
Application.run()
```

## Complete Code

Here's the full application:

```swift
import TermKit

Application.prepare()

let win = Window("Hello World")
win.fill()

// Prompt label
let promptLabel = Label("Enter your name:")
promptLabel.x = Pos.at(2)
promptLabel.y = Pos.at(1)
promptLabel.width = Dim.sized(20)
win.addSubview(promptLabel)

// Name input field
let nameField = TextField("")
nameField.x = Pos.at(2)
nameField.y = Pos.at(2)
nameField.width = Dim.sized(30)
win.addSubview(nameField)

// Greet button
let greetButton = Button("Say Hello")
greetButton.x = Pos.at(2)
greetButton.y = Pos.at(4)
greetButton.clicked = { _ in
    let name = nameField.text.isEmpty ? "World" : nameField.text
    let _ = MessageBox.query("Greeting", "Hello, \(name)!", buttons: ["OK"])
}
win.addSubview(greetButton)

// Quit button
let quitButton = Button("Quit")
quitButton.x = Pos.at(2)
quitButton.y = Pos.at(6)
quitButton.clicked = { _ in
    Application.requestStop()
}
win.addSubview(quitButton)

Application.top.addSubview(win)
Application.run()
```

## Using the Application

- **Tab** / **Shift+Tab**: Move between controls
- **Enter**: Activate the focused button
- **Type**: Enter text when the text field is focused
- **Ctrl+C**: Emergency exit

## Key Concepts Learned

1. **Application.prepare()** - Initializes the console driver and framework
2. **Window** - A titled container with a border
3. **Label** - Displays static text
4. **TextField** - Single-line text input
5. **Button** - Clickable control with an action
6. **Pos and Dim** - Position and dimension objects for layout
7. **Application.run()** - Starts the main event loop
8. **Application.requestStop()** - Exits the current top-level view

## Next Steps

- <doc:GettingStarted-CoreConcepts> - Understand the view hierarchy and responder chain
- <doc:GettingStarted-LayoutFundamentals> - Learn responsive layouts with Pos and Dim

## See Also

- ``Button``
- ``TextField``
- ``Label``
- ``Window``
- ``MessageBox``
