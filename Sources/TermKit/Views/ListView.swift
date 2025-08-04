//
//  ListView.swift
//  TermKit
//
//  Created by Miguel de Icaza on 5/23/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//
// TODO:
//   - Mouse, toggle selection
//   - Mouse, activate
//   - leftColumn: the first column to render
//   - scroll left/right
//

import Foundation

public protocol ListViewDataSource {
    func getCount (listView: ListView) -> Int
    func isMarked (listView: ListView, item: Int) -> Bool
    func setMark (listView: ListView, item: Int, state: Bool)
}

public protocol ListViewDelegate {
    /// Method invoked to render one item on the ListView.
    ///
    /// This method should take into account both the `selected` state, which will be true,
    /// if this is being called to render a line that currently has the cursor selection, or false if
    /// it is just another row.
    ///
    /// In addition, this method needs to probe listView.hasFocus to determine if the listview
    /// is focused, if so, it should use the proper color from the ColorScheme to draw attention
    /// to the ListView and its selected element.
    /// 
    /// - Parameters:
    ///   - listView: The source list view being drawn
    ///   - painter: painter object that can be used to draw
    ///   - selected: whether the line should be rendered as selected
    ///   - item: the index of the item to render
    ///   - col: The column where the rendering will take place
    ///   - line: The line where the rendering will take place
    ///   - width: The total number of columns to render
    func render (listView: ListView, painter: Painter, selected: Bool, item: Int, col: Int, line: Int, width: Int)
    
    /// This method is invoked when the currently selected item has changed
    func selectionChanged (listView: ListView)
    
    /// Invoked when the return key has been pressed while on the ListView
    /// - Parameters:
    ///   - listView: the listview that is raising the event
    ///   - item: The item that was postiioned
    /// - Returns: should return true if handled, otherwise false
    func activate (listView: ListView, item: Int) -> Bool
}

/**
 * ListView is a control used to displays rows of data.
 *
 * # Initialization
 *
 * The ListView offers both easy to use, as well as customizable options for the data being rendered.
 * For very simple scenarios there is a constructor that takes an array of strings, and provides a way of
 * rendering those, and selecting those (the selection can be retrieved through the API).
 *
 * If you desire to customize the rendering of the data, or if your data is not a string, a separate constructor
 * takes both a ListViewDataSource instance, which is used to describe your information to display, as well
 * as a rendering method that is invoked to render every line on demand and is expected to return a string,
 * which is in turn rendered.
 *
 * A more advanced method requires both the datasource and the delegate to be specified, in this scenario,
 * you can control directly how the contents of your data source are rendered.
 *
 * To scroll to a particular place, you can set the "topItem" property.
 *
 * You can set the `selectedMarker` property to a string value if you want to show a visual indicator
 * of where the seleciton is.   For example, it could be something like ">" or an emoji of your choice.
 *
 * You can also set the `markerStrings` to an array of two strings to control which character is used
 * to show markers
 */
open class ListView: View {
    var top: Int = 0
    var selected: Int = 0
    
    /// If set, this allows the elements on the list to be marked
    /// If true, this will render the items with the mark strings
    public var allowMarking: Bool = true {
        didSet { setNeedsDisplay () }
    }

    /// If set, allows multiple items to be selected
    public var allowsMultipleSelection: Bool = true {
        didSet {
            if allowsMultipleSelection == false {
                clearMarks ()
            }
        }
    }
    
    var selectedMarkerEmpty: String = ""
    var selectedMarkerCount: Int = 0
    /// If set, uses this as the visual aid to show for the selected row for simple rendering
    public var selectedMarker: String? = nil {
        didSet {
            if let m = selectedMarker {
                selectedMarkerCount = m.cellCount()
                selectedMarkerEmpty = String (repeating: " ", count: selectedMarkerCount)
            } else {
                selectedMarkerEmpty = ""
            }
        }
    }

    var markerCount: Int = 0
    /// An array of two strings with the unmarked, marked values, defaults to [" ", "*"], the first array value
    /// is for items that are not marked, the second is for items that are marked.
    public var markerStrings: [String] = [" ", "*"] {
        didSet {
            if markerStrings.count != 2 {
                markerStrings = [" ", "*"]
            }
            markerCount = markerStrings [0].cellCount()
        }
    }

    class RenderDelegate: ListViewDelegate {
        func selectionChanged(listView: ListView) {
            
        }
        
        func activate(listView: ListView, item: Int) -> Bool {
            return false
        }
        
        var render: ((_ row: Int, _ width: Int) -> String)
        
        init (_ render: @escaping ((_ row: Int, _ width: Int) -> String))
        {
            self.render = render
        }
        
        func render (
            listView: ListView,
            painter: Painter,
            selected: Bool,
            item: Int,
            col: Int,
            line: Int,
            width: Int
        )
        {
            let txt = render (item, width-listView.selectedMarkerCount)
            let count = txt.cellCount()
            painter.goto (col: col, row: line)
            painter.attribute = listView.hasFocus && selected ? listView.colorScheme.focus : listView.colorScheme.normal
            if let m = listView.selectedMarker {
                if selected {
                    painter.add(str: m)
                } else {
                    painter.add(str: listView.selectedMarkerEmpty)
                }
            }
            painter.add (str: txt)
            if count < width {
                let space = UnicodeScalar(" ")
                for _ in count..<width {
                    painter.add(rune: space)
                }
            }
        }
    }
    
