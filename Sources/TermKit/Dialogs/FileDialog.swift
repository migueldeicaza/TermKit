//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 3/20/21.
//

import Foundation
import OpenCombine
class DirListView: View {
    weak var parent: FileDialog?
    
    public var directory: String {
        didSet {
            
        }
    }
    init (_ parent: FileDialog) {
        self.parent = parent
        self.directory = ""
        super.init ()
    }
}

/// Base class for the `OpenDialog` and `SaveDialog`
public class FileDialog: Dialog {
    var prompt, cancel: Button
    var nameFieldLabel, message, dirLabel: Label
    var dirEntry, nameEntry: TextField
    var dirListView: DirListView!
    var canceled: Bool = true
    
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
        
        dirEntry = TextField ("")
        dirEntry.x = Pos.right(of: dirLabel)
        dirEntry.y = Pos.at (1 + msgLines)
        dirEntry.width = Dim.fill() - 1
        
        self.nameFieldLabel = Label (nameFieldLabel)
        self.nameFieldLabel.set (x: 6, y: 3+msgLines)
        
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
            dirListView.directory = directoryPath
        }
    }
    
    var filePath: String = ""

}

/**
 * The `SaveDialog` provides an interactive dialog box for users to pick a file to save.
 *
 * To use, create an instance of `SaveDialog`, and pass it to
 * `Application.present`. This will run the dialog and when you are done,
 * `fileName` property will contain the selected file name or`nil` if the user canceled.
 */
public class SaveDialog: FileDialog {
    /// Creates a new instance of the SaveDialog
    /// - Parameters:
    ///   - title: Tilte to show for the dialog
    ///   - message: Additional message to display in the save dialog
    public init (title: String = "", message: String = "")
    {
        super.init(title: title, prompt: "Save", nameFieldLabel: "Save as:", message: message)
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
}

/**
 * The `OpenDialog` provides an interactive dialog box for users to select files or directories.
 *
 * The open dialog can be used to select files for opening, it can be configured to allow
 * multiple items to be selected (based on the `allowsMultipleSelection`) variable and
 * you can control whether this should allow files or directories to be selected.
 * To use, create an instance of `OpenDialog`, and pass it to
 * `Application.present`. When complete, the list of files will be available in the `filePaths property.
 *
 * To select more than one file, users can use the spacebar, or control-t.
 */
public class OpenDialog: FileDialog {
    /// Creates a new instance of the OpenDialog
    /// - Parameters:
    ///   - title: Tilte to show for the dialog
    ///   - message: Additional message to display in the open dialog
    public init (title: String = "", message: String = "")
    {
        super.init(title: title, prompt: "Open", nameFieldLabel: "Open:", message: message)
    }
}
