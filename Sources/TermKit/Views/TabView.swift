//
//  TabView.swift - Tab container control
//  TermKit
//
//  A TabView control that can contain multiple views in tabs with keyboard and mouse navigation
//

import Foundation

/**
 * TabView is a container control that displays multiple views in tabs.
 * Each tab has a title and contains a view. Users can switch between tabs
 * using keyboard navigation or mouse clicks.
 */
open class TabView: View {
    
    /// Style options for tab rendering
    public enum TabStyle {
        /// Plain text tabs with color distinction
        case plain
        /// Bordered tabs with Unicode box characters
        case bordered
    }
    
    /// Position options for tab placement
    public enum TabPosition {
        /// Tabs shown at the top (default)
        case top
        /// Tabs shown at the bottom
        case bottom
        /// Tabs shown on the left side
        case left
        /// Tabs shown on the right side
        case right
    }
    
    /// Tab data structure
    public struct Tab {
        public let title: String
        public let content: View
        public let id: Int
        
        init(title: String, content: View, id: Int) {
            self.title = title
            self.content = content
            self.id = id
        }
    }
    
    private var tabs: [Tab] = []
    private var selectedTabIndex: Int = -1  // -1 means no tab selected
    private var nextTabId: Int = 0
    private var tabHeaderHeight: Int = 1
    private var tabHeaderWidth: Int = 1
    private var isNavigatingTabs: Bool = false
    private var firstVisibleTabIndex: Int = 0
    
    /// The style used to render tabs
    public var tabStyle: TabStyle = .bordered {
        didSet {
            updateTabDimensions()
            layoutTabs()
            setNeedsDisplay()
        }
    }
    
    /// The position where tabs are displayed
    public var tabPosition: TabPosition = .top {
        didSet {
            updateTabDimensions()
            layoutTabs()
            setNeedsDisplay()
        }
    }
    
    /// The currently selected tab index
    public var selectedTab: Int {
        get { selectedTabIndex }
        set {
            if newValue >= 0 && newValue < tabs.count && newValue != selectedTabIndex {
                selectTab(newValue)
            }
        }
    }
    
    /// The number of tabs
    public var tabCount: Int {
        return tabs.count
    }
    
    public override init() {
        super.init()
        canFocus = true
        wantContinuousButtonPressed = true
        updateTabDimensions()
    }
    
    public override init(frame: Rect) {
        super.init(frame: frame)
        canFocus = true
        wantContinuousButtonPressed = true
        updateTabDimensions()
    }
    
    private func updateTabDimensions() {
        switch tabPosition {
        case .top, .bottom:
            tabHeaderHeight = (tabStyle == .bordered) ? 3 : 1
            tabHeaderWidth = 0  // Full width
        case .left, .right:
            tabHeaderHeight = 0  // Full height
            tabHeaderWidth = calculateMaxTabWidth()
        }
    }
    
    private func calculateMaxTabWidth() -> Int {
        guard !tabs.isEmpty else { return 10 }  // Default width
        
        let maxTitleLength = tabs.map { $0.title.count }.max() ?? 8
        return (tabStyle == .bordered) ? maxTitleLength + 4 : maxTitleLength + 2
    }
    
    // MARK: - Tab Management
    
    /**
     * Adds a new tab with the specified title and content
     * - Parameters:
     *   - title: The title displayed in the tab header
     *   - content: The view to display in the tab content area
     * - Returns: The index of the newly added tab
     */
    @discardableResult
    public func addTab(_ title: String, content: View) -> Int {
        let tab = Tab(title: title, content: content, id: nextTabId)
        nextTabId += 1
        tabs.append(tab)
        
        // Update tab dimensions in case this tab is wider
        updateTabDimensions()
        
        // Don't add as subview yet - we'll manage this in selectTab
        layoutTabs()
        
        // Select the first tab if this is the first one added
        if tabs.count == 1 {
            selectTab(0)
        }
        
        setNeedsDisplay()
        return tabs.count - 1
    }
    
    /**
     * Removes a tab at the specified index
     * - Parameter index: The index of the tab to remove
     * - Returns: true if the tab was removed, false if the index was invalid
     */
    @discardableResult
    public func removeTab(at index: Int) -> Bool {
        guard index >= 0 && index < tabs.count else { return false }
        
        let tab = tabs[index]
        removeSubview(tab.content)
        tabs.remove(at: index)
        
        // Adjust selected tab index if necessary
        if selectedTabIndex >= tabs.count {
            selectedTabIndex = max(-1, tabs.count - 1)
        }
        
        if tabs.count > 0 && selectedTabIndex >= 0 {
            selectTab(selectedTabIndex)
        } else if tabs.count == 0 {
            selectedTabIndex = -1
        }
        
        layoutTabs()
        setNeedsDisplay()
        return true
    }
    
    /**
     * Moves a tab from one position to another
     * - Parameters:
     *   - from: The current index of the tab
     *   - to: The target index for the tab
     * - Returns: true if the tab was moved, false if either index was invalid
     */
    @discardableResult
    public func moveTab(from: Int, to: Int) -> Bool {
        guard from >= 0 && from < tabs.count && to >= 0 && to < tabs.count && from != to else {
            return false
        }
        
        let tab = tabs.remove(at: from)
        tabs.insert(tab, at: to)
        
        // Update selected tab index
        if selectedTabIndex == from {
            selectedTabIndex = to
        } else if selectedTabIndex > from && selectedTabIndex <= to {
            selectedTabIndex -= 1
        } else if selectedTabIndex >= to && selectedTabIndex < from {
            selectedTabIndex += 1
        }
        
        ensureSelectedTabVisible()
        layoutTabs()
        setNeedsDisplay()
        return true
    }
    
    /**
     * Changes the title of a tab at the specified index
     * - Parameters:
     *   - index: The index of the tab to modify
     *   - title: The new title for the tab
     * - Returns: true if the title was changed, false if the index was invalid
     */
    @discardableResult
    public func setTabTitle(at index: Int, title: String) -> Bool {
        guard index >= 0 && index < tabs.count else { return false }
        
        // Create a new tab with the updated title
        let oldTab = tabs[index]
        let newTab = Tab(title: title, content: oldTab.content, id: oldTab.id)
        tabs[index] = newTab
        
        setNeedsDisplay()
        return true
    }
    
    /**
     * Gets the title of a tab at the specified index
     * - Parameter index: The index of the tab
     * - Returns: The title of the tab, or nil if the index is invalid
     */
    public func getTabTitle(at index: Int) -> String? {
        guard index >= 0 && index < tabs.count else { return nil }
        return tabs[index].title
    }
    
    /**
     * Finds the index of a tab containing the specified view
     * - Parameter view: The view to search for
     * - Returns: The index of the tab containing the view, or nil if not found
     */
    public func findTabIndex(containing view: View) -> Int? {
        return tabs.firstIndex { tab in
            return tab.content == view
        }
    }
    
    // MARK: - Internal Tab Management
    
