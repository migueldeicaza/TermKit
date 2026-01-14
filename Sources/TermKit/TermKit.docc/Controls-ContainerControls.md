# Container Controls

Controls for organizing and grouping other views.

## Overview

Container controls provide structure and organization for your UI. They handle scrolling, splitting, tabbing, and visual grouping.

## Window

``Window`` is a titled, bordered container that can be moved and resized.

### Basic Usage

```swift
let win = Window("Document Editor")
win.fill()
Application.top.addSubview(win)

// Add content
let content = Label("Window content")
win.addSubview(content)
```

### Movable and Resizable

```swift
let win = Window("Floating Window")
win.frame = Rect(x: 5, y: 5, width: 40, height: 15)
win.allowMove = true
win.allowResize = true
```

### Window Controls

```swift
win.allowClose = true     // Show close button
win.allowMaximize = true  // Show maximize button
win.allowMinimize = true  // Show minimize button

win.closeClicked = { window in
    // Handle close
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `title` | `String` | Window title |
| `allowMove` | `Bool` | Enable dragging |
| `allowResize` | `Bool` | Enable resize handles |
| `allowClose` | `Bool` | Show close button |
| `allowMaximize` | `Bool` | Show maximize button |
| `allowMinimize` | `Bool` | Show minimize button |

---

## Frame

``Frame`` provides a bordered container with optional title.

### Basic Usage

```swift
let frame = Frame("Settings")
frame.x = Pos.at(2)
frame.y = Pos.at(2)
frame.width = Dim.sized(40)
frame.height = Dim.sized(10)
container.addSubview(frame)

// Add content inside frame
let option = Checkbox("Enable feature")
frame.addSubview(option)
```

### Border Styles

```swift
frame.border = .single    // ┌─┐│└─┘
frame.border = .double    // ╔═╗║╚═╝
frame.border = .rounded   // ╭─╮│╰─╯
frame.border = .heavy     // ┏━┓┃┗━┛
frame.border = .none      // No border
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `title` | `String?` | Optional title |
| `border` | `BorderStyle` | Border style |
| `padding` | `EdgeInsets` | Internal padding |

---

## ScrollView

``ScrollView`` provides scrollable content area.

### Basic Usage

```swift
let scroll = ScrollView()
scroll.fill()
scroll.contentSize = Size(width: 200, height: 100)
container.addSubview(scroll)

// Add scrollable content
let largeContent = Label("Very long content...")
scroll.addSubview(largeContent)
```

### Scroll Position

```swift
// Scroll to position
scroll.contentOffset = Point(x: 0, y: 50)

// Scroll to make rect visible
scroll.scrollTo(rect: Rect(x: 0, y: 80, width: 10, height: 1))
```

### Scroll Bars

```swift
scroll.showHorizontalScrollIndicator = true
scroll.showVerticalScrollIndicator = true
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `contentSize` | `Size` | Total content size |
| `contentOffset` | `Point` | Current scroll position |
| `showHorizontalScrollIndicator` | `Bool` | Show horizontal bar |
| `showVerticalScrollIndicator` | `Bool` | Show vertical bar |

### Keyboard

- **Arrow keys**: Scroll content
- **Page Up/Down**: Scroll by page
- **Home/End**: Scroll to start/end

---

## SplitView

``SplitView`` divides space into resizable panels.

### Horizontal Split

```swift
let split = SplitView()
split.fill()
split.orientation = .horizontal  // Left | Right

let leftPanel = Frame("Left")
let rightPanel = Frame("Right")

split.addArrangedSubview(leftPanel)
split.addArrangedSubview(rightPanel)

container.addSubview(split)
```

### Vertical Split

```swift
split.orientation = .vertical  // Top / Bottom
```

### Panel Ratios

```swift
// Set initial ratio (0.0 to 1.0)
split.position = 0.3  // Left panel gets 30%
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `orientation` | `Orientation` | Horizontal or vertical |
| `position` | `Float` | Divider position (0.0-1.0) |

### Interaction

- **Drag divider**: Resize panels
- **Arrow keys**: Move divider when focused

---

## TabView

``TabView`` provides a tabbed interface.

### Basic Usage

```swift
let tabs = TabView()
tabs.fill()

// Add tabs
let tab1 = View()
tabs.addTab(Tab(title: "General", view: tab1))

let tab2 = View()
tabs.addTab(Tab(title: "Advanced", view: tab2))

container.addSubview(tabs)
```

### Tab Styles

```swift
tabs.style = .top       // Tabs on top
tabs.style = .bottom    // Tabs on bottom
tabs.style = .left      // Tabs on left
tabs.style = .right     // Tabs on right
```

### Tab Selection

```swift
// Select by index
tabs.selectedTab = 1

// Handle selection change
tabs.selectedTabChanged = { tabView in
    print("Selected: \(tabView.selectedTab)")
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `tabs` | `[Tab]` | Array of tabs |
| `selectedTab` | `Int` | Selected index |
| `style` | `TabViewStyle` | Tab position |

### Keyboard

- **Left/Right** or **Tab/Shift+Tab**: Switch tabs
- **Number keys**: Select tab by index

---

## StandardDesktop

``StandardDesktop`` provides a complete desktop environment.

### Basic Usage

```swift
Application.prepare()

let desktop = StandardDesktop()
desktop.fill()

// Create windows
let win1 = Window("Editor")
win1.frame = Rect(x: 5, y: 2, width: 50, height: 15)
desktop.manage(window: win1)

let win2 = Window("Browser")
win2.frame = Rect(x: 20, y: 5, width: 60, height: 20)
desktop.manage(window: win2)

Application.top.addSubview(desktop)
Application.run()
```

### Menu Bar

```swift
let menu = MenuBar(menus: [
    MenuBarItem(title: "_File", children: [
        MenuItem(title: "_New", action: { /* ... */ }),
        MenuItem(title: "_Open", action: { /* ... */ }),
        nil,  // Separator
        MenuItem(title: "_Quit", action: { Application.requestStop() })
    ])
])
desktop.addSubview(menu)
```

### Window Management

Desktop provides automatic window management:
- Bring to front on click
- Window menu with list of windows
- Maximize, minimize, tile operations

---

## Common Patterns

### Form Section

```swift
let section = Frame("Personal Information")
section.x = Pos.at(0)
section.y = Pos.at(0)
section.width = Dim.fill()
section.height = Dim.sized(8)

let nameLabel = Label("Name:")
let nameField = TextField("")
// ... position fields inside section
section.addSubview(nameLabel)
section.addSubview(nameField)
```

### Master-Detail

```swift
let split = SplitView()
split.orientation = .horizontal
split.position = 0.3

let masterList = ListView(items: items)
let detailView = Frame("Details")

split.addArrangedSubview(masterList)
split.addArrangedSubview(detailView)
```

### Tabbed Preferences

```swift
let tabs = TabView()

let generalTab = View()
// ... add general options
tabs.addTab(Tab(title: "General", view: generalTab))

let advancedTab = View()
// ... add advanced options
tabs.addTab(Tab(title: "Advanced", view: advancedTab))
```

## See Also

- ``Window``
- ``Frame``
- ``ScrollView``
- ``SplitView``
- ``TabView``
- ``StandardDesktop``
