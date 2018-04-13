import Foundation
import StoreKit

#if false
let error: Error = NSError(domain: SKError._nsErrorDomain, code: SKError.paymentCancelled.rawValue)

switch error as? SKError {
case .some(SKError.paymentCancelled):
    print("paymentCancelled")
default:
    print("default")
}
#else
let error: Error = NSError(domain: SKError._nsErrorDomain, code: SKError.paymentCancelled.rawValue)

switch error as? SKError {
case .some(SKError.paymentCancelled):
    print("paymentCancelled")
default:
    print("default")
}
#endif


