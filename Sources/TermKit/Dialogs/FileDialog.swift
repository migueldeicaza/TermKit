//
// FileDialog.swift - implements the file save and file open dialogs
//  
// TODO:
//   - canCreateDirectories
//   - Add a path navigator
//
// Created by Miguel de Icaza on 3/20/21.
//

import Foundation
import OpenCombine

struct FileData {
    var name: String
    var isDirectory: Bool
    var isMarked: Bool
    var date: Date
    var size: Int64
}

class DirListView: ListView, ListViewDataSource, ListViewDelegate {
    weak var parent: FileDialog?
    let fm = FileManager.default
    // Configuration options
    var canChooseFiles = true
    var canChooseDirectories = false
    var fileData: [FileData] = []
    var dformatter = DateFormatter ()
    var tformatter = DateFormatter ()
    var attrSel, attrSelMarked, attrMarked: Attribute!
    
    init (_ parent: FileDialog) {
        self.parent = parent
        _directory = "."
        
        super.init()
        dataSource = self
        delegate = self
        
        canFocus = true
        
        dformatter.dateStyle = .short
        dformatter.timeStyle = .none
        tformatter.timeStyle = .short
        tformatter.dateStyle = .none
        _ = reloadContents ()

        // TODO: pick b&w colors
        attrSel = driver.makeAttribute(fore: .gray, back: .blue)
        attrSelMarked = driver.makeAttribute(fore: .brightYellow, back: .blue)
    }
    
    var _directory: String = "."
    var directory: String {
        get {
            return _directory
        }
        set {
            if newValue == _directory { return }
            if reloadContents (newValue) {
                _directory = newValue
            }
        }
    }
    
    public override var frame: Rect {
        get {
            super.frame
        }
        set {
            super.frame = newValue
        }
    }
    
    func isDirectory (_ attr: [FileAttributeKey:Any]) -> Bool {
        if attr [.type] as? FileAttributeType == .typeDirectory {
            return true
        }
        return false
    }
    
    // Attempts to load the specified directory, returns true on success, false on failure
    func reloadContents (_ dirsrc: String? = nil) -> Bool {
        let dir = dirsrc ?? directory

        func isAllowed (_ path: String, _ attr:  [FileAttributeKey:Any]) -> Bool {
            if isDirectory(attr) { return true }
            
            if let filter = allowedFileTypes {
                for ext in filter {
                    if path.hasSuffix(ext) {
                        return true
                    }
                }
                return false
            }
            return true
        }
        
        guard let files = try? fm.contentsOfDirectory(atPath: dir) else {
            return false
        }
        fileData = []
        for file in files {
            let path = "\(dir)/\(file)"
            guard let attr = try? fm.attributesOfItem (atPath: path) else {
                continue
            }
            let isDir = isDirectory(attr)
            let modDate = (attr [.modificationDate] as? Date) ?? Date ()
            let size = (attr [.size] as? NSNumber)?.int64Value ?? 0
            
            if isAllowed(path, attr) {
                if !canChooseFiles ? isDir : true {
                    let data = FileData(name: file, isDirectory: isDir, isMarked: false, date: modDate, size: size)
                    fileData.append(data)
                }
            }
        }
        fileData.sort {
            if $0.isDirectory == $1.isDirectory {
                return $0.name < $1.name
            }
            return ($1.isDirectory ? 1 : 0) < ($0.isDirectory ? 1 : 0)
        }
        if dir != "/" {
            fileData.insert(FileData(name: "..", isDirectory: true, isMarked: false, date: Date()
                                     , size: 0), at: 0)
        }
        reload ()
        return true
    }
    
    // Protocol method implementation
    func getCount(listView: ListView) -> Int {
        fileData.count
    }
    
    func isMarked(listView: ListView, item: Int) -> Bool {
        guard item < fileData.count else {
            return false
        }
        return fileData [item].isMarked
    }
    
    func setMark(listView: ListView, item: Int, state: Bool) {
        guard item < fileData.count else {
            return
        }
        if fileData [item].name == ".." { return }
        
        fileData [item].isMarked = state
    }
    
