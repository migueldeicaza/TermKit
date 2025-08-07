//
//  TerminfoParser.swift
//  TermKit
//
//  Created by TermKit on 2025-08-04.
//

import Foundation

/**
 * Parser for terminfo database files.
 * Reads binary terminfo files and extracts terminal capabilities.
 */
public class TerminfoParser {
    
    struct TerminfoEntry {
        let booleans: [Bool]
        let numbers: [Int16]
        let strings: [String?]
        let extendedBooleans: [Bool]
        let extendedNumbers: [Int32]
        let extendedStrings: [String?]
    }
    
    private static let commonTerminfoPaths = [
        "/usr/share/terminfo",
        "/usr/lib/terminfo",
        "/usr/local/share/terminfo",
        "/etc/terminfo",
        "~/.terminfo"
    ]
    
    /**
     * Parses terminfo capabilities for the given terminal type.
     * First checks TERM environment variable, then falls back to provided terminal name.
     */
    public static func parseCapabilities(for terminalType: String? = nil) -> TerminalCapability? {
        let term = terminalType ?? ProcessInfo.processInfo.environment["TERM"] ?? "xterm"
        
        // Try to find terminfo file
        guard let data = loadTerminfoFile(for: term) else {
            return nil
        }
        
        // Parse the binary data
        guard let entry = parseTerminfoData(data) else {
            return nil
        }
        
        // Convert to TerminalCapability
        return createTerminalCapability(from: entry, terminalType: term)
    }
    
    private static func loadTerminfoFile(for term: String) -> Data? {
        guard !term.isEmpty else { return nil }
        
        let firstChar = String(term.first!).lowercased()
        let hexChar = String(format: "%02x", firstChar.unicodeScalars.first!.value)
        
        // Check each terminfo path
        for basePath in commonTerminfoPaths {
            let expandedPath = NSString(string: basePath).expandingTildeInPath
            let termPath = "\(expandedPath)/\(hexChar)/\(term)"
            
            if let data = try? Data(contentsOf: URL(fileURLWithPath: termPath)) {
                return data
            }
        }
        
        return nil
    }
    
