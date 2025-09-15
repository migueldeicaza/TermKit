//
//  SwiftLogging.swift
//  TermKit
//
//  Lightweight bootstrap for Swift Logging with a file-backed handler.
//

import Foundation
import Logging

// Simple file-backed LogHandler.
final class FileLogHandler: LogHandler {
    private let label: String
    private let fileHandle: FileHandle
    private let lock = NSLock()
    public var metadata: Logger.Metadata = [:]
    public var logLevel: Logger.Level = .debug

    init(label: String, fileURL: URL) {
        self.label = label
        // Ensure file exists
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
        // Open for appending
        self.fileHandle = try! FileHandle(forWritingTo: fileURL)
        // Seek to end for append behavior
        try? self.fileHandle.seekToEnd()
    }

    deinit {
        try? fileHandle.close()
    }

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        let ts = ISO8601DateFormatter().string(from: Date())
        var md = self.metadata
        if let metadata { md.merge(metadata) { $1 } }
        let mdStr = md.isEmpty ? "" : " \(md)"
        let line = "\(ts) [\(level)] \(label): \(message)\(mdStr)\n"
        if let data = line.data(using: .utf8) {
            lock.lock()
            fileHandle.write(data)
            lock.unlock()
        }
    }
}

enum TermKitLog {
    private static var bootstrapped = false
    private static var loggerInstance: Logger = Logger(label: "TermKit")

    static func bootstrapIfNeeded() {
        guard !bootstrapped else { return }
        let path = ProcessInfo.processInfo.environment["TERMKIT_LOG"] ?? "/tmp/termkit.log"
        let fileURL = URL(fileURLWithPath: path)
        LoggingSystem.bootstrap { label in
            FileLogHandler(label: label, fileURL: fileURL)
        }
        loggerInstance = Logger(label: "TermKit")
        bootstrapped = true
        loggerInstance.info("Logging bootstrapped -> \(path)")
    }

    static var logger: Logger {
        bootstrapIfNeeded()
        return loggerInstance
    }
}