    func leftPadding(_ str: String, toLength: Int, withPad character: Character) -> String {
        let stringLength = str.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + str
        } else {
            return String(str.suffix(toLength))
        }
    }

    public override func redrawColor (_ painter: Painter, selection: Bool) {
        if hasFocus {
            if selection {
                painter.attribute = colorScheme!.hotNormal
            } else {
                painter.attribute = colorScheme.focus
            }
        } else {
            painter.attribute = colorScheme.focus
        }
    }
    
    func render(listView: ListView, painter: Painter, selected: Bool, item: Int, col: Int, line: Int, width: Int) {
        painter.goto (col: col, row: line)
        painter.add(ch: selected ? ">" : " ")
        let f = frame
        if item < fileData.count {
            let d = fileData [item]
            if selected {
                if d.isMarked {
                    painter.attribute = attrSelMarked
                } else {
                    painter.attribute = attrSel
                }
            } else {
                let attrMarked = colorScheme!.focus.change(foreground: .brightYellow)
                if d.isMarked {
                    painter.attribute = attrMarked
                } else {
                    painter.attribute = colorScheme!.focus
                }
            }

            painter.add (ch: d.isDirectory ? "/" : " ")
            painter.add(str: d.name.padding (toLength: width, withPad: " ", startingAt: 0))
            painter.goto(col: f.width-32, row: line)
            painter.add(rune: driver.vLine)
            painter.add(str: leftPadding (ByteCountFormatter.string (fromByteCount: d.size, countStyle: .file), toLength: 11, withPad: " "))
            painter.add(rune: driver.vLine)
            painter.goto(col: f.width-19, row: line)
            painter.add(str: leftPadding (dformatter.string(from: d.date), toLength: 8, withPad: " "))
            painter.goto(col: f.width-10, row: line)
            painter.add(str: leftPadding (tformatter.string(from: d.date), toLength: 8, withPad: " "))
        } else {
            for _ in 0..<f.width {
                painter.add(ch: " ")
            }
        }
    }
    
    func selectionChanged(listView: ListView) {
        parent?.cbSelectedChanged(fileData [selected].name)
    }
    
    func activate(listView: ListView, item: Int) -> Bool {
        if fileData.count == 0 { return false }
        guard item < fileData.count else {
            return false
        }
        let d = fileData [item]
        let full = directory + "/" + d.name
        if d.isDirectory {
            if reloadContents(full) {
                _directory = full
                parent?.cbDirectoryChanged(full)
            }
        } else {
            parent?.cbFileChanged(full)
            if canChooseFiles {
                parent?.canceled = false
                parent?.complete ()
                Application.requestStop()
            }
        }
        return true
    }
    
    /// The array of filename extensions allowed (including the ".", or null if all file extensions are allowed
    var allowedFileTypes: [String]? = nil
    
    public var selectedPaths: [String] {
        get {
            var res: [String] = []
            if allowsMultipleSelection {
                for item in fileData {
                    if item.isMarked {
                        res.append (_directory + "/" + item.name)
                    }
                }
                if res.count == 0 && fileData.count > 0 && fileData [selected].name != ".." {
                    res.append(directory + "/" + fileData [selected].name)
                }
                return res
            } else {
                if fileData.count == 0 {
                    return []
                }
                if fileData [selected].isDirectory {
                    if canChooseDirectories && selected != 0 {
                        return [directory + "/" + fileData [selected].name]
                    }
                } else {
                    if canChooseFiles {
                        return [directory + "/" + fileData [selected].name]
                    }
                }
            }
            return []
        }
    }
}

/// Base class for the `OpenDialog` and `SaveDialog`, use one of those subclasses.
open class FileDialog: Dialog {
    var prompt, cancel: Button
    var nameFieldLabel, message, dirLabel: Label
    var dirEntry, nameEntry: TextField
    var dirListView: DirListView!
    
    /// If true, this means that the dialog was canceled, otherwise, you can pick the various
    /// properties to pick the selection.
    public var canceled: Bool = false
    
    /// Initializes the FileDialog
    /// - Parameters:
    ///   - title: Title for the dialog
    ///   - prompt: Prompt to show to the user
    ///   - nameFieldLabel: The name field label
    ///   - message: Message to the display to the user
    public init (title: String = "", prompt: String = "", nameFieldLabel: String = "", message: String = "")
    {
        self.message = Label (message)
        self.message.x = Pos.at (1)
        self.message.y = Pos.at (0)
        
        // TODO: use TextFormatter to compute the number of lines
        let msgLines = 1
        dirLabel = Label ("Directory: ")
        dirLabel.set (x: 1, y: 1+msgLines)
        
        dirEntry = TextField (".")
        dirEntry.x = Pos.right(of: dirLabel)
        dirEntry.y = Pos.at (1 + msgLines)
        dirEntry.width = Dim.fill() - 1
        
        self.nameFieldLabel = Label (nameFieldLabel)
        self.nameFieldLabel.set (x: 1, y: 3+msgLines)
        
        nameEntry = TextField ("")
        nameEntry.x = Pos.left(of: dirEntry)
        nameEntry.y = Pos.at (3 + msgLines)
        nameEntry.width = Dim.fill () - 1
        
        directoryPath = FileManager.default.currentDirectoryPath
        
        cancel = Button ("Cancel")
        self.prompt = Button (prompt)
        self.prompt.isDefault = true
        
        super.init(title: title, width: 80, height: 20, buttons: [])

        dirListView = DirListView (self)
        dirListView.set(x: 1, y: 3+msgLines+2)
        //dirListView.set(width: 60, height: 20)
        dirListView.width = Dim.fill () - 1
        dirListView.height = Dim.fill() - 4
        
        width = Dim.percent(n: 80)
        height = Dim.percent(n: 80)
        addSubviews([self.message, dirLabel, dirEntry, self.nameFieldLabel, nameEntry, dirListView])
        addButton(cancel)
        addButton(self.prompt)

        dirEntry.textChanged = { entry, old in
            self.directoryPath = entry.text
            self.nameEntry.text = ""
        }
        cancel.clicked = { button in
            self.canceled = true
            self.complete()
            Application.requestStop()
        }
        self.prompt.clicked = { button in
            self.canceled = false
            self.complete()
            Application.requestStop()
        }
    }

