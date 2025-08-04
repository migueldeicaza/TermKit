//
//  DataTable.swift:
//  
// This is a port of Thomas Nind's TableView from Terminal.Gui for C# to Swift for TermKit
// I changed the name from "TableView" to "DataTable", as "TableView" has a different
// connotation in UIKit land
//
// TODO:
// Should use TermKit's ability to render AttributedStrings
// Probably shoudl have a way of providing column styles in the protocol with some defaults
// Would be nice to expose a method "edit (cell)" which would present some custom editor
// at the location where the cell is.
//
import Foundation

/// Protocol that describes a matrix made up of columns and rows, where the columns can be labeled
public protocol DataSource {
    /// Number of columns in the data source
    var cols: Int { get }
    // Number of rows in the data source
    var rows: Int { get }
    /// The titles for the columns
    var columnTitles: [String] { get }
    /// Indexer used to access the data.
    subscript (col: Int, row: Int) -> String { get set }
    
    /// This method returns the column style for the given column, can return nil if it should just use the defaults,
    /// the default implenentation returns nil
    func getColumnStyle (col: Int) -> ColumnStyle?
}

public extension DataSource {
    func getColumnStyle (col: Int) -> ColumnStyle? {
        nil
    }
}

/// The DataTable provides an easy way to display data tables, that are made up of rows and columns
/// and allows both browsing and in-place editing of the data.
///
/// For user data, you must implement the `DataSource` protocol that provides a bridge to your data
///
open class DataTable: View {
    
    /// The data table to render in the view.  Setting this property automatically updates and redraws the control.
    public var source: DataSource {
        didSet { reload () }
    }
    
    /// True to select the entire row at once.  False to select individual cells.  Defaults to false
    public var fullRowSelect: Bool = false
    
    /// True to allow regions to be selected
    public var multiSelect: Bool = true
    
    var multiSelectedRegions: [Rect] = []
    
    public var rowOffset: Int = 0 {
        didSet {
            rowOffset = max (0, min (rowOffset, source.rows-1))
            setNeedsDisplay()
        }
    }
    
    /// Horizontal scroll offset.  The index of the first column in `source` to display when when rendering the view.
    public var columnOffset: Int = 0 {
        didSet {
            columnOffset = max (0, min (columnOffset, source.cols-1))
            setNeedsDisplay()
        }
    }

    var _selectedColumn: Int = 0
    ///  The index of columns in source that the user has currently selected
    public var selectedColumn: Int {
        get { _selectedColumn }
        set {
            let next =  max (0, min (newValue, source.cols-1))
            if next != _selectedColumn {
                setNeedsDisplay()
                _selectedColumn = next
            }
        }
    }

    var _selectedRow: Int = 0
    ///  The index of rows in source that the user has currently selected
    public var selectedRow: Int {
        get { _selectedRow }
        set {
            let next =  max (0, min (newValue, source.rows-1))
            if next != _selectedRow {
                setNeedsDisplay()
                _selectedRow = next
            }
        }
    }
    
    /// The maximum number of characters to render in any given column.  This prevents one long column from pushing out all the others
    public var maxCellWidth = 100

    /// The text representation that should be rendered for cells with the value nil.
    public var nilChar = "-"
    
    /// The symbol to add after each cell value and header value to visually seperate values (if not using vertical gridlines)
    public var separatorSymbol = " "
    
    /// This event is raised when a cell is activated e.g. by double clicking or pressing <see cref="CellActivationKey"/>
    public var cellActivated: (_ source: DataSource, _ col: Int, _ row: Int)->() = { a, b, c in }
    
    /// The key which when pressed should trigger `cellActivated`event.  Defaults to Return.
    public var cellActivationKey: Key = Key.controlJ
    
    func reload () {
        _selectedRow = 0
        _selectedColumn = 0
        columnOffset = 0
        rowOffset = 0
    }
    /// When scrolling down always lock the column headers in place as the first row of the table
    public var alwaysShowHeaders: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// True to render a solid line above the headers
    public var showHorizontalHeaderOverline = true {
        didSet {
            setNeedsDisplay()
        }
    }

    /// True to render a solid line under the headers
    public var showHorizontalHeaderUnderline = true {
        didSet {
            setNeedsDisplay()
        }
    }

