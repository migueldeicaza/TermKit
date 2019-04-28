//
//  Dialog.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/28/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * The dialog box is a window that by default is centered and contains one or more buttons
 */
public class Dialog : Window {
    var buttons : [Button]
   
    public init (title: String, width: Int, height: Int, buttons: [Button])
    {
        self.buttons = buttons
        super.init(title, padding: 1)
        x = Pos.center ()
        y = Pos.center ()
        width = Dim (width)
        //height = Dim (height)
        colorScheme = Colors.dialog
    }
}