    private static func parseTerminfoData(_ data: Data) -> TerminfoEntry? {
        guard data.count >= 12 else { return nil }
        
        var offset = 0
        
        // Read header
        let magic = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int16.self) }
        offset += 2
        
        // Check magic number (0x11a for compiled terminfo)
        guard magic == 0x011a else { return nil }
        
        let namesSize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int16.self) })
        offset += 2
        
        let boolCount = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int16.self) })
        offset += 2
        
        let numCount = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int16.self) })
        offset += 2
        
        let strCount = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int16.self) })
        offset += 2
        
        let _ = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int16.self) })
        offset += 2
        
        // Skip terminal names
        offset += namesSize
        
        // Align to even boundary
        if offset % 2 != 0 {
            offset += 1
        }
        
        // Read boolean capabilities
        var booleans: [Bool] = []
        for _ in 0..<boolCount {
            if offset < data.count {
                let value = data[offset]
                booleans.append(value != 0)
                offset += 1
            }
        }
        
        // Align to even boundary
        if offset % 2 != 0 {
            offset += 1
        }
        
        // Read numeric capabilities
        var numbers: [Int16] = []
        for _ in 0..<numCount {
            if offset + 1 < data.count {
                let value = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int16.self) }
                numbers.append(value)
                offset += 2
            }
        }
        
        // Read string capability offsets
        var stringOffsets: [Int16] = []
        for _ in 0..<strCount {
            if offset + 1 < data.count {
                let value = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int16.self) }
                stringOffsets.append(value)
                offset += 2
            }
        }
        
        // Read string table and extract strings
        let stringTableStart = offset
        var strings: [String?] = []
        
        for stringOffset in stringOffsets {
            if stringOffset == -1 {
                strings.append(nil)
            } else {
                let actualOffset = stringTableStart + Int(stringOffset)
                if actualOffset < data.count {
                    // Find null terminator
                    var endOffset = actualOffset
                    while endOffset < data.count && data[endOffset] != 0 {
                        endOffset += 1
                    }
                    
                    if let string = String(data: data[actualOffset..<endOffset], encoding: .utf8) {
                        strings.append(string)
                    } else {
                        strings.append(nil)
                    }
                } else {
                    strings.append(nil)
                }
            }
        }
        
        return TerminfoEntry(
            booleans: booleans,
            numbers: numbers,
            strings: strings,
            extendedBooleans: [], // For simplicity, not parsing extended capabilities
            extendedNumbers: [],
            extendedStrings: []
        )
    }
    
    private static func createTerminalCapability(from entry: TerminfoEntry, terminalType: String) -> TerminalCapability {
        return TerminfoCapability(entry: entry, terminalType: terminalType)
    }
    
    /**
     * Extracts the number of colors supported by the terminal from terminfo.
     * Returns nil if the information is not available.
     */
    public static func getColorCount(for terminalType: String? = nil) -> Int? {
        let term = terminalType ?? ProcessInfo.processInfo.environment["TERM"] ?? "xterm"
        
        guard let data = loadTerminfoFile(for: term) else {
            return nil
        }
        
        guard let entry = parseTerminfoData(data) else {
            return nil
        }
        
        // Standard terminfo numeric capability indices (from terminfo(5)):
        // 0: columns (cols) - number of columns in a line
        // 1: init_tabs (it) - tabs initially every # spaces
        // 2: lines - number of lines on screen or page
        // 3: lines_of_memory (lm) - lines of memory if > line, 0 means varies
        // 4: magic_cookie_glitch (xmc) - number of blank characters left by smso or rmso
        // 5: padding_baud_rate (pb) - lowest baud rate where cr/nl padding is needed
        // 6: virtual_terminal (vt) - virtual terminal number (CB/unix)
        // 7: width_status_line (wsl) - number of columns in status line
        // 8: num_labels (nlab) - number of labels on screen
        // 9: label_height (lh) - rows in each label
        // 10: label_width (lw) - columns in each label
        // 11: max_attributes (ma) - maximum combined attributes terminal can handle
        // 12: maximum_windows (wnum) - maximum number of definable windows
        // 13: colors (colors) - maximum number of colors on screen
        
        // Look for the colors capability at index 13
        if entry.numbers.count > 13 {
            let colorCount = Int(entry.numbers[13])
            return colorCount >= 0 ? colorCount : nil
        }
        
        // If not found at index 13, search through all numeric capabilities
        // Some terminfo implementations might have different ordering
        for (_, number) in entry.numbers.enumerated() {
            // Colors capability should be a reasonable number (2-16777216)
            let colorCount = Int(number)
            if colorCount >= 2 && colorCount <= 16777216 && 
               (colorCount == 8 || colorCount == 16 || colorCount == 256 || colorCount == 16777216) {
                // This looks like a colors capability
                return colorCount
            }
        }
        
        return nil
    }
    
    /**
     * Processes a parametrized terminfo string by substituting parameters.
     * This implements terminfo's parameter processing language for color sequences.
     */
    public static func processParametrizedString(_ template: String, parameters: [Int]) -> String {
        return TerminfoParameterProcessor.process(template, parameters: parameters)
    }
}

/**
 * Processes terminfo parametrized strings using a stack-based approach.
 * Handles the subset needed for color sequences (setaf/setab).
 */
class TerminfoParameterProcessor {
    private var stack: [Int] = []
    private var result: String = ""
    private var chars: [Character] = []
    private var index: Int = 0
    
    static func process(_ template: String, parameters: [Int]) -> String {
        let processor = TerminfoParameterProcessor()
        return processor.processString(template, parameters: parameters)
    }
    
    private func processString(_ template: String, parameters: [Int]) -> String {
        result = ""
        stack = []
        chars = Array(template)
        index = 0
        
        while index < chars.count {
            let char = chars[index]
            
            if char == "%" && index + 1 < chars.count {
                processPercentSequence(parameters: parameters)
            } else {
                result.append(char)
                index += 1
            }
        }
        
        return result
    }
    
