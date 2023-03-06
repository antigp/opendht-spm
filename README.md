# SPM OpenDHT + Swift wrapper

### Swift Package Manager

You can also manually add the package to your Package.swift file:

```swift
.package(url: "https://github.com/antigp/opendht-spm.git", from: "2.4.12")
```

And add to dependecies
```swift
.product(name: "opendht_swift", package: "opendht-spm")
or
.product(name: "opendht_c", package: "opendht-spm")
or (only experemental)
.product(name: "opendht_cpp", package: "opendht-spm")
```
