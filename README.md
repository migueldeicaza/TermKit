[![Build Status](https://migueldeicaza.visualstudio.com/TermKit/_apis/build/status/TermKit-Xcode-CI?branchName=master)](https://migueldeicaza.visualstudio.com/TermKit/_build/latest?definitionId=10&branchName=master)

# TermKit - Terminal UI Toolkit for Swift

This is a simple UI Toolkit for Swift, a port of my [gui.cs library
for .NET](https://github.com/migueldeicaza/gui.cs).

This toolkit contains various controls for build text user interfaces
using Swift.

You can [checkout the documentation](https://migueldeicaza.github.io/TermKit/index.html)

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

You can change this from Xcode/Preferences/Locations.