    private func processPercentSequence(parameters: [Int]) {
        index += 1 // Skip %
        guard index < chars.count else { return }
        
        let cmd = chars[index]
        
        switch cmd {
        case "%":
            result.append("%")
            index += 1
            
        case "p":
            // %p1, %p2, etc. - push parameter onto stack
            index += 1
            if index < chars.count, let paramNum = Int(String(chars[index])) {
                if paramNum > 0 && paramNum <= parameters.count {
                    stack.append(parameters[paramNum - 1])
                }
            }
            index += 1
            
        case "d":
            // %d - pop integer from stack and output as decimal
            if !stack.isEmpty {
                result.append(String(stack.removeLast()))
            }
            index += 1
            
        case "c":
            // %c - pop integer from stack and output as character
            if !stack.isEmpty {
                let value = stack.removeLast()
                if value >= 0 && value <= 255 {
                    result.append(Character(UnicodeScalar(value)!))
                }
            }
            index += 1
            
        case "+", "-", "*", "/", "m":
            // Arithmetic operations
            if stack.count >= 2 {
                let b = stack.removeLast()
                let a = stack.removeLast()
                switch cmd {
                case "+": stack.append(a + b)
                case "-": stack.append(a - b)
                case "*": stack.append(a * b)
                case "/": stack.append(b != 0 ? a / b : 0)
                case "m": stack.append(b != 0 ? a % b : 0)
                default: break
                }
            }
            index += 1
            
        case "{":
            // %{number} - push constant onto stack
            index += 1
            var numberStr = ""
            while index < chars.count && chars[index] != "}" {
                numberStr.append(chars[index])
                index += 1
            }
            if index < chars.count, let number = Int(numberStr) {
                stack.append(number)
            }
            index += 1
            
        case "<", ">", "=":
            // Comparison operations
            if stack.count >= 2 {
                let b = stack.removeLast()
                let a = stack.removeLast()
                let comparison: Bool
                switch cmd {
                case "<": comparison = a < b
                case ">": comparison = a > b
                case "=": comparison = a == b
                default: comparison = false
                }
                stack.append(comparison ? 1 : 0)
            }
            index += 1
            
        case "?":
            // Start conditional
            index += 1
            processConditional(parameters: parameters)
            
        default:
            result.append("%")
            result.append(cmd)
            index += 1
        }
    }
    
    private func processConditional(parameters: [Int]) {
        // Process the conditional expression %?condition%tTHEN%eELSE%;
        let condition = stack.isEmpty ? 0 : stack.removeLast()
        
        // Parse the conditional structure manually
        var depth = 0
        var thenStart = -1
        var thenEnd = -1
        var elseStart = -1
        var elseEnd = -1
        var i = index
        
        // Find the structure: %?...%t...%e...%;
        while i < chars.count - 1 {
            if chars[i] == "%" {
                let cmd = chars[i + 1]
                switch cmd {
                case "?":
                    depth += 1
                case "t":
                    if depth == 0 && thenStart == -1 {
                        thenStart = i + 2
                    }
                case "e":
                    if depth == 0 && thenEnd == -1 {
                        thenEnd = i
                        elseStart = i + 2
                    }
                case ";":
                    if depth == 0 {
                        if elseStart != -1 && elseEnd == -1 {
                            elseEnd = i
                        } else if thenEnd == -1 {
                            thenEnd = i
                        }
                        break
                    } else {
                        depth -= 1
                    }
                default:
                    break
                }
                i += 2
            } else {
                i += 1
            }
        }
        
        // Execute the appropriate branch
        if condition != 0 {
            // Execute then part
            if thenStart != -1 && thenEnd != -1 && thenEnd > thenStart {
                let thenPart = String(chars[thenStart..<thenEnd])
                let processor = TerminfoParameterProcessor()
                processor.stack = stack
                let thenResult = processor.processString(thenPart, parameters: parameters)
                result.append(thenResult)
                stack = processor.stack
            }
        } else if elseStart != -1 && elseEnd != -1 && elseEnd > elseStart {
            // Execute else part
            let elsePart = String(chars[elseStart..<elseEnd])
            let processor = TerminfoParameterProcessor()
            processor.stack = stack
            let elseResult = processor.processString(elsePart, parameters: parameters)
            result.append(elseResult)
            stack = processor.stack
        }
        
        // Skip to after the closing ;
        index = i + 1
    }
    
    private func findMatchingToken(_ token: String, from start: Int) -> Int {
        var i = start
        var depth = 0
        
        while i < chars.count - 1 {
            if chars[i] == "%" {
                let next = chars[i + 1]
                if String(next) == token && depth == 0 {
                    return i + 2
                } else if next == "?" {
                    depth += 1
                } else if next == ";" {
                    depth -= 1
                }
                i += 2
            } else {
                i += 1
            }
        }
        
        return chars.count
    }
}

