//
//  DemoTabBar.swift
//  TermKit
//
//  TabView demonstration showing different tab styles and functionality
//

import Foundation
import TermKit

func DemoTabBar(tabPosition: TabView.TabPosition = .top) -> Window {
    let win = Window("TabView Demo")
    win.closeOnControlC = true
    win.fill()
    
    // Create main container
    // TODO: we a
    let container = View()
    container.fill()
    win.addSubview(container)
    
    // Create style selection buttons at the top
    let styleLabel = Label("Tab Style:")
    styleLabel.x = Pos.at(2)
    styleLabel.y = Pos.at(1)
    container.addSubview(styleLabel)
    
    let plainButton = Button("Plain")
    plainButton.x = Pos.right(of: styleLabel) + 2
    plainButton.y = Pos.at(1)
    container.addSubview(plainButton)
    
    let borderedButton = Button("Bordered")
    borderedButton.x = Pos.right(of: plainButton) + 2
    borderedButton.y = Pos.at(1)
    container.addSubview(borderedButton)
    
    // Create position selection buttons
    let positionLabel = Label("Tab Position:")
    positionLabel.x = Pos.right(of: borderedButton) + 4
    positionLabel.y = Pos.at(1)
    container.addSubview(positionLabel)
    
    let topButton = Button("Top")
    topButton.x = Pos.right(of: positionLabel) + 2
    topButton.y = Pos.at(1)
    container.addSubview(topButton)
    
    let bottomButton = Button("Bottom")
    bottomButton.x = Pos.right(of: topButton) + 2
    bottomButton.y = Pos.at(1)
    container.addSubview(bottomButton)
    
    let leftButton = Button("Left")
    leftButton.x = Pos.right(of: bottomButton) + 2
    leftButton.y = Pos.at(1)
    container.addSubview(leftButton)
    
    let rightButton = Button("Right")
    rightButton.x = Pos.right(of: leftButton) + 2
    rightButton.y = Pos.at(1)
    container.addSubview(rightButton)
    
    // Create the main TabView
    let tabView = TabView()
    tabView.tabPosition = tabPosition
    tabView.x = Pos.at(2)
    tabView.y = Pos.at(3)
    tabView.width = Dim.fill(2)
    tabView.height = Dim.fill(10)
    container.addSubview(tabView)
    
    // Tab 1: Text Controls
    let textTab = View()
    textTab.fill()
    
    let textLabel = Label("Text Controls Demo")
    textLabel.x = Pos.at(2)
    textLabel.y = Pos.at(1)
    textTab.addSubview(textLabel)
    
    let nameLabel = Label("Name:")
    nameLabel.x = Pos.at(2)
    nameLabel.y = Pos.at(3)
    textTab.addSubview(nameLabel)
    
    let nameField = TextField("Enter your name")
    nameField.x = Pos.right(of: nameLabel) + 2
    nameField.y = Pos.at(3)
    nameField.width = Dim.sized(30)
    textTab.addSubview(nameField)
    
    let emailLabel = Label("Email:")
    emailLabel.x = Pos.at(2)
    emailLabel.y = Pos.at(5)
    textTab.addSubview(emailLabel)
    
    let emailField = TextField("user@example.com")
    emailField.x = Pos.right(of: emailLabel) + 2
    emailField.y = Pos.at(5)
    emailField.width = Dim.sized(30)
    textTab.addSubview(emailField)
    
    let multilineLabel = Label("Comments:")
    multilineLabel.x = Pos.at(2)
    multilineLabel.y = Pos.at(7)
    textTab.addSubview(multilineLabel)
    
    let textView = TextView()
    textView.x = Pos.at(2)
    textView.y = Pos.at(8)
    textView.width = Dim.fill(2)
    textView.height = Dim.sized(6)
    textView.text = "This is a multiline text area.\nYou can type multiple lines here.\nTry navigating with arrow keys!"
    textTab.addSubview(textView)
    
    // Tab 2: Buttons and Checkboxes
    let controlsTab = View()
    controlsTab.fill()
    
    let controlsLabel = Label("Buttons and Controls Demo")
    controlsLabel.x = Pos.at(2)
    controlsLabel.y = Pos.at(1)
    controlsTab.addSubview(controlsLabel)
    
    let button1 = Button("Click Me!")
    button1.x = Pos.at(2)
    button1.y = Pos.at(3)
    button1.clicked = { _ in
        MessageBox.query("Button Clicked", message: "You clicked the first button!", buttons: ["OK"]) { _ in }
    }
    controlsTab.addSubview(button1)
    
    let button2 = Button("Another Button")
    button2.x = Pos.right(of: button1) + 2
    button2.y = Pos.at(3)
    button2.clicked = { _ in
        MessageBox.query("Button Clicked", message: "You clicked the second button!", buttons: ["OK"]) { _ in }
    }
    controlsTab.addSubview(button2)
    
    let checkbox1 = Checkbox("Enable notifications")
    checkbox1.x = Pos.at(2)
    checkbox1.y = Pos.at(5)
    controlsTab.addSubview(checkbox1)
    
    let checkbox2 = Checkbox("Auto-save documents")
    checkbox2.x = Pos.at(2)
    checkbox2.y = Pos.at(6)
    checkbox2.checked = true
    controlsTab.addSubview(checkbox2)
    
    let checkbox3 = Checkbox("Show hidden files")
    checkbox3.x = Pos.at(2)
    checkbox3.y = Pos.at(7)
    controlsTab.addSubview(checkbox3)
    
    // Add radio group
    let radioGroup = RadioGroup(labels: ["Option A", "Option B", "Option C"], selected: 0)
    radioGroup.x = Pos.at(2)
    radioGroup.y = Pos.at(9)
    radioGroup.width = Dim.sized(20)
    radioGroup.height = Dim.sized(3)
    // RadioGroup selected item is set in the constructor
    controlsTab.addSubview(radioGroup)
    
    // Tab 3: Progress and Status
    let progressTab = View()
    progressTab.fill()
    
    let progressLabel = Label("Progress and Status Demo")
    progressLabel.x = Pos.at(2)
    progressLabel.y = Pos.at(1)
    progressTab.addSubview(progressLabel)
    
    let progressBar1 = ProgressBar()
    progressBar1.x = Pos.at(2)
    progressBar1.y = Pos.at(3)
    progressBar1.width = Dim.sized(40)
    progressBar1.fraction = 0.3
    progressTab.addSubview(progressBar1)
    
    let progressLabel1 = Label("30% Complete")
    progressLabel1.x = Pos.right(of: progressBar1) + 2
    progressLabel1.y = Pos.at(3)
    progressTab.addSubview(progressLabel1)
    
    let progressBar2 = ProgressBar()
    progressBar2.x = Pos.at(2)
    progressBar2.y = Pos.at(5)
    progressBar2.width = Dim.sized(40)
    progressBar2.fraction = 0.7
    progressTab.addSubview(progressBar2)
    
    let progressLabel2 = Label("70% Complete")
    progressLabel2.x = Pos.right(of: progressBar2) + 2
    progressLabel2.y = Pos.at(5)
    progressTab.addSubview(progressLabel2)
    
    let statusBar = StatusBar()
    statusBar.y = Pos.at(10)
    statusBar.width = Dim.fill()
    progressTab.addSubview(statusBar)
    
    // Tab 4: Lists and Tables (with many items to test scrolling)
    let listTab = View()
    listTab.fill()
    
    let listLabel = Label("Lists Demo - This tab has a long title to test scrolling")
    listLabel.x = Pos.at(2)
    listLabel.y = Pos.at(1)
    listTab.addSubview(listLabel)
    
    let items = (1...100).map { i in "Item \(i): This is list item number \(i)" }
    let listView = ListView(items: items)
    listView.x = Pos.at(2)
    listView.y = Pos.at(3)
    listView.width = Dim.fill(2)
    listView.height = Dim.fill(1)
    listTab.addSubview(listView)
    
    // Tab 5: More tabs to test horizontal scrolling
    let tab5 = View()
    tab5.fill()
    let tab5Label = Label("Tab 5 Content")
    tab5Label.x = Pos.at(2)
    tab5Label.y = Pos.at(1)
    tab5.addSubview(tab5Label)
    
    let tab6 = View()
    tab6.fill()
    let tab6Label = Label("Tab 6 Content")
    tab6Label.x = Pos.at(2)
    tab6Label.y = Pos.at(1)
    tab6.addSubview(tab6Label)
    
    let tab7 = View()
    tab7.fill()
    let tab7Label = Label("Tab 7 Content")
    tab7Label.x = Pos.at(2)
    tab7Label.y = Pos.at(1)
    tab7.addSubview(tab7Label)
    
    let tab8 = View()
    tab8.fill()
    let tab8Label = Label("Tab 8 Content")
    tab8Label.x = Pos.at(2)
    tab8Label.y = Pos.at(1)
    tab8.addSubview(tab8Label)
    
    // Add all tabs to the TabView
    tabView.addTab("Text Fields", content: textTab)
    tabView.addTab("Controls", content: controlsTab)
    tabView.addTab("Progress", content: progressTab)
    tabView.addTab("Lists & Tables", content: listTab)
    tabView.addTab("Extra Tab 1", content: tab5)
    tabView.addTab("Extra Tab 2", content: tab6)
    tabView.addTab("Extra Tab 3", content: tab7)
    tabView.addTab("Extra Tab 4", content: tab8)
    
    // Style button handlers
    plainButton.clicked = { _ in
        tabView.tabStyle = .plain
    }
    
    borderedButton.clicked = { _ in
        tabView.tabStyle = .bordered
    }
    
    // Position button handlers
    topButton.clicked = { _ in
        tabView.tabPosition = .top
    }
    
    bottomButton.clicked = { _ in
        tabView.tabPosition = .bottom
    }
    
    leftButton.clicked = { _ in
        tabView.tabPosition = .left
    }
    
    rightButton.clicked = { _ in
        tabView.tabPosition = .right
    }
    
    // Add control buttons at the bottom
    let controlsFrame = Frame("Tab Controls")
    controlsFrame.x = Pos.at(2)
    controlsFrame.y = Pos.bottom(of: tabView) + 1
    controlsFrame.width = Dim.fill(2)
    controlsFrame.height = Dim.sized(6)
    container.addSubview(controlsFrame)
    
    let addTabButton = Button("Add Tab")
    addTabButton.x = Pos.at(2)
    addTabButton.y = Pos.at(1)
    addTabButton.clicked = { _ in
        let newTab = View()
        newTab.fill()
        let newLabel = Label("Dynamically Added Tab")
        newLabel.x = Pos.at(2)
        newLabel.y = Pos.at(1)
        newTab.addSubview(newLabel)
        
        let tabIndex = tabView.addTab("New Tab", content: newTab)
        tabView.selectedTab = tabIndex
    }
    controlsFrame.addSubview(addTabButton)
    
    let removeTabButton = Button("Remove Current")
    removeTabButton.x = Pos.right(of: addTabButton) + 2
    removeTabButton.y = Pos.at(1)
    removeTabButton.clicked = { _ in
        if tabView.tabCount > 1 {
            tabView.removeTab(at: tabView.selectedTab)
        }
    }
    controlsFrame.addSubview(removeTabButton)
    
    let renameTabButton = Button("Rename Current")
    renameTabButton.x = Pos.right(of: removeTabButton) + 2
    renameTabButton.y = Pos.at(1)
    renameTabButton.clicked = { _ in
        let currentTitle = tabView.getTabTitle(at: tabView.selectedTab) ?? "Unknown"
        InputBox.request("Rename Tab", message: "Enter new tab title:", text: currentTitle) { newTitle in
            if let newTitle = newTitle {
                tabView.setTabTitle(at: tabView.selectedTab, title: newTitle)
            }
        }
    }
    controlsFrame.addSubview(renameTabButton)
    
    let infoLabel = Label("Use Tab/Shift+Tab to navigate, arrows to switch tabs, mouse to click")
    infoLabel.x = Pos.at(2)
    infoLabel.y = Pos.at(3)
    infoLabel.width = Dim.fill(2)
    controlsFrame.addSubview(infoLabel)
    
    return win
}
