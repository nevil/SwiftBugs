import UIKit


extension UIApplication {
    
    func openURL(_ url: URL, completion: ((Bool) -> Void)?) {
        if #available(iOS 10, *) {
            open(url, options: [:], completionHandler: completion)
        }
    }
}

