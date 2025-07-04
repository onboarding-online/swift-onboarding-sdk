// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OnboardingiOSSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "OnboardingiOSSDK",
            targets: ["OnboardingiOSSDK"]),
        .library(
            name: "OnboardingPaymentKit",
            targets: ["OnboardingPaymentKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/onboarding-online/swift-screens-graph", exact: "1.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "OnboardingiOSSDK",
            dependencies: [
                .product(name: "ScreensGraph", package: "swift-screens-graph")
            ], path: "Sources/OnboardingiOSSDK", resources: [.process("Resources")]
        ),
        .target(
            name: "OnboardingPaymentKit",
            dependencies: [
                "OnboardingiOSSDK",
            ],
            path: "Sources/OnboardingPaymentKit"),
        .testTarget(
            name: "OnboardingiOSSDKTests",
            dependencies: ["OnboardingiOSSDK"]),
        .testTarget(
            name: "OnboardingPaymentKitTests",
            dependencies: ["OnboardingPaymentKit"]),
    ]
)

