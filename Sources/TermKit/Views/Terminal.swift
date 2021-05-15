//
//  Terminal.swift
//
//  Created by Miguel de Icaza on 3/27/21.
//
// TODO: add support for lowering from Unicode to plain output for old terminals on redraw
// TODO: implement the updateDisplay like from the NSView/UIView versions of SwiftTerm,
// so that the display is only updated every N ms, and not on every data read.
//
import Foundation
import SwiftTerm

public protocol TerminalViewDelegate: class {
    /**
     * The client code sending commands to the terminal has requested a new size for the terminal
     * Applications that support this should call the `TerminalView.getOptimalFrameSize`
     * to get the ideal frame size.
     *
     * This is needed for the rare cases where the remote client request 80 or 132 column displays,
     * it is a rare feature and you most likely can ignore this request.
     */
    func sizeChanged (source: TerminalView, newCols: Int, newRows: Int)
  
    /**
     * Request to change the title of the terminal.
     */
    func setTerminalTitle(source: TerminalView, title: String)
  
    /**
     * Invoked when the OSC command 7 for "current directory has changed" command is sent
     */
    func hostCurrentDirectoryUpdate (source: TerminalView, directory: String?)
    
    /**
     * Request that date be sent to the application running inside the terminal.
     * - Parameter data: Slice of data that should be sent
     */
    func send (source: TerminalView, data: ArraySlice<UInt8>)
  
    /**
     * Invoked when the terminal has been scrolled and the new position is provided
     * - Parameter position: the relative position that the code was scrolled to, a value between 0 and 1
     */
    func scrolled (source: TerminalView, position: Double)
    
    /**
     * Invoked in response to the user clicking on a link, which is most likely a url, but is not
     * mandatory, so custom implementations receive a string, and they can act on this as a way
     * of communciating with the host if desired.   The default implementation calls NSWorkspace.shared.open()
     * on the URL.
     * - Parameter source: the terminalview that called this method
     * - Parameter link: the string that was encoded as a link by the client application, typically a url,
     * but could be anything, and could be used to communicate by the embedded application and the host
     * - Parameter params: the specification allows for key/value pairs to be provided, this contains the
     * key and value pairs that were provided
     */
    func requestOpenLink (source: TerminalView, link: String, params: [String:String])
    
    /**
     * This method will be invoked when the host beeps.
     */
    func bell (source: TerminalView)
}

public protocol LocalProcessTerminalViewDelegate {
    /**
     * This method is invoked to notify that the terminal has been resized to the specified number of columns and rows
     * the user interface code might try to adjut the containing scroll view, or if it is a toplevel window, the window itself
     * - Parameter source: the sending instance
     * - Parameter newCols: the new number of columns that should be shown
     * - Parameter newRow: the new number of rows that should be shown
     */
    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int)

    /**
     * This method is invoked when the title of the terminal window should be updated to the provided title
     * - Parameter source: the sending instance
     * - Parameter title: the desired title
     */
    func setTerminalTitle(source: LocalProcessTerminalView, title: String)

    /**
     * This method will be invoked when the child process started by `startProcess` has terminated.
     * - Parameter source: the local process that terminated
     * - Parameter exitCode: the exit code returned by the process, or nil if this was an error caused during the IO reading/writing
     */
    func processTerminated (source: LocalProcessTerminalView, exitCode: Int32?)
}

///
/// The terminal captures almost all input, if you want to send a command to the toolkit, you can use
/// Control-Q which will quote the next keystroke, and will instead be prcessed by TermKit.
///
open class TerminalView: View, TerminalDelegate {
    public func send(source: Terminal, data: ArraySlice<UInt8>) {
        terminalDelegate?.send (source: self, data: data)
    }
    
    var terminal: Terminal!
    public var terminalDelegate: TerminalViewDelegate?
    
    public override init ()
    {
        super.init ()
        canFocus = true
        let terminalOptions = TerminalOptions(cols: 80, rows: 24)
        terminal = Terminal (delegate: self, options: terminalOptions)
    }
    
