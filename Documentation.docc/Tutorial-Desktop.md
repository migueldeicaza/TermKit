# Building a Desktop Application

Create a full-featured desktop environment with windows and menus.

## Overview

This tutorial shows you how to build a complete desktop-style application using `StandardDesktop`. You'll create an application with a menu bar, status bar, and multiple managed windows.

## What We're Building

A note-taking application with:
- Menu bar with File, Edit, Window, and Help menus
- Multiple floating note windows
- Status bar showing current status
- Window management (minimize, maximize, tile)

## Step 1: Set Up the Desktop

```swift
import TermKit

Application.prepare()

let desktop = StandardDesktop()
desktop.fill()
```

## Step 2: Create the Menu Bar

```swift
let menuBar = MenuBar(menus: [
    MenuBarItem(title: "_File", children: [
        MenuItem(title: "_New Note", shortcut: "^N", action: { createNewNote() }),
        nil,  // Separator
        MenuItem(title: "_Quit", shortcut: "^Q", action: { Application.requestStop() })
    ]),
    MenuBarItem(title: "_Edit", children: [
        MenuItem(title: "_Cut", shortcut: "^X", action: { cut() }),
        MenuItem(title: "_Copy", shortcut: "^C", action: { copy() }),
        MenuItem(title: "_Paste", shortcut: "^V", action: { paste() })
    ]),
    MenuBarItem(title: "_Window", children: [
        MenuItem(title: "_Tile Horizontally", action: { tileHorizontally() }),
        MenuItem(title: "Tile _Vertically", action: { tileVertically() }),
        nil,
        MenuItem(title: "_Close All", action: { closeAllNotes() })
    ]),
    MenuBarItem(title: "_Help", children: [
        MenuItem(title: "_About", action: { showAbout() })
    ])
])
desktop.addSubview(menuBar)
```

## Step 3: Create the Status Bar

```swift
var noteCount = 0

let statusBar = StatusBar(items: [
    StatusItem(title: "Notes: 0"),
    StatusItem(title: "F1 Help"),
    StatusItem(title: "^N New"),
    StatusItem(title: "^Q Quit")
])
statusBar.x = Pos.at(0)
statusBar.y = Pos.anchorEnd(margin: 0)
statusBar.width = Dim.fill()
desktop.addSubview(statusBar)

func updateStatusBar() {
    statusBar.items[0].title = "Notes: \(noteCount)"
    statusBar.setNeedsDisplay()
}
```

## Step 4: Note Window Class

Create a reusable note window:

```swift
class NoteWindow: Window {
    let textView: TextView
    var noteId: Int

    init(id: Int) {
        self.noteId = id
        self.textView = TextView()

        super.init("Note \(id)")

        // Configure window
        frame = Rect(x: 5 + (id * 3), y: 3 + (id * 2), width: 40, height: 15)
        allowMove = true
        allowResize = true
        allowClose = true
        allowMinimize = true
        allowMaximize = true

        // Configure text editor
        textView.fill()
        addSubview(textView)

        // Handle close
        closeClicked = { [weak self] _ in
            self?.confirmClose()
        }
    }

    var hasUnsavedChanges: Bool {
        return !textView.text.isEmpty
    }

    func confirmClose() {
        if hasUnsavedChanges {
            let result = MessageBox.query(
                "Unsaved Changes",
                "Discard changes to Note \(noteId)?",
                buttons: ["Discard", "Cancel"]
            )
            if result == 0 {
                close()
            }
        } else {
            close()
        }
    }

    func close() {
        if let parent = superview {
            parent.removeSubview(self)
            noteCount -= 1
            updateStatusBar()
        }
    }
}
```

## Step 5: Note Management Functions

```swift
var notes: [NoteWindow] = []
var nextNoteId = 1

func createNewNote() {
    let note = NoteWindow(id: nextNoteId)
    nextNoteId += 1

    desktop.manage(window: note)
    notes.append(note)

    noteCount += 1
    updateStatusBar()

    // Focus the new note
    desktop.setFocus(note)
}

func closeAllNotes() {
    let result = MessageBox.query(
        "Close All",
        "Close all \(noteCount) notes?",
        buttons: ["Close All", "Cancel"]
    )

    if result == 0 {
        for note in notes {
            desktop.removeSubview(note)
        }
        notes.removeAll()
        noteCount = 0
        updateStatusBar()
    }
}
```

## Step 6: Window Tiling

```swift
func tileHorizontally() {
    guard !notes.isEmpty else { return }

    let desktopBounds = desktop.contentFrame
    let windowHeight = desktopBounds.height / notes.count

    for (index, note) in notes.enumerated() {
        note.frame = Rect(
            x: 0,
            y: index * windowHeight,
            width: desktopBounds.width,
            height: windowHeight
        )
        note.setNeedsDisplay()
    }
}

func tileVertically() {
    guard !notes.isEmpty else { return }

    let desktopBounds = desktop.contentFrame
    let windowWidth = desktopBounds.width / notes.count

    for (index, note) in notes.enumerated() {
        note.frame = Rect(
            x: index * windowWidth,
            y: 0,
            width: windowWidth,
            height: desktopBounds.height
        )
        note.setNeedsDisplay()
    }
}
```

