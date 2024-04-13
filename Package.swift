// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProfileSummarizer",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "ProfileSummarizer",
            targets: ["ProfileSummarizer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/1024jp/GzipSwift", from: Version(6, 0, 0))],
    targets: [
        .target(
            name: "ProfileSummarizer"),
        //        .testTarget(
        //            name: "ProfileSummarizerTests",
        //            dependencies: ["ProfileSummarizer"]),
            .target(name: "ProfileReader", dependencies: [.product(name: "Gzip", package: "GzipSwift")]),
        .testTarget(
            name: "ProfileReaderTests",
            dependencies: ["ProfileReader"],
            resources: [.copy("TestData")])
    ]
)
