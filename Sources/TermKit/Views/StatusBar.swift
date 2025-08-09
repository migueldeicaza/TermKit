//
//  StatusBar.swift
//  TermKit
//
//  Created by Miguel de Icaza on 1/1/21.
//

import Foundation

/// A status bar for the application
open class StatusBar: View {    
    public enum Priority: Int, CaseIterable {
        case veryLow = 1
        case low = 2
        case `default` = 3
        case high = 4
        case veryHigh = 5
    }
    
    // Private properties for panel management
    private var panels: [String: Panel] = [:]
    private var visiblePanels: [Panel] = []
    
    public override init() {
        super.init()
        // StatusBar can not be focused
        canFocus = false
        colorScheme = Colors.dialog
        x = Pos.at(0)
        y = Pos.anchorEnd()-1 // Bottom of screen
        width = Dim.fill()
        height = Dim.sized(1)
    }
    
    // MARK: - Status Message Management
    
    /// Sets a temporary status message that disappears after timeout
    public func setStatus(_ message: String, timeout: TimeInterval = 5.0, priority: Priority = .default) {
        let statusId = "__temp_status__"
        addPanel(id: statusId, content: message, priority: priority, placement: .leading)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { @MainActor [weak self] in
            self?.removePanel(id: statusId)
        }
    }
    
    /// Clears the temporary status message.
    public func clearStatus() {
        removePanel(id: "__temp_status__")
        updateVisiblePanels()
    }
    
    // MARK: - Panel Management
    
    /// Adds or updates a permanent panel.
    public func addPanel(id: String, content: String, priority: Priority = .default, placement: PanelPlacement = .trailing) {
        let label = Label(content)
        let panelWidth = content.count
        label.width = Dim.sized(panelWidth)
        label.height = Dim.sized(1)
        let panel = Panel(id: id, content: content, priority: priority, isTemporary: false, placement: placement, view: label, width: panelWidth)
        panels[id] = panel
        updateVisiblePanels()
    }
    
    /// Updates the content of an existing panel.
    public func updatePanel(id: String, content: String) {
        guard let existingPanel = panels[id] else { return }
        
        // Create a new panel with updated content and width
        if let label = existingPanel.view as? Label {
            label.text = content
            let newWidth = content.count
            label.width = Dim.sized(newWidth)
            let updatedPanel = Panel(
                id: existingPanel.id,
                content: content,
                priority: existingPanel.priority,
                isTemporary: existingPanel.isTemporary,
                placement: existingPanel.placement,
                view: existingPanel.view,
                width: newWidth
            )
            panels[id] = updatedPanel
            updateVisiblePanels()
        }
        setNeedsDisplay()
    }
    
    /// Removes a panel.
    public func removePanel(id: String) {
        if let panel = panels.removeValue(forKey: id) {
            removeSubview(panel.view)
        }
        updateVisiblePanels()
        setNeedsDisplay()
    }
    
    // MARK: - Progress Indicators
    
    /// Shows a simple spinner for indeterminate tasks.
    public func showSpinner(id: String, message: String, priority: Priority = .high, kind: Spinner.Definition = Spinner.dot, placement: PanelPlacement = .leading) {
        let containerView = View()
        let spinner = Spinner(definition: kind)
        let label = Label(" " + message)
        
        // Fixed dimensions: spinner = 1 char, message = message.count + 1 (space)
        let spinnerWidth = 1
        let labelWidth = message.count + 1 // +1 for the space
        let totalWidth = spinnerWidth + labelWidth
        
        spinner.start()
        spinner.width = Dim.sized(spinnerWidth)
        spinner.height = Dim.sized(1)
        label.width = Dim.sized(labelWidth)
        label.height = Dim.sized(1)
        label.x = Pos.at(spinnerWidth)
        
        containerView.width = Dim.sized(totalWidth)
        containerView.height = Dim.sized(1)
        containerView.addSubview(spinner)
        containerView.addSubview(label)
        
        let panel = Panel(id: id, content: message, priority: priority, isTemporary: false, placement: placement, view: containerView, width: totalWidth)
        panels[id] = panel
        updateVisiblePanels()
        setNeedsDisplay()
    }
    
    /// Shows a progress bar for determinate tasks.
    public func showProgressBar(id: String, current: Int, total: Int, message: String, priority: Priority = .veryHigh, placement: PanelPlacement = .leading) {
        let containerView = View()
        let progressBar = ProgressBar()
        let label = Label(message + " ")
        
        // Fixed dimensions: message = message.count + 1 (space), progress bar = 25 chars
        let labelWidth = message.count + 1 // +1 for the space
        let progressBarWidth = 25
        let totalWidth = labelWidth + progressBarWidth
        
        progressBar.fraction = total > 0 ? Float(current) / Float(total) : 0.0
        progressBar.x = Pos.at(labelWidth)
        progressBar.width = Dim.sized(progressBarWidth)
        progressBar.height = Dim.sized(1)
        label.width = Dim.sized(labelWidth)
        label.height = Dim.sized(1)
        
        containerView.width = Dim.sized(totalWidth)
        containerView.height = Dim.sized(1)
        containerView.addSubview(label)
        containerView.addSubview(progressBar)
                
        let panel = Panel(id: id, content: message, priority: priority, isTemporary: false, placement: placement, view: containerView, width: totalWidth)
        panels[id] = panel
        updateVisiblePanels()
        setNeedsDisplay()
    }
    
