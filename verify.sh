#! /usr/bin/env bash

# Invoke this script as:
# SWIFTC=/Library/Developer/Toolchains/swift-4.2-DEVELOPMENT-SNAPSHOT-2018-06-26-a.xctoolchain/usr/bin/swiftc ./verify.sh

function bugstart() {
    echo "################## Start $1 #############################################################"
}

function bugend() {
    echo "################## End $1 ###############################################################"
}

function execswiftc() {
    $SWIFTC ${@:2} -sdk ${XCODE_DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk $1
}

function execswift() {
    bugstart $1
    execswiftc $@
    bugend $1
}


: ${XCODE_DEVELOPER:=$(xcode-select -p)}
: ${SWIFTC:="${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"}

execswift SR-7055.swift -c -v
execswift SR-7986.swift

pushd SR-7784
execswift SR-7784.swift -c -F . -framework VersionedKit.framework
popd


bugstart SR-14012
execswiftc SR-14012.swift -Onone -sanitize=thread
./SR-14012 && echo "SR-14012 Passed" || echo "SR-14012 Failed"
bugend SR-14012

