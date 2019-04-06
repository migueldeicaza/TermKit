//
//  main.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 3/6/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation
import Darwin.ncurses

print("Hello, World!")

var driver = CursesDriver ()
driver.Init ()
attron(COLOR_PAIR(0))
addstr ("hello")
refresh ()

getchar()
endwin()
