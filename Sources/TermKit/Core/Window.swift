//
//  Window.swift - These are toplevel that are drawn with a border.
//  TermKit
//
//  Created by Miguel de Icaza on 4/14/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * A toplevel view that draws a frame around its region and has a "ContentView" subview where the contents are added.
 * with an optional title that is displayed at the top
 */
public class Window : Toplevel {
    var contentView : View
    var padding : Int
    
    /// The title to be displayed for this window.
    public var title : String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    class ContentView : View {
        public override var debugDescription: String {
            return "Window.ContentView (\(super.debugDescription))"
        }
    }
    
    public override convenience init ()
    {
        self.init (nil, padding: 0)
    }
    
    public init (_ title : String? = nil, padding : Int = 0)
    {
        self.padding = padding
        self.title = title
        contentView = ContentView()
        contentView.x = Pos.at (padding + 1)
        contentView.y = Pos.at (padding + 1)
        contentView.width = Dim.fill(padding+1)
        contentView.height = Dim.fill(padding+1)
        super.init ()
        super.addSubview(contentView)
        
        wantMousePositionReports = true
        wantContinuousButtonPressed = true
    }
    
    public override func addSubview(_ view: View)
    {
        contentView.addSubview(view)
        if view.canFocus {
            canFocus = true
        }
    }
    
    public var allowMove = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // Before we maximize, we store the values here
    var unmaximizedBounds: Rect? = nil
    
    public var allowMaximize = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // Currently private, since I do not have a good palce to put this
    var allowMinimize = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var allowClose = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var allowResize = false
    
    lazy var closeAttribute = colorScheme.normal.change(foreground: .red)
    lazy var minimizeAttribute = colorScheme.normal.change(foreground: .brightYellow)
    lazy var maximizeAttribute = colorScheme.normal.change(foreground: .green)
    
    // TODO: remove
    
    // TODO: removeAll

    public override func resignFirstResponder() -> Bool {
        setNeedsDisplay()
        return super.resignFirstResponder()
    }
    
    public override func becomeFirstResponder() -> Bool {
        setNeedsDisplay()
        return super.becomeFirstResponder()
    }
    
    public override func redraw(region: Rect, painter p: Painter) {
        //log ("Window.redraw: \(frame) and region to redraw is: \(region)")
        
        if !needDisplay.isEmpty {
            p.attribute = colorScheme!.normal
            p.drawFrame (bounds, padding: padding, fill: true, double: hasFocus)
            
            var needButtons = (allowClose ? 1 : 0) + (allowMaximize ? 1 : 0) + (allowMinimize ? 1 : 0)
            if needButtons > 0 {
                let buttonIcon = Application.driver.filledCircle
                
                p.goto (col: 1+padding, row: padding)
                p.add(rune: Application.driver.rightTee)
                if allowClose {
                    p.attribute = closeAttribute
                    p.add(rune: buttonIcon)
                }
                if allowMinimize {
                    p.attribute = minimizeAttribute
                    p.add(rune: buttonIcon)
                }
                if allowMaximize {
                    p.attribute = maximizeAttribute
                    p.add(rune: buttonIcon)
                }
                p.attribute = colorScheme!.normal
                p.add(rune: Application.driver.leftTee)
                needButtons += 2
            }
            
            if hasFocus {
                p.attribute = colorScheme!.normal
            }
            let width = frame.width
            if let t = title, width > 4+needButtons {
                p.goto (col: padding+needButtons+1, row: padding)
                p.add (rune: Unicode.Scalar(32))
                let str = t.count > (width+4) ? t : String (t.prefix (width-4))
                p.add (str: str)
                p.add (rune: Unicode.Scalar(32))
            }
            p.attribute = colorScheme!.normal
        }
        contentView.redraw(region: contentView.bounds, painter: Painter (from: contentView, parent: p))
        clearNeedsDisplay()
    }
    
    var closeCallback: (Window) -> () = { w in }
    /// Call this method to set the close event handler
    public func closeClicked (callback: @escaping (Window) -> ())
    {
        closeCallback = callback
    }
    
    var moveGrab: Point? = nil
    var resizeGrab: Point? = nil
    
    public override func mouseEvent(event: MouseEvent) -> Bool {
        if event.flags == [.button4Released] {
            if moveGrab != nil {
                moveGrab = nil
                return true
            }
            if resizeGrab != nil {
                resizeGrab = nil
                return true
            }
        }
        if let g = moveGrab {
            let deltax = event.absX - g.x
            let deltay = event.absY - g.y

            self.x = Pos.at (frame.minX + deltax)
            self.y = Pos.at (frame.minY + deltay)
            setNeedsLayout()
            moveGrab = Point (x: event.absX, y: event.absY)
            return true
        } else if let g = resizeGrab {
            let deltax = event.absX - g.x
            let deltay = event.absY - g.y

            self.width = Dim.sized (frame.width + deltax)
            self.height = Dim.sized (frame.height + deltay)
            setNeedsLayout()
            resizeGrab = Point (x: event.absX, y: event.absY)
            return true

        }
        if event.flags == [.button1Clicked] && event.y == padding {
            let x = event.x
            var expect = 2+padding
            if allowClose {
                if x == expect {
                    closeCallback (self)
                }
                expect += 1
            }
            if allowMinimize {
                if x == expect {
                    log ("minimize")
                }
                expect += 1
            }
            if allowMaximize {
                if x == expect {
                    if let prev = unmaximizedBounds {
                        set (x: prev.minX, y: prev.minY, width: prev.width, height: prev.height)
                        unmaximizedBounds = nil
                    } else {
                        unmaximizedBounds = frame
                        self.x = Pos.at (0)
                        self.y = Pos.at (1)
                        height = Dim.fill()
                        width = Dim.fill()
                        superview?.setFocus(self)
                    }
                }
            }
            
        }
        if event.flags == [.button4Pressed] || event.flags == [.button1Pressed] {
            print ("line: \(event.y) and \(frame.height-padding-1)")
            if event.y == padding {
                log ("grabbed")
                Application.grabMouse(from: self)
                moveGrab = Point (x: event.absX, y: event.absY)
            } else if event.y == frame.height-padding-1 && event.x == frame.width-padding-1 {
                resizeGrab = Point (x: event.absX, y: event.absY)
            }
        }
        return true
    }
    
    public override func positionCursor() {
        if let f = focused {
            f.positionCursor()
        } else {
            moveTo (col: 1, row: 1)
        }
    }
    public override var debugDescription: String {
        return "Window (\(super.debugDescription))"
    }
}
