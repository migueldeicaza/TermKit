//
//  ProgressBar.swift
//  TermKit
//
//  Created by Miguel de Icaza on 4/28/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * Progress bar can indicate progress of an activity visually.
 *
 * The progressbar can operate in two modes, percentage mode, or
 * activity mode.  The progress bar starts in percentage mode and
 * setting the `fraction` property will reflect on the UI the progress
 * made so far.   Activity mode is used when the application has no
 * way of knowing how much time is left, and is started when you invoke
 * the Pulse() method.    You should call the `pulse` method repeatedly as
 * your application makes progress.
 */
public class ProgressBar : View {
    var isActivity = false
    var activityPos = 0, delta = 0
    
    /// Initializes a new instance of the `ProgressBar` class, starts in percentage mode and uses relative layout.
    public override init ()
    {
        fraction = 0
        super.init ()
        canFocus = false
    }
    
    /**
     * Gets or sets the progress indicator fraction to display, must be a value between 0 and 1
     */
    public var fraction : Float {
        didSet {
            isActivity = false
            setNeedsDisplay()
        }
    }
    
    /**
     * Notifies the progress bar that some progress has taken place.
     *
     * If the ProgressBar is is percentage mode, it switches to activity
     * mode.   If is in activity mode, the marker is moved.
     */
    public func pulse ()
    {
        if isActivity {
            activityPos += delta
            if activityPos < 0 {
                activityPos = 1
                delta = 1
            } else if activityPos >= frame.width {
                activityPos = frame.width - 2
                delta = -1
            }
        } else {
            isActivity = false
            activityPos = 0
            delta = 1
        }
        setNeedsDisplay()
    }
    
    public override func redraw(region: Rect) {
        driver.setAttribute(colorScheme!.normal)
        let top = frame.width
        if isActivity {
            moveTo(col: 0, row: 0)
            for i in 0..<top {
                driver.addRune (i == activityPos ? driver.stipple : driver.space)
            }
        } else {
            moveTo(col: 0, row: 0)
            let mid = Int (fraction * Float (top))
            for _ in 0..<mid {
                driver.addRune(driver.stipple)
            }
            for _ in mid..<top {
                driver.addRune (driver.space)
            }
        }
    }
}