    private func selectTab(_ index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        if index == selectedTabIndex { return }
        
        // Remove current tab content from subviews (if there was a previous tab)
        if selectedTabIndex >= 0 && selectedTabIndex < tabs.count && selectedTabIndex != index {
            removeSubview(tabs[selectedTabIndex].content)
        }
        
        selectedTabIndex = index
        ensureSelectedTabVisible()
        
        // Add new tab content as subview
        let contentView = tabs[selectedTabIndex].content
        addSubview(contentView)
        
        // Set the frame and force a layout update, guarding against negative/invalid sizes
        var contentFrame = calculateContentFrame()
        if contentFrame.width < 0 || contentFrame.height < 0 {
            contentFrame.size = Size(width: max(0, contentFrame.width), height: max(0, contentFrame.height))
        }
        if contentFrame.minX < 0 || contentFrame.minY < 0 {
            contentFrame.origin = Point(x: max(0, contentFrame.minX), y: max(0, contentFrame.minY))
        }
        contentView.frame = contentFrame
        // Force the content view to use fixed layout since we're managing its frame
        contentView.layoutStyle = .fixed
        
        // Force layout of the content view and its subviews
        do {
            try contentView.layoutSubviews()
        } catch {
            // Handle layout errors gracefully
        }
        
        // Force redraw of content
        contentView.setNeedsDisplay()
        setNeedsDisplay()
        
        // Focus the content if we're not navigating tabs
        log("DEBUG selectTab: isNavigatingTabs = \(isNavigatingTabs), hasFocus = \(hasFocus)")
        if !isNavigatingTabs && hasFocus {
            log("DEBUG selectTab: Calling focusTabContent()")
            focusTabContent()
        } else {
            log("DEBUG selectTab: NOT calling focusTabContent()")
        }
    }
    
    private func ensureSelectedTabVisible() {
        guard tabs.count > 0 && selectedTabIndex >= 0 else { return }
        
        // Calculate what tabs are currently visible with the current firstVisibleTabIndex
        let currentVisibleRange: (count: Int, lastIndex: Int)
        switch tabPosition {
        case .top, .bottom:
            currentVisibleRange = calculateVisibleTabsRange()
        case .left, .right:
            currentVisibleRange = calculateVisibleTabsRangeVertical()
        }
        
        let lastVisibleIndex = firstVisibleTabIndex + currentVisibleRange.count - 1
        
        // If the selected tab is already fully visible, don't scroll at all
        if selectedTabIndex >= firstVisibleTabIndex && selectedTabIndex <= lastVisibleIndex {
            return
        }
        
        // Only scroll if the selected tab is actually outside the visible range
        
        if selectedTabIndex < firstVisibleTabIndex {
            // Selected tab is before visible range - scroll to show it
            firstVisibleTabIndex = selectedTabIndex
        } else if selectedTabIndex > lastVisibleIndex {
            // Selected tab is after visible range - scroll to show it
            // Try to make it the last visible tab
            firstVisibleTabIndex = selectedTabIndex
            
            // Adjust backwards until we can fit the selected tab and as many others as possible
            while firstVisibleTabIndex > 0 {
                let testRange: (count: Int, lastIndex: Int)
                switch tabPosition {
                case .top, .bottom:
                    testRange = calculateVisibleTabsRangeFrom(firstVisibleTabIndex - 1)
                case .left, .right:
                    testRange = calculateVisibleTabsRangeVerticalFrom(firstVisibleTabIndex - 1)
                }
                
                if selectedTabIndex < firstVisibleTabIndex - 1 + testRange.count {
                    firstVisibleTabIndex = firstVisibleTabIndex - 1
                } else {
                    break
                }
            }
        }
        
        // Ensure we don't scroll past boundaries
        firstVisibleTabIndex = max(0, firstVisibleTabIndex)
    }
    
    private func calculateVisibleTabsRangeFrom(_ startIndex: Int) -> (count: Int, lastIndex: Int) {
        guard startIndex >= 0 && startIndex < tabs.count else { return (0, 0) }
        
        let availableWidth = frame.width
        var currentWidth = 0
        var visibleCount = 0
        
        // Account for potential scroll indicators
        let needsLeftScroll = startIndex > 0
        let leftScrollWidth = needsLeftScroll ? 1 : 0
        
        // First pass: calculate how many tabs we can fit
        var tempWidth = leftScrollWidth
        var tempCount = 0
        
        for i in startIndex..<tabs.count {
            let tab = tabs[i]
            let tabText = " \(tab.title) "
            let tabWidth = (tabStyle == .bordered) ? tabText.count + 2 : tabText.count
            
            if tempWidth + tabWidth > availableWidth {
                break
            }
            
            tempWidth += tabWidth
            tempCount += 1
        }
        
        // Check if we need right scroll indicator
        let needsRightScroll = (startIndex + tempCount < tabs.count)
        let rightScrollWidth = needsRightScroll ? 1 : 0
        let usableWidth = availableWidth - leftScrollWidth - rightScrollWidth
        
        // Second pass: recalculate with right scroll indicator accounted for
        currentWidth = 0
        visibleCount = 0
        
        for i in startIndex..<tabs.count {
            let tab = tabs[i]
            let tabText = " \(tab.title) "
            let tabWidth = (tabStyle == .bordered) ? tabText.count + 2 : tabText.count
            
            if currentWidth + tabWidth > usableWidth {
                break
            }
            
            currentWidth += tabWidth
            visibleCount += 1
        }
        
        return (visibleCount, startIndex + visibleCount - 1)
    }
    
    private func calculateMaxVisibleTabs() -> Int {
        let availableWidth = frame.width
        var currentWidth = 0
        var count = 0
        
        // Account for potential scroll indicators (2 characters total)
        let scrollIndicatorWidth = 2
        let usableWidth = max(0, availableWidth - scrollIndicatorWidth)
        
        // Calculate based on average tab width starting from selected tab
        let startIndex = max(0, selectedTabIndex)
        for i in startIndex..<tabs.count {
            let tabText = " \(tabs[i].title) "
            let tabWidth = (tabStyle == .bordered) ? tabText.count + 2 : tabText.count
            
            if currentWidth + tabWidth > usableWidth && count > 0 {
                break
            }
            
            currentWidth += tabWidth
            count += 1
        }
        
        return max(1, count) // Always show at least one tab
    }
    
    private func calculateVisibleTabsRange() -> (count: Int, lastIndex: Int) {
        guard tabs.count > 0 else { return (0, 0) }
        
        let availableWidth = frame.width
        var currentWidth = 0
        var visibleCount = 0
        
        // Check if we need scroll indicators
        let needsLeftScroll = firstVisibleTabIndex > 0
        let leftScrollWidth = needsLeftScroll ? 1 : 0
        
        // First pass: calculate how many tabs we can fit
        var tempWidth = leftScrollWidth
        var tempCount = 0
        
        for i in firstVisibleTabIndex..<tabs.count {
            let tab = tabs[i]
            let tabText = " \(tab.title) "
            let tabWidth = (tabStyle == .bordered) ? tabText.count + 2 : tabText.count
            
            if tempWidth + tabWidth > availableWidth {
                break
            }
            
            tempWidth += tabWidth
            tempCount += 1
        }
        
        // Check if we need right scroll indicator
        let needsRightScroll = (firstVisibleTabIndex + tempCount < tabs.count)
        let rightScrollWidth = needsRightScroll ? 1 : 0
        let usableWidth = availableWidth - leftScrollWidth - rightScrollWidth
        
        // Second pass: recalculate with right scroll indicator accounted for
        currentWidth = 0
        visibleCount = 0
        
        for i in firstVisibleTabIndex..<tabs.count {
            let tab = tabs[i]
            let tabText = " \(tab.title) "
            let tabWidth = (tabStyle == .bordered) ? tabText.count + 2 : tabText.count
            
            if currentWidth + tabWidth > usableWidth {
                break
            }
            
            currentWidth += tabWidth
            visibleCount += 1
        }
        
        return (visibleCount, firstVisibleTabIndex + visibleCount - 1)
    }
    
