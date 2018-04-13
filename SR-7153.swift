protocol AProtocol {
    var rawValue: Int { get }
}


private enum AnEnum: Int, AProtocol {
    case a = 0
}