/**
 * TerminalCapability implementation based on parsed terminfo data.
 */
public class TerminfoCapability: TerminalCapability {
    public let providerDescription: String
    private let entry: TerminfoParser.TerminfoEntry
    
    init(entry: TerminfoParser.TerminfoEntry, terminalType: String) {
        self.entry = entry
        self.providerDescription = "Terminfo(\(terminalType))"
    }
    
    // Standard terminfo string capability indices
    public enum StringCap: Int {
        case bell = 1
        case cr = 5
        case csr = 6
        case tbc = 7
        case clear = 8
        case el = 9
        case ed = 10
        case hpa = 11
        case cmdch = 12
        case cup = 13
        case cud1 = 14
        case home = 15
        case civis = 16
        case cub1 = 17
        case cnorm = 18
        case cuf1 = 19
        case cuu1 = 20
        case cvvis = 21
        case dch1 = 22
        case dl1 = 23
        case dsl = 24
        case hd = 25
        case smacs = 26
        case blink = 27
        case bold = 28
        case smcup = 29
        case smdc = 30
        case dim = 31
        case smir = 32
        case invis = 33
        case prot = 34
        case rev = 35
        case smso = 36
        case smul = 37
        case ech = 38
        case rmacs = 39
        case sgr0 = 40
        case rmcup = 41
        case rmdc = 42
        case rmir = 43
        case rmso = 44
        case rmul = 45
        case flash = 46
        case ff = 47
        case fsl = 48
        case is1 = 49
        case is2 = 50
        case is3 = 51
        case if_ = 52
        case ich1 = 53
        case il1 = 54
        case ip = 55
        case kbs = 56
        case ktbc = 57
        case kclr = 58
        case kctab = 59
        case kdch1 = 60
        case kdl1 = 61
        case kcud1 = 62
        case krmir = 63
        case kel = 64
        case ked = 65
        case kf0 = 66
        case kf1 = 67
        case kf10 = 68
        case kf2 = 69
        case kf3 = 70
        case kf4 = 71
        case kf5 = 72
        case kf6 = 73
        case kf7 = 74
        case kf8 = 75
        case kf9 = 76
        case khome = 77
        case kich1 = 78
        case kcub1 = 79
        case kll = 80
        case knp = 81
        case kpp = 82
        case kcuf1 = 83
        case kind = 84
        case kri = 85
        case khts = 86
        case kcuu1 = 87
        case rmkx = 88
        case smkx = 89
        case lf0 = 90
        case lf1 = 91
        case lf10 = 92
        case lf2 = 93
        case lf3 = 94
        case lf4 = 95
        case lf5 = 96
        case lf6 = 97
        case lf7 = 98
        case lf8 = 99
        case lf9 = 100
        case rmm = 101
        case smm = 102
        case nel = 103
        case pad = 104
        case dch = 105
        case dl = 106
        case cud = 107
        case ich = 108
        case indn = 109
        case il = 110
        case cub = 111
        case cuf = 112
        case rin = 113
        case cuu = 114
        case pfkey = 115
        case pfloc = 116
        case pfx = 117
        case mc0 = 118
        case mc4 = 119
        case mc5 = 120
        case rep = 121
        case rs1 = 122
        case rs2 = 123
        case rs3 = 124
        case rf = 125
        case rc = 126
        case vpa = 127
        case sc = 128
        case ind = 129
        case ri = 130
        case sgr = 131
        case hts = 132
        case wind = 133
        case ht = 134
        case tsl = 135
        case uc = 136
        case hu = 137
        case iprog = 138
        case ka1 = 139
        case ka3 = 140
        case kb2 = 141
        case kc1 = 142
        case kc3 = 143
        case mc5p = 144
        case rmp = 145
        case acsc = 146
        case pln = 147
        case kcbt = 148
        case smxon = 149
        case rmxon = 150
        case smam = 151
        case rmam = 152
        case xonc = 153
        case xoffc = 154
        case enacs = 155
        case smln = 156
        case rmln = 157
        case kend = 158
        case kbeg = 159
        case kcan = 160
        case kclo = 161
        case kcmd = 162
        case kcpy = 163
        case kcrt = 164
        case kext = 165
        case kfnd = 166
        case khlp = 167
        case kmrk = 168
        case kmsg = 169
        case kmov = 170
        case knxt = 171
        case kopn = 172
        case kopt = 173
        case kprv = 174
        case kprt = 175
        case krdo = 176
        case kref = 177
        case krfr = 178
        case krpl = 179
        case krst = 180
        case kres = 181
        case ksav = 182
        case kspd = 183
        case kund = 184
        case kBEG = 185
        case kCAN = 186
        case kCMD = 187
        case kCPY = 188
        case kCRT = 189
        case kDC = 190
        case kDL = 191
        case kslt = 192
        case kEND = 193
        case kEOL = 194
        case kEXT = 195
        case kFND = 196
        case kHLP = 197
        case kHOM = 198
        case kIC = 199
        case kLFT = 200
        case kMSG = 201
        case kMOV = 202
        case kNXT = 203
        case kOPT = 204
        case kPRV = 205
        case kPRT = 206
        case kRDO = 207
        case kRPL = 208
        case kRIT = 209
        case kRES = 210
        case kSAV = 211
        case kSPD = 212
        case kUND = 213
        case rfi = 214
        case kf11 = 215
        case kf12 = 216
        case kf13 = 217
        case kf14 = 218
        case kf15 = 219
        case kf16 = 220
        case kf17 = 221
        case kf18 = 222
        case kf19 = 223
        case kf20 = 224
        case kf21 = 225
        case kf22 = 226
        case kf23 = 227
        case kf24 = 228
        case kf25 = 229
        case kf26 = 230
        case kf27 = 231
        case kf28 = 232
        case kf29 = 233
        case kf30 = 234
        case kf31 = 235
        case kf32 = 236
        case kf33 = 237
        case kf34 = 238
        case kf35 = 239
        case kf36 = 240
        case kf37 = 241
        case kf38 = 242
        case kf39 = 243
        case kf40 = 244
        case kf41 = 245
        case kf42 = 246
        case kf43 = 247
        case kf44 = 248
        case kf45 = 249
        case kf46 = 250
        case kf47 = 251
        case kf48 = 252
        case kf49 = 253
        case kf50 = 254
        case kf51 = 255
        case kf52 = 256
        case kf53 = 257
        case kf54 = 258
        case kf55 = 259
        case kf56 = 260
        case kf57 = 261
        case kf58 = 262
        case kf59 = 263
        case kf60 = 264
        case kf61 = 265
        case kf62 = 266
        case kf63 = 267
        case el1 = 268
        case mgc = 269
        case smgl = 270
        case smgr = 271
        case fln = 272
        case sclk = 273
        case dclk = 274
        case rmclk = 275
        case cwin = 276
        case wingo = 277
        case hup = 278
        case dial = 279
        case qdial = 280
        case tone = 281
        case pulse = 282
        case hook = 283
        case pause = 284
        case wait = 285
        case u0 = 286
        case u1 = 287
        case u2 = 288
        case u3 = 289
        case u4 = 290
        case u5 = 291
        case u6 = 292
        case u7 = 293
        case u8 = 294
        case u9 = 295
        case op = 296
        case oc = 297
        case initc = 298
        case initp = 299
        case scp = 300
        case setf = 301
        case setb = 302
        case cpi = 303
        case lpi = 304
        case chr = 305
        case cvr = 306
        case defc = 307
        case swidm = 308
        case sdrfq = 309
        case sitm = 310
        case slm = 311
        case smicm = 312
        case snlq = 313
        case snrmq = 314
        case sshm = 315
        case ssubm = 316
        case ssupm = 317
        case sum = 318
        case rwidm = 319
        case ritm = 320
        case rlm = 321
        case rmicm = 322
        case rshm = 323
        case rsubm = 324
        case rsupm = 325
        case rum = 326
        case mhpa = 327
        case mcud1 = 328
        case mcub1 = 329
        case mcuf1 = 330
        case mvpa = 331
        case mcuu1 = 332
        case porder = 333
        case mcud = 334
        case mcub = 335
        case mcuf = 336
        case mcuu = 337
        case gtxyz = 338
        case smgb = 339
        case smgbp = 340
        case smglp = 341
        case smgrp = 342
        case smgt = 343
        case smgtp = 344
        case sbim = 345
        case scsd = 346
        case rbim = 347
        case rcsd = 348
        case subcs = 349
        case supcs = 350
        case docr = 351
        case zerom = 352
        case csnm = 353
        case kmous = 354
        case minfo = 355
        case reqmp = 356
        case getm = 357
        case setaf = 358  // Set ANSI foreground color
        case setab = 359  // Set ANSI background color
        case pfxl = 360
        case devt = 361
        case csin = 362
        case s0ds = 363
        case s1ds = 364
        case s2ds = 365
        case s3ds = 366
        case smglr = 367
        case smgtb = 368
        case birep = 369
        case binel = 370
        case bicr = 371
        case colornm = 372
        case defbi = 373
        case endbi = 374
        case setcolor = 375
        case mlhp = 376
        case mlvp = 377
        case mcol = 378
        case mcs = 379
        case mls = 380
        case margb = 381
        case margl = 382
        case margr = 383
        case margt = 384
        case smgl2 = 385
        case smgr2 = 386
        case smgb2 = 387
        case smgt2 = 388
        case smgbp2 = 389
        case smglp2 = 390
        case smgrp2 = 391
        case smgtp2 = 392
    }
    
