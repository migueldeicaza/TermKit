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
    public var tabStyle: TabStyle = .plain {
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
            contentFrame = Rect(
                x: 1,
                y: tabHeaderHeight,
                width: frame.width - 2,
                height: frame.height - tabHeaderHeight - 1
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
        if !isNavigatingTabs && hasFocus {
            focusTabContent()
        }
    }
    
    private func ensureSelectedTabVisible() {
        guard tabs.count > 0 else { return }
        
        // Calculate visible tabs range
        let visibleRange = calculateVisibleTabsRange()
        
        // If selected tab is before visible range, scroll left
        if selectedTabIndex < firstVisibleTabIndex {
            firstVisibleTabIndex = selectedTabIndex
        }
        // If selected tab is after visible range, scroll right
        else if selectedTabIndex >= firstVisibleTabIndex + visibleRange.count {
            firstVisibleTabIndex = max(0, selectedTabIndex - visibleRange.count + 1)
        }
        
        // Ensure we don't scroll past the beginning
        firstVisibleTabIndex = max(0, firstVisibleTabIndex)
        
        // Ensure we don't scroll past the end unnecessarily
        if firstVisibleTabIndex + visibleRange.count >= tabs.count {
            firstVisibleTabIndex = max(0, tabs.count - visibleRange.count)
        }
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
            contentFrame = Rect(
                x: 1,
                y: tabHeaderHeight,
                width: frame.width - 2,
                height: frame.height - tabHeaderHeight - 1
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
        guard selectedTabIndex >= 0 && selectedTabIndex < tabs.count else { return }
        let content = tabs[selectedTabIndex].content
        
        // Try to find the first focusable view in the content
        if let focusable = findFirstFocusable(in: content) {
            // Set focus on the content view, which will pass focus to the focusable child
            content.setFocus(focusable)
        } else {
            // If no focusable child found, try to focus the content view itself
            if content.canFocus {
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
        painter.clear()
        
        // Draw content area border for bordered style FIRST
        if tabStyle == .bordered {
            drawContentBorder(painter: painter)
        }
        
        drawTabHeaders(painter: painter)
        
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
            
            // Set appropriate colors - only highlight when navigating tabs, not when selected
            if isTabNavigating {
                painter.attribute = colorScheme.focus
            } else {
                painter.attribute = colorScheme.normal
            }
            
            // Draw top border
            painter.goto(col: col, row: 0)
            painter.add(rune: driver.ulCorner)
            for _ in 0..<(tabWidth - 2) {
                painter.add(rune: driver.hLine)
            }
            painter.add(rune: driver.urCorner)
            
            // Draw tab content
            painter.goto(col: col, row: 1)
            painter.add(rune: driver.vLine)
            painter.add(str: tabText)
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
        
        // Third pass: draw continuous horizontal line on row 2, then tab connections
        painter.attribute = colorScheme.normal
        
        // Draw continuous horizontal line on row 2, but leave edges for content border connections
        painter.goto(col: 1, row: 2)
        for _ in 1..<(frame.width - 1) {
            painter.add(rune: driver.hLine)
        }
        
        // Draw the content border connections at the edges
        painter.goto(col: 0, row: 2)
        painter.add(rune: driver.vLine)
        painter.goto(col: frame.width - 1, row: 2)
        painter.add(rune: driver.vLine)
        
        // Fourth pass: draw tab-specific connections on row 2
        for (_, startCol, tabWidth, actualIndex) in tabPositions {
            let isSelected = (actualIndex == selectedTabIndex)
            
            if !isSelected {
                // For non-selected tabs, use appropriate connections
                painter.goto(col: startCol, row: 2)
                if startCol == 0 {
                    // Left edge: connects to content border - use rightTee
                    painter.add(rune: driver.rightTee)  // ├
                } else {
                    // Not left edge: connects to horizontal line - use bottomTee
                    painter.add(rune: driver.bottomTee)  // ┴
                }
                
                painter.goto(col: startCol + tabWidth - 1, row: 2)
                if startCol + tabWidth - 1 == frame.width - 1 {
                    // Right edge: connects to content border - use leftTee
                    painter.add(rune: driver.leftTee)  // ┤
                } else {
                    // Not right edge: connects to horizontal line - use bottomTee
                    painter.add(rune: driver.bottomTee)  // ┴
                }
                
            } else {
                // For selected tab, draw connecting border on row 2 to link to content area
                painter.goto(col: startCol, row: 2)
                
                // Left connection
                if startCol == 0 {
                    // First tab: connect straight down to content border
                    painter.add(rune: driver.vLine)
                } else {
                    // Not first tab: draw corner to connect from tab to content area
                    painter.add(rune: driver.lrCorner)
                }
                
                // Middle spaces (the opening)
                for _ in 0..<(tabWidth - 2) {
                    painter.add(str: " ")
                }
                
                // Right connection  
                if startCol + tabWidth >= frame.width {
                    // Last tab: connect straight down to content border
                    painter.add(rune: driver.vLine)
                } else {
                    // Not last tab: draw corner to connect from tab to content area
                    painter.add(rune: driver.llCorner)
                }
            }
        }
    }
    
    private func drawContentBorder(painter: Painter) {
        painter.attribute = colorScheme.normal
        
        // For bordered style with tabHeaderHeight = 3:
        // Row 0: Top border of tabs (┌─┐)
        // Row 1: Text content of tabs (│text│)  
        // Row 2: Bottom of tabs (└─┘ for non-selected, spaces for selected)
        // Row 3+: Content area borders
        
        // Draw left and right borders of content area starting from connection row (row 2)
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
        // Check if we should switch to tab navigation
        if event.key == .cursorUp {
            // Always go to tab navigation mode when pressing up
            isNavigatingTabs = true
            setNeedsDisplay()
            return true
        }
        
        // Let the content handle the key
        return false
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
        let result = super.becomeFirstResponder()
        if result {
            isNavigatingTabs = true
            setNeedsDisplay()
        }
        return result
    }
    
    public override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            isNavigatingTabs = false
            setNeedsDisplay()
        }
        return result
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
            
            // If we can't advance within current tab, try next tab
            if selectedTabIndex < tabs.count - 1 {
                selectTab(selectedTabIndex + 1)
                // Only focus content if we're not in tab navigation mode
                if !isNavigatingTabs {
                    focusTabContent()
                }
                return true
            }
            
            // No more tabs, give up focus
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
            
            // If we can't go backward within current tab, try previous tab
            if selectedTabIndex > 0 {
                selectTab(selectedTabIndex - 1)
                // Only focus content if we're not in tab navigation mode
                if !isNavigatingTabs {
                    if let lastFocusable = findLastFocusable(in: tabs[selectedTabIndex].content) {
                        lastFocusable.superview?.setFocus(lastFocusable)
                    }
                }
                return true
            }
            
            // No previous tabs, navigate to tab headers
            isNavigatingTabs = true
            setNeedsDisplay()
            return true
        }
    }
}
