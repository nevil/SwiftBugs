// /Library/Developer/Toolchains/swift-DEVELOPMENT-SNAPSHOT-2018-03-17-a.xctoolchain/usr/bin/swiftc -sdk  /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -target arm64-apple-ios10.0 -c -v bug.swift

import UIKit

class ACollectionViewDelegate: NSObject, UICollectionViewDelegate {
    var collectionView: UICollectionView! { return UICollectionView() }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}

