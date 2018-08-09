SWIFTC=/Library/Developer/Toolchains/swift-4.2-DEVELOPMENT-SNAPSHOT-2018-07-13-a.xctoolchain/usr/bin/swiftc
#SWIFTC=/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc
IOS_SDK="/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
IOS_TARGET="arm64-apple-ios12.0"
$SWIFTC -frontend -sdk $IOS_SDK -target $IOS_TARGET -c -update-code -primary-file full-path.swift -emit-migrated-file-path full-path.migrated.swift -swift-version 4
#$SWIFTC -sdk $IOS_SDK -target $IOS_TARGET -c full-path.migrated.swift

