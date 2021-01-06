#! /usr/bin/env bash

# Invoke this script as:
# SWIFTC=/Library/Developer/Toolchains/swift-4.2-DEVELOPMENT-SNAPSHOT-2018-06-26-a.xctoolchain/usr/bin/swiftc ./verify.sh

function bugstart() {
    echo "################## Start $1 #############################################################"
}

function bugend() {
    echo "################## End $1 ###############################################################"
}

function execswift() {
    bugstart $1
    $SWIFTC ${@:2} $1
    bugend $1
}

: ${XCODE_DEVELOPER:=$(xcode-select -p)}
: ${SWIFTC:="${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"}

IOS_SDK="${XCODE_DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
IOS_TARGET="arm64-apple-ios12.0"
$SWIFTC -frontend -sdk $IOS_SDK -target $IOS_TARGET -c -update-code -primary-file SR-8150.swift -emit-migrated-file-path SR-8150.migrated.swift -swift-version 4
execswift SR-8150.migrated.swift -c -v -sdk $IOS_SDK -target $IOS_TARGET

bugstart Radar-41712912.swift
IOS_SDK="${XCODE_DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
IOS_TARGET="arm64-apple-ios12.0"

$SWIFTC -sdk $IOS_SDK -target $IOS_TARGET -c Radar-41712912.swift
bugend Radar-41712912.swift

bugstart Radar-43088982.swift
$SWIFTC -frontend -sdk $IOS_SDK -target $IOS_TARGET -c -update-code -primary-file Radar-43088982.swift -emit-migrated-file-path Radar-43088982.migrated.swift -swift-version 5
diff Radar-43088982.swift Radar-43088982.migrated.swift && echo "Verified." || echo "Failed."
bugend Radar-43088982.swift

bugstart SR-7295
echo "Expected error: error: contextual closure type '(String, Error?) -> Void' expects 2 arguments, but 1 was used in closure body"
$SWIFTC SR-7295.swift -sdk ${XCODE_DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
bugend SR-7295

execswift SR-7425.swift  -sdk ${XCODE_DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -c -v