    private func calculateContentFrame() -> Rect {
        let borderOffset = (tabStyle == .bordered) ? 1 : 0
        // Safeguard: view might not be laid out yet; avoid negative sizes
        let fw = max(0, frame.width)
        let fh = max(0, frame.height)
        switch tabPosition {
        case .top:
            if tabStyle == .bordered {
                return Rect(
                    x: borderOffset,
                    y: max(0, tabHeaderHeight + borderOffset),
                    width: max(0, fw - 2 * borderOffset),
                    height: max(0, fh - tabHeaderHeight - 2 * borderOffset)
                )
            } else {
                return Rect(
                    x: 0,
                    y: max(0, tabHeaderHeight),
                    width: fw,
                    height: max(0, fh - tabHeaderHeight)
                )
            }
        case .bottom:
            if tabStyle == .bordered {
                return Rect(
                    x: borderOffset,
                    y: borderOffset,
                    width: max(0, fw - 2 * borderOffset),
                    height: max(0, fh - tabHeaderHeight - 2 * borderOffset)
                )
            } else {
                return Rect(
                    x: 0,
                    y: 0,
                    width: fw,
                    height: max(0, fh - tabHeaderHeight)
                )
            }
        case .left:
            if tabStyle == .bordered {
                return Rect(
                    x: max(0, tabHeaderWidth + borderOffset),
                    y: borderOffset,
                    width: max(0, fw - tabHeaderWidth - 2 * borderOffset),
                    height: max(0, fh - 2 * borderOffset)
                )
            } else {
                return Rect(
                    x: max(0, tabHeaderWidth),
                    y: 0,
                    width: max(0, fw - tabHeaderWidth),
                    height: fh
                )
            }
        case .right:
            if tabStyle == .bordered {
                return Rect(
                    x: borderOffset,
                    y: borderOffset,
                    width: max(0, fw - tabHeaderWidth - 2 * borderOffset),
                    height: max(0, fh - 2 * borderOffset)
                )
            } else {
                return Rect(
                    x: 0,
                    y: 0,
                    width: max(0, fw - tabHeaderWidth),
                    height: fh
                )
            }
        }
    }
    
    private func layoutTabs() {
        guard tabs.count > 0 && selectedTabIndex >= 0 && selectedTabIndex < tabs.count else { return }
        
        // Only layout the currently selected tab since it's the only one added as subview
        let contentFrame = calculateContentFrame()
        
        let contentView = tabs[selectedTabIndex].content
        contentView.frame = contentFrame
        // Force the content view to use fixed layout since we're managing its frame
        contentView.layoutStyle = .fixed
        
        // Force layout of the content view
        do {
            try contentView.layoutSubviews()
        } catch {
            // Handle layout errors gracefully
        }
    }
    
    public override func layoutSubviews() throws {
        try super.layoutSubviews()
        layoutTabs()
    }
    
    private func focusTabContent() {
//        print("DEBUG focusTabContent: Called")
        guard selectedTabIndex >= 0 && selectedTabIndex < tabs.count else { return }
        let content = tabs[selectedTabIndex].content
        
        // Try to find the first focusable view in the content
        if let focusable = findFirstFocusable(in: content) {
//            print("DEBUG focusTabContent: Found focusable view, setting focus")
            // Set focus on the content view, which will pass focus to the focusable child
            content.setFocus(focusable)
        } else {
            // If no focusable child found, try to focus the content view itself
            if content.canFocus {
//                print("DEBUG focusTabContent: Content view can focus, setting focus on it")
                setFocus(content)
            }
        }
    }
    
    private func findFirstFocusable(in view: View) -> View? {
        if view.canFocus {
            return view
        }
        
        for subview in view.subviews {
            if let focusable = findFirstFocusable(in: subview) {
                return focusable
            }
        }
        
        return nil
    }
    
    private func findLastFocusable(in view: View) -> View? {
        for subview in view.subviews.reversed() {
            if let focusable = findLastFocusable(in: subview) {
                return focusable
            }
        }
        
        if view.canFocus {
            return view
        }
        
        return nil
    }
    
    // MARK: - Rendering
    
    public override func redraw(region: Rect, painter: Painter) {
        painter.attribute = colorScheme.normal
        
        // Draw content area border for bordered style FIRST
        if tabStyle == .bordered {
            drawContentBorder(painter: painter)
        }
        
        drawTabHeaders(painter: painter)
        setNeedsDisplay(region)
        // Now let the parent class handle subview rendering
        super.redraw(region: region, painter: painter)
    }
    
    private func drawTabHeaders(painter: Painter) {
        guard tabs.count > 0 else { return }

        switch (tabPosition, tabStyle) {
        case (.top, .plain):
            drawPlainTabHeadersTop(painter: painter)
        case (.top, .bordered):
            drawBorderedTabHeadersTop(painter: painter)
        case (.bottom, .plain):
            drawPlainTabHeadersBottom(painter: painter)
        case (.bottom, .bordered):
            drawBorderedTabHeadersBottom(painter: painter)
        case (.left, .plain):
            drawPlainTabHeadersLeft(painter: painter)
        case (.left, .bordered):
            drawBorderedTabHeadersLeft(painter: painter)
        case (.right, .plain):
            drawPlainTabHeadersRight(painter: painter)
        case (.right, .bordered):
            drawBorderedTabHeadersRight(painter: painter)
        }
    }
    
    private func drawPlainTabHeadersTop(painter: Painter) {
        var col = 0
        let visibleRange = calculateVisibleTabsRange()
        let needsLeftScroll = firstVisibleTabIndex > 0
        let needsRightScroll = firstVisibleTabIndex + visibleRange.count < tabs.count
        
        // Draw left scroll indicator
        if needsLeftScroll {
            painter.attribute = colorScheme.normal
            painter.goto(col: col, row: 0)
            painter.add(str: "<")
            col += 1
        }
        
        // Draw visible tabs
        for i in firstVisibleTabIndex..<min(tabs.count, firstVisibleTabIndex + visibleRange.count) {
            let tab = tabs[i]
            let isSelected = (i == selectedTabIndex)
            let isTabNavigating = isNavigatingTabs && isSelected && hasFocus
            
            // DEBUG: Check focus state
            if isSelected {
                log("DEBUG drawPlain: tab \(i) selected, isNavigatingTabs=\(isNavigatingTabs), hasFocus=\(hasFocus), isTabNavigating=\(isTabNavigating)")
            }
            
            // Set appropriate colors
            if isTabNavigating {
                painter.attribute = colorScheme.focus
            } else if isSelected {
                painter.attribute = colorScheme.hotNormal
            } else {
                painter.attribute = colorScheme.normal
            }
            
            painter.goto(col: col, row: 0)
            let tabText = " \(tab.title) "
            painter.add(str: tabText)
            
            col += tabText.count
            
            if col >= frame.width - (needsRightScroll ? 1 : 0) {
                break
            }
        }
        
        // Draw right scroll indicator
        if needsRightScroll && col < frame.width {
            painter.attribute = colorScheme.normal
            painter.goto(col: frame.width - 1, row: 0)
            painter.add(str: ">")
        }
    }
    