## Step 7: Edit Menu Actions

```swift
func cut() {
    if let focused = findFocusedTextView() {
        // Implement cut
        Clipboard.contents = focused.selectedText
        focused.deleteSelection()
    }
}

func copy() {
    if let focused = findFocusedTextView() {
        Clipboard.contents = focused.selectedText
    }
}

func paste() {
    if let focused = findFocusedTextView() {
        focused.insertText(Clipboard.contents)
    }
}

func findFocusedTextView() -> TextView? {
    for note in notes {
        if note.textView.hasFocus {
            return note.textView
        }
    }
    return nil
}
```

## Step 8: About Dialog

```swift
func showAbout() {
    let _ = MessageBox.info(
        "About Notes",
        """
        Notes Application v1.0

        A simple note-taking application
        built with TermKit.

        Press ^N to create a new note.
        """
    )
}
```

## Step 9: Run the Application

```swift
// Create an initial note
createNewNote()

Application.top.addSubview(desktop)
Application.run()
```

## Complete Code

```swift
import TermKit

Application.prepare()

let desktop = StandardDesktop()
desktop.fill()

var notes: [NoteWindow] = []
var nextNoteId = 1
var noteCount = 0

// Status bar
let statusBar = StatusBar(items: [
    StatusItem(title: "Notes: 0"),
    StatusItem(title: "F1 Help"),
    StatusItem(title: "^N New"),
    StatusItem(title: "^Q Quit")
])
statusBar.x = Pos.at(0)
statusBar.y = Pos.anchorEnd(margin: 0)
statusBar.width = Dim.fill()

func updateStatusBar() {
    statusBar.items[0].title = "Notes: \(noteCount)"
    statusBar.setNeedsDisplay()
}

// Forward declarations for menu actions
func createNewNote() { /* implemented below */ }
func closeAllNotes() { /* implemented below */ }
func tileHorizontally() { /* implemented below */ }
func tileVertically() { /* implemented below */ }
func showAbout() { /* implemented below */ }

// Menu bar
let menuBar = MenuBar(menus: [
    MenuBarItem(title: "_File", children: [
        MenuItem(title: "_New Note", shortcut: "^N", action: { createNewNote() }),
        nil,
        MenuItem(title: "_Quit", shortcut: "^Q", action: { Application.requestStop() })
    ]),
    MenuBarItem(title: "_Window", children: [
        MenuItem(title: "_Tile Horizontally", action: { tileHorizontally() }),
        MenuItem(title: "Tile _Vertically", action: { tileVertically() }),
        nil,
        MenuItem(title: "_Close All", action: { closeAllNotes() })
    ]),
    MenuBarItem(title: "_Help", children: [
        MenuItem(title: "_About", action: { showAbout() })
    ])
])

desktop.addSubview(menuBar)
desktop.addSubview(statusBar)

// Note window class
class NoteWindow: Window {
    let textView = TextView()
    let noteId: Int

    init(id: Int) {
        self.noteId = id
        super.init("Note \(id)")
        frame = Rect(x: 5 + (id * 3), y: 3 + (id * 2), width: 40, height: 15)
        allowMove = true
        allowResize = true
        textView.fill()
        addSubview(textView)
    }
}

// Implement functions
func createNewNote() {
    let note = NoteWindow(id: nextNoteId)
    nextNoteId += 1
    desktop.manage(window: note)
    notes.append(note)
    noteCount += 1
    updateStatusBar()
}

func closeAllNotes() {
    for note in notes { desktop.removeSubview(note) }
    notes.removeAll()
    noteCount = 0
    updateStatusBar()
}

func tileHorizontally() {
    let bounds = desktop.contentFrame
    let h = bounds.height / max(1, notes.count)
    for (i, note) in notes.enumerated() {
        note.frame = Rect(x: 0, y: i * h, width: bounds.width, height: h)
    }
}

func tileVertically() {
    let bounds = desktop.contentFrame
    let w = bounds.width / max(1, notes.count)
    for (i, note) in notes.enumerated() {
        note.frame = Rect(x: i * w, y: 0, width: w, height: bounds.height)
    }
}

func showAbout() {
    let _ = MessageBox.info("About", "Notes Application v1.0\nBuilt with TermKit")
}

// Create initial note
createNewNote()

Application.top.addSubview(desktop)
Application.run()
```

## What You Learned

1. **StandardDesktop** for desktop environments
2. **MenuBar** with nested menus and shortcuts
3. **StatusBar** for status display
4. **Window management** with move/resize/minimize
5. **Custom window subclasses** for reusable components
6. **Window tiling** and layout management

## Next Steps

- Add file save/load functionality
- Implement find and replace
- Add keyboard shortcuts for window switching

## See Also

- ``StandardDesktop``
- ``MenuBar``
- ``StatusBar``
- ``Window``