    public func getString(_ cap: StringCap) -> String {
        let index = cap.rawValue
        if index < entry.strings.count, let value = entry.strings[index] {
            return processEscapeSequences(value)
        }
        return ""
    }
    
    private func processEscapeSequences(_ str: String) -> String {
        var result = str
        
        // Convert common terminfo sequences to actual escape codes
        result = result.replacingOccurrences(of: "\\E", with: "\u{1b}")
        result = result.replacingOccurrences(of: "^G", with: "\u{07}")
        result = result.replacingOccurrences(of: "^H", with: "\u{08}")
        result = result.replacingOccurrences(of: "^I", with: "\u{09}")
        result = result.replacingOccurrences(of: "^J", with: "\u{0a}")
        result = result.replacingOccurrences(of: "^M", with: "\u{0d}")
        
        return result
    }
    
    // MARK: - TerminalCapability implementation
    
    public var cursorUp: String { getString(.cuu1) }
    public var cursorDown: String { getString(.cud1) }
    public var cursorForward: String { getString(.cuf1) }
    public var cursorBackward: String { getString(.cub1) }
    public var cursorPosition: String { getString(.cup) }
    public var cursorHome: String { getString(.home) }
    public var saveCursorPosition: String { getString(.sc) }
    public var restoreCursorPosition: String { getString(.rc) }
    
