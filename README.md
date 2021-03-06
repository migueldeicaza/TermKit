

# TermKit - Terminal UI Toolkit for Swift

This is a simple UI Toolkit for Swift, a port of my [gui.cs library
for .NET](https://github.com/migueldeicaza/gui.cs).   While I originally
wrote gui.cs, it has evolved significantly by the contributions of
Charlie Kindel (@tig), @BDisp and various other contributors - this port 
is bringing their work.

This toolkit contains various controls for build text user interfaces
using Swift.

You can [checkout the documentation](https://migueldeicaza.github.io/TermKit/index.html)

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


