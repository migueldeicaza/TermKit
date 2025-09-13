//
//  DemoLayer.swift
//  TermKit Example
//
//  Simple demo to validate layer-backed rendering and composition
//

import TermKit

class DemoLayer: DemoHost {
    init() {
        super.init(title: "Layer/Compose Demo")
    }

    override func setupDemo() {
        // Frame with a label inside
        let frame = Frame("Layer Test")
        frame.set(x: 2, y: 2, width: 30, height: 8)
        let label = Label("Hello inside Frame")
        label.x = Pos.at(2)
        label.y = Pos.at(2)
        frame.addSubview(label)
        topWindow.addSubview(frame)

        // ScrollView demo: a viewport with scrolled content
        let sv = ScrollView()
        sv.set(x: 2, y: 12, width: 30, height: 6)
        sv.contentSize = Size(width: 80, height: 20)
        sv.showHorizontalScrollIndicator = true
        sv.showVerticalScrollIndicator = true
        // Put a label far in the content space to validate offset composition
        let deepLabel = Label("Far content -> should be visible")
        deepLabel.set(x: 35, y: 10)
        sv.addSubview(deepLabel)
        // Scroll so that the label comes into view
        sv.contentOffset = Point(x: 30, y: 8)
        topWindow.addSubview(sv)
    }
}

