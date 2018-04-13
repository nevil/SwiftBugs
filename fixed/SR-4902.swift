import UIKit

protocol CrasherProtocol: NSObjectProtocol {
    var hidden: Bool { get set }
}

final class CrasherView: UIView, CrasherProtocol {
}