    private func drawBorderedTabHeadersTop(painter: Painter) {
        var col = 0
        let visibleRange = calculateVisibleTabsRange()
        let needsLeftScroll = firstVisibleTabIndex > 0
        let needsRightScroll = firstVisibleTabIndex + visibleRange.count < tabs.count
        
        // Draw left scroll indicator
        if needsLeftScroll {
            painter.attribute = colorScheme.normal
            painter.goto(col: col, row: 0)
            painter.add(str: "<")
            painter.goto(col: col, row: 1)
            painter.add(str: " ")
            col += 1
        }
        
        // First pass: draw tab tops for visible tabs
        let visibleTabs = Array(tabs[firstVisibleTabIndex..<min(tabs.count, firstVisibleTabIndex + visibleRange.count)])
        var tabPositions: [(tab: Tab, col: Int, width: Int, index: Int)] = []
        
        for (visibleIndex, tab) in visibleTabs.enumerated() {
            let actualIndex = firstVisibleTabIndex + visibleIndex
            let isSelected = (actualIndex == selectedTabIndex)
            let isTabNavigating = isNavigatingTabs && isSelected && hasFocus
            let tabText = " \(tab.title) "
            let tabWidth = tabText.count + 2 // Add 2 for side borders
            
            if col + tabWidth > frame.width - (needsRightScroll ? 1 : 0) {
                break
            }
            
            tabPositions.append((tab, col, tabWidth, actualIndex))
            
            // Draw top border with normal color
            painter.attribute = colorScheme.normal
            painter.goto(col: col, row: 0)
            painter.add(rune: driver.ulCorner)
            for _ in 0..<(tabWidth - 2) {
                painter.add(rune: driver.hLine)
            }
            painter.add(rune: driver.urCorner)
            
            // Draw tab sides with normal color
            painter.attribute = colorScheme.normal
            painter.goto(col: col, row: 1)
            painter.add(rune: driver.vLine)
            
            // Draw tab text with appropriate focus color
            if isTabNavigating {
                painter.attribute = colorScheme.focus
            } else if isSelected, hasFocus {
                painter.attribute = colorScheme.hotNormal  
            } else {
                painter.attribute = colorScheme.normal
            }
            painter.add(str: tabText)
            
            // Draw right side with normal color
            painter.attribute = colorScheme.normal
            painter.add(rune: driver.vLine)
            
            col += tabWidth
        }
        
        // Draw right scroll indicator
        if needsRightScroll && col < frame.width {
            painter.attribute = colorScheme.normal
            painter.goto(col: frame.width - 1, row: 0)
            painter.add(str: ">")
            painter.goto(col: frame.width - 1, row: 1)
            painter.add(str: " ")
        }
        
        // Third pass: draw tab-specific connections on row 2 FIRST
        painter.attribute = colorScheme.normal
        
        // Start with a baseline horizontal line
        painter.goto(col: 0, row: 2)
        for _ in 0..<frame.width {
            painter.add(rune: driver.hLine)
        }
        
        // Then overlay tab-specific connections
        for (_, startCol, tabWidth, actualIndex) in tabPositions {
            let isSelected = (actualIndex == selectedTabIndex)
            
            if !isSelected {
                // For non-selected tabs, draw bottomTee connections
                painter.goto(col: startCol, row: 2)
                painter.add(rune: driver.bottomTee)  // ┴
                
                painter.goto(col: startCol + tabWidth - 1, row: 2)
                painter.add(rune: driver.bottomTee)  // ┴
                
            } else {
                // For selected tab, create opening in the horizontal line
                for col in startCol..<(startCol + tabWidth) {
                    painter.goto(col: col, row: 2)
                    if col == startCol {
                        // Left connection
                        if startCol == 0 {
                            painter.add(rune: driver.vLine)
                        } else {
                            painter.add(rune: driver.lrCorner)
                        }
                    } else if col == startCol + tabWidth - 1 {
                        // Right connection  
                        if startCol + tabWidth >= frame.width {
                            painter.add(rune: driver.vLine)
                        } else {
                            painter.add(rune: driver.llCorner)
                        }
                    } else {
                        // Opening space
                        painter.add(str: " ")
                    }
                }
            }
        }
        
        // Finally, ensure content border connections at the edges
        painter.goto(col: 0, row: 2)
        painter.add(rune: driver.vLine)
        painter.goto(col: frame.width - 1, row: 2)
        painter.add(rune: driver.vLine)
    }
    
    private func drawContentBorder(painter: Painter) {
        painter.attribute = colorScheme.normal
        
        switch tabPosition {
        case .top:
            drawContentBorderTop(painter: painter)
        case .bottom:
            drawContentBorderBottom(painter: painter)
        case .left:
            drawContentBorderLeft(painter: painter)
            break
        case .right:
            drawContentBorderRight(painter: painter)
        }
    }
    
    private func drawContentBorderTop(painter: Painter) {
        // For bordered style with tabHeaderHeight = 3:
        // Row 0: Top border of tabs (┌─┐)
        // Row 1: Text content of tabs (│text│)  
        // Row 2: Bottom of tabs (└─┘ for non-selected, spaces for selected)
        // Row 3+: Content area borders
        
        // Draw left and right borders of content area starting from connection row (row 2) to connect with tabs
        for row in 2..<frame.height {
            // Left border
            painter.goto(col: 0, row: row)
            painter.add(rune: driver.vLine)
            
            // Right border
            painter.goto(col: frame.width - 1, row: row)
            painter.add(rune: driver.vLine)
        }
        
        // Draw bottom border
        let bottomRow = frame.height - 1
        painter.goto(col: 0, row: bottomRow)
        painter.add(rune: driver.llCorner)
        for _ in 1..<frame.width - 1 {
            painter.add(rune: driver.hLine)
        }
        painter.add(rune: driver.lrCorner)
    }
    
    private func drawContentBorderBottom(painter: Painter) {
        // Draw top border
        painter.goto(col: 0, row: 0)
        painter.add(rune: driver.ulCorner)
        for _ in 1..<frame.width - 1 {
            painter.add(rune: driver.hLine)
        }
        painter.add(rune: driver.urCorner)
        
        // Draw left and right borders up to tab connection area
        let endRow = frame.height - 3 // Where bottom tabs connect
        for row in 1..<endRow {
            // Left border
            painter.goto(col: 0, row: row)
            painter.add(rune: driver.vLine)
            
            // Right border
            painter.goto(col: frame.width - 1, row: row)
            painter.add(rune: driver.vLine)
        }
    }
    
    private func drawContentBorderLeft(painter: Painter) {
        // Draw top border starting after tab width
        painter.goto(col: tabHeaderWidth, row: 0)
        painter.add(rune: driver.ulCorner)
        for _ in (tabHeaderWidth + 1)..<frame.width - 1 {
            painter.add(rune: driver.hLine)
        }
        painter.add(rune: driver.urCorner)
        
        // Draw left connection border at tab width
        for row in 1..<frame.height - 1 {
            painter.goto(col: tabHeaderWidth, row: row)
            painter.add(rune: driver.vLine)
        }
        
        // Draw right border
        for row in 1..<frame.height - 1 {
            painter.goto(col: frame.width - 1, row: row)
            painter.add(rune: driver.vLine)
        }
        
        // Draw bottom border
        let bottomRow = frame.height - 1
        painter.goto(col: tabHeaderWidth, row: bottomRow)
        painter.add(rune: driver.llCorner)
        for _ in (tabHeaderWidth + 1)..<frame.width - 1 {
            painter.add(rune: driver.hLine)
        }
        painter.add(rune: driver.lrCorner)
    }
    
