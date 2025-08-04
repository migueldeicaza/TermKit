//
//  DemoSplitView.swift
//  Example
//
//  Demonstrates the SplitView with a principal-detail interface
//

import Foundation
import TermKit

@MainActor
func DemoSplitView() -> Toplevel {
    let top = Toplevel()
    top.fill()
    
    // Menu bar
    let menu = MenuBar(menus: [
        MenuBarItem(title: "_File", children: [
            MenuItem(title: "_Close", action: {
                Application.requestStop()
            })
        ]),
        MenuBarItem(title: "_View", children: [
            MenuItem(title: "_Toggle Orientation", action: {
                if let splitView = top.subviews.first(where: { $0 is SplitView }) as? SplitView {
                    splitView.orientation = splitView.orientation == .horizontal ? .vertical : .horizontal
                }
            })
        ])
    ])
    top.addSubview(menu)
    
    // Main window
    let win = Window("SplitView Demo - principal/Detail")
    win.x = Pos.at(0)
    win.y = Pos.at(1)
    win.width = Dim.fill()
    win.height = Dim.fill()
    
    // principal list (categories)
    let principalFrame = Frame("Categories")
    let categories = ["Animals", "Plants", "Vehicles"]
    let principalList = ListView(items: categories)
    principalFrame.addSubview(principalList)
    
    // Detail list (items)
    let detailFrame = Frame("Items")
    let detailList = ListView(items: [])
    detailFrame.addSubview(detailList)
    
    // Data for each category
    let categoryData: [String: [String]] = [
        "Animals": ["Dog", "Cat", "Horse", "Elephant", "Lion", "Tiger", "Bear", "Wolf", "Fox", "Rabbit"],
        "Plants": ["Oak Tree", "Rose", "Tulip", "Cactus", "Fern", "Bamboo", "Maple", "Pine", "Daisy", "Sunflower"],
        "Vehicles": ["Car", "Truck", "Bicycle", "Motorcycle", "Bus", "Train", "Airplane", "Boat", "Helicopter", "Scooter"]
    ]
    
    // Handle selection in principal list
    principalList.activate = { item in
        let category = categories[item]
        if let items = categoryData[category] {
            detailFrame.title = "Items - \(category)"
            detailList.items = items
            detailList.setNeedsDisplay()
        }
        return true
    }
    
    // Create the split view
    let splitView = SplitView(first: principalFrame, second: detailFrame, orientation: .horizontal)
    splitView.splitPosition = .percentage(0.4)
    splitView.minimumPaneSize = 20
    splitView.isDraggable = true
    splitView.fill()
    
    // Add status bar with instructions
    let statusBar = Label("Tab: Switch panes | Mouse: Drag separator | Ctrl+C: Exit")
    statusBar.x = Pos.at(0)
    statusBar.y = Pos.anchorEnd()
    statusBar.width = Dim.fill()
    statusBar.colorScheme = Colors.menu
    
    win.addSubview(splitView)
    win.addSubview(statusBar)
    
    // Select first category by default
    principalList.selectedItem = 0
    _ = principalList.activate?(0)
    
    top.addSubview(win)
    return top
}
