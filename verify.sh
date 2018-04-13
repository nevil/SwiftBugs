#! /usr/bin/env bash

# Invoke this script as:
# SWIFTC=/Library/Developer/Toolchains/swift-DEVELOPMENT-SNAPSHOT-2018-04-12-a.xctoolchain/usr/bin/swiftc ./verify.sh

function execswift() {
    echo "################## Start $1 #############################################################"
    $SWIFTC ${@:2} $1
    echo "################## End $1 ###############################################################"
}

execswift SR-7055.swift -c -v
execswift SR-7153.swift -c -v
execswift SR-7235.swift -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -target arm64-apple-ios10.0 -c -v
execswift SR-7295.swift -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

