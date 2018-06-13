import Foundation

func afunction(_ pattern: String, options: [String]? = nil) -> String {
    return pattern
}


class Testing {
    private static let defaultValue = afunction("Foo", options: ["Bar"])

    private func afunction(for file: String, using pattern: String) -> String {
        return "Hogehoge"
    }

    init() {}
}


Testing()

