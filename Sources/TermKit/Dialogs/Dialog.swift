//
//  Dialog.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/28/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * The dialog box is a window that by default is centered and contains one or more buttons,
 * it defaults to the `Colors.dialog` color scheme and has a 1 cell padding around the edges.
 *
 * To run the dialog modally, create the `Dialog`, and pass this to `Application.run` which
 * will execute the dialog until it terminates via the [ESC] key, or when one of the views
 *
 */
open class Dialog: Window {
    var buttons: [Button]
   
    /**
     * Initializes a new instance of the `Dialog` class with an optional set of buttons to display
     *
     * - Parameter title: Title for the dialog
     * - Parameter width: Width for the dialog.
     * - Parameter height: Height for the dialog
     * - Parameter buttons: buttons to lay out at the bottom of the dialog
     */
    public init (title: String, width: Int, height: Int, buttons: [Button])
    {
        self.buttons = buttons
        super.init(title, padding: 1)
        x = Pos.center ()
        y = Pos.center ()
        self.width = Dim.sized (width)
        self.height = Dim.sized (height)
        colorScheme = Colors.dialog
        
        for button in buttons {
            addSubview(button)
        }
        modal = true
        allowClose = true
        allowMaximize = false
        allowMinimize = false
        closeClicked =  { d in self.close () }
    }
    
    /**
     * Adds the specified button to the dialog
     * - Parameter button: the button to add to the dialog box
     */
    public func addButton (_ button: Button){
        buttons.append(button)
        addSubview(button)
        setNeedsLayout()
    }
    
    public override func layoutSubviews() throws {
        try super.layoutSubviews()
        var buttonSpace = 0
        var maxHeight = 0
        for button in buttons {
            buttonSpace += button.frame.width + 1
            maxHeight = max(maxHeight, button.frame.height)
        }
        let borderWidth = 2
        var start = (frame.width-borderWidth - buttonSpace)/2
        let y = frame.height - borderWidth - maxHeight - 1 - 1 /* padding */
        for button in buttons {
            let bf = button.frame
            button.frame = Rect (x: start, y: y, width: bf.width, height: bf.height)
            start += bf.width + 1
        }
    }
    
    /// Method to invoke if the dialog is closed with [ESC}, used by Dialog
    public var closedCallback: (() -> ())? = nil
    
    public override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .esc:
            close ()
            return true
        default:
            return super.processKey(event: event)
        }
    }
    
    func close ()
    {
        Application.requestStop()
    }
}