    /// True to render a solid line vertical line between cells
    public var showVerticalCellLines = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// True to render a solid line vertical line between headers
    public var showVerticalHeaderLines = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // public var columnStyles:
    
    /// /// Initialzies a new DataTable with the provided data source
    public init (source: DataSource) {
        self.source = source
        super.init()
        canFocus = true
    }
    
    func calculateViewport (bounds: Rect, padding: Int = 1) -> [ColumnToRender] {
        var columnsToRender: [ColumnToRender] = []
        var usedSpace = 0
        
        //if horizontal space is required at the start of the line (before the first header)
        if showVerticalHeaderLines || showVerticalCellLines {
            usedSpace += 1
        }
        let availableHorizontalSpace = bounds.width
        var rowsToRender = bounds.height
        
        // reserved for the headers row
        if shouldRenderHeaders {
            rowsToRender -= getHeaderHeight()
        }
        
        var first = true
        let cols = source.cols
        
        for col in 0..<cols {
            if col < columnOffset {
                continue
            }
            let startingIdxForCurrentHeader = usedSpace
            let colStyle = getColumnStyle(col: col)
            
            // is there enough space for this column (and it's data)?
            usedSpace += calculateMaxCellWidth (col: col, rowsToRender: rowsToRender, colStyle: colStyle) + padding
            
            // no (don't render it) unless its the only column we are render (that must be one massively wide column!)
            if (!first && usedSpace > availableHorizontalSpace) {
                break
            }
            
            columnsToRender.append(ColumnToRender (col: col, x: startingIdxForCurrentHeader))
            first = false
        }
        return columnsToRender
    }
    
    var shouldRenderHeaders: Bool {
        source.cols == 0 ? false : (alwaysShowHeaders || rowOffset == 0)
    }
    
    func calculateMaxCellWidth (col: Int, rowsToRender: Int, colStyle: ColumnStyle?) -> Int {
        let rows = source.rows
        let titles = source.columnTitles
        var spaceRequired = titles [col].cellCount()
        
        // if table has no rows
        if rowOffset < 0 {
            return spaceRequired
        }
        
        var i = rowOffset
        while i < rowOffset + rowsToRender && i < rows {
            defer { i += 1 }
            
            //expand required space if cell is bigger than the last biggest cell or header
            spaceRequired = max (spaceRequired, getRepresentation (value: source [col, i], colStyle: colStyle).cellCount())
        }
        
        // Don't require more space than the style allows
        if let style = colStyle {
            // enforce maximum cell width based on style
            if spaceRequired > style.maxWidth {
                spaceRequired = style.maxWidth
            }
            
            // enforce minimum cell width based on style
            if spaceRequired < style.minWidth {
                spaceRequired = style.minWidth
            }
        }
        
        // enforce maximum cell width based on global table style
        if spaceRequired > maxCellWidth {
            spaceRequired = maxCellWidth
        }

        return spaceRequired
    }
    
    func clearLine (row: Int, width: Int, painter: Painter) {
        painter.goto(col: 0, row: row)
        painter.colorNormal()
        painter.add(str: String (repeating: " ", count: width))
    }
    
    func getHeaderHeightIfAny() -> Int {
        shouldRenderHeaders ? getHeaderHeight () : 0
    }
    
    func getHeaderHeight() -> Int {
        var heightRequired = 1
        if showHorizontalHeaderOverline {
            heightRequired += 1
        }
        if showHorizontalHeaderUnderline {
            heightRequired += 1
        }
        return heightRequired
    }
    
    // Renders a line above table headers (when visible) like:
    // ┌────────────────────┬──────────┬───────────┬──────────────┬─────────┐
    func renderHeaderOverline (row: Int, availableWidth: Int, columnsToRender: [ColumnToRender], painter: Painter)
    {
        let defRune = driver.hLine
        var c = 0
        
        painter.goto(col: 0, row: row)
        while c < availableWidth {
            defer { c += 1 }

            var rune = defRune

            if showVerticalHeaderLines {
                if c == 0 {
                    rune = driver.ulCorner
                } else if columnsToRender.contains (where: { r in r.x == c+1 }) {
                    // if the next column is the start of a header

                    rune = driver.topTee
                } else if(c == availableWidth - 1) {
                    rune = driver.urCorner
                }
            }
            
            painter.add(rune: rune)
        }
    }
    