    class StringWrapperDataSource: ListViewDataSource {
        var src: [String]
        var marks: [Int:Bool] = [:]
        
        init (_ src: [String]) {
            self.src = src
        }
        func getCount(listView: ListView) -> Int {
            src.count
        }
        
        func isMarked(listView: ListView, item: Int) -> Bool {
            return marks [item] ?? false
        }
        
        func setMark(listView: ListView, item: Int, state: Bool) {
            marks [item] = state
        }
    }
    
    public var dataSource: ListViewDataSource? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Specifies the delegate instance that will receive important notifications from the ListView
    public var delegate: ListViewDelegate? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Convenience callback method that is invoked with the index of the item that was activated, must return true if it
    /// consumed the event, false otherwise.  If set, this is called after the `ListViewDelegate.activate` method.
    public var activate: ((_ index: Int) -> Bool)? = nil
    
    /// Constructs a ListView with a datasource and a method that can produce a rendered line on demand
    /// - Parameters:
    ///   - dataSource: the datasource describing the data
    ///   - renderWith: method that can be used to render the data on demand by returning a string.
    public init (dataSource: ListViewDataSource, renderWith: @escaping ((_ row: Int, _ width: Int) -> String))
    {
        self.dataSource = dataSource
        delegate = RenderDelegate (renderWith)
        super.init ()
        canFocus = true
    }
    
    /// Initialization method to allow the delegate and datasource to be set later, withour referencing self
    public override init ()
    {
        self.dataSource = StringWrapperDataSource ([])
        self.delegate = RenderDelegate { row, width in "" }
        super.init ()
        canFocus = true
    }
    
    /// Initialies a ListView with botht he source and delegate fully specified.
    /// - Parameter dataSource: Should provide information about the data being rendered
    /// - Parameter delegate: Should provide the methods to render and respond to the ListView
    public init (dataSource: ListViewDataSource,
                 delegate: ListViewDelegate)
    {
        self.dataSource = dataSource
        self.delegate = delegate
        super.init ()
        canFocus = true
    }
    
    /// Initialies a ListView that presents an array of strings with the default formatting
    /// - Parameter items: Array of strings to render
    public init (items: [String])
    {
        super.init ()
        self.items = items
        canFocus = true
    }

    /// If the list view is configured to render a string array, it returns it, otherwise it returns nil,
    /// if you set it, then this sets the 'dataSource' and 'delegate' properties
    public var items: [String]? {
        get {
            if let s = dataSource as? StringWrapperDataSource {
                return s.src
            }
            return nil
        }
        set {
            guard let newValue else {
                self.dataSource = StringWrapperDataSource ([])
                self.delegate = nil
                return
            }
            self.dataSource = StringWrapperDataSource (newValue)
            self.delegate = RenderDelegate { row, width in
                let value = row < newValue.count ? newValue [row] : ""
                    return value.padding (toLength: width, withPad: " ", startingAt: 0)
            }
        }
    }
    /// The index of the item to display at the top of the list
    public var topItem: Int {
        get {
            return top
        }
        set {
            guard let dataSource else {
                return
            }
            if newValue < 0 || newValue >= dataSource.getCount (listView: self) {
                return
            }
            top = newValue
            setNeedsDisplay ()
        }
    }
    
    /// Controls the current visibly selected item
    public var selectedItem: Int {
        get {
            return selected
        }
        set {
            guard let dataSource else {
                return
            }
            if newValue < 0 || newValue >= dataSource.getCount (listView: self) {
                return
            }
            selected = newValue
            delegate?.selectionChanged(listView: self)
            setNeedsDisplay()
        }
    }
    
    /// If this property is set to true, when the user reaches the end of the scrollview boundaries
    /// the event will not be processed, allowing automatically focusing the next view in the
    /// direction of the moevemnt
    public var autoNavigateToNextViewOnBoundary = false

    public func redrawColor (_ painter: Painter, selection: Bool)
    {
        if selection {
            painter.colorSelection()
        } else {
            painter.colorNormal()
        }
    }
    open override func redraw(region: Rect, painter: Painter) {
        let b = bounds
        let lines = bounds.height
        
        redrawColor(painter, selection: false)
        
        for row in 0..<lines {
            let item = top + row
            painter.goto(col: 0, row: row)
            redrawColor(painter, selection: item == selected)
            var space = b.width
            if allowMarking, let dataSource {
                painter.add(str: dataSource.isMarked(listView: self, item: item) ? markerStrings [1]: markerStrings [0])
                space -= 1
            }
            delegate?.render(listView: self, painter: painter,
                            selected: selected == item,
                            item: item, col: allowMarking ? 1 : 0,
                            line: row, width: space)
        }
    }
    
