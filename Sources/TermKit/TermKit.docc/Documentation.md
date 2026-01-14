# ``TermKit``

A comprehensive Terminal User Interface toolkit for Swift.

## Overview

TermKit is a Swift package for building rich, interactive terminal-based user interfaces. Inspired by UIKit and gui.cs, it provides a familiar programming model with views, responder chains, and event handling.

**Key Features:**
- View-based architecture with nested subviews
- Flexible layout system with Pos and Dim
- Keyboard and mouse input support
- Layer-based rendering for efficient updates
- Cross-platform: macOS, Linux, and Windows
- 21+ built-in controls

```swift
import TermKit

Application.prepare()

let win = Window("Hello World")
win.fill()

let label = Label("Welcome to TermKit!")
label.x = Pos.center()
label.y = Pos.center()
win.addSubview(label)

Application.top.addSubview(win)
Application.run()
```

## Topics

### Getting Started

- <doc:GettingStarted-QuickStart>
- <doc:GettingStarted-HelloWorld>
- <doc:GettingStarted-CoreConcepts>
- <doc:GettingStarted-LayoutFundamentals>

### Architecture

- <doc:Architecture-Overview>
- <doc:Architecture-ViewHierarchy>
- <doc:Architecture-Rendering>
- <doc:Architecture-Events>
- <doc:Architecture-Drivers>

### Controls Reference

- <doc:Controls-InputControls>
- <doc:Controls-DisplayControls>
- <doc:Controls-ContainerControls>
- <doc:Controls-ListAndTableControls>
- <doc:Controls-NavigationControls>
- <doc:Controls-Dialogs>
- <doc:Controls-SpecializedControls>

### Tutorials

- <doc:Tutorial-BuildingAForm>
- <doc:Tutorial-CustomControl>
- <doc:Tutorial-Desktop>

### Advanced Topics

- <doc:Advanced-Theming>
- <doc:Advanced-CustomDrawing>
- <doc:Advanced-CrossPlatform>

### Examples

- <doc:Examples>

### Core Classes

- ``Application``
- ``View``
- ``Toplevel``
- ``Window``
- ``Responder``

### Layout

- ``Pos``
- ``Dim``
- ``Rect``
- ``Point``
- ``Size``

### Rendering

- ``Painter``
- ``Layer``
- ``Attribute``
- ``ColorScheme``

### Input Controls

- ``Button``
- ``TextField``
- ``TextView``
- ``Checkbox``
- ``RadioGroup``

### Display Controls

- ``Label``
- ``ProgressBar``
- ``Spinner``
- ``HexView``
- ``MarkdownView``

### Container Controls

- ``Frame``
- ``ScrollView``
- ``SplitView``
- ``TabView``
- ``StandardDesktop``

### List and Table Controls

- ``ListView``
- ``DataTable``

### Navigation Controls

- ``Menu``
- ``MenuBar``
- ``CommandPalette``
- ``StatusBar``

### Dialogs

- ``Dialog``
- ``MessageBox``
- ``InputBox``
- ``FileDialog``

### Specialized Controls

- ``Terminal``
- ``SolidBackground``

### Drivers

- ``ConsoleDriver``
- ``CursesDriver``
- ``UnixDriver``
- ``TTYDriver``