    func getColumnStyle (col: Int) -> ColumnStyle? {
        // TODO
        return nil
    }
    
    // Renders something like:
    // │ArithmeticComparator│chi       │Healthboard│Interpretation│Labnumber│
    func renderHeaderMidline(row: Int, columnsToRender: [ColumnToRender], painter: Painter) {
        clearLine(row: row, width: bounds.width, painter: painter)
        painter.goto(col: 0, row: row)
        
        // render start of line
        if showVerticalHeaderLines {
            painter.add(rune: driver.vLine)
        }
        
        let titles = source.columnTitles
        for i in 0..<columnsToRender.count {
            let current =  columnsToRender [i]
            let availableWidthForCell = getCellWidth (columnsToRender: columnsToRender, i: i)
            let colStyle = getColumnStyle (col: current.col)
            let colName = titles [current.col]

            painter.goto(col: current.x-1, row: row)
            painter.add (str: getSeparator(isHeader: true))
                        
            painter.goto(col: current.x, row: row)
            painter.add(str: truncateOrPad (colName, colName, availableWidthForCell, colStyle))
        }

        //render end of line
        if showVerticalHeaderLines {
            painter.goto(col: bounds.width-1, row: row)
            painter.add(rune: driver.vLine)
        }
    }
    
    /// Calculates how much space is available to render index <paramref name="i"/> of the <paramref name="columnsToRender"/> given the remaining horizontal space
    func getCellWidth (columnsToRender: [ColumnToRender], i: Int) -> Int {
        let current = columnsToRender [i]
        let next = i+1 < columnsToRender.count ? columnsToRender [i+1] : nil
        
        if let n = next {
            return n.x - current.x
        } else {
            // cell can fill to end of the line
            return bounds.width - current.x
        }
    }
    
    // Renders a line below the table headers (when visible) like:
    // ├──────────┼───────────┼───────────────────┼──────────┼────────┼─────────────┤
    func renderHeaderUnderline(row: Int, availableWidth: Int, columnsToRender: [ColumnToRender], painter: Painter) {
        let defRune = driver.hLine
        painter.goto(col: 0, row: row)
        for c in 0..<availableWidth {
            var rune = defRune
            
            if showVerticalHeaderLines {
                if c == 0 {
                    rune = showVerticalCellLines ? driver.leftTee : driver.llCorner
                } else if columnsToRender.contains(where: { r in r.x == c + 1}) {
                    // if the next column is the start of a header
                    /* TODO: is ┼ symbol in Driver? */
                    rune = showVerticalCellLines ? "┼" : driver.bottomTee
                } else if c == availableWidth - 1 {
                    rune = showVerticalCellLines ? driver.rightTee : driver.lrCorner
                }
            }
            painter.add(rune: rune)
        }
    }
    
    func renderRow (row: Int, rowToRender: Int, columnsToRender: [ColumnToRender], painter: Painter) {
        painter.goto(col: 0, row: row)
        //render start of line
        if showVerticalCellLines {
            painter.add(rune: driver.vLine)
        }
        
        // Render cells for each visible header for the current row
        for i in 0..<columnsToRender.count  {
            let current = columnsToRender [i]
            let availableWidthForCell = getCellWidth (columnsToRender: columnsToRender,i: i)

            let colStyle = getColumnStyle (col: current.col)

            // move to start of cell (in line with header positions)
            painter.goto(col: current.x, row: row)

            // Set color scheme based on whether the current cell is the selected one
            let isSelectedCell = isSelected (col: current.col, row: rowToRender)

            painter.attribute = isSelectedCell ? colorScheme.hotFocus : colorScheme.normal

            let val = source [current.col, rowToRender]

            // Render the (possibly truncated) cell value
            let representation = getRepresentation (value: val, colStyle: colStyle)
            
            painter.add(str: truncateOrPad (val, representation, availableWidthForCell, colStyle))
            
            // If not in full row select mode always, reset color scheme to normal and render the vertical line (or space) at the end of the cell
            if !fullRowSelect {
                painter.attribute = colorScheme.normal
            }
            
            painter.goto(col: current.x-1, row: row)
            painter.add (str: getSeparator(isHeader: false))
        }

        //render end of line
        if showVerticalCellLines {
            painter.goto(col: bounds.width-1, row: row)
            painter.add(rune: driver.vLine)
        }
    }
    