    public var clearScreen: String { getString(.clear) }
    public var clearToEndOfScreen: String { getString(.ed) }
    public var clearToBeginningOfScreen: String { "\u{1b}[1J" }
    public var clearLine: String { "\u{1b}[2K" }
    public var clearToEndOfLine: String { getString(.el) }
    public var clearToBeginningOfLine: String { getString(.el1) }
    
    public var reset: String { getString(.sgr0) }
    public var bold: String { getString(.bold) }
    public var dim: String { getString(.dim) }
    public var underline: String { getString(.smul) }
    public var blink: String { getString(.blink) }
    public var reverse: String { getString(.rev) }
    public var hidden: String { getString(.invis) }
    public var strikethrough: String { "\u{1b}[9m" }
    
    public var noBold: String { "\u{1b}[22m" }
    public var noUnderline: String { getString(.rmul) }
    public var noBlink: String { "\u{1b}[25m" }
    public var noReverse: String { "\u{1b}[27m" }
    
    public var foregroundBlack: String { "\u{1b}[30m" }
    public var foregroundRed: String { "\u{1b}[31m" }
    public var foregroundGreen: String { "\u{1b}[32m" }
    public var foregroundYellow: String { "\u{1b}[33m" }
    public var foregroundBlue: String { "\u{1b}[34m" }
    public var foregroundMagenta: String { "\u{1b}[35m" }
    public var foregroundCyan: String { "\u{1b}[36m" }
    public var foregroundWhite: String { "\u{1b}[37m" }
    public var foregroundDefault: String { "\u{1b}[39m" }
    
    public var backgroundBlack: String { "\u{1b}[40m" }
    public var backgroundRed: String { "\u{1b}[41m" }
    public var backgroundGreen: String { "\u{1b}[42m" }
    public var backgroundYellow: String { "\u{1b}[43m" }
    public var backgroundBlue: String { "\u{1b}[44m" }
    public var backgroundMagenta: String { "\u{1b}[45m" }
    public var backgroundCyan: String { "\u{1b}[46m" }
    public var backgroundWhite: String { "\u{1b}[47m" }
    public var backgroundDefault: String { "\u{1b}[49m" }
    
