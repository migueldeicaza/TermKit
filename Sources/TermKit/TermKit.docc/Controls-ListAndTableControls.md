# List and Table Controls

Controls for displaying collections of data.

## Overview

TermKit provides controls for displaying lists and tabular data with selection, scrolling, and customization options.

## ListView

``ListView`` displays a scrollable list of items.

### Simple Usage with Strings

```swift
let items = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
let list = ListView(items: items)
list.fill()
container.addSubview(list)
```

### Selection Handling

```swift
list.selectedItem = 2  // Select "Cherry"

// Handle selection changes
list.selectionChanged = { listView in
    print("Selected index: \(listView.selectedItem)")
}

// Handle activation (Enter key)
list.activated = { listView, index in
    print("Activated: \(items[index])")
}
```

### Marking Items

Allow users to mark multiple items:

```swift
list.allowMarking = true
list.allowsMultipleSelection = true

// Customize markers
list.markerStrings = [" ", "✓"]  // Unmarked, Marked
```

### Selected Item Indicator

```swift
list.selectedMarker = "→"  // Shows → next to selected row
```

### Custom Data Source

For complex data, implement `ListViewDataSource`:

```swift
class MyDataSource: ListViewDataSource {
    var items: [MyModel] = []

    func getCount(listView: ListView) -> Int {
        return items.count
    }

    func isMarked(listView: ListView, item: Int) -> Bool {
        return items[item].isMarked
    }

    func setMark(listView: ListView, item: Int, state: Bool) {
        items[item].isMarked = state
    }
}

let dataSource = MyDataSource()
let list = ListView(dataSource: dataSource) { index, width in
    return dataSource.items[index].displayString
}
```

### Custom Rendering

For full control, implement `ListViewDelegate`:

```swift
class MyDelegate: ListViewDelegate {
    func render(
        listView: ListView,
        painter: Painter,
        selected: Bool,
        item: Int,
        col: Int,
        line: Int,
        width: Int
    ) {
        let attr = selected ? listView.colorScheme.focus : listView.colorScheme.normal
        painter.attribute = attr
        painter.goto(col: col, row: line)
        painter.add(str: myItems[item].formattedDisplay(width: width))
    }

    func selectionChanged(listView: ListView) {
        // Handle selection change
    }

    func activate(listView: ListView, item: Int) -> Bool {
        // Handle activation, return true if handled
        return true
    }
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `selectedItem` | `Int` | Selected index |
| `topItem` | `Int` | First visible row |
| `allowMarking` | `Bool` | Enable marking items |
| `allowsMultipleSelection` | `Bool` | Allow multiple marks |
| `selectedMarker` | `String?` | Selection indicator |
| `markerStrings` | `[String]` | Marking indicators |

### Keyboard

| Key | Action |
|-----|--------|
| **Up/Down** | Move selection |
| **Page Up/Down** | Scroll page |
| **Home/End** | Go to first/last |
| **Enter** | Activate selected |
| **Space** | Toggle mark |

---

## DataTable

``DataTable`` displays tabular data with columns.

### Basic Usage

```swift
let table = DataTable()
table.fill()

// Define columns
table.columns = [
    DataColumn(title: "Name", width: 20),
    DataColumn(title: "Age", width: 5),
    DataColumn(title: "City", width: 15)
]

// Add rows
table.rows = [
    ["Alice", "30", "New York"],
    ["Bob", "25", "Los Angeles"],
    ["Charlie", "35", "Chicago"]
]

container.addSubview(table)
```

### Column Configuration

```swift
let nameColumn = DataColumn(title: "Name")
nameColumn.width = 25
nameColumn.alignment = .left
nameColumn.sortable = true

table.columns.append(nameColumn)
```

### Selection

```swift
table.selectedRow = 1
table.selectedColumn = 0

table.selectionChanged = { table in
    print("Row: \(table.selectedRow), Col: \(table.selectedColumn)")
}
```

### Sorting

```swift
table.sortColumn = 0  // Sort by first column
table.sortAscending = true
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `columns` | `[DataColumn]` | Column definitions |
| `rows` | `[[String]]` | Row data |
| `selectedRow` | `Int` | Selected row index |
| `selectedColumn` | `Int` | Selected column index |
| `sortColumn` | `Int?` | Column to sort by |
| `sortAscending` | `Bool` | Sort direction |

### Keyboard

| Key | Action |
|-----|--------|
| **Up/Down** | Move row selection |
| **Left/Right** | Move column selection |
| **Page Up/Down** | Scroll page |
| **Home/End** | Go to first/last row |

---

## Common Patterns

### Filterable List

```swift
let searchField = TextField("")
let list = ListView(items: allItems)

searchField.textChanged = { field, _ in
    let query = field.text.lowercased()
    if query.isEmpty {
        list.items = allItems
    } else {
        list.items = allItems.filter { $0.lowercased().contains(query) }
    }
    list.setNeedsDisplay()
}
```

### Master-Detail with List

```swift
let list = ListView(items: documents.map { $0.title })
let detailView = TextView()

list.selectionChanged = { listView in
    let doc = documents[listView.selectedItem]
    detailView.text = doc.content
}
```

### Table with Actions

```swift
table.activated = { table, row in
    let item = data[row]
    showDetailDialog(for: item)
    return true
}
```

### Multi-Select List

```swift
let list = ListView(items: files)
list.allowMarking = true
list.allowsMultipleSelection = true
list.markerStrings = ["[ ]", "[x]"]

// Get marked items
func getSelectedFiles() -> [String] {
    return (0..<list.count).filter { list.isMarked(item: $0) }
        .map { files[$0] }
}
```

### Dynamic Table Data

```swift
func refreshTable() {
    table.rows = fetchData().map { item in
        [item.name, String(item.count), item.status]
    }
    table.setNeedsDisplay()
}
```

## See Also

- ``ListView``
- ``ListViewDataSource``
- ``ListViewDelegate``
- ``DataTable``
- ``DataColumn``