    func getSeparator (isHeader: Bool) -> String {
        let renderLines = isHeader ? showVerticalHeaderLines : showVerticalCellLines
        return renderLines ? String (driver.vLine) : separatorSymbol
    }

    func truncateOrPad (_ originalCellValue: String, _ representation: String, _ availableHorizontalSpace: Int, _ colStyle: ColumnStyle?) -> String {
        if representation == "" {
            return ""
        }
        // if value is not wide enough
        let rcell = representation.cellCount()
        if rcell < availableHorizontalSpace {
            // pad it out with spaces to the given alignment
            let toPad = availableHorizontalSpace - rcell + 1
            
            switch colStyle?.getAlignment(originalCellValue) ?? .left {
            case .left:
                return representation + String (repeating: " ", count: toPad)
                
            case .right:
                return String(repeating: " ", count: toPad) + representation
                
            // TODO: With single line cells, centered and justified are the same right?
            case .centered, .justified:
                let n = toPad/2
                return String(repeating: " ", count: n) + representation + String(repeating: " ", count: toPad-n)
            }
        }
        
        // value is too wide
        return representation.getVisibleString(availableHorizontalSpace)
    }
    
    open override func redraw(region: Rect, painter: Painter) {
        painter.goto(col: 0, row: 0)
        let f = frame
        let width = f.width
        
        // What columns to render at what X offset in viewport
        let columnsToRender = calculateViewport (bounds: bounds)
        
        painter.attribute = colorScheme.normal

        //invalidate current row (prevents scrolling around leaving old characters in the frame
        clearLine(row: 0, width: width, painter: painter)

        var line = 0
        
        if shouldRenderHeaders {
            // Render something like:
            /*
             ┌────────────────────┬──────────┬───────────┬──────────────┬─────────┐
             │ArithmeticComparator│chi       │Healthboard│Interpretation│Labnumber│
             └────────────────────┴──────────┴───────────┴──────────────┴─────────┘
             */
            if showHorizontalHeaderOverline {
                renderHeaderOverline(row: line, availableWidth: width, columnsToRender: columnsToRender, painter: painter)
                line += 1
            }
            
            renderHeaderMidline(row: line, columnsToRender: columnsToRender, painter: painter)
            line += 1
            
            if showHorizontalHeaderUnderline {
                renderHeaderUnderline(row: line, availableWidth: width, columnsToRender: columnsToRender, painter: painter)
                line += 1
            }
        }
        let headerLinesConsumed = line
        let height = frame.height
        //render the cells
        while line < height {
            defer { line += 1 }
            clearLine(row: line, width: width, painter: painter)
            
            //work out what Row to render
            let rowToRender = rowOffset + (line - headerLinesConsumed)
            
            // if we have run off the end of the table
            if rowToRender >= source.rows || rowToRender < 0 {
                continue
            }
            renderRow(row: line, rowToRender: rowToRender, columnsToRender: columnsToRender, painter: painter)
        }
    }
    
    public func isSelected (col: Int, row: Int) -> Bool {
        
        // Cell is also selected if in any multi selection region
        if multiSelect && multiSelectedRegions.contains(where: { rect in rect.contains(x: col, y: row) }) {
            return true
        }
        
        // Cell is also selected if Y axis appears in any region (when FullRowSelect is enabled)
        if fullRowSelect && multiSelect && multiSelectedRegions.contains(where: { rect in rect.contains(x: col, y: row)}) {
            return true
        }
        return row == selectedRow && (col == selectedColumn || fullRowSelect)
    }
    
    func getRepresentation(value: String?, colStyle: ColumnStyle?) -> String
    {
        guard let str = value else {
            return nilChar
        }
        return colStyle?.getRepresentation(str) ?? str
    }
    
