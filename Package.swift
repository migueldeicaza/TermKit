// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TermKit",
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
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.11.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TermKit",
            dependencies: ["Curses", "OpenCombine"]),
        .systemLibrary(
            name: "Curses"), // , pkgConfig: "/tmp/ncursesw.pc"),
        .target(
            name: "Example",
            dependencies: ["TermKit"]),
            .testTarget(
                name: "TermKitTests",
                dependencies: ["TermKit"]),
    ]
)