    public var foregroundBrightBlack: String { "\u{1b}[90m" }
    public var foregroundBrightRed: String { "\u{1b}[91m" }
    public var foregroundBrightGreen: String { "\u{1b}[92m" }
    public var foregroundBrightYellow: String { "\u{1b}[93m" }
    public var foregroundBrightBlue: String { "\u{1b}[94m" }
    public var foregroundBrightMagenta: String { "\u{1b}[95m" }
    public var foregroundBrightCyan: String { "\u{1b}[96m" }
    public var foregroundBrightWhite: String { "\u{1b}[97m" }
    
    public var backgroundBrightBlack: String { "\u{1b}[100m" }
    public var backgroundBrightRed: String { "\u{1b}[101m" }
    public var backgroundBrightGreen: String { "\u{1b}[102m" }
    public var backgroundBrightYellow: String { "\u{1b}[103m" }
    public var backgroundBrightBlue: String { "\u{1b}[104m" }
    public var backgroundBrightMagenta: String { "\u{1b}[105m" }
    public var backgroundBrightCyan: String { "\u{1b}[106m" }
    public var backgroundBrightWhite: String { "\u{1b}[107m" }
    
    public func foregroundRGB(_ r: Int, _ g: Int, _ b: Int) -> String {
        return "\u{1b}[38;2;\(r);\(g);\(b)m"
    }
    
    public func backgroundRGB(_ r: Int, _ g: Int, _ b: Int) -> String {
        return "\u{1b}[48;2;\(r);\(g);\(b)m"
    }
    
    public var alternateScreenBuffer: String { getString(.smcup) }
    public var normalScreenBuffer: String { getString(.rmcup) }
    public var hideCursor: String { getString(.civis) }
    public var showCursor: String { getString(.cnorm) }
    public var enableLineWrap: String { getString(.smam) }
    public var disableLineWrap: String { getString(.rmam) }
    
    public var enableMouseTracking: String { "\u{1b}[?1000h" }
    public var disableMouseTracking: String { "\u{1b}[?1000l" }
    public var enableMouseMotionTracking: String { "\u{1b}[?1003h" }
    public var disableMouseMotionTracking: String { "\u{1b}[?1003l" }
    public var enableSGRMouse: String { "\u{1b}[?1006h" }
    public var disableSGRMouse: String { "\u{1b}[?1006l" }
    
    public var keyUp: String { getString(.kcuu1) }
    public var keyDown: String { getString(.kcud1) }
    public var keyRight: String { getString(.kcuf1) }
    public var keyLeft: String { getString(.kcub1) }
    public var keyHome: String { getString(.khome) }
    public var keyEnd: String { getString(.kend) }
    public var keyPageUp: String { getString(.kpp) }
    public var keyPageDown: String { getString(.knp) }
    public var keyInsert: String { getString(.kich1) }
    public var keyDelete: String { getString(.kdch1) }
    public var keyF1: String { getString(.kf1) }
    public var keyF2: String { getString(.kf2) }
    public var keyF3: String { getString(.kf3) }
    public var keyF4: String { getString(.kf4) }
    public var keyF5: String { getString(.kf5) }
    public var keyF6: String { getString(.kf6) }
    public var keyF7: String { getString(.kf7) }
    public var keyF8: String { getString(.kf8) }
    public var keyF9: String { getString(.kf9) }
    public var keyF10: String { getString(.kf10) }
    
    public var queryTerminalSize: String { "\u{1b}[18t" }
    public var queryCursorPosition: String { "\u{1b}[6n" }
    
    // Color support methods
    public func setForegroundColor(_ colorIndex: Int) -> String {
        let setafTemplate = getString(.setaf)
        if !setafTemplate.isEmpty {
            return TerminfoParser.processParametrizedString(setafTemplate, parameters: [colorIndex])
        }
        return ""
    }
    
    public func setBackgroundColor(_ colorIndex: Int) -> String {
        let setabTemplate = getString(.setab)
        if !setabTemplate.isEmpty {
            return TerminfoParser.processParametrizedString(setabTemplate, parameters: [colorIndex])
        }
        return ""
    }
}