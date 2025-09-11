//
//  Window.swift - These are toplevel that are drawn with a border.
//  TermKit
//
//  Created by Miguel de Icaza on 4/14/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

class ContentView: View {
    open override var debugDescription: String {
        return "Window.ContentView (\(super.debugDescription))"
    }
    
    open override func redraw(region: Rect, painter: Painter) {
        painter.attribute = superview?.colorScheme.normal ?? ColorScheme.fallback.normal
        painter.clear (needDisplay)
        super.redraw(region: region, painter: painter)
    }
}

/**
 * A toplevel view that draws a frame around its region and has a "ContentView" subview where the contents are added.
 * with an optional title that is displayed at the top
 */
open class Window: Toplevel {
    var contentView: View
    var padding: Int
    
    /// The title to be displayed for this window.
    public var title: String? {
        didSet {
            setNeedsDisplay()
        }
    }

    public override convenience init ()
    {
        self.init (nil, padding: 0)
    }
    
    public init (_ title: String? = nil, padding: Int = 0)
    {
        self.padding = padding
        self.title = title
        contentView = ContentView()
        contentView.x = Pos.at (padding + 1)
        contentView.y = Pos.at (padding + 1)
        contentView.width = Dim.fill(padding+1)
        contentView.height = Dim.fill(padding+1)
        contentView.canFocus = true
        super.init ()
        super.addSubview(contentView)
        
        wantMousePositionReports = true
        wantContinuousButtonPressed = true
    }
    
    open override func addSubview(_ view: View)
    {
        contentView.addSubview(view)
        if view.canFocus {
            canFocus = true
        }
    }
    
    /// Controls whether this window can be dragged, defaults to not.  If you set this value it will switch the layoutStyle to `.fixed` and the location will be determined by the `frame`
    public var allowMove = false {
        didSet {
            if allowMove {
                layoutStyle = .fixed
            }
            setNeedsDisplay()
        }
    }
    
    // Before we maximize, we store the values here
    var unmaximizedBounds: Rect? = nil
    
    /// Controls whether this window can be maximized, if so, the layoutStyle will be switched to `.fixed`
    public var allowMaximize = false {
        didSet {
            if allowMaximize {
                layoutStyle = .fixed
            }
            setNeedsDisplay()
        }
    }
    
    // Currently private, since I do not have a good palce to put this
    var allowMinimize = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// If this value is set, then the layoutStyle will be changed to `.fixed`
    public var allowResize = false {
        didSet {
            layoutStyle = .fixed
        }
    }
    
    lazy var closeAttribute = colorScheme.normal.change(foreground: .red)
    lazy var minimizeAttribute = colorScheme.normal.change(foreground: .brightYellow)
    lazy var maximizeAttribute = colorScheme.normal.change(foreground: .green)
    
    // TODO: remove
    
    // TODO: removeAll

    open override func resignFirstResponder() -> Bool {
        setNeedsDisplay()
        return super.resignFirstResponder()
    }
    
    open override func becomeFirstResponder() -> Bool {
        setNeedsDisplay()
        return super.becomeFirstResponder()
    }
    
    open override func redraw(region: Rect, painter p: Painter) {
        //log ("Window.redraw: \(frame) and region to redraw is: \(region)")
        let contentFrame = contentView.frame
        if !needDisplay.isEmpty {
            p.attribute = colorScheme.normal
            p.drawFrame (bounds, padding: padding, fill: false, double: hasFocus)
            
            if allowResize {
                let b = bounds
                p.goto(col: b.width-1-padding, row: b.height-1-padding)
                
                // Invert the character for resizable ones
                p.add(rune: hasFocus ? driver.lrCorner : driver.doubleLrCorner)
            }
            var needButtons = (closeClicked != nil ? 1 : 0) + (allowMaximize ? 1 : 0) + (allowMinimize ? 1 : 0)
            if needButtons > 0 {
                let buttonIcon = Application.driver.filledCircle
                
                p.goto (col: 1+padding, row: padding)
                p.add(rune: Application.driver.rightTee)
                if closeClicked != nil {
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
                p.attribute = colorScheme.normal
                p.add(rune: Application.driver.leftTee)
                needButtons += 2
            }
            
            if hasFocus {
                p.attribute = colorScheme.normal
            }
            let width = frame.width
            if let t = title, width > 4+needButtons {
                p.goto (col: padding+needButtons+1, row: padding)
                p.add (rune: Unicode.Scalar(32))
                let str = t.count > (width+4) ? t : String (t.prefix (width-4))
                p.add (str: str)
                p.add (rune: Unicode.Scalar(32))
            }
            p.attribute = colorScheme.normal
        }
        clearNeedsDisplay()
    }
    
    /// If this value is set to not-nil, then a close icon is displayed.
    public var closeClicked: ((Window) -> ())? = nil
    
    var moveGrab: Point? = nil
    var resizeGrab: Point? = nil
        
    open override func mouseEvent(event: MouseEvent) -> Bool {
        log ("Mouse event on Window '\(title ?? "<unnamed>"):#\(viewId)' -> \(event)")
        if event.flags.contains (.button1Released) || event.flags.contains(.button1Released) {
            log ("grab finished")
            Application.ungrabMouse()

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
            let delta = event.absPos - g

            log("Frame was \(frame)")
            frame = Rect(x: frame.minX + delta.x, y: frame.minY + delta.y, width: frame.width, height: frame.height)
            log("   NOW \(frame)")
            superview?.setNeedsDisplay()
            moveGrab = event.absPos
            return true
        } else if let g = resizeGrab {
            let delta = event.absPos - g

            self.width = Dim.sized (frame.width + delta.x)
            self.height = Dim.sized (frame.height + delta.y)
            setNeedsLayout()
            resizeGrab = event.absPos
            return true

        }
        if event.flags == [.button1Clicked] {
            log ("oops")
        }
        if event.flags == [.button1Clicked] && event.pos.y == padding {
            let x = event.pos.x
            var expect = 2+padding
            if let closeClicked {
                if x == expect {
                    closeClicked (self)
                    return true
                }
                expect += 1
            }
            if allowMinimize {
                if x == expect {
                    log ("minimize")
                    // TODO
                    return true
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
                    return true
                }
            }
            if !hasFocus {
                superview?.setFocus(self)
            }
            return true
        }
        if event.flags == [.button4Pressed] || event.flags == [.button1Pressed], layoutStyle == .fixed, allowMove {
            if let superview {
                superview.bringSubviewToFront(self)
                superview.setFocus(self)
            }
    
            if event.pos.y == padding {
                Application.grabMouse(from: self)
                moveGrab = event.absPos
            } else if event.pos.y == frame.height-padding-1 && event.pos.x == frame.width-padding-1 {
                Application.grabMouse(from: self)
                resizeGrab = event.absPos
            }
        }
        return true
    }
    
    open override func positionCursor() {
        if let f = focused {
            f.positionCursor()
        } else {
            moveTo (col: 1, row: 1)
        }
    }
    open override var debugDescription: String {
        return "Window (\(super.debugDescription))"
    }
}