    open override var frame: Rect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            terminal.resize(cols: newValue.width, rows: newValue.height)
        }
    }
    
    /// Sends data to the terminal emulator for interpretation, this can be invoked from a background thread
    public func feed (text: String) {
        terminal.feed (text: text)
        
        // TODO: use a timer and regions, not this
        setNeedsDisplay()
    }
    
    /// Sends data to the terminal emulator for interpretation, this can be invoked from a background thread
    public func feed (byteArray: ArraySlice<UInt8>) {
        terminal.feed (buffer: byteArray)
        // TODO: use a timer and regions, not this
        setNeedsDisplay()
    }
    
    func map (color: SwiftTerm.Attribute.Color, isBg: Bool) -> TermKit.Color {
        switch color {
        
        case .ansi256(code: let code):
            switch code {
            case 0: return .black
            case 1: return .red
            case 2: return .green
            case 3: return .brown
            case 4: return .blue
            case 5: return .magenta
            case 6: return .cyan
            case 7: return .gray
            default:
                return isBg ? .black : .gray
            }
        case .trueColor: // (red: let _, green: let _, blue: let _):
            return isBg ? .black : .gray
        case .defaultColor:
            return isBg ? .black : .gray
        case .defaultInvertedColor:
            return isBg ? .gray : .black
        }
    }
    
    public func send (_ data: ArraySlice<UInt8>)
    {
        terminalDelegate?.send(source: self, data: data)
    }
    
    open override func redraw(region: Rect, painter: Painter) {
        let driver = Application.driver
    
        // Maps from a SwiftTerm attribute to the attribute we can use on the display
        func mapAttribute (attr: SwiftTerm.Attribute) -> TermKit.Attribute {
            let bg = map (color: attr.bg, isBg: true)
            let fg = map (color: attr.fg, isBg: false)
            var flags: CellFlags = []
            
            if attr.style.contains(.none) { flags = [] }
            if attr.style.contains (.bold) { flags = [flags, .bold]}
            if attr.style.contains (.underline) { flags = [flags, .underline]}
            if attr.style.contains (.blink) { flags = [flags, .blink]}
            if attr.style.contains (.inverse) { flags = [flags, .invert]}
            //if attr.style.contains (.invisible) { flags = [flags, ]}
            if attr.style.contains (.dim) { flags = [flags, .dim]}
            // if attr.style.contains (.italic) { flags = [flags, ]}
            if attr.style.contains (.crossedOut) { flags = [flags, .standout]}
            
            return driver.makeAttribute(fore: fg, back: bg, flags: flags)
        }
        // TODO: perhaps I need to use a different color?  Look at what the UIView/NSView are using
        painter.attribute = mapAttribute (attr: terminal.currentAttribute)

        let dim = frame.size
        let maxCol = dim.width
        let maxRow = dim.height
    
    
        var lastAttr: SwiftTerm.Attribute? = nil
        for row in 0..<maxRow {
            painter.goto(col: 0, row: row)
            
            if row >= terminal.rows {
                continue
            }
            guard let line = terminal.getLine(row: row) else {
                continue
            }
            for col in 0..<maxCol {
                let cell = line [col]
                if cell.attribute != lastAttr {
                    lastAttr = cell.attribute
                    painter.attribute = mapAttribute(attr: cell.attribute)
                }
                var ch = cell.getCharacter()
                if ch == "\u{0}" {
                    ch = " "
                }
                // TODO: map chars here for non UTF-8 Terminals
                painter.add(ch: ch)
            }
        }
    }
    
    var quoteChar = false
    open override func processKey(event: KeyEvent) -> Bool {
        if quoteChar == false, case .controlQ = event.key  {
            quoteChar = true
            return true
        }
        if quoteChar {
            quoteChar = false
            return false
        }
        if event.isAlt {
            send ([0x1b])
        }

        switch event.key {
        case .esc:
            send([0x1b])
        case .controlSpace:
            send([0])
        case .controlA:
            send([1])
        case .controlB:
            send([2])
        case .controlC:
            send([3])
        case .controlD:
            send([4])
        case .controlE:
            send([5])
        case .controlF:
            send([6])
        case .controlG:
            send([7])
        case .controlH:
            send([8])
        case .controlI:
            send([9])
        case .controlJ:
            send([10])
        case .controlK:
            send([11])
        case .controlL:
            send([12])
        case .controlM:
            send([13])
        case .controlN:
            send([14])
        case .controlO:
            send([15])
        case .controlP:
            send([16])
        case .controlQ:
            send([17])
        case .controlR:
            send([18])
        case .controlS:
            send([19])
        case .controlT:
            send([20])
        case .controlU:
            send([21])
        case .controlV:
            send([22])
        case .controlW:
            send([23])
        case .controlX:
            send([24])
        case .controlY:
            send([25])
        case .controlZ:
            send([26])
        case .fs:
            send([28])
        case .gs:
            send([29])
        case .rs:
            send([30])
        case .us:
            send([31])
        case .delete:
            send([127])
        case .cursorUp:
            send (terminal.applicationCursor ? [ 0x1b, 0x4f, 0x41 ] : [ 0x1b, 0x5b, 0x41 ])
        case .cursorDown:
            send(terminal.applicationCursor ? [ 0x1b, 0x4f, 0x42 ] : [ 0x1b, 0x5b, 0x42 ])
        case .cursorLeft:
            send(terminal.applicationCursor ? [ 0x1b, 0x4f, 0x44 ] : [ 0x1b, 0x5b, 0x44 ])
        case .cursorRight:
            send(terminal.applicationCursor ? [ 0x1b, 0x4f, 0x43 ] : [ 0x1b, 0x5b, 0x43 ])
        case .pageUp:
            send([ 0x1b, 0x5b, 0x35, 0x7e ])
        case .pageDown:
            send([ 0x1b, 0x5b, 0x36, 0x7e ])
        case .home:
            send(terminal.applicationCursor ? [ 0x1b, 0x4f, 0x48 ] : [ 0x1b, 0x5b, 0x48 ])
        case .end:
            send(terminal.applicationCursor ? [ 0x1b, 0x4f, 0x46 ] : [ 0x1b, 0x5b, 0x46 ])
        case .deleteChar:
            send([0x1b, 0x5b, 0x33, 0x7e])
        case .insertChar:
            // Mhm, how do I enter this on my mac?
            break
        case .f1:
            send([ 0x1b, 0x4f, 0x50 ])
        case .f2:
            send([ 0x1b, 0x4f, 0x51 ])
        case .f3:
            send([ 0x1b, 0x4f, 0x52 ])
        case .f4:
            send([ 0x1b, 0x4f, 0x53 ])
        case .f5:
            send([ 0x1b, 0x5b, 0x31, 0x35, 0x7e ])
        case .f6:
            send([ 0x1b, 0x5b, 0x31, 0x37, 0x7e ])
        case .f7:
            send([ 0x1b, 0x5b, 0x31, 0x38, 0x7e ])
        case .f8:
            send([ 0x1b, 0x5b, 0x31, 0x39, 0x7e ])
        case .f9:
            send([ 0x1b, 0x5b, 0x32, 0x30, 0x7e ])
        case .f10:
            send([ 0x1b, 0x5b, 0x32, 0x31, 0x7e ])
        case .backtab:
            send([ 0x1b, 0x5b, 0x5a ])
        case .letter(let x):
            send (([UInt8](x.utf8))[...])
        case .Unknown:
            return false
        }
        return true
    }
    
    open override func positionCursor() {
        let (x,y) = terminal.getCursorLocation()
        
        moveTo(col: x, row: y)
    }
}