    private func drawContentBorderRight(painter: Painter) {
        let contentEndCol = frame.width - tabHeaderWidth
        
        // Draw top border
        painter.goto(col: 0, row: 0)
        painter.add(rune: driver.ulCorner)
        for _ in 1..<contentEndCol  {
            painter.add(rune: driver.hLine)
        }
        // Connect top border to right connection border
        painter.goto(col: contentEndCol, row: 0)
        painter.add(rune: driver.urCorner)
        
        // Draw left border
        for row in 1..<frame.height - 1 {
            painter.goto(col: 0, row: row)
            painter.add(rune: driver.vLine)
        }
        
        // Draw right connection border at content end
        for row in 1..<frame.height - 1 {
            painter.goto(col: contentEndCol, row: row)
            painter.add(rune: driver.vLine)
        }
        
        // Draw bottom border
        let bottomRow = frame.height - 1
        painter.goto(col: 0, row: bottomRow)
        painter.add(rune: driver.llCorner)
        for _ in 1..<contentEndCol  {
            painter.add(rune: driver.hLine)
        }
        
        // Connect bottom border to right connection border
        painter.goto(col: contentEndCol, row: bottomRow)
        painter.add(rune: driver.lrCorner)
    }
    
    // MARK: - Additional Tab Drawing Methods
    
    private func drawPlainTabHeadersBottom(painter: Painter) {
        var col = 0
        let row = frame.height - 1
        let visibleRange = calculateVisibleTabsRange()
        let needsLeftScroll = firstVisibleTabIndex > 0
        let needsRightScroll = firstVisibleTabIndex + visibleRange.count < tabs.count
        
        // Draw left scroll indicator
        if needsLeftScroll {
            painter.attribute = colorScheme.normal
            painter.goto(col: col, row: row)
            painter.add(str: "<")
            col += 1
        }
        
        // Draw visible tabs
        for i in firstVisibleTabIndex..<min(tabs.count, firstVisibleTabIndex + visibleRange.count) {
            let tab = tabs[i]
            let isSelected = (i == selectedTabIndex)
            let isTabNavigating = isNavigatingTabs && isSelected && hasFocus
            
            // Set appropriate colors
            if isTabNavigating {
                painter.attribute = colorScheme.focus
            } else if isSelected {
                painter.attribute = colorScheme.hotNormal
            } else {
                painter.attribute = colorScheme.normal
            }
            
            painter.goto(col: col, row: row)
            let tabText = " \(tab.title) "
            painter.add(str: tabText)
            
            col += tabText.count
            
            if col >= frame.width - (needsRightScroll ? 1 : 0) {
                break
            }
        }
        
        // Draw right scroll indicator
        if needsRightScroll && col < frame.width {
            painter.attribute = colorScheme.normal
            painter.goto(col: frame.width - 1, row: row)
            painter.add(str: ">")
        }
    }
    
    private func drawBorderedTabHeadersBottom(painter: Painter) {
        var col = 0
        let startRow = frame.height - 3
        let visibleRange = calculateVisibleTabsRange()
        let needsLeftScroll = firstVisibleTabIndex > 0
        let needsRightScroll = firstVisibleTabIndex + visibleRange.count < tabs.count
        
        // Similar to top but at bottom - reverse the drawing order
        if needsLeftScroll {
            painter.attribute = colorScheme.normal
            painter.goto(col: col, row: startRow + 2)
            painter.add(str: "<")
            painter.goto(col: col, row: startRow + 1)
            painter.add(str: " ")
            col += 1
        }
        
        let visibleTabs = Array(tabs[firstVisibleTabIndex..<min(tabs.count, firstVisibleTabIndex + visibleRange.count)])
        var tabPositions: [(tab: Tab, col: Int, width: Int, index: Int)] = []
        
        for (visibleIndex, tab) in visibleTabs.enumerated() {
            let actualIndex = firstVisibleTabIndex + visibleIndex
            let isSelected = (actualIndex == selectedTabIndex)
            let isTabNavigating = isNavigatingTabs && isSelected && hasFocus
            let tabText = " \(tab.title) "
            let tabWidth = tabText.count + 2
            
            if col + tabWidth > frame.width - (needsRightScroll ? 1 : 0) {
                break
            }
            
            tabPositions.append((tab, col, tabWidth, actualIndex))
            
            // Draw bottom border
            painter.attribute = colorScheme.normal
            painter.goto(col: col, row: startRow + 2)
            painter.add(rune: driver.llCorner)
            for _ in 0..<(tabWidth - 2) {
                painter.add(rune: driver.hLine)
            }
            painter.add(rune: driver.lrCorner)
            
            // Draw tab text
            painter.attribute = colorScheme.normal
            painter.goto(col: col, row: startRow + 1)
            painter.add(rune: driver.vLine)
            
            if isTabNavigating {
                painter.attribute = colorScheme.focus
            } else if isSelected, hasFocus {
                painter.attribute = colorScheme.hotNormal  
            } else {
                painter.attribute = colorScheme.normal
            }
            painter.add(str: tabText)
            
            painter.attribute = colorScheme.normal
            painter.add(rune: driver.vLine)
            
            col += tabWidth
        }
        
        if needsRightScroll && col < frame.width {
            painter.attribute = colorScheme.normal
            painter.goto(col: frame.width - 1, row: startRow + 2)
            painter.add(str: ">")
            painter.goto(col: frame.width - 1, row: startRow + 1)
            painter.add(str: " ")
        }
        
        // Draw connection line
        painter.attribute = colorScheme.normal
        painter.goto(col: 0, row: startRow)
        for _ in 0..<frame.width {
            painter.add(rune: driver.hLine)
        }
        
        // Handle tab connections
        for (_, startCol, tabWidth, actualIndex) in tabPositions {
            let isSelected = (actualIndex == selectedTabIndex)
            
            if !isSelected {
                painter.goto(col: startCol, row: startRow)
                painter.add(rune: driver.topTee)
                painter.goto(col: startCol + tabWidth - 1, row: startRow)
                painter.add(rune: driver.topTee)
            } else {
                for col in startCol..<(startCol + tabWidth) {
                    painter.goto(col: col, row: startRow)
                    if col == startCol {
                        if startCol == 0 {
                            painter.add(rune: driver.vLine)
                        } else {
                            painter.add(rune: driver.urCorner)
                        }
                    } else if col == startCol + tabWidth - 1 {
                        if startCol + tabWidth >= frame.width {
                            painter.add(rune: driver.vLine)
                        } else {
                            painter.add(rune: driver.ulCorner)
                        }
                    } else {
                        painter.add(str: " ")
                    }
                }
            }
        }
    }
    
    private func drawPlainTabHeadersLeft(painter: Painter) {
        var row = 0
        let visibleRange = calculateVisibleTabsRangeVertical()
        let needsUpScroll = firstVisibleTabIndex > 0
        let needsDownScroll = firstVisibleTabIndex + visibleRange.count < tabs.count
        
        if needsUpScroll {
            painter.attribute = colorScheme.normal
            painter.goto(col: 0, row: row)
            painter.add(str: "^")
            row += 1
        }
        
        for i in firstVisibleTabIndex..<min(tabs.count, firstVisibleTabIndex + visibleRange.count) {
            let tab = tabs[i]
            let isSelected = (i == selectedTabIndex)
            let isTabNavigating = isNavigatingTabs && isSelected && hasFocus
            
            if isTabNavigating {
                painter.attribute = colorScheme.focus
            } else if isSelected {
                painter.attribute = colorScheme.hotNormal
            } else {
                painter.attribute = colorScheme.normal
            }
            
            painter.goto(col: 0, row: row)
            let tabText = " \(tab.title.padding(toLength: tabHeaderWidth - 2, withPad: " ", startingAt: 0)) "
            painter.add(str: String(tabText.prefix(tabHeaderWidth)))
            
            row += 1
            if row >= frame.height - (needsDownScroll ? 1 : 0) {
                break
            }
        }
        
        if needsDownScroll && row < frame.height {
            painter.attribute = colorScheme.normal
            painter.goto(col: 0, row: frame.height - 1)
            painter.add(str: "v")
        }
    }
    
