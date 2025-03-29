// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EasyFFmpeg",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EasyFFmpeg",
            targets: ["EasyFFmpeg"]),
    ],
    targets: [
        .binaryTarget(
            name: "ffmpegkit",
            path: "Sources/easyffmpeg/ffmpegkit.xcframework"
        ),
        .binaryTarget(
            name: "libavcodec",
            path: "Sources/easyffmpeg/libavcodec.xcframework"
        ),
        .binaryTarget(
            name: "libavdevice",
            path: "Sources/easyffmpeg/libavdevice.xcframework"
        ),
        .binaryTarget(
            name: "libavfilter",
            path: "Sources/easyffmpeg/libavfilter.xcframework"
        ),
        .binaryTarget(
            name: "libavformat",
            path: "Sources/easyffmpeg/libavformat.xcframework"
        ),
        .binaryTarget(
            name: "libavutil",
            path: "Sources/easyffmpeg/libavutil.xcframework"
        ),
        .binaryTarget(
            name: "libswresample",
            path: "Sources/easyffmpeg/libswresample.xcframework"
        ),
        .binaryTarget(
            name: "libswscale",
            path: "Sources/easyffmpeg/libswscale.xcframework"
        ),
        .target(
            name: "EasyFFmpeg",
            dependencies: [
                "ffmpegkit",
                "libavcodec",
                "libavdevice",
                "libavfilter",
                "libavformat",
                "libavutil",
                "libswresample",
                "libswscale"
            ],
            path: "Sources/easyffmpeg"
        ),
    ]
)