public class LocalProcessTerminalView: TerminalView, LocalProcessDelegate, TerminalViewDelegate {
    public func bell(source: TerminalView) {
        //
    }
    
    public func scrolled(source: TerminalView, position: Double) {
        //
    }
    
    public func setTerminalTitle(source: TerminalView, title: String) {
        //
    }
    
    var process: LocalProcess!
    var processDelegate: LocalProcessTerminalViewDelegate?
    
    public init (delegate: LocalProcessTerminalViewDelegate? = nil)
    {
        super.init ()
        process = LocalProcess (delegate: self)
        self.processDelegate = delegate
        self.terminalDelegate = self
    }

    /**
     * Launches a child process inside a pseudo-terminal.
     * - Parameter executable: The executable to launch inside the pseudo terminal, defaults to /bin/bash
     * - Parameter args: an array of strings that is passed as the arguments to the underlying process
     * - Parameter environment: an array of environment variables to pass to the child process, if this is null, this picks a good set of defaults from `Terminal.getEnvironmentVariables`.
     */
    public func startProcess(executable: String = "/bin/bash", args: [String] = [], environment: [String]? = nil, execName: String? = nil)
    {
        process.startProcess(executable: executable, args: args, environment: environment, execName: execName)
    }
    
    /**
     * This method is invoked when input from the user needs to be sent to the client
     */
    public func send(source: TerminalView, data: ArraySlice<UInt8>)
    {
        process.send (data: data)
    }

    // Protocol methods
    public func processTerminated(_ source: LocalProcess, exitCode: Int32?) {
        processDelegate?.processTerminated(source: self, exitCode: exitCode)
    }
    
    public func dataReceived(slice: ArraySlice<UInt8>) {
        feed (byteArray: slice)
        //TODO use the proper system
        setNeedsDisplay()
        Application.postProcessEvent()
    }
    
    open override var frame: Rect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            var size = getWindowSize()
            
            let _ = PseudoTerminalHelpers.setWinSize(masterPtyDescriptor: process.childfd, windowSize: &size)
            
            processDelegate?.sizeChanged (source: self, newCols: newValue.width, newRows: newValue.height)
        }
    }

    public func getWindowSize() -> winsize {
        let size = bounds.size
        var w = winsize()
        w.ws_col = UInt16 (size.width)
        w.ws_row = UInt16 (size.height)
        w.ws_xpixel = UInt16 (size.width)
        w.ws_ypixel = UInt16 (size.height)
        return w
    }
    
    public func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        // TODO: pending an update
//        guard process.running else {
//            return
//        }
        var size = getWindowSize()
        let _ = PseudoTerminalHelpers.setWinSize(masterPtyDescriptor: process.childfd, windowSize: &size)
        
        processDelegate?.sizeChanged (source: self, newCols: newCols, newRows: newRows)
    }
    
    public func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        // TODO
    }
    
    public func requestOpenLink(source: TerminalView, link: String, params: [String : String]) {
        // TODO
    }
    

}
