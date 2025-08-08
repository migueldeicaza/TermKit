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
    private var isNavigatingTabs: Bool = false
    private var firstVisibleTabIndex: Int = 0
    
    /// The style used to render tabs
    public var tabStyle: TabStyle = .bordered {
        didSet {
            tabHeaderHeight = (tabStyle == .bordered) ? 3 : 1
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
    }
    
    public override init(frame: Rect) {
        super.init(frame: frame)
        canFocus = true
        wantContinuousButtonPressed = true
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
        
        // Set the frame and force a layout update
        let contentFrame: Rect
        if tabStyle == .bordered {
            // Account for border padding in bordered mode
            // Content starts after tab area (tabHeaderHeight = 3) + 1 more row for proper spacing
            contentFrame = Rect(
                x: 1,
                y: tabHeaderHeight + 1,
                width: frame.width - 2,
                height: frame.height - tabHeaderHeight - 2
            )
        } else {
            contentFrame = Rect(
                x: 0,
                y: tabHeaderHeight,
                width: frame.width,
                height: frame.height - tabHeaderHeight
            )
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
        let currentVisibleRange = calculateVisibleTabsRange()
        let lastVisibleIndex = firstVisibleTabIndex + currentVisibleRange.count - 1
        
        // If the selected tab is already fully visible, don't scroll at all
        if selectedTabIndex >= firstVisibleTabIndex && selectedTabIndex <= lastVisibleIndex {
            return
        }
        
        // Only scroll if the selected tab is actually outside the visible range
        
        if selectedTabIndex < firstVisibleTabIndex {
            // Selected tab is to the left of visible range - scroll left
            firstVisibleTabIndex = selectedTabIndex
        } else if selectedTabIndex > lastVisibleIndex {
            // Selected tab is to the right of visible range - scroll right
            // Try to make it the last visible tab
            firstVisibleTabIndex = selectedTabIndex
            
            // Adjust backwards until we can fit the selected tab and as many others as possible
            while firstVisibleTabIndex > 0 {
                let testRange = calculateVisibleTabsRangeFrom(firstVisibleTabIndex - 1)
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
    
    private func layoutTabs() {
        guard tabs.count > 0 && selectedTabIndex >= 0 && selectedTabIndex < tabs.count else { return }
        
        // Only layout the currently selected tab since it's the only one added as subview
        let contentFrame: Rect
        if tabStyle == .bordered {
            // Account for border padding in bordered mode
            // Content starts after tab area (tabHeaderHeight = 3) + 1 more row for proper spacing
            contentFrame = Rect(
                x: 1,
                y: tabHeaderHeight + 1,
                width: frame.width - 2,
                height: frame.height - tabHeaderHeight - 2
            )
        } else {
            contentFrame = Rect(
                x: 0,
                y: tabHeaderHeight,
                width: frame.width,
                height: frame.height - tabHeaderHeight
            )
        }
        
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
        
        switch tabStyle {
        case .plain:
            drawPlainTabHeaders(painter: painter)
        case .bordered:
            drawBorderedTabHeaders(painter: painter)
        }
    }
    
    private func drawPlainTabHeaders(painter: Painter) {
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
    
    private func drawBorderedTabHeaders(painter: Painter) {
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
        switch event.key {
        case .cursorLeft:
            if selectedTabIndex > 0 {
                selectTab(selectedTabIndex - 1)
                setNeedsDisplay()
            }
            return true
            
        case .cursorRight:
            if selectedTabIndex < tabs.count - 1 {
                selectTab(selectedTabIndex + 1)
                setNeedsDisplay()
            }
            return true
            
        case .cursorDown, .controlM: // Enter key
            isNavigatingTabs = false
            focusTabContent()
            setNeedsDisplay()
            return true
            
        case .esc:
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
        if event.flags.contains(.button1Clicked) && event.pos.y < tabHeaderHeight {
            return handleTabClick(at: event.pos.x)
        }
        
        return super.mouseEvent(event: event)
    }
    
    private func handleTabClick(at x: Int) -> Bool {
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
        var col = 0
        let visibleRange = calculateVisibleTabsRange()
        let needsLeftScroll = firstVisibleTabIndex > 0
        
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
                    return Point(x: col + 2, y: 1) // +1 for vLine, +1 for space
                } else {
                    // For plain tabs: cursor goes on first letter of title 
                    // Tab structure: SPACE title SPACE <- cursor on first letter of title
                    return Point(x: col + 1, y: 0) // +1 for the leading space
                }
            }
            
            // Move past this tab
            let tabText = " \(tabs[i].title) "
            let tabWidth = (tabStyle == .bordered) ? tabText.count + 2 : tabText.count
            col += tabWidth
        }
        
        // Fallback: position at start of tab area
        return Point(x: col, y: tabStyle == .bordered ? 1 : 0)
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
