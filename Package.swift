// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireGuardKit",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(name: "WireGuardKit", targets: ["WireGuardKit"])
    ],
    dependencies: [],
    targets: [
        // Main WireGuardKit target
        .target(
            name: "WireGuardKit",
            dependencies: ["WireGuardKitC", "WireGuardKitGo", "WireGuardNetworkExtension"],
            path: "Sources/WireGuardKit",
            exclude: [],
            sources: nil, // Will include all Swift files in the directory
            cSettings: [
                .headerSearchPath("../WireGuardKitGo"),
                .define("APPLICATION_EXTENSION_API_ONLY", to: "1")
            ],
            swiftSettings: [
                .define("APPLICATION_EXTENSION_API_ONLY")
            ]
        ),

        // C components target
        .target(
            name: "WireGuardKitC",
            dependencies: [],
            path: "Sources/WireGuardKitC",
            exclude: [],
            sources: nil, // Will include all .c files
            publicHeadersPath: ".",
            cSettings: [
                .define("APPLICATION_EXTENSION_API_ONLY", to: "1")
            ]
        ),

        // Go components target
        .target(
            name: "WireGuardKitGo",
            dependencies: [],
            path: "Sources/WireGuardKitGo",
            exclude: [
                "goruntime-boottime-over-monotonic.diff",
                "go.mod",
                "go.sum",
                "api-apple.go",
                "api-xray.go",
                "Makefile",
                "out"
            ],
            sources: ["wireguard.h"], // Only include the header
            publicHeadersPath: ".",
            cSettings: [
                .define("APPLICATION_EXTENSION_API_ONLY", to: "1")
            ]
        ),

        // Network Extension target
        .target(
            name: "WireGuardNetworkExtension",
            dependencies: ["WireGuardKitC"],
            path: "Sources/WireGuardNetworkExtension",
            exclude: [],
            sources: nil, // Will include all Swift and C files
            cSettings: [
                .headerSearchPath("../WireGuardKitGo"),
                .define("APPLICATION_EXTENSION_API_ONLY", to: "1")
            ],
            swiftSettings: [
                .define("APPLICATION_EXTENSION_API_ONLY")
            ]
        ),

        // Shared components target
        .target(
            name: "Shared",
            dependencies: [],
            path: "Sources/Shared",
            exclude: [
                "**/test*.*"  // Exclude test files
            ],
            sources: nil, // Will include all Swift and C files
            cSettings: [
                .define("APPLICATION_EXTENSION_API_ONLY", to: "1")
            ],
            swiftSettings: [
                .define("APPLICATION_EXTENSION_API_ONLY")
            ]
        ),

        // Binary target for the pre-built framework
        .binaryTarget(
            name: "wg-go",
            path: "Frameworks/wg-go.xcframework"
        )
    ]
)