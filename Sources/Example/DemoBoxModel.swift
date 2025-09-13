//
//  DemoBoxModel.swift
//  TermKit
//
//  Demonstrates margin, border, and padding with nested frames
//

import Foundation
import TermKit

class DemoBoxModel: DemoHost {
    init() {
        super.init(title: "Box Model Demo")
    }

    override func setupDemo() {
        // Split the window into two panes: left = examples, right = live controls
        let leftPane = Frame("Examples")
        leftPane.x = Pos.at(0)
        leftPane.y = Pos.at(0)
        leftPane.width = Dim.percent(n: 50)
        leftPane.height = Dim.fill()
        leftPane.border = .solid
        leftPane.padding = EdgeInsets(all: 1)

        let rightPane = Frame("Live Controls")
        rightPane.x = try? Pos.percent(n: 50)
        rightPane.y = Pos.at(0)
        rightPane.width = Dim.percent(n: 50)
        rightPane.height = Dim.fill()
        rightPane.border = .solid
        rightPane.padding = EdgeInsets(all: 1)

        topWindow.addSubviews([leftPane, rightPane])

        // LEFT: examples
        do {
            // Example 1: simple bordered frame with padding
            let f1 = Frame("Padding: 2 all")
            f1.set(x: 2, y: 1, width: 36, height: 8)
            f1.padding = EdgeInsets(all: 2)
            f1.border = .solid
            let l1 = Label("Content sits inside padding")
            l1.x = Pos.at(0); l1.y = Pos.at(0)
            f1.addSubview(l1)

            // Example 2: margin + different border
            let f2 = Frame("Margin 2, Double border")
            f2.set(x: 2, y: 10, width: 36, height: 8)
            f2.margin = EdgeInsets(all: 2)
            f2.border = .double
            f2.padding = EdgeInsets(top: 1, left: 2, bottom: 1, right: 2)
            let l2 = Label("Margin pushes from neighbors")
            l2.x = Pos.at(0); l2.y = Pos.at(0)
            f2.addSubview(l2)

            // Example 3: nested frames to illustrate contentFrame
            let outer = Frame("Outer: round + padding 1")
            outer.set(x: 42, y: 1, width: 36, height: 17)
            outer.border = .round
            outer.padding = EdgeInsets(all: 1)

            let inner = Frame("Inner: ascii, margin 1")
            inner.fill()
            inner.margin = EdgeInsets(all: 1)
            inner.border = .ascii
            inner.padding = EdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
            let l3 = Label("Inner fills outer contentFrame")
            l3.x = Pos.at(0); l3.y = Pos.at(0)
            inner.addSubview(l3)
            outer.addSubview(inner)

            leftPane.addSubviews([f1, f2, outer])
        }

        // RIGHT: live controls + a canvas containing a sample frame (to make margin effects obvious)
        let canvas = Frame("Canvas")
        canvas.border = .round
        canvas.padding = EdgeInsets(all: 1)
        canvas.x = Pos.at(2)
        canvas.y = Pos.at(8)
        canvas.width = Dim.fill(2)
        canvas.height = Dim.sized(12)

        let sampleView = Frame("Sample")
        sampleView.border = .solid
        sampleView.padding = EdgeInsets(all: 1)
        sampleView.margin = EdgeInsets(all: 1)
        sampleView.x = Pos.at(0)
        sampleView.y = Pos.at(0)
        sampleView.width = Dim.sized(24)
        sampleView.height = Dim.sized(9)

        let nameLabel = Label("Name:")
        nameLabel.x = Pos.at(0)
        nameLabel.y = Pos.at(0)
        let nameField = TextField("")
        nameField.x = Pos.right(of: nameLabel) + 1
        nameField.y = Pos.top(of: nameLabel)
        nameField.width = Dim.fill()

        sampleView.addSubviews([nameLabel, nameField])
        canvas.addSubview(sampleView)

        // Control widgets
        let header = Label("Adjust padding, margin, and border of the Sample")
        header.x = Pos.at(0)
        header.y = Pos.at(0)

        let padLabel = Label("Padding:")
        padLabel.x = Pos.at(0)
        padLabel.y = Pos.at(2)
        let padMinus = Button("-1")
        padMinus.x = Pos.right(of: padLabel) + 1
        padMinus.y = Pos.top(of: padLabel)
        let padPlus = Button("+1")
        padPlus.x = Pos.right(of: padMinus) + 2
        padPlus.y = Pos.top(of: padLabel)

        let marLabel = Label("Margin:")
        marLabel.x = Pos.at(0)
        marLabel.y = Pos.at(4)
        let marMinus = Button("-1")
        marMinus.x = Pos.right(of: marLabel) + 1
        marMinus.y = Pos.top(of: marLabel)
        let marPlus = Button("+1")
        marPlus.x = Pos.right(of: marMinus) + 2
        marPlus.y = Pos.top(of: marLabel)

        let borderLabel = Label("Border:")
        borderLabel.x = Pos.at(0)
        borderLabel.y = Pos.at(6)
        let borderCycle = Button("Next")
        borderCycle.x = Pos.right(of: borderLabel) + 1
        borderCycle.y = Pos.top(of: borderLabel)
        let borderName = Label("")
        borderName.x = Pos.right(of: borderCycle) + 2
        borderName.y = Pos.top(of: borderLabel)

        // Helper state and updaters
        var padVal = 1
        var marVal = 1
        let styles: [BorderStyle] = [.none, .ascii, .round, .solid, .double, .heavy]
        var styleIndex = styles.firstIndex(of: sampleView.border) ?? 3
        func styleName(_ s: BorderStyle) -> String {
            switch s {
            case .none: return "none"
            case .blank: return "blank"
            case .ascii: return "ascii"
            case .round: return "round"
            case .solid: return "solid"
            case .double: return "double"
            case .dashed: return "dashed"
            case .heavy: return "heavy"
            case .inner: return "inner"
            case .outer: return "outer"
            case .thick: return "thick"
            case .hkey: return "hkey"
            case .vkey: return "vkey"
            case .tall: return "tall"
            case .panel: return "panel"
            case .tab: return "tab"
            case .wide: return "wide"
            }
        }
        let valueLine = Label("")
        valueLine.x = Pos.at(0)
        valueLine.y = Pos.at(1)
        func refreshLabels() {
            borderName.text = styleName(sampleView.border)
            valueLine.text = "Pad: \(padVal)   Mar: \(marVal)   Border: \(borderName.text)"
        }
        refreshLabels()

        // Wire up buttons
        padMinus.clicked = { _ in
            padVal = max(0, padVal - 1)
            sampleView.padding = EdgeInsets(all: padVal)
            refreshLabels()
        }
        padPlus.clicked = { _ in
            padVal += 1
            sampleView.padding = EdgeInsets(all: padVal)
            refreshLabels()
        }
        marMinus.clicked = { _ in
            marVal = max(0, marVal - 1)
            sampleView.margin = EdgeInsets(all: marVal)
            refreshLabels()
        }
        marPlus.clicked = { _ in
            marVal += 1
            sampleView.margin = EdgeInsets(all: marVal)
            refreshLabels()
        }
        borderCycle.clicked = { _ in
            styleIndex = (styleIndex + 1) % styles.count
            sampleView.border = styles[styleIndex]
            refreshLabels()
        }

        // Add controls before the canvas so tab order reaches them first
        rightPane.addSubviews([
            header, valueLine,
            padLabel, padMinus, padPlus,
            marLabel, marMinus, marPlus,
            borderLabel, borderCycle, borderName
        ])
        rightPane.addSubview(canvas)
    }
}
