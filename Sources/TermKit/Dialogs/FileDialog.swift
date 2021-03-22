//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 3/20/21.
//

import Foundation

class DirListView: View {
    
}

/// Base class for the `OpenDialog` and `SaveDialog`
public class FileDialog: Dialog {
//    var prompt, cancel: Button
//    var nameFieldLabel, message, dirLabel: Label
//    var dirEntry, nameEntry: TextField
//    var dirListView: DirListView
//    
//    /// Initializes the FileDialog
//    /// - Parameters:
//    ///   - title: Title for the dialog
//    ///   - prompt: Prompt to show to the user
//    ///   - nameFieldLabel: The name field label
//    ///   - message: Message to the display to the user
//    public init (title: String = "", prompt: String = "", nameFieldLabel: String = "", message: String = "")
//    {
//        self.message = Label (message)
//        self.message.x = Pos.at (1)
//        self.message.y = Pos.at (0)
//        
//        // TODO: use TextFormatter
//        var msgLines = 1
//        let dirLabel = Label ("Directory: ")
//        dirLabel.x = Pos.at (1)
//        dirLabel.y = Pos.at (1 + msgLines)
//        addSubview(self.message)
//        )
//    }
}

public class SaveDialog: FileDialog {
    
}

public class OpenDialog: FileDialog {
    
}
