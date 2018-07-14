#! /usr/bin/env bash

# Invoke this script as:
# SWIFTC=/Library/Developer/Toolchains/swift-4.2-DEVELOPMENT-SNAPSHOT-2018-06-26-a.xctoolchain/usr/bin/swiftc ./verify.sh

function execswift() {
    echo "################## Start $1 #############################################################"
    $SWIFTC ${@:2} $1
    echo "################## End $1 ###############################################################"
}

IOS_SDK="/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
IOS_TARGET="arm64-apple-ios12.0"
$SWIFTC -frontend -sdk $IOS_SDK -target $IOS_TARGET -c -update-code -primary-file SR-8150.swift -emit-migrated-file-path SR-8150.migrated.swift -swift-version 4
execswift SR-8150.migrated.swift -c -v -sdk $IOS_SDK -target $IOS_TARGET