    func cbDirectoryChanged (_ dir: String) {
        nameEntry.text = ""
        dirEntry.text = dir
    }
    
    func cbFileChanged (_ file: String) {
        nameEntry.text = file == ".." ? "" : file
    }
    
    func cbSelectedChanged (_ file: String) {
        nameEntry.text = file == ".." ? "" : file
    }
    
    /// Gets or sets the directory path for this panel
    public var directoryPath: String {
        didSet {
            if dirListView.directory == directoryPath {
                return
            }
            dirListView.directory = directoryPath
            dirEntry.text = directoryPath
        }
    }
    
    // Overwritten by base classes
    func complete () {
    }
    
    /// The File path that is currently shown on the panel
    public var filePath: String {
        get {
            directoryPath + "/" + nameEntry.text
        }
        set {
            let asUrl = URL(fileURLWithPath: newValue)
            nameEntry.text = asUrl.lastPathComponent
        }
    }
}

/**
 * The `SaveDialog` provides an interactive dialog box for users to pick a file to save.
 *
 * To use, create an instance of `SaveDialog`, and call present with a callback
 * for completion.  Then you can examine the `fileName` property, that will
 * contain the selected file name or`nil` if the user canceled.
 */
open class SaveDialog: FileDialog {
    /// Creates a new instance of the SaveDialog
    /// - Parameters:
    ///   - title: Tilte to show for the dialog
    ///   - message: Additional message to display in the save dialog
    public init (title: String = "", message: String = "")
    {
        super.init(title: title, prompt: "Save", nameFieldLabel: "Save as:", message: message)
        dirListView.allowsMultipleSelection = false
    }

    /// Gets the name of the file the user selected for saving, or `nil` if the user canceled the `SaveDialog`
    public var fileName: String? {
        get {
            if canceled {
                return nil
            }
            return filePath
        }
    }
    
    override func complete () {
        if let c = callback {
            c (self)
        }
    }
    
    var callback: ((SaveDialog) -> ())? = nil
    
    /// Use this method to present the dialog, the callback will be invoked when the
    /// dialog is closed, probe the `canceled` variable, if it is set to true, it means that
    /// the user did cancel the dialog, otherwise the selection is on the `fileName` property
    /// (that variable is nil if the user canceled as well)
    public func present (_ callback: @escaping (SaveDialog) -> ()) {
        self.callback = callback
        Application.present(top: self)
    }
}

/**
 * The `OpenDialog` provides an interactive dialog box for users to select files or directories.
 *
 * The open dialog can be used to select files for opening, it can be configured to allow
 * multiple items to be selected (based on the `allowsMultipleSelection`) variable and
 * you can control whether this should allow files or directories to be selected.
 * To use, create an instance of `OpenDialog`, and call it to
 * `present`. When complete, the list of files will be available in the `filePaths property.
 *
 * To select more than one file, users can use the spacebar, or control-t.
 */
open class OpenDialog: FileDialog {
    /// Creates a new instance of the OpenDialog
    /// - Parameters:
    ///   - title: Tilte to show for the dialog
    ///   - message: Additional message to display in the open dialog
    public init (title: String = "", message: String = "")
    {
        super.init(title: title, prompt: "Open", nameFieldLabel: "Open:", message: message)
    }
    
    /// Controls whether the open dialog can allow multiple files to be selected
    public var allowsMultipleSelection: Bool {
        get {
            dirListView.allowsMultipleSelection
        }
        set {
            dirListView.allowsMultipleSelection = newValue
            dirListView.reload()
        }
    }
    
    /// Gets or sets a value indicating whether this `OpenDialog` can choose directories.
    public var canChooseDirectories: Bool {
        get {
            dirListView.canChooseDirectories
        }
        set {
            dirListView.canChooseDirectories = newValue
            dirListView.reload()
        }
    }

    /// Gets or sets a value indicating whether this `OpenDialog` can choose files.
    public var canChooseFiles: Bool {
        get {
            dirListView.canChooseFiles
        }
        set {
            dirListView.canChooseFiles = newValue
            dirListView.reload()
        }
    }

    /// The list of selected paths, nil if the user canceled the operation
    public var filePaths: [String]? {
        get {
            if canceled {
                return nil
            }
            return dirListView.selectedPaths
        }
    }
    
    override func complete () {
        if let c = callback {
            c (self)
        }
    }
    
    var callback: ((OpenDialog) -> ())? = nil
    
    /// Use this method to present the dialog, the callback will be invoked when the
    /// dialog is closed, probe the `canceled` variable, if it is set to true, it means that
    /// the user did cancel the dialog, otherwise the selection is on the `fileName` property
    /// (that variable is nil if the user canceled as well)
    public func present (_ callback: @escaping (OpenDialog) -> ()) {
        self.callback = callback
        Application.present(top: self)
    }
}