    /// Updates an existing progress bar
    public func updateProgressBar(id: String, current: Int, total: Int, message: String) {
        guard let existingPanel = panels[id] else { return }
        
        let containerView = existingPanel.view
        if containerView.subviews.count >= 2,
           let label = containerView.subviews[0] as? Label,
           let progressBar = containerView.subviews[1] as? ProgressBar {
            
            // Fixed dimensions: message = message.count + 1 (space), progress bar = 25 chars
            let labelWidth = message.count + 1 // +1 for the space
            let progressBarWidth = 25
            let totalWidth = labelWidth + progressBarWidth
            
            label.text = message + " "
            label.width = Dim.sized(labelWidth)
            progressBar.fraction = total > 0 ? Float(current) / Float(total) : 0.0
            
            // Update container and layout with fixed dimensions
            containerView.width = Dim.sized(totalWidth)
            label.width = Dim.sized(labelWidth)
            progressBar.x = Pos.at(labelWidth)
            
            // Create updated panel with new width
            let updatedPanel = Panel(
                id: existingPanel.id,
                content: message,
                priority: existingPanel.priority,
                isTemporary: existingPanel.isTemporary,
                placement: existingPanel.placement,
                view: existingPanel.view,
                width: totalWidth
            )
            panels[id] = updatedPanel
            updateVisiblePanels()
        }
        
        setNeedsDisplay()
    }
    
    /// Hides any progress indicator.
    public func hideIndicator(id: String) {
        removePanel(id: id)
    }
    
    public override var frame: Rect {
        get { super.frame }
        set {
            super.frame = newValue
            updateVisiblePanels()
        }
    }
    
    private func updateVisiblePanels() {
        // Remove all current subviews
        for subview in subviews {
            removeSubview(subview)
        }
        
        // Sort panels by priority (higher priority first)
        let sortedPanels = panels.values.sorted { $0.priority.rawValue > $1.priority.rawValue }
        
        // Separate leading and trailing panels
        let leadingPanels = sortedPanels.filter { $0.placement == .leading }
        let trailingPanels = sortedPanels.filter { $0.placement == .trailing }
        
        // Layout variables
        var currentLeading = 0
        var currentTrailing = frame.width
        visiblePanels = []
        
        // Place leading panels from left to right
        for panel in leadingPanels {
            let panelWidth = panel.width
            if currentLeading + panelWidth <= currentTrailing {
                panel.view.frame = Rect(x: currentLeading, y: 0, width: panelWidth, height: 1)
                panel.view.x = Pos.at(currentLeading)
                panel.view.y = Pos.at(0)
                panel.view.width = Dim.sized(panelWidth)
                panel.view.height = Dim.sized(1)

                addSubview(panel.view)
                log("Adding panel \(panel.id) at \(currentLeading)")
                currentLeading += panelWidth + 1 // Add space between panels
                var mutablePanel = panel
                mutablePanel.isVisible = true
                visiblePanels.append(mutablePanel)
            }
        }
        
        // Place trailing panels from right to left
        for panel in trailingPanels {
            let panelWidth = panel.width
            if currentTrailing - panelWidth >= currentLeading {
                currentTrailing -= panelWidth
                panel.view.x = Pos.at(currentTrailing)
                panel.view.y = Pos.at(0)
                panel.view.width = Dim.sized(panelWidth)
                panel.view.height = Dim.sized(1)

                log("Trai panel \(panel.id) at \(currentTrailing)")
                addSubview(panel.view)
                currentTrailing -= 1 // Add space between panels
                var mutablePanel = panel
                mutablePanel.isVisible = true
                visiblePanels.append(mutablePanel)
            }
        }
    }
    
    open override func redraw(region: Rect, painter: Painter) {
        painter.attribute = Colors.dialog.normal
        painter.clear()
        for (index, subview) in subviews.enumerated() {
            log("Subview \(index) is \(subview.frame)")
        }
        super.redraw(region: region, painter: painter)
    }
    
    open override func positionCursor() {
        moveTo(col: frame.minX, row: frame.minY)
    }
}

// MARK: - Private Structs

public enum PanelPlacement {
    case leading
    case trailing
}

private struct Panel {
    let id: String
    var content: String
    let priority: StatusBar.Priority
    let isTemporary: Bool
    let placement: PanelPlacement
    var view: View
    let width: Int
    var isVisible: Bool = false
    
    init(id: String, content: String, priority: StatusBar.Priority, isTemporary: Bool, placement: PanelPlacement, view: View, width: Int) {
        self.id = id
        self.content = content
        self.priority = priority
        self.isTemporary = isTemporary
        self.placement = placement
        self.view = view
        self.width = width
    }
}