    private func drawBorderedTabHeadersLeft(painter: Painter) {
        var row = 0
        let visibleRange = calculateVisibleTabsRangeVertical()
        let needsUpScroll = firstVisibleTabIndex > 0
        let needsDownScroll = firstVisibleTabIndex + visibleRange.count < tabs.count
        
        if needsUpScroll {
            painter.attribute = colorScheme.normal
            painter.goto(col: 0, row: row)
            painter.add(str: "^")
            row += 1
        }
        
        for i in firstVisibleTabIndex..<min(tabs.count, firstVisibleTabIndex + visibleRange.count) {
            let tab = tabs[i]
            let isSelected = (i == selectedTabIndex)
            let isTabNavigating = isNavigatingTabs && isSelected && hasFocus
            let tabText = " \(tab.title) "
            let paddedText = tabText.padding(toLength: tabHeaderWidth - 2, withPad: " ", startingAt: 0)
            
            // Draw top border
            painter.attribute = colorScheme.normal
            painter.goto(col: 0, row: row)
            painter.add(rune: driver.ulCorner)
            for _ in 1..<tabHeaderWidth  {
                painter.add(rune: driver.hLine)
            }
    
            if !isSelected {
                painter.add(rune: i == firstVisibleTabIndex ? driver.topTee : driver.rightTee)
            } else {
                painter.add(rune: i == firstVisibleTabIndex ? driver.hLine : driver.lrCorner)
            }
            row += 1
            
            // Draw text with borders
            painter.attribute = colorScheme.normal
            painter.goto(col: 0, row: row)
            painter.add(rune: driver.vLine)
            
            if isTabNavigating {
                painter.attribute = colorScheme.focus
            } else if isSelected {
                painter.attribute = colorScheme.hotNormal
            } else {
                painter.attribute = colorScheme.normal
            }
            painter.add(str: String(paddedText.prefix(tabHeaderWidth - 2)))
            painter.goto(col: tabHeaderWidth, row: row)
            if isSelected {
                painter.add(ch: " ")
            } else {
                painter.add(rune: driver.vLine)
            }

            painter.attribute = colorScheme.normal
            // For selected left tab, don't draw right border (opening to content)
            painter.add(str: " ") // Opening for selected tab
            row += 1
            
            // Draw bottom border
            painter.attribute = colorScheme.normal
            painter.goto(col: 0, row: row)
            painter.add(rune: driver.llCorner)
            for _ in 1..<tabHeaderWidth {
                painter.add(rune: driver.hLine)
            }
            if !isSelected {
                painter.add(rune: driver.rightTee)
            } else {
                painter.add(rune: driver.urCorner)
            }
            row += 1
            
            if row >= frame.height - (needsDownScroll ? 2 : 0) {
                break
            }
        }
        
        if needsDownScroll && row < frame.height {
            painter.attribute = colorScheme.normal
            painter.goto(col: 0, row: frame.height - 1)
            painter.add(str: "v")
        }
        
    }
    
    private func drawPlainTabHeadersRight(painter: Painter) {
        var row = 0
        let col = frame.width - tabHeaderWidth
        let visibleRange = calculateVisibleTabsRangeVertical()
        let needsUpScroll = firstVisibleTabIndex > 0
        let needsDownScroll = firstVisibleTabIndex + visibleRange.count < tabs.count
        
        if needsUpScroll {
            painter.attribute = colorScheme.normal
            painter.goto(col: frame.width - 1, row: row)
            painter.add(str: "^")
            row += 1
        }
        
        for i in firstVisibleTabIndex..<min(tabs.count, firstVisibleTabIndex + visibleRange.count) {
            let tab = tabs[i]
            let isSelected = (i == selectedTabIndex)
            let isTabNavigating = isNavigatingTabs && isSelected && hasFocus
            
            if isTabNavigating {
                painter.attribute = colorScheme.focus
            } else if isSelected {
                painter.attribute = colorScheme.hotNormal
            } else {
                painter.attribute = colorScheme.normal
            }
            
            painter.goto(col: col, row: row)
            let tabText = " \(tab.title.padding(toLength: tabHeaderWidth - 2, withPad: " ", startingAt: 0)) "
            painter.add(str: String(tabText.prefix(tabHeaderWidth)))
            
            row += 1
            if row >= frame.height - (needsDownScroll ? 1 : 0) {
                break
            }
        }
        
        if needsDownScroll && row < frame.height {
            painter.attribute = colorScheme.normal
            painter.goto(col: frame.width - 1, row: frame.height - 1)
            painter.add(str: "v")
        }
    }
    
    private func drawBorderedTabHeadersRight(painter: Painter) {
        var row = 0
        let startCol = frame.width - tabHeaderWidth
        let visibleRange = calculateVisibleTabsRangeVertical()
        let needsUpScroll = firstVisibleTabIndex > 0
        let needsDownScroll = firstVisibleTabIndex + visibleRange.count < tabs.count
        
        if needsUpScroll {
            painter.attribute = colorScheme.normal
            painter.goto(col: frame.width - 1, row: row)
            painter.add(str: "^")
            row += 1
        }
        
        for i in firstVisibleTabIndex..<min(tabs.count, firstVisibleTabIndex + visibleRange.count) {
            let tab = tabs[i]
            let isSelected = (i == selectedTabIndex)
            let isTabNavigating = isNavigatingTabs && isSelected && hasFocus
            let tabText = " \(tab.title) "
            let paddedText = tabText.padding(toLength: tabHeaderWidth - 2, withPad: " ", startingAt: 0)
            
            // Draw top border
            painter.attribute = colorScheme.normal
            painter.goto(col: startCol, row: row)
            // For selected right tab, don't draw top-left corner (opening to content)
            if !isSelected {
                painter.add(rune: i == firstVisibleTabIndex ? driver.topTee : driver.leftTee)
            } else {
                painter.add(rune: i == firstVisibleTabIndex ? driver.hLine : driver.llCorner)
            }
            for _ in 1..<tabHeaderWidth - 1 {
                painter.add(rune: driver.hLine)
            }
            painter.add(rune: driver.urCorner)
            row += 1
            
            // Draw text with borders
            painter.attribute = colorScheme.normal
            painter.goto(col: startCol, row: row)
            // For selected right tab, don't draw left border (opening to content)
            if !isSelected {
                painter.add(rune: driver.vLine)
            } else {
                painter.add(ch: " ") // Opening for selected tab
            }
            
            if isTabNavigating {
                painter.attribute = colorScheme.focus
            } else if isSelected {
                painter.attribute = colorScheme.hotNormal
            } else {
                painter.attribute = colorScheme.normal
            }
            painter.add(str: String(paddedText.prefix(tabHeaderWidth - 2)))
            
            painter.attribute = colorScheme.normal
            painter.add(rune: driver.vLine)
            row += 1
            
            // Draw bottom border
            painter.attribute = colorScheme.normal
            painter.goto(col: startCol, row: row)
            if !isSelected {
                painter.add(rune: driver.leftTee)
            } else {
                painter.add(rune: driver.ulCorner)
            }
            for _ in 1..<tabHeaderWidth - 1 {
                painter.add(rune: driver.hLine)
            }
            painter.add(rune: driver.lrCorner)
            row += 1
            
            if row >= frame.height - (needsDownScroll ? 2 : 0) {
                break
            }
        }
        
        if needsDownScroll && row < frame.height {
            painter.attribute = colorScheme.normal
            painter.goto(col: frame.width - 1, row: frame.height - 1)
            painter.add(str: "v")
        }
    }
    