    open override func processKey(event: KeyEvent) -> Bool {
        switch event.key {
        case .controlJ:
            cellActivated (source, selectedColumn, selectedRow)
            
        case .cursorLeft:
        //case .cursorLeft | Key.ShiftMask:
            changeSelectionByOffset (offsetX: -1, offsetY: 0, extendExistingSelection: false)
            update()
            
        case .cursorRight:
            // case .cursorRight + shift
            changeSelectionByOffset (offsetX: 1, offsetY: 0, extendExistingSelection: false)
            update ()
            
        case .cursorDown:
            changeSelectionByOffset (offsetX: 0, offsetY: 1, extendExistingSelection: false)
            update()
            
        case .cursorUp:
            changeSelectionByOffset (offsetX: 0, offsetY: -1, extendExistingSelection: false)
            update()
            
        case .pageUp:
            changeSelectionByOffset (offsetX: 0, offsetY: -(bounds.height-getHeaderHeightIfAny()), extendExistingSelection: false)
            update ()

        case .pageDown:
            changeSelectionByOffset (offsetX: 0, offsetY: (bounds.height-getHeaderHeightIfAny()), extendExistingSelection: false)
            update ()
            
        case .home:
            setSelection(col: 0, row: 0, extendExistingSelection: false)
            update ()

        case .end:
            setSelection(col: source.cols-1, row: source.rows-1, extendExistingSelection: false)
            update ()

        case .controlA:
            selectAll ()
            update ()
            
        default:
            // Not a keystroke we care about
            return false
        }
        return true
    }
    
    func createTableSelection (_ col1: Int, _ row1: Int, _ col2: Int, _ row2: Int) -> Rect {
        Rect (x: min (col1, col2), y: min (row1, row2), width: abs (col2-col2)+1, height: abs (row2-row1)+1)
    }
    
    /// Moves the `SelectedRow` and `SelectedColumn` to the given col/row. Optionally starting a box selection if `multiSelect` is set.
    /// - Parameters:
    ///   - col: Column location to add to the selection
    ///   - row: Row location to add to the selection
    ///   - extendExistingSelection: if multiSelect is true, this extends the selection
    public func setSelection (col: Int, row: Int, extendExistingSelection: Bool)
    {
        if !multiSelect || !extendExistingSelection {
            multiSelectedRegions = []
        }

        if extendExistingSelection {
            // If we are extending current selection but there isn't one
            if multiSelectedRegions.count == 0 {
                // Create a new region between the old active cell and the new cell
                let rect = createTableSelection (selectedColumn, selectedRow, col, row)
                multiSelectedRegions.append (rect)
            } else {
                // Extend the current head selection to include the new cell
                if let head = multiSelectedRegions.last {
                    let newRect = createTableSelection (head.minX, head.minY, col, row)
                    multiSelectedRegions.append (newRect)
                }
            }
        }

        selectedColumn = col
        selectedRow = row
    }

    /// Moves the `selectedRow` and `selectedCol` by the provided offsets. Optionally starting a box selection (if `multiSelect` is set)
    /// - Parameters:
    ///   - offsetX: Offset in number of columns
    ///   - offsetY: Offset in number of rows
    ///   - extendExistingSelection: True to create a multi cell selection or adjust an existing one
    public func changeSelectionByOffset (offsetX: Int, offsetY: Int, extendExistingSelection: Bool)
    {
        setSelection (col: selectedColumn + offsetX, row: selectedRow + offsetY, extendExistingSelection: extendExistingSelection)
    }

    /// When `MultiSelect` is on, creates selection over all cells in the table (replacing any old selection regions)
    public func selectAll() {
        if !multiSelect || source.rows == 0 {
            return
        }
        multiSelectedRegions = []

        // Create a single region over entire table, set the origin of the selection to the active cell so that a followup spread selection e.g. shift-right behaves properly
        multiSelectedRegions.append(createTableSelection(selectedColumn, selectedRow, source.cols, source.rows))
        update ()
    }
    
    public func update () {
        setNeedsDisplay()
        
        ensureValidScrollOffsets ()
        ensureValidSelection ()
        ensureSelectedCellIsVisible ()
    }
    
    func ensureValidScrollOffsets () {
        columnOffset = max (min (columnOffset, source.cols - 1), 0)
        rowOffset = max (min (rowOffset, source.rows - 1), 0)
    }
    
