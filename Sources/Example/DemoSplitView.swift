//
//  DemoSplitView.swift
//  Example
//
//  Demonstrates the SplitView with a principal-detail interface
//

import Foundation
import TermKit

class DemoSplitView: DemoHost {
    init() {
        super.init(title: "Split View Demo")
    }
    
    var splitViewToggle: SplitView? = nil
    
    func toggle() {
        if let splitViewToggle {
            splitViewToggle.orientation = splitViewToggle.orientation == .horizontal ? .vertical : .horizontal
        }
    }
    
    override func setupDemo() {
        let top = topWindow
        
        setMenu(MenuBar(menus: [
            MenuBarItem(title: "_File", children: [
                MenuItem(title: "_Close", action: {
                    Application.requestStop()
                })
            ]),
            MenuBarItem(title: "_View", children: [
                MenuItem(title: "_Toggle Orientation", action: toggle)
            ])
        ]))
        
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
        splitView.minimumPaneSize = 5
        splitView.isDraggable = true
        splitView.fill()
        splitViewToggle = splitView
        
        statusBar.addPanel(id: "help", content: "Tab: Switch panes | Mouse: Drag separator | Ctrl+C: Exit")
        topWindow.addSubview(splitView)
        
        // Select first category by default
        principalList.selectedItem = 0
        _ = principalList.activate?(0)
    }
}