    private func calculateVisibleTabsRangeVertical() -> (count: Int, lastIndex: Int) {
        guard tabs.count > 0 else { return (0, 0) }
        
        let availableHeight = frame.height
        var currentHeight = 0
        var visibleCount = 0
        
        let needsUpScroll = firstVisibleTabIndex > 0
        let upScrollHeight = needsUpScroll ? 1 : 0
        
        // Calculate how many tabs can fit
        let tabHeight = (tabStyle == .bordered) ? 3 : 1
        let usableHeight = availableHeight - upScrollHeight
        
        for _ in firstVisibleTabIndex..<tabs.count {
            if currentHeight + tabHeight > usableHeight {
                break
            }
            currentHeight += tabHeight
            visibleCount += 1
        }
        
        // Check if we need down scroll and adjust if necessary
        let needsDownScroll = (firstVisibleTabIndex + visibleCount < tabs.count)
        if needsDownScroll && visibleCount > 0 {
            // Reserve space for down scroll indicator
            let finalUsableHeight = availableHeight - upScrollHeight - 1
            currentHeight = 0
            visibleCount = 0
            
            for _ in firstVisibleTabIndex..<tabs.count {
                if currentHeight + tabHeight > finalUsableHeight {
                    break
                }
                currentHeight += tabHeight
                visibleCount += 1
            }
        }
        
        return (max(1, visibleCount), firstVisibleTabIndex + max(1, visibleCount) - 1)
    }
    
    private func calculateVisibleTabsRangeVerticalFrom(_ startIndex: Int) -> (count: Int, lastIndex: Int) {
        guard startIndex >= 0 && startIndex < tabs.count else { return (0, 0) }
        
        let availableHeight = frame.height
        var currentHeight = 0
        var visibleCount = 0
        
        let needsUpScroll = startIndex > 0
        let upScrollHeight = needsUpScroll ? 1 : 0
        
        // Calculate how many tabs can fit
        let tabHeight = (tabStyle == .bordered) ? 3 : 1
        let usableHeight = availableHeight - upScrollHeight
        
        for _ in startIndex..<tabs.count {
            if currentHeight + tabHeight > usableHeight {
                break
            }
            currentHeight += tabHeight
            visibleCount += 1
        }
        
        // Check if we need down scroll and adjust if necessary
        let needsDownScroll = (startIndex + visibleCount < tabs.count)
        if needsDownScroll && visibleCount > 0 {
            // Reserve space for down scroll indicator
            let finalUsableHeight = availableHeight - upScrollHeight - 1
            currentHeight = 0
            visibleCount = 0
            
            for _ in startIndex..<tabs.count {
                if currentHeight + tabHeight > finalUsableHeight {
                    break
                }
                currentHeight += tabHeight
                visibleCount += 1
            }
        }
        
        return (max(1, visibleCount), startIndex + max(1, visibleCount) - 1)
    }
    
    // MARK: - Input Handling
    
    public override func processHotKey(event: KeyEvent) -> Bool {
        guard tabs.count > 0 else { return false }
        
        if isNavigatingTabs {
            // TODO: add support for hot-labels in the tabs
            return false
        }
        return tabs[selectedTabIndex].content.processHotKey(event: event)
    }
    
    public override func processColdKey(event: KeyEvent) -> Bool {
        guard tabs.count > 0 else { return false }
        
        if isNavigatingTabs {
            // TODO: add support for hot-labels in the tabs
            return false
        }
        return tabs[selectedTabIndex].content.processColdKey(event: event)
    }
    
    public override func processKey(event: KeyEvent) -> Bool {
        guard tabs.count > 0 else { return false }
        
        // If we're navigating tabs (tab headers have focus)
        if isNavigatingTabs {
            return handleTabNavigationKey(event: event)
        }
        
        // If we're in tab content
        return handleContentNavigationKey(event: event)
    }
    
    private func handleTabNavigationKey(event: KeyEvent) -> Bool {
        switch (tabPosition, event.key) {
        case (.top, .cursorLeft), (.bottom, .cursorLeft), (.left, .cursorUp), (.right, .cursorUp):
            if selectedTabIndex > 0 {
                selectTab(selectedTabIndex - 1)
                setNeedsDisplay()
                return true
            }
            return false
            
        case (.top, .cursorRight), (.bottom, .cursorRight), (.left, .cursorDown), (.right, .cursorDown):
            if selectedTabIndex < tabs.count - 1 {
                selectTab(selectedTabIndex + 1)
                setNeedsDisplay()
                return true
            }
            return false
            
        case (.top, .cursorDown), (.bottom, .cursorUp), (.left, .cursorRight), (.right, .cursorLeft):
            isNavigatingTabs = false
            focusTabContent()
            setNeedsDisplay()
            return true
            
        case (_, .controlM): // Enter key
            isNavigatingTabs = false
            focusTabContent()
            setNeedsDisplay()
            return true
            
        case (_, .esc):
            // Give up focus to parent
            isNavigatingTabs = false
            return false
            
        default:
            return false
        }
    }
    
    private func handleContentNavigationKey(event: KeyEvent) -> Bool {
        // Let the content handle the key
        return tabs[selectedTabIndex].content.processKey(event: event)
    }
    
    private func getCurrentFocused() -> View? {
        // This is a simplified version - in practice, you'd need to track focus properly
        return tabs[selectedTabIndex].content.subviews.first { $0.hasFocus }
    }
    
    public override func mouseEvent(event: MouseEvent) -> Bool {
        if event.flags.contains(.button1Clicked) {
            switch tabPosition {
            case .top:
                if event.pos.y < tabHeaderHeight {
                    return handleTabClick(at: event.pos.x, row: event.pos.y)
                }
            case .bottom:
                if event.pos.y >= frame.height - tabHeaderHeight {
                    return handleTabClick(at: event.pos.x, row: event.pos.y)
                }
            case .left:
                if event.pos.x < tabHeaderWidth {
                    return handleTabClick(at: event.pos.x, row: event.pos.y)
                }
            case .right:
                if event.pos.x >= frame.width - tabHeaderWidth {
                    return handleTabClick(at: event.pos.x, row: event.pos.y)
                }
            }
        }
        
        return super.mouseEvent(event: event)
    }
    
    private func handleTabClick(at x: Int, row y: Int) -> Bool {
        switch tabPosition {
        case .top, .bottom:
            return handleHorizontalTabClick(at: x)
        case .left, .right:
            return handleVerticalTabClick(at: y)
        }
    }
    
    private func handleHorizontalTabClick(at x: Int) -> Bool {
        var col = 0
        let visibleRange = calculateVisibleTabsRange()
        let needsLeftScroll = firstVisibleTabIndex > 0
        let needsRightScroll = firstVisibleTabIndex + visibleRange.count < tabs.count
        
        // Handle left scroll indicator click
        if needsLeftScroll && x == 0 {
            firstVisibleTabIndex = max(0, firstVisibleTabIndex - 1)
            setNeedsDisplay()
            return true
        }
        
        // Adjust starting column for left scroll indicator
        if needsLeftScroll {
            col = 1
        }
        
        // Handle visible tab clicks
        for i in firstVisibleTabIndex..<min(tabs.count, firstVisibleTabIndex + visibleRange.count) {
            let tab = tabs[i]
            let tabText = " \(tab.title) "
            let tabWidth = (tabStyle == .bordered) ? tabText.count + 2 : tabText.count
            
            if col + tabWidth > frame.width - (needsRightScroll ? 1 : 0) {
                break
            }
            
            if x >= col && x < col + tabWidth {
                selectTab(i)
                isNavigatingTabs = false
                focusTabContent()
                setNeedsDisplay()
                return true
            }
            
            col += tabWidth
        }
        
        // Handle right scroll indicator click
        if needsRightScroll && x == frame.width - 1 {
            let maxFirstVisible = max(0, tabs.count - visibleRange.count)
            firstVisibleTabIndex = min(maxFirstVisible, firstVisibleTabIndex + 1)
            setNeedsDisplay()
            return true
        }
        
        return false
    }
    
