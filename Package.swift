// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenDHT",
    products: [
        .library(
            name: "opendht_c",
            targets: ["opendht_c"]),
        .library(
            name: "opendht_cpp",
            targets: ["opendht_cpp"])
    ],
    dependencies: [
        .package(url: "https://github.com/antigp/msgpack-c-spm.git", from: "2.1.5"),
        .package(url: "https://github.com/antigp/asio-spm.git", from: "1.24.0"),
        .package(url: "https://github.com/krzyzanowskim/OpenSSL.git", .upToNextMinor(from: "1.1.1700")),
        .package(url: "https://github.com/antigp/phc-winner-argon2.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "opendht_cpp",
            dependencies: [
                "OpenSSL",
                "gmp",
                "gnutls",
                "libtasn1",
                "nettle",
                .product(name: "argon2", package: "phc-winner-argon2"),
                .product(name: "msgpack_cpp", package: "msgpack-c-spm"),
                .product(name: "asio", package: "asio-spm")
            ],
            exclude: [
                "src/rng.cpp",
                "src/compat/msvc/unistd.h",
                "src/compat/msvc/wingetopt.c",
                "src/compat/msvc/wingetopt.h",
                "src/http.cpp",
                "src/dht_proxy_server.cpp",
                "src/dht_proxy_client.cpp"
            ],
            sources: ["src"],
            cxxSettings: [
                .headerSearchPath("include/opendht"),
                .headerSearchPath("../../Frameworks/nettle.xcframework/ios-arm64/nettle.framework/Headers"),
                .headerSearchPath("../../Frameworks/libtasn1.xcframework/ios-arm64/libtasn1.framework/Headers"),
                .headerSearchPath("../../Frameworks/gnutls.xcframework/ios-arm64/gnutls.framework/Headers"),
                .headerSearchPath("../../Frameworks/gmp.xcframework/ios-arm64/gmp.framework/Headers"),
            ]
        ),
        .target(
            name: "opendht_c",
            dependencies: [
                "opendht_cpp",
                "OpenSSL",
                "gmp",
                "gnutls",
                "libtasn1",
                "nettle",
                .product(name: "msgpack_c", package: "msgpack-c-spm"),
                .product(name: "argon2", package: "phc-winner-argon2")
            ],
            sources: ["src"],
            cSettings: [],
            cxxSettings: [
                .headerSearchPath("include"),
                .headerSearchPath("../../Frameworks/gnutls.xcframework/ios-arm64/gnutls.framework/Headers"),
            ]
        ),
        .binaryTarget(
            name: "gmp",
            path: "Frameworks/gmp.xcframework"
        ),
        .binaryTarget(
            name: "gnutls",
            path: "Frameworks/gnutls.xcframework"
        ),
        .binaryTarget(
            name: "libtasn1",
            path: "Frameworks/libtasn1.xcframework"
        ),
        .binaryTarget(
            name: "nettle",
            path: "Frameworks/nettle.xcframework"
        ),
        .testTarget(
            name: "OpenDHTTests",
            dependencies: ["opendht_c"]
        )
    ],
    cLanguageStandard: .c17,
    cxxLanguageStandard: .cxx17
)
