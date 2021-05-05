//
//  DataTable.swift:
//  
// This is a port of Thomas Nind's TableView from Terminal.Gui for C# to Swift for TermKit
// I changed the name from "TableView" to "DataTable", as "TableView" has a different
// connotation in UIKit land
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
    /// Whether the data source can be modified, in that case, the subscript method would be invoked with
    /// a new value to update the specific cell
    var isEditable: Bool { get }
    /// Indexer used to access the data.
    subscript (col: Int, row: Int) -> String { get set }
}

public protocol DataEditor {
    func edit (frame: Rect, source: DataTable, col: Int, row: Int, completion: () -> ())
}

/// The DataTable provides an easy way to display data tables, that are made up of rows and columns
/// and allows both browsing and in-place editing of the data.
///
/// For user data, you must implement the `DataSource` protocol that provides a bridge to your data
///
public class DataTable: View {
    
    /// The data table to render in the view.  Setting this property automatically updates and redraws the control.
    public var source: DataSource {
        didSet { reload () }
    }
    
    /// True to select the entire row at once.  False to select individual cells.  Defaults to false
    public var fullRowSelect: Bool = false
    
    /// True to allow regions to be selected
    var multiSelect: Bool = true
    
    // var multiSelectedRegions: [TableSelection] = []
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
    
    /// When scrolling down always lock the column headers in place as the first row of the table
    public var alwaysShowHeaders: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    func reload () {
        abort ()
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
    }
        
    var shouldRenderHeaders: Bool {
        source.cols == 0 ? false : (alwaysShowHeaders || rowOffset == 0)
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
        
        var titles = source.columnTitles
        for i in 0..<columnsToRender.count {
            let current =  columnsToRender [i]
            var availableWidthForCell = getCellWidth (columnsToRender: columnsToRender, i: i)
            var colStyle = getColumnStyle (col: current.col)
            var colName = titles [current.col]

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
            var isSelectedCell = isSelected (col: current.col, row: rowToRender)

            painter.attribute = isSelectedCell ? colorScheme.hotFocus : colorScheme.normal

            let val = source [current.col, rowToRender]

            // Render the (possibly truncated) cell value
            let representation = getRepresentation (value: val, colStyle: colStyle)
            
            driver.addStr(truncateOrPad (val, representation, availableWidthForCell, colStyle))
            
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
        abort ()
        // if value is not wide enough
//        if  representation.Sum(c=>Rune.ColumnWidth(c)) < availableHorizontalSpace) {
//
//            // pad it out with spaces to the given alignment
//            int toPad = availableHorizontalSpace - (representation.Sum(c=>Rune.ColumnWidth(c)) +1 /*leave 1 space for cell boundary*/);
//
//            switch(colStyle?.GetAlignment(originalCellValue) ?? TextAlignment.Left) {
//
//            case TextAlignment.Left :
//                return representation + new string(' ',toPad);
//            case TextAlignment.Right :
//                return new string(' ',toPad) + representation;
//
//            // TODO: With single line cells, centered and justified are the same right?
//            case TextAlignment.Centered :
//            case TextAlignment.Justified :
//                return
//                    new string(' ',(int)Math.Floor(toPad/2.0)) + // round down
//                        representation +
//                        new string(' ',(int)Math.Ceiling(toPad/2.0)) ; // round up
//            }
//        }
//
//        // value is too wide
//        return new string(representation.TakeWhile(c=>(availableHorizontalSpace-= Rune.ColumnWidth(c))>0).ToArray());
    }
    
    public override func redraw(region: Rect, painter: Painter) {
        painter.goto(col: 0, row: 0)
        let f = frame
        
//        // What columns to render at what X offset in viewport
//        var columnsToRender = CalculateViewport(bounds).ToArray();
//
//        Driver.SetAttribute (ColorScheme.Normal);
//
//        //invalidate current row (prevents scrolling around leaving old characters in the frame
//        Driver.AddStr (new string (' ', bounds.Width));
//
//        int line = 0;
//
//        if(ShouldRenderHeaders()){
//            // Render something like:
//            /*
//                ┌────────────────────┬──────────┬───────────┬──────────────┬─────────┐
//                │ArithmeticComparator│chi       │Healthboard│Interpretation│Labnumber│
//                └────────────────────┴──────────┴───────────┴──────────────┴─────────┘
//            */
//            if(Style.ShowHorizontalHeaderOverline){
//                RenderHeaderOverline(line,bounds.Width,columnsToRender);
//                line++;
//            }
//
//            RenderHeaderMidline(line,columnsToRender);
//            line++;
//
//            if(Style.ShowHorizontalHeaderUnderline){
//                RenderHeaderUnderline(line,bounds.Width,columnsToRender);
//                line++;
//            }
//        }
//
//        int headerLinesConsumed = line;
//
//        //render the cells
//        for (; line < frame.Height; line++) {
//
//            ClearLine(line,bounds.Width);
//
//            //work out what Row to render
//            var rowToRender = RowOffset + (line - headerLinesConsumed);
//
//            //if we have run off the end of the table
//            if ( Table == null || rowToRender >= Table.Rows.Count || rowToRender < 0)
//                continue;
//
//            RenderRow(line,rowToRender,columnsToRender);
//        }
    }
    
    public func isSelected (col: Int, row: Int) -> Bool {
//                // Cell is also selected if in any multi selection region
//                if(MultiSelect && MultiSelectedRegions.Any(r=>r.Rect.Contains(col,row)))
//                    return true;
//
//                // Cell is also selected if Y axis appears in any region (when FullRowSelect is enabled)
//                if(FullRowSelect && MultiSelect && MultiSelectedRegions.Any(r=>r.Rect.Bottom> row  && r.Rect.Top <= row))
//                    return true;
//
//                return row == SelectedRow &&
//                        (col == SelectedColumn || FullRowSelect);
        abort ()
    }
    
    func getRepresentation(value: Any, colStyle: ColumnStyle?) -> String
    {
        abort ()
//        if (value == null || value == DBNull.Value) {
//            return NullSymbol;
//        }
//
//        return colStyle != null ? colStyle.GetRepresentation(value): value.ToString();
    }
}

/// Describes how to render a given column in  a <see cref="TableView"/> including <see cref="Alignment"/>
/// and textual representation of cells (e.g. date formats)
public struct ColumnStyle {
    /// Defines the default alignment for all values rendered in this column.  For custom alignment based on cell contents use <see cref="AlignmentGetter"/>.
    var alignment: TextAlignment
}

struct ColumnToRender {
    var col: Int
    var x: Int
}