    private func handleVerticalTabClick(at y: Int) -> Bool {
        var row = 0
        let visibleRange = calculateVisibleTabsRangeVertical()
        let needsUpScroll = firstVisibleTabIndex > 0
        let needsDownScroll = firstVisibleTabIndex + visibleRange.count < tabs.count
        let tabHeight = (tabStyle == .bordered) ? 3 : 1
        
        // Handle up scroll indicator click
        if needsUpScroll && y == 0 {
            firstVisibleTabIndex = max(0, firstVisibleTabIndex - 1)
            setNeedsDisplay()
            return true
        }
        
        // Adjust starting row for up scroll indicator
        if needsUpScroll {
            row = 1
        }
        
        // Handle visible tab clicks
        for i in firstVisibleTabIndex..<min(tabs.count, firstVisibleTabIndex + visibleRange.count) {
            if y >= row && y < row + tabHeight {
                selectTab(i)
                isNavigatingTabs = false
                focusTabContent()
                setNeedsDisplay()
                return true
            }
            
            row += tabHeight
            if row >= frame.height - (needsDownScroll ? 1 : 0) {
                break
            }
        }
        
        // Handle down scroll indicator click
        if needsDownScroll && y == frame.height - 1 {
            let maxFirstVisible = max(0, tabs.count - visibleRange.count)
            firstVisibleTabIndex = min(maxFirstVisible, firstVisibleTabIndex + 1)
            setNeedsDisplay()
            return true
        }
        
        return false
    }
    
    // MARK: - Focus Management
    
    public override func becomeFirstResponder() -> Bool {
        log("DEBUG TabView.becomeFirstResponder: Setting isNavigatingTabs = true, hasFocus was: \(hasFocus)")
        
        // Set tab navigation mode FIRST and make sure it stays that way
        if focused == nil {
            isNavigatingTabs = true
        }
        
        // Handle focus state manually to avoid parent class complications
        _hasFocus = true
        
        // Notify superview manually 
        if let sup = superview {
            if sup.focused != self {
                sup.setFocus(self)
            }
        }
        
        log("DEBUG TabView.becomeFirstResponder: Manually set focus, isNavigatingTabs = \(isNavigatingTabs), hasFocus now: \(hasFocus)")
        setNeedsDisplay()
        
        return true
    }
    
    public override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            isNavigatingTabs = false
            setNeedsDisplay()
        }
        return result
    }
    
    public override func positionCursor() {
        if isNavigatingTabs && selectedTabIndex >= 0 && selectedTabIndex < tabs.count {
            // Position cursor on the first letter of the selected tab's title
            let cursorPosition = calculateSelectedTabCursorPosition()
            moveTo(col: cursorPosition.x, row: cursorPosition.y)
        } else {
            // When not navigating tabs, use default behavior or delegate to content
            if let focused = focused {
                focused.positionCursor()
            } else {
                super.positionCursor()
            }
        }
    }
    
    private func calculateSelectedTabCursorPosition() -> Point {
        switch tabPosition {
        case .top, .bottom:
            return calculateHorizontalTabCursorPosition()
        case .left, .right:
            return calculateVerticalTabCursorPosition()
        }
    }
    
    private func calculateHorizontalTabCursorPosition() -> Point {
        var col = 0
        let visibleRange = calculateVisibleTabsRange()
        let needsLeftScroll = firstVisibleTabIndex > 0
        let row = tabPosition == .top ? 0 : frame.height - tabHeaderHeight
        
        // Account for left scroll indicator
        if needsLeftScroll {
            col += 1
        }
        
        // Find the selected tab's position
        for i in firstVisibleTabIndex..<min(tabs.count, firstVisibleTabIndex + visibleRange.count) {
            if i == selectedTabIndex {
                // Found the selected tab, calculate cursor position within it
                if tabStyle == .bordered {
                    // For bordered tabs: cursor goes on first letter inside the border
                    // Tab structure: |ulCorner hLine* urCorner|
                    //                |vLine SPACE title SPACE vLine| <- cursor on first letter of title
                    return Point(x: col + 2, y: row + 1) // +1 for vLine, +1 for space
                } else {
                    // For plain tabs: cursor goes on first letter of title 
                    // Tab structure: SPACE title SPACE <- cursor on first letter of title
                    return Point(x: col + 1, y: row) // +1 for the leading space
                }
            }
            
            // Move past this tab
            let tabText = " \(tabs[i].title) "
            let tabWidth = (tabStyle == .bordered) ? tabText.count + 2 : tabText.count
            col += tabWidth
        }
        
        // Fallback: position at start of tab area
        return Point(x: col, y: tabStyle == .bordered ? row + 1 : row)
    }
    
    private func calculateVerticalTabCursorPosition() -> Point {
        var row = 0
        let visibleRange = calculateVisibleTabsRangeVertical()
        let needsUpScroll = firstVisibleTabIndex > 0
        let tabHeight = (tabStyle == .bordered) ? 3 : 1
        let col = tabPosition == .left ? 0 : frame.width - tabHeaderWidth
        
        // Account for up scroll indicator
        if needsUpScroll {
            row += 1
        }
        
        // Find the selected tab's position
        for i in firstVisibleTabIndex..<min(tabs.count, firstVisibleTabIndex + visibleRange.count) {
            if i == selectedTabIndex {
                // Found the selected tab, calculate cursor position within it
                if tabStyle == .bordered {
                    // For bordered tabs: cursor goes on first letter inside the border
                    return Point(x: col + 1, y: row + 1) // +1 for border
                } else {
                    // For plain tabs: cursor goes on first letter of title 
                    return Point(x: col + 1, y: row) // +1 for the leading space
                }
            }
            
            row += tabHeight
            if row >= frame.height - (firstVisibleTabIndex + visibleRange.count < tabs.count ? 1 : 0) {
                break
            }
        }
        
        // Fallback: position at start of tab area
        return Point(x: col + (tabStyle == .bordered ? 1 : 1), y: row)
    }
    
    // MARK: - Focus Handling
    
    override public func focusNext() -> Bool {
        guard tabs.count > 0 else { return false }
        
        if isNavigatingTabs {
            // Focus the content of the selected tab
            isNavigatingTabs = false
            focusTabContent()
            return true
        } else {
            // Try to advance focus within current tab
            let currentTab = tabs[selectedTabIndex]
            if currentTab.content.focusNext() {
                return true
            }
            
            // If we can't advance within current tab, continue with normal hierarchy focus
            // instead of switching tabs - let the parent handle focus navigation
            return false
        }
    }
    
    override public func focusPrev() -> Bool {
        guard tabs.count > 0 else { return false }
        
        if isNavigatingTabs {
            // Give up focus to parent
            return false
        } else {
            // Try to go backward within current tab
            let currentTab = tabs[selectedTabIndex]
            if currentTab.content.focusPrev() {
                return true
            }
            
            // If we can't go backward within current tab, continue with normal hierarchy focus
            // instead of switching tabs - let the parent handle focus navigation
            isNavigatingTabs = true
            return true
        }
    }
}
