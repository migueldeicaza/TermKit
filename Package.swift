// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TermKit",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TermKit",
            targets: ["TermKit"]),

        .executable(
            name: "Example",
            targets: ["Example"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.11.0"),
        .package(url: "https://github.com/migueldeicaza/TextBufferKit.git", from: "0.2.0"),
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.0.4")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TermKit",
            dependencies: ["Curses", "OpenCombine", "TextBufferKit", "SwiftTerm"]),
        .systemLibrary(
            name: "Curses"), // , pkgConfig: "/tmp/ncursesw.pc"),
        .target(
            name: "Example",
            dependencies: ["TermKit", "SwiftTerm"]),
            .testTarget(
                name: "TermKitTests",
                dependencies: ["TermKit"]),
    ]
)
