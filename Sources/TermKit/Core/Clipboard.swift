//
//  Clipboard.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/25/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * Clipboard is a simple interface to share data across views
 */
public class Clipboard {
    /// Contents of the clipboard
    public static var contents : String = ""
}
