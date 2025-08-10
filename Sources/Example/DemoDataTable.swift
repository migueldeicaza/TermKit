//
// DemoDataTable.swift
//  
// Shows how the DataTable view is used to display a grid
//
// Created by Miguel de Icaza on 5/5/21.
//

import Foundation
import TermKit

// This is a simple wrapper that shows how to implement the
// DataSource protocol, at the heart, the data to be rendered
// is an array of array of strings (`data`) that has a number
// of titles for it in `titles`
class StringWrapper: DataSource {
    var data: [[String]] = []
    var titles: [String] = []
    
    // Protocol conformance
    var cols: Int { 10 }
    var rows: Int { 100 }
    var columnTitles: [String] {
        get { titles }
    }
    
    subscript(col: Int, row: Int) -> String {
        get {
            return data [row][col]
        }
        set(newValue) {
            data [row][col] = newValue
        }
    }
    
    public init () {
        for r in 0..<rows {
            var row: [String] = []
            
            for c in 0..<cols {
                row.append("Cell \(c), \(r)")
            }
            data.append(row)
        }
        for c in 0..<cols {
            titles.append("Column \(c)")
        }
    }
}

class DataTableDialogs: DemoHost {
    init(){
        super.init(title: "Data Table")
    }
    
    override func setupDemo() {
        let mySource = StringWrapper ()
        
        let table = DataTable (source: mySource)
        table.fill (percentage: 60)
        table.x = Pos.at(12)
        table.y = Pos.at(2)
        table.alwaysShowHeaders = true
        table.cellActivated = { source, col, row in
            InputBox.request ("Update Value", message: "Please enter a new value for this cell", text: source [col, row]) { newValue in
                if let setValue = newValue {
                    mySource [col, row] = setValue
                    table.setNeedsDisplay()
                }
            }
        }
        let quit = Button ("Quit") { Application.requestStop() }
        quit.set (x: 1, y: 2)
        
        func check (_ text: String, _ y: Int, _ start: Bool, _ cback: @escaping (Checkbox) -> ()) -> Checkbox {
            let checkbox = Checkbox (text)
            checkbox.x = Pos.at (3)
            checkbox.y = Pos.bottom(of: table) + y
            checkbox.checked = start
            checkbox.toggled = cback
            return checkbox
        }
        
        let c1 = check ("Always show headers", 2, table.alwaysShowHeaders, { c in table.alwaysShowHeaders = c.checked })
        let c2 = check ("Line above headers", 3, table.showHorizontalHeaderOverline, { c in table.showHorizontalHeaderOverline = c.checked })
        let c3 = check ("Line under headers", 4, table.showHorizontalHeaderUnderline, { c in table.showHorizontalHeaderUnderline = c.checked })
        let c4 = check ("Show vertical lines", 5, table.showVerticalCellLines, { c in table.showVerticalCellLines = c.checked })
        let c5 = check ("Show vertical header lines", 5, table.showVerticalHeaderLines, { c in table.showVerticalHeaderLines = c.checked })
        let c6 = check ("Multiple selection", 6, table.multiSelect, { c in table.multiSelect = c.checked })
        let c7 = check ("Full row selection", 7, table.fullRowSelect, { c in table.fullRowSelect = c.checked })
        
        topWindow.addSubviews([table, c1, c2, c3, c4, c5, c6, c7, quit])
    }
}
