//
//  DemoMarkdown.swift
//  Example
//
//  Demonstrates the MarkdownView component rendering markdown content
//

import Foundation
import TermKit

class DemoMarkdown: DemoHost {
    
    init() {
        super.init(title: "Markdown Demo")
    }
    
    override func setupDemo() {
        let win = topWindow
        
        let markdown = MarkdownView()
        markdown.x = Pos.at(0)
        markdown.y = Pos.at(0) 
        markdown.width = Dim.fill()
        markdown.height = Dim.fill()
        
        let sampleMarkdown = """
### Features Supported

- **Headings** with different levels (# ## ### etc.)
- **Paragraphs** with proper spacing between them
- **Emphasis** using *italic* and **bold** formatting
- **Code blocks** with syntax highlighting preservation
- **Inline code** using backtick notation
- **Links** in [text](url) format
- **Block quotes** with > prefix notation
- **Lists** with bullet point indicators


#### Heading Styles

All heading levels are properly supported with different visual treatments.

## Navigation Keys

Use these keyboard shortcuts to navigate through the content:

- **↑/↓ arrows** or **Ctrl+P/N**: Scroll line by line
- **Page Up/Down** or **Alt+V/Ctrl+V**: Scroll page by page  
- **Home/End** or **Alt+</Alt+>**: Jump to beginning/end of document

## Code Example

Here's how to use the MarkdownView in your own code:

```swift
let markdown = MarkdownView()
markdown.setMarkdown(content: "# Hello World\\n\\nThis is **bold** text.")
parent.addSubview(markdown)
```

## Block Quote Example

> This is a block quote demonstrating how quoted text appears in the markdown viewer.
> 
> Block quotes can span multiple lines and preserve the formatting as expected.

## List Examples

### Unordered List

- First item in the list
- Second item with some *emphasized* text
- Third item with `inline code`
- Fourth item to demonstrate scrolling behavior

## Technical Details

The MarkdownView is built using:

- **swift-markdown** library for parsing
- **TermKit's AttributedString** for rendering
- **View base class** for integration with TermKit's layout system
- **MarkupWalker protocol** for traversing the markdown AST

### Color Customization

The view uses the current color scheme by default:

- Normal text uses `colorScheme.normal`
- Headings use `colorScheme.focus`  
- Emphasized text uses `colorScheme.hotNormal`
- Code uses `colorScheme.hotFocus`

You can also customize colors by setting:

```swift
markdown.headingColor = customAttribute
markdown.emphasisColor = customAttribute
markdown.linkColor = customAttribute
markdown.codeColor = customAttribute
```

# Nested Lists Test

Testing nested list rendering:

- Level 0 item
- Level 0 with children:
  - Level 1 child A
  - Level 1 child B  
    - Level 2 child A
    - Level 2 child B with VERY LONG text that should wrap around and continue properly aligned under the L of Level
      - Level 3 deeply nested item
  - Back to level 1 child C
- Back to level 0 item

---

**Try scrolling** through this content using the navigation keys listed above. The MarkdownView handles long documents efficiently and provides smooth scrolling through any amount of markdown content.

Press **Control-C** or use the menu to return to the main demo selection.
"""
        
        markdown.setMarkdown(content: sampleMarkdown)
        markdown.wrapAround = true // Enable text wrapping
        win.addSubview(markdown)
        
        // Auto-quit for test mode (TERMKIT_DRIVER=tty)
        if ProcessInfo.processInfo.environment["TERMKIT_DRIVER"] == "tty" {
            DispatchQueue.main.async {
                Application.requestStop()
            }
        }
        
        // Add status bar help
        statusBar.removePanel(id: "quit")
        statusBar.addPanel(id: "scroll", content: "↑↓/PgUp/PgDn: Scroll")
        statusBar.addHotkeyPanel(id: "quit", hotkeyText: "Control-C", labelText: "Quit", hotkey: .controlC) {
            Application.requestStop()
        }
    }
}