    func ensureValidSelection () {
        selectedColumn = max (min (selectedColumn, source.cols - 1), 0)
        selectedRow = max (min (selectedRow, source.rows - 1), 0)

        let oldRegions = multiSelectedRegions.reversed()
        
        multiSelectedRegions = []
        
        // evaluate
        for region in oldRegions  {
            // ignore regions entirely below current table state
            if region.top >= source.rows {
                continue
            }
            
            // ignore regions entirely too far right of table columns
            if region.left >= source.cols {
                continue
            }
            
            // ensure region's origin exists
            // ensure regions do not go over edge of table bounds
            let new = Rect(
                left: max(min(region.origin.x, source.cols - 1),0),
                top: max(min(region.origin.y, source.rows - 1),0),
                right: max(min(region.right, source.cols), 0),
                bottom:max(min(region.bottom, source.rows), 0))
            
            multiSelectedRegions.append (new)
        }
    }
    
    func ensureSelectedCellIsVisible () {
        let columnsToRender = calculateViewport (bounds: bounds)
        let headerHeight = getHeaderHeightIfAny()
        
        // if we have scrolled too far to the left
        let minCol = columnsToRender.min (by: { a, b in a.col < b.col })?.col ?? 0
        let maxCol = columnsToRender.max (by: { a, b in a.col < b.col })?.col ?? source.cols-1
        
        if selectedColumn < minCol {
            columnOffset = selectedColumn
        }
        
        // if we have scrolled too far to the right
        if selectedColumn > maxCol {
            columnOffset = selectedColumn
        }
        
        // if we have scrolled too far down
        if selectedRow >= rowOffset + (bounds.height - headerHeight) {
            rowOffset = selectedRow
        }
        
        // if we have scrolled too far up
        if selectedRow < rowOffset {
            rowOffset = selectedRow
        }
    }
    
    /// Returns the column and row of <see cref="Table"/> that corresponds to a given point on the screen (relative to the control client area).  Returns null if the point is in the header, no table is loaded or outside the control bounds
    /// <param name="clientX">X offset from the top left of the control</param>
    /// <param name="clientY">Y offset from the top left of the control</param>
    /// <returns></returns>
    public func screenToCell (clientX: Int, clientY: Int) -> Point? {
        let viewPort = calculateViewport (bounds: bounds)
        let headerHeight = getHeaderHeightIfAny ()
        let col = viewPort.last(where: {c in c.x <= clientX })
        
        // Click is on the header section of rendered UI
        if clientY < headerHeight {
            return nil
        }
        let rowIdx = rowOffset - headerHeight + clientY
        
        if let c = col, rowIdx >= 0 {
            return Point (x: c.col, y: rowIdx)
        }
        return nil
    }
    
    /// <summary>
    /// Returns the screen position (relative to the control client area) that the given cell is rendered or null if it is outside the current scroll area or no table is loaded
    /// </summary>
    /// <param name="tableColumn">The index of the <see cref="Table"/> column you are looking for, use <see cref="DataColumn.Ordinal"/></param>
    /// <param name="tableRow">The index of the row in <see cref="Table"/> that you are looking for</param>
    /// <returns></returns>
    public func cellToScreen (tableColumn: Int, tableRow: Int) -> Point? {
        let viewPort = calculateViewport (bounds: bounds)
        let headerHeight = getHeaderHeightIfAny()

        // If it is outside
        guard let colHit = viewPort.first(where: {c in c.col == tableColumn}) else {
            return nil
        }
        
        // the cell is too far up above the current scroll area
        if rowOffset > tableRow {
            return nil
        }
    
        // the cell is way down below the scroll area and off the screen
        if tableRow > rowOffset + (bounds.height - headerHeight) {
            return nil
        }
        return Point (x: colHit.x, y: tableRow + headerHeight - rowOffset)
    }
    
    open override func positionCursor() {
        if let screenPoint = cellToScreen (tableColumn: selectedColumn, tableRow: selectedRow) {
            moveTo(col: screenPoint.x, row: screenPoint.y)
        }
    }
}

/// Describes how to render a given column in  a <see cref="TableView"/> including <see cref="Alignment"/>
/// and textual representation of cells (e.g. date formats)
public struct ColumnStyle {
    /// Defines the default alignment for all values rendered in this column.  For custom alignment based on cell contents use <see cref="AlignmentGetter"/>.
    var defaultAlignment: TextAlignment = .left
    var maxWidth = 100
    var minWidth = 1
    
    func getAlignment (_ text: String) -> TextAlignment {
        return defaultAlignment
    }
    
    func getRepresentation (_ text: String) -> String {
        return text
    }
}

struct ColumnToRender {
    var col: Int
    var x: Int
}
