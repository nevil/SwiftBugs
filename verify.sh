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

execswift SR-7055.swift -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -c -v
execswift SR-7425.swift -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -c -v
execswift SR-7986.swift -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

pushd SR-7784
execswift SR-7784.swift -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -c -F . -framework VersionedKit.framework
popd

