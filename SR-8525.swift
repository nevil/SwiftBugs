struct AStruct {
    struct Nested {
    }
}

typealias NestedStruct = AStruct.Nested

private protocol AProtocol {
    func genericFunction<T>(_ v: T)
}

struct A: AProtocol {
    func genericFunction<AStruct>(_ v: AStruct) {
    }
}

struct B: AProtocol {
    func genericFunction<NestedStruct>(_ v: NestedStruct) {
    }
}

struct C: AProtocol {
    func genericFunction<AStruct.Nested>(_ v: AStruct.Nested) {
    }
}


// The case below is more similar to what I actually used when I discovered the bug
//
//public enum Result<V, E> {
//    case success(V)
//    case failure(E)
//}
//
//private protocol AProtocol {
//    func genericFunction<T>(_ v: @escaping (Result<T, Error>) -> Void)
//}
//
//struct A: AProtocol {
//    func genericFunction<AStruct>(_ v: @escaping (Result<AStruct, Error>) -> Void) {
//    }
//}
//
//struct B: AProtocol {
//    func genericFunction<NestedStruct>(_ v: @escaping (Result<NestedStruct, Error>) -> Void) {
//    }
//}
//
//struct C: AProtocol {
//    func genericFunction<AStruct.Nested>(_ v: @escaping (Result<AStruct.Nested, Error>) -> Void) {
//    }
//}
//

