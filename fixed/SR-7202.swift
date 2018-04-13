// Invocation:
// /Library/Developer/Toolchains/swift-DEVELOPMENT-SNAPSHOT-2018-03-13-a.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -target arm64-apple-ios10.0 -c -v ./Network.swift

import Foundation

struct Resource<A> {
    let requestBody: Data?
    let parse: (Data) -> A?
}

class Network {
    required init() { }
    class func apiRequest<A>(base: String, resource: Resource<A>) {}
}

