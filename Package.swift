// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "TalkTalk",
	platforms: [.macOS(.v14)],
	products: [
		.executable(
			name: "tlk",
			targets: ["tlk"]
		),
		.library(
			name: "TalkTalk",
			targets: ["TalkTalk"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
		.package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.executableTarget(
			name: "tlk",
			dependencies: [
				"TalkTalk",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]
		),
		.target(name: "TalkTalk"),
		.testTarget(
			name: "TalktalkTests",
			dependencies: [
				"TalkTalk",
				.product(name: "Testing", package: "swift-testing"),
			]
		),
	]
)
