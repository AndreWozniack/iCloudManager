// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "CloudManagerPackage",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "CloudManagerPackage",
            targets: ["CloudManagerPackage"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CloudManagerPackage",
            dependencies: []),
    ]
)
