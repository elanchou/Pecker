// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Pecker",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/exyte/Chat.git", from: "1.0.0"),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.0.0"),
        .package(url: "https://github.com/pujiaxin33/JXSegmentedView.git", from: "1.3.0"),
        .package(url: "https://github.com/KittenYang/NextGrowingTextView.git", from: "2.0.0"),
        .package(url: "https://github.com/uias/Tabman", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "Pecker",
            dependencies: [
                "SwiftSoup",
                .product(name: "ExyteChat", package: "Chat"),
                .product(name: "SDWebImage", package: "SDWebImage"),
                .product(name: "JXSegmentedView", package: "JXSegmentedView"),
                .product(name: "NextGrowingTextView", package: "NextGrowingTextView"),
                .product(name: "Tabman", package: "Tabman"),
            ]
        )
    ]
) 
</```
rewritten_file>