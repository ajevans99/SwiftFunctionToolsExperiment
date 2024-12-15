// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftFunctionToolsExperiment",
  platforms: [.macOS(.v15)],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    .package(url: "https://github.com/ajevans99/swift-json-schema.git", from: "0.3.0"),
    .package(url: "https://github.com/ajevans99/OpenAI.git", branch: "function-tool-arguments-as-string"),
    .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "2.1.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "SwiftFunctionToolsExperiment",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "JSONSchema", package: "swift-json-schema"),
        .product(name: "JSONSchemaBuilder", package: "swift-json-schema"),
        .product(name: "OpenAI", package: "OpenAI"),
        .product(name: "SwiftDotenv", package: "swift-dotenv"),
      ]
    ),
  ]
)
