#! /usr/bin/env bash

# Invoke this script as:
# SWIFTC=/Library/Developer/Toolchains/swift-4.2-DEVELOPMENT-SNAPSHOT-2018-06-26-a.xctoolchain/usr/bin/swiftc ./verify.sh

function execswift() {
    echo "################## Start $1 #############################################################"
    $SWIFTC ${@:2} $1
    echo "################## End $1 ###############################################################"
}

execswift SR-7055.swift -c -v
execswift SR-7235.swift -sdk /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -target arm64-apple-ios10.0 -c -v
execswift SR-7295.swift -sdk /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
execswift SR-7425.swift -c -v
execswift SR-7986.swift -sdk /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

pushd SR-7784
execswift SR-7784.swift -c -F . -framework VersionedKit.framework
popd

IOS_SDK="/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
IOS_TARGET="arm64-apple-ios12.0"

$SWIFTC -sdk $IOS_SDK -target $IOS_TARGET -c Radar-41712912.swift

