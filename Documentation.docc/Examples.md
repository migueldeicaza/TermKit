# Examples Catalog

Explore the included demo applications.

## Overview

TermKit includes a comprehensive set of demo applications that showcase various features. This guide explains each demo and what you can learn from it.

## Running the Examples

### Run All Demos

```bash
swift build
swift run
```

This shows a menu where you can select any demo.

### Run a Specific Demo

```bash
swift run Example --demo=<name>
```

Available demo names:
- `misc` - Assorted controls
- `boxmodel` - Box model demonstration
- `dialogs` - File dialogs
- `terminal` - Terminal emulation
- `datatable` - DataTable control
- `splitview` - SplitView control
- `drawing` - Custom drawing
- `tabview` - TabView control
- `spinner` - Spinner animations
- `statusbar` - StatusBar control
- `windows` - Window management
- `markdown` - Markdown rendering
- `desktop` - StandardDesktop
- `layer` - Layer composition
- `cmdpalette` - Command Palette

## Demo Descriptions

### Assorted (`misc`)

**File:** `DemoAssorted.swift`

Demonstrates a mix of basic controls:
- Labels and text fields
- Buttons (regular and default)
- Checkboxes with event handling
- Layout using Pos and Dim
- MarkupView for colored text

**Key Concepts:**
- Basic control creation and layout
- Event handling with callbacks
- Relative positioning between controls

```bash
swift run Example --demo=misc
```

---

### Box Model (`boxmodel`)

**File:** `DemoBoxModel.swift`

Shows the CSS-like box model:
- Margin (external spacing)
- Border (different styles)
- Padding (internal spacing)
- Content area

**Key Concepts:**
- EdgeInsets for margin and padding
- BorderStyle options
- contentFrame vs bounds

```bash
swift run Example --demo=boxmodel
```

---

### File Dialogs (`dialogs`)

**File:** `DemoDialogs.swift`

Demonstrates dialog controls:
- FileDialog for file selection
- MessageBox for alerts
- InputBox for text prompts
- Custom dialogs

**Key Concepts:**
- Modal dialog presentation
- File system navigation
- User input collection

```bash
swift run Example --demo=dialogs
```

---

### Terminal (`terminal`)

**File:** `DemoTerminal.swift`

Shows embedded terminal emulation:
- PTY process management
- Full VT100/ANSI support
- Color and Unicode support
- Input/output handling

**Key Concepts:**
- Terminal view integration
- Process spawning
- Terminal I/O

```bash
swift run Example --demo=terminal
```

---

### DataTable (`datatable`)

**File:** `DemoDataTable.swift`

Demonstrates tabular data display:
- Column configuration
- Row selection
- Scrolling large datasets
- Cell rendering

**Key Concepts:**
- DataTable setup
- Column definitions
- Selection handling

```bash
swift run Example --demo=datatable
```

---

### SplitView (`splitview`)

**File:** `DemoSplitView.swift`

Shows resizable split panels:
- Horizontal splitting
- Vertical splitting
- Nested splits
- Divider interaction

**Key Concepts:**
- Panel arrangement
- Resize handling
- Nested containers

```bash
swift run Example --demo=splitview
```

---

### Drawing (`drawing`)

**File:** `DemoDrawing.swift`

Demonstrates custom drawing:
- Line drawing
- Box characters
- Color manipulation
- Custom view rendering

**Key Concepts:**
- Painter API usage
- Custom view implementation
- Unicode box characters

```bash
swift run Example --demo=drawing
```

---

### TabView (`tabview`)

**File:** `DemoTabBar.swift`

Shows tabbed interfaces:
- Tab creation and switching
- Different tab styles
- Dynamic tab management
- Tab content views

**Key Concepts:**
- Tab configuration
- Style options
- Content management

```bash
swift run Example --demo=tabview
```

---

### Spinner (`spinner`)

**File:** `SpinnerDemo.swift`

Demonstrates loading indicators:
- Various spinner styles
- Animation control
- Combined with labels

**Key Concepts:**
- Spinner styles
- Start/stop animation
- Async indication

```bash
swift run Example --demo=spinner
```

---

### StatusBar (`statusbar`)

**File:** `DemoStatusBar.swift`

Shows status bar features:
- Status items
- Hotkey panels
- Dynamic updates
- Click handling

**Key Concepts:**
- StatusBar configuration
- Panel types
- Action binding

```bash
swift run Example --demo=statusbar
```

---

### Windows (`windows`)

**File:** `DemoWindows.swift`

Demonstrates window management:
- Movable windows
- Resizable windows
- Window controls
- Z-ordering

**Key Concepts:**
- Window properties
- Move/resize interaction
- Window decorations

```bash
swift run Example --demo=windows
```

---

### Markdown (`markdown`)

**File:** `DemoMarkdown.swift`

Shows Markdown rendering:
- Headings
- Lists
- Code blocks
- Emphasis

**Key Concepts:**
- MarkdownView usage
- Supported syntax
- Text layout

```bash
swift run Example --demo=markdown
```

---

### Desktop (`desktop`)

**File:** `DemoStandardDesktop.swift`

Demonstrates the desktop environment:
- MenuBar integration
- StatusBar integration
- Window management
- Background surface

**Key Concepts:**
- StandardDesktop setup
- Menu creation
- Window lifecycle

```bash
swift run Example --demo=desktop
```

---

### Layer/Compose (`layer`)

**File:** `DemoLayer.swift`

Shows the rendering pipeline:
- Layer creation
- View composition
- Z-ordering
- Dirty region tracking

**Key Concepts:**
- Layer-based rendering
- Composition order
- Debugging rendering

```bash
swift run Example --demo=layer
```

---

### Command Palette (`cmdpalette`)

**File:** `DemoCommandPalette.swift`

Demonstrates VS Code-style command search:
- Fuzzy search
- Multiple providers
- Command discovery
- Custom actions

**Key Concepts:**
- CommandProvider protocol
- SimpleCommandProvider
- Palette configuration

```bash
swift run Example --demo=cmdpalette
```

## Learning Path

If you're new to TermKit, explore demos in this order:

1. **misc** - Basic controls and layout
2. **dialogs** - User interaction patterns
3. **tabview** - Container organization
4. **splitview** - Panel layouts
5. **desktop** - Full application structure
6. **cmdpalette** - Modern navigation
7. **drawing** - Custom rendering

## Source Code Location

All examples are in `Sources/Example/`:

```
Sources/Example/
├── main.swift              # Demo launcher
├── DemoHost.swift          # Base class for demos
├── DemoAssorted.swift
├── DemoBoxModel.swift
├── DemoCommandPalette.swift
├── DemoDataTable.swift
├── DemoDialogs.swift
├── DemoDrawing.swift
├── DemoLayer.swift
├── DemoMarkdown.swift
├── DemoSplitView.swift
├── DemoStandardDesktop.swift
├── DemoStatusBar.swift
├── DemoTabBar.swift
├── DemoTerminal.swift
├── DemoWindows.swift
└── SpinnerDemo.swift
```

## See Also

- <doc:GettingStarted-QuickStart>
- <doc:Tutorial-Desktop>
- <doc:Tutorial-BuildingAForm>
