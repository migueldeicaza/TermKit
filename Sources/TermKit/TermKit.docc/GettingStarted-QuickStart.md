# Quick Start

Get TermKit running in your project in minutes.

## Overview

TermKit is a Swift package for building terminal-based user interfaces. This guide walks you through adding TermKit to your project and running your first application.

## Adding TermKit to Your Project

### Swift Package Manager

Add TermKit as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/migueldeicaza/TermKit", branch: "main")
]
```

Then add it to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["TermKit"]
)
```

### Xcode

1. Open your project in Xcode
2. Go to File > Add Package Dependencies
3. Enter `https://github.com/migueldeicaza/TermKit`
4. Select the main branch and add to your target

## Your First Application

Create a minimal TermKit application:

```swift
import TermKit

// Initialize the application
Application.prepare()

// Create a window
let win = Window("My First App")
win.fill()

// Add a label
let label = Label("Welcome to TermKit!")
label.x = Pos.center()
label.y = Pos.center()
win.addSubview(label)

// Add the window to the application
Application.top.addSubview(win)

// Start the event loop
Application.run()
```

## Building and Running

From the command line:

```bash
swift build
swift run
```

Press `Ctrl+C` to exit the application.

## Running the Examples

TermKit includes a comprehensive demo application. Clone the repository and run:

```bash
git clone https://github.com/migueldeicaza/TermKit
cd TermKit
swift run
```

Run specific demos with the `--demo` flag:

```bash
swift run Example --demo=cmdpalette   # Command Palette demo
swift run Example --demo=desktop      # Desktop environment demo
swift run Example --demo=tabbar       # Tab view demo
swift run Example --demo=dialogs      # Dialog boxes demo
```

## Next Steps

- <doc:GettingStarted-HelloWorld> - Build a complete interactive application
- <doc:GettingStarted-CoreConcepts> - Understand the fundamental concepts
- <doc:GettingStarted-LayoutFundamentals> - Master the layout system

## Topics

### Essentials

- <doc:GettingStarted-HelloWorld>
- <doc:GettingStarted-CoreConcepts>
- <doc:GettingStarted-LayoutFundamentals>