    open override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .cursorUp, .controlP:
            return moveSelectionUp () || !autoNavigateToNextViewOnBoundary
        case .cursorDown, .controlN:
            return moveSelectionDown () || !autoNavigateToNextViewOnBoundary
        case .controlV, .pageDown:
            return movePageDown () || !autoNavigateToNextViewOnBoundary
        case .letter("v") where event.isAlt, .pageUp:
            return movePageUp () || !autoNavigateToNextViewOnBoundary
        case .letter(" "):
            if toggleMarkOnRow ()  { return true }
        case .controlJ:
            if triggerActivate () { return true }
        case .home:
            moveHome ()
            return true
        case .end:
            moveEnd ()
            return true
        default:
            break
        }
        return super.processKey(event: event)
    }
    
    // Triggers the activation action for this item
    func triggerActivate () -> Bool {
        guard let dataSource else { return false }
        let count = dataSource.getCount (listView: self)
        if count == 0 {
            return false
            
        }
        
        if delegate?.activate(listView: self, item: selected) ?? false {
            return true
        }
        if let cb = activate {
            return cb (selected)
        }
        return false
    }
    
    func clearMarks ()
    {
        guard let dataSource else { return }
        // Need to clear anything that might have been selected
        let count = dataSource.getCount (listView: self)
        for idx in 0..<count {
            if idx != selected && dataSource.isMarked (listView: self, item: idx) {
                dataSource.setMark (listView: self, item: idx, state: false)
            }
        }
    }
    
    func toggleMarkOnRow () -> Bool {
        guard allowMarking else { return false }
        guard allowsMultipleSelection else { return false }
        guard let dataSource else { return false }
        if dataSource.isMarked(listView: self, item: selected) {
            dataSource.setMark(listView: self, item: selected, state: false)
        } else {
            if !allowsMultipleSelection {
                clearMarks()
            }
            dataSource.setMark(listView: self, item: selected, state: true)
        }
        setNeedsDisplay()
        return true
    }
    
    /// Moves the selection to the previous item
    /// - Returns: True if the selection was moved, false otherwise
    public func moveSelectionUp () -> Bool
    {
        guard let dataSource else { return false }

        let count = dataSource.getCount(listView: self)
        if count == 0 {
            return false
        }
        
        if selected > 0 {
            selectedItem -= 1
            if selected < top {
                top = selected
            } else if selected > top + frame.height {
                top = max (selected - frame.height + 1, 0)
            }
            setNeedsDisplay()
            return true
        }
        return false
    }
    
    /// Moves the selection to the next item
    /// - Returns: True if the selection was moved, false otherwise
    public func moveSelectionDown () -> Bool
    {
        guard let dataSource else { return false }
        
        let count = dataSource.getCount(listView: self)
        if count == 0 {
            return false
        }
        
        if selected + 1 < count {
            selectedItem += 1
            if selected >= (top + frame.height) {
                top += 1
            } else if selected < top {
                top = selected
            }
            setNeedsDisplay()
            return true
        }
        return false
    }

    /// Moves the selection one page up
    /// - Returns: true if this change the selected position, false otherwise
    public func movePageUp () -> Bool {
        guard let dataSource else { return false }

        let count = dataSource.getCount(listView: self)
        if count == 0 {
            return false
        }
        
        if selected > 0 {
            selectedItem = max (0, selectedItem-frame.height)
            if selected > count {
                selectedItem = count - 1
            }
            if selected < top {
                top = selected
            } else if selected > top + frame.height {
                top = max (selected - frame.height + 1, 0)
            }
            setNeedsDisplay()
            return true
        }
        return false
    }
    
    /// Moves the selection one page up
    /// - Returns: true if this change the selected position, false otherwise
    public func movePageDown () -> Bool {
        guard let dataSource else { return false }

        let count = dataSource.getCount(listView: self)
        if count == 0 {
            return false
        }
        
        if selected + 1 < count {
            selectedItem = min (selectedItem + frame.height, count-1)
            if selected >= (top + frame.height) {
                top = max (0, selected-frame.height+1)
            } else if selected < top {
                top = selected
            }
            setNeedsDisplay()
            return true
        }
        return false
    }

    /// Moves the selection cursor to the first element
    public func moveHome ()
    {
        if selected != 0 {
            selectedItem = 0
            top = selected
            setNeedsDisplay()
        }
    }
    
    /// Moves the selection cursor to the last element
    public func moveEnd ()
    {
        guard let dataSource else { return }

        let count = dataSource.getCount(listView: self)
        if selected != count - 1 {
            selectedItem = count - 1
            top = selected
            setNeedsDisplay()
        }
    }

    public func reload () {
        selectedItem = 0
        top = 0
        setNeedsDisplay()
    }
    open override func positionCursor() {
        moveTo (col: allowMarking ? 0 : bounds.width-1, row: selected-top)
    }
    
    open override func mouseEvent(event: MouseEvent) -> Bool {
        if !hasFocus && canFocus {
            superview?.setFocus(self)
        }
        guard let dataSource else { return false }

        let c = dataSource.getCount(listView: self)
        if event.pos.y + top >= c {
            return true
        }
        selectedItem = top + event.pos.y
        setNeedsDisplay()
        if event.flags == [.button1DoubleClicked] {
            _ = triggerActivate()
        }
        return true
    }
}
