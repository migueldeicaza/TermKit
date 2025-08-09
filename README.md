
[![Build, test, and docs](https://github.com/migueldeicaza/TermKit/actions/workflows/build.yml/badge.svg)](https://github.com/migueldeicaza/TermKit/actions/workflows/build.yml)

# TermKit - Terminal UI Toolkit for Swift

This is a simple UI Toolkit for Swift, a port of my [gui.cs library
for .NET](https://github.com/migueldeicaza/gui.cs).   While I originally
wrote gui.cs, it has evolved significantly by the contributions of
Charlie Kindel (@tig), @BDisp and various other contributors - this port 
is bringing their work.

This toolkit contains various controls for build text user interfaces
using Swift. It works on macOS and Linux.

## Controls

The following controls are currently implemented:

- **Button** - Clickable buttons with text
- **Checkbox** - Checkboxes for boolean input
- **DataTable** - Tabular data display
- **Frame** - Container with optional border and title
- **HexView** - Hexadecimal data viewer
- **Label** - Text display
- **ListView** - Lists with selection and scrolling
- **MarkupView** - Rich text with markup support
- **Menu/MenuBar** - Menus and menu bars
- **ProgressBar** - Progress indicators
- **RadioGroup** - Radio button groups
- **ScrollView** - Scrollable containers
- **Spinner** - Loading spinners
- **SplitView** - Resizable split containers
- **StatusBar** - Status information display
- **TabView** - Tabbed interfaces
- **Terminal/TerminalView** - Terminal emulation
- **TextField** - Single-line text input
- **TextView** - Multi-line text editing
- **Toplevel** - Top-level windows

## Dialogs

- **Dialog** - Base dialog class
- **FileDialog** - File selection dialog
- **InputBox** - Text input dialog
- **MessageBox** - Message display dialog

## Drivers

TermKit supports multiple console drivers:

- **CursesDriver** - NCurses-based driver for Unix systems
- **UnixDriver** - Raw Unix terminal driver
- **TTYDriver** - Basic TTY driver for testing

You can [checkout the documentation](https://migueldeicaza.github.io/TermKit/documentation/termkit/) which is automatically generated and published using DocC.

<img width="1222" alt="Screen Shot 2021-03-13 at 12 44 05 PM" src="https://user-images.githubusercontent.com/36863/111039012-d6df8400-83f9-11eb-9215-88549635a33f.png">

# Running this

From the command line:

```
$ swift build
$ swift run
```

From Xcode, if you want to debug, it is best to make sure that the
application that you want to Debug (in this project, the "Example"
target is what you want) has its Scheme for Running configured
like this:

     * Run/Info: Launch "Wait for Executable to be launched"

Then, when you run, switch to a console, and run the executable, I have my
global settings for DerivedData to be relative to the current directory,
so I can run it like this:

```
$ DerivedData/TermKit/Build/Products/Debug/Example
```

The location for where your executable is produced is configured in Xcode/Preferences/Locations,
I just happen to like project-relative output like the example above shows.

# Debugging

While debugging is useful, sometimes it can be obnoxious to single step or debug over
code that is called too many times in a row, so printf-like debugging is convenient.

Except that prints go to the same console where your application is running, making this
experience painful.

In that case, you can call `Application.log` with a message, and this message will use
MacOS `os_log`, which you can then either look for in the Console.app, or you can monitor from 
a terminal window like this:

```
$ log stream --style compact --predicate 'subsystem == "termkit"'
```

# Documentation

This project uses Swift DocC for documentation generation. The documentation is automatically built and published to GitHub Pages via GitHub Actions.

## Building Documentation Locally

To generate and preview documentation locally:

```bash
# Generate documentation
swift package generate-documentation --target TermKit

# Preview documentation with a local server
swift package --disable-sandbox preview-documentation --target TermKit
```

The documentation source files are located in the `Documentation.docc/` directory.


