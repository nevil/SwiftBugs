// /Library/Developer/Toolchains/swift-4.1-DEVELOPMENT-SNAPSHOT-2018-02-21-a.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk  a-new-bug.swift

import Foundation

class A {

    func doSomething(a: (() -> Void)? = nil, completion: @escaping ((String, Error?) -> Void)) {}

    func doSomething(b: @escaping ((String, Error?, Bool) -> Void)) {}

    func a() {
        doSomething(a: nil, completion: { _ in })
    }
}

let a = A()

