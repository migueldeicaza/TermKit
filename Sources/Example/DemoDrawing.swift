//
//  DemoDrawing.swift
//  Example
//
//  Drawing program with color palette and X marks on mouse clicks
//

import Foundation
import TermKit

@MainActor
func DemoDrawing() -> Toplevel {
    let top = Toplevel()
    top.fill()
    
    // Menu bar
    let menu = MenuBar(menus: [
        MenuBarItem(title: "_File", children: [
            MenuItem(title: "_Clear Canvas", action: {
                if let canvas = findCanvas(in: top) {
                    canvas.clearCanvas()
                }
            }),
            MenuItem(title: "_Close", action: {
                Application.requestStop()
            })
        ])
    ])
    top.addSubview(menu)
    
    // Main window
    let win = Window("Drawing Demo - Click to Draw X")
    win.x = Pos.at(0)
    win.y = Pos.at(1)
    win.width = Dim.fill()
    win.height = Dim.fill()
    
    // Color palette view
    let paletteFrame = Frame("Colors")
    let palette = ColorPaletteView()
    paletteFrame.addSubview(palette)
    
    // Drawing canvas view
    let canvasFrame = Frame("Canvas")
    let canvas = DrawingCanvasView()
    canvas.selectedColor = palette.selectedColor
    canvasFrame.addSubview(canvas)
    
    // Connect palette to canvas
    palette.onColorChanged = { color in
        canvas.selectedColor = color
    }
    
    // Create the split view
    let splitView = SplitView(first: paletteFrame, second: canvasFrame, orientation: .horizontal)
    splitView.splitPosition = .percentage(0.25)
    splitView.minimumPaneSize = 15
    splitView.isDraggable = true
    splitView.fill()
    
    // Add status bar with instructions
    let statusBar = Label("Click on canvas to draw X marks | Select colors from palette | Ctrl+C: Exit")
    statusBar.x = Pos.at(0)
    statusBar.y = Pos.anchorEnd()
    statusBar.width = Dim.fill()
    statusBar.colorScheme = Colors.menu
    
    win.addSubview(splitView)
    win.addSubview(statusBar)
    
    top.addSubview(win)
    return top
}

// Helper function to find canvas in view hierarchy
private func findCanvas(in view: View) -> DrawingCanvasView? {
    if let canvas = view as? DrawingCanvasView {
        return canvas
    }
    for subview in view.subviews {
        if let found = findCanvas(in: subview) {
            return found
        }
    }
    return nil
}

// Color palette view
class ColorPaletteView: View {
    var selectedColor: Attribute = Colors.base.normal
    var onColorChanged: ((Attribute) -> Void)?
    
    private lazy var colors: [(name: String, attr: Attribute)] = [
        ("Red", Application.makeAttribute(fore: .red, back: .black)),
        ("Green", Application.makeAttribute(fore: .green, back: .black)),
        ("Blue", Application.makeAttribute(fore: .blue, back: .black)),
        ("Yellow", Application.makeAttribute(fore: .brightYellow, back: .black)),
        ("Magenta", Application.makeAttribute(fore: .magenta, back: .black)),
        ("Cyan", Application.makeAttribute(fore: .cyan, back: .black)),
        ("White", Application.makeAttribute(fore: .white, back: .black)),
        ("Black", Application.makeAttribute(fore: .black, back: .gray))
    ]
    
    private var selectedIndex = 0
    
    override init() {
        super.init()
        canFocus = true
        fill()
        selectedColor = colors[0].attr
    }
    
    override func redraw(region: Rect, painter: Painter) {
        painter.clear()
        
        for (index, color) in colors.enumerated() {
            let y = index
            if y >= bounds.height {
                break
            }
            
            let isSelected = index == selectedIndex
            let prefix = isSelected ? "► " : "  "
            let text = "\(prefix)\(color.name)"
            
            // Draw color sample
            let attr = isSelected ? color.attr.change(background: .gray) : color.attr
            painter.attribute = attr
            painter.goto(col: 0, row: y)
            painter.add(str: text)
        }
    }
    
    override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .cursorUp:
            if selectedIndex > 0 {
                selectedIndex -= 1
                updateSelection()
            }
            return true
        case .cursorDown:
            if selectedIndex < colors.count - 1 {
                selectedIndex += 1
                updateSelection()
            }
            return true
        case .controlM:
            updateSelection()
            return true
        default:
            return super.processKey(event: event)
        }
    }
    
    override func mouseEvent(event: MouseEvent) -> Bool {
        if event.flags.contains(.button1Clicked) {
            let clickedIndex = event.pos.y
            if clickedIndex >= 0 && clickedIndex < colors.count && clickedIndex < bounds.height {
                selectedIndex = clickedIndex
                updateSelection()
                return true
            }
        }
        return super.mouseEvent(event: event)
    }
    
    private func updateSelection() {
        selectedColor = colors[selectedIndex].attr
        onColorChanged?(selectedColor)
        setNeedsDisplay()
    }
}

// Drawing canvas view
class DrawingCanvasView: View {
    var selectedColor: Attribute = Colors.base.normal
    private var marks: [(Point, Attribute)] = []
    
    override init() {
        super.init()
        canFocus = true
        wantMousePositionReports = true
        fill()
    }
    
    override func redraw(region: Rect, painter: Painter) {
        painter.clear()
        
        // Draw all X marks
        for (point, color) in marks {
            if point.x >= 0 && point.x < bounds.width && point.y >= 0 && point.y < bounds.height {
                painter.attribute = color
                painter.goto(col: point.x, row: point.y)
                painter.add(str: "X")
            }
        }
    }
    
    var drawing = false
    override func mouseEvent(event: MouseEvent) -> Bool {
        print("Got \(event)")
        if event.flags.contains(.button1Clicked) {
            if drawing {
                drawing = false
                return true
            }
            drawing = true
            let clickPoint = Point(x: event.pos.x, y: event.pos.y)
            marks.append((clickPoint, selectedColor))
            setNeedsDisplay()
            return true
        }
        if drawing {
            if event.flags.contains(.mousePosition) {
                let clickPoint = Point(x: event.pos.x, y: event.pos.y)
                marks.append((clickPoint, selectedColor))
                setNeedsDisplay()
                return true
            }
            if event.flags.contains(.button1Released) {
                drawing = false
                return true
            }
        }
        return super.mouseEvent(event: event)
    }
    
    func clearCanvas() {
        marks.removeAll()
        setNeedsDisplay()
    }
}
