//
//  Spinner.swift - implements animated spinner views
//  TermKit
//
//  Copyright © 2024 Miguel de Icaza. All rights reserved.
//

import Foundation

/**
 * Spinner view that displays an animated sequence of characters.
 * 
 * The Spinner can be started and stopped, and when active, it animates through
 * a sequence of frames at a specified frame rate defined by the Spinner.Definition.
 */
open class Spinner: View {
    
    /**
     * Definition for a spinner animation, containing the frames and timing information.
     */
    public struct Definition {
        /// Array of strings representing each frame of the animation
        public let frames: [String]
        /// Duration between frames in seconds
        public let frameRate: TimeInterval
        
        public init(frames: [String], frameRate: TimeInterval) {
            self.frames = frames
            self.frameRate = frameRate
        }
    }
    
    // MARK: - Predefined Spinner Definitions
    
    /// Simple line spinner with |, /, -, \ characters
    public static let line = Definition(
        frames: ["|", "/", "-", "\\"],
        frameRate: 0.1  // 1/10th second
    )
    
    /// Braille dot spinner animation
    public static let dot = Definition(
        frames: ["⣾ ", "⣽ ", "⣻ ", "⢿ ", "⡿ ", "⣟ ", "⣯ ", "⣷ "],
        frameRate: 0.1  // 1/10th second
    )
    
    /// Mini dot spinner with single braille characters
    public static let miniDot = Definition(
        frames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"],
        frameRate: 1.0/12.0  // 1/12th second
    )
    
    /// Jumping dot animation
    public static let jump = Definition(
        frames: ["⢄", "⢂", "⢁", "⡁", "⡈", "⡐", "⡠"],
        frameRate: 0.1  // 1/10th second
    )
    
    /// Pulse animation with different block characters
    public static let pulse = Definition(
        frames: ["█", "▓", "▒", "░"],
        frameRate: 0.125  // 1/8th second
    )
    
    /// Points animation
    public static let points = Definition(
        frames: ["∙∙∙", "●∙∙", "∙●∙", "∙∙●"],
        frameRate: 1.0/7.0  // 1/7th second
    )
    
    /// Globe emoji animation
    public static let globe = Definition(
        frames: ["🌍", "🌎", "🌏"],
        frameRate: 0.25  // 1/4th second
    )
    
    /// Moon phases animation
    public static let moon = Definition(
        frames: ["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"],
        frameRate: 0.125  // 1/8th second
    )
    
    /// Monkey emoji animation
    public static let monkey = Definition(
        frames: ["🙈", "🙉", "🙊"],
        frameRate: 1.0/3.0  // 1/3rd second
    )
    
    /// Meter animation
    public static let meter = Definition(
        frames: ["▱▱▱", "▰▱▱", "▰▰▱", "▰▰▰", "▰▰▱", "▰▱▱", "▱▱▱"],
        frameRate: 1.0/7.0  // 1/7th second
    )
    
    /// Hamburger animation
    public static let hamburger = Definition(
        frames: ["☱", "☲", "☴", "☲"],
        frameRate: 1.0/3.0  // 1/3rd second
    )
    
    /// Ellipsis animation
    public static let ellipsis = Definition(
        frames: ["", ".", "..", "..."],
        frameRate: 1.0/3.0  // 1/3rd second
    )
    
    // MARK: - Properties
    
    /// The spinner definition containing frames and timing
    public var definition: Definition {
        didSet {
            currentFrame = 0
            if isAnimating {
                stopAnimation()
                startAnimation()
            }
            autoSize()
        }
    }
    
    /// Whether the spinner is currently animating
    public private(set) var isAnimating: Bool = false
    
    // Private properties
    private var currentFrame: Int = 0
    private var animationWorkItem: DispatchWorkItem?
    
    // MARK: - Initialization
    
    /// Creates a spinner with the specified definition
    public init(definition: Definition = Spinner.line) {
        self.definition = definition
        super.init()
        autoSize()
    }
    
    /// Creates a spinner with a fixed frame and the specified definition
    public init(frame: Rect, definition: Definition = Spinner.line) {
        self.definition = definition
        super.init(frame: frame)
    }
    
    // MARK: - Public Methods
    
    /// Starts the spinner animation
    public func start() {
        guard !isAnimating else { return }
        isAnimating = true
        currentFrame = 0
        startAnimation()
    }
    
    /// Stops the spinner animation
    public func stop() {
        guard isAnimating else { return }
        isAnimating = false
        stopAnimation()
        setNeedsDisplay()
    }
    
    /// Automatically sizes the view to fit the largest frame
    public func autoSize() {
        let maxWidth = definition.frames.reduce(0) { max($0, $1.cellCount()) }
        width = Dim.sized(maxWidth)
        height = Dim.sized(1)
        setNeedsLayout()
    }
    
    // MARK: - Private Methods
    
    private func startAnimation() {
        scheduleNextFrame()
    }
    
    private func stopAnimation() {
        animationWorkItem?.cancel()
        animationWorkItem = nil
    }
    
    private func scheduleNextFrame() {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.isAnimating else { return }
            self.updateFrame()
            if self.isAnimating {
                self.scheduleNextFrame()
            }
        }
        animationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + definition.frameRate, execute: workItem)
    }
    
    private func updateFrame() {
        currentFrame = (currentFrame + 1) % definition.frames.count
        setNeedsDisplay()
    }
    
    // MARK: - View Override Methods
    
    open override func redraw(region: Rect, painter: Painter) {
        painter.clear()
        
        guard !definition.frames.isEmpty else { return }
        
        let frameText = definition.frames[currentFrame]
        painter.goto(col: 0, row: 0)
        painter.add(str: frameText)
    }
    
    open override func positionCursor() {
        moveTo(col: frame.minX, row: frame.minY)
    }
    
    // Clean up timer when view is removed
    deinit {
        stopAnimation()
    }
}
