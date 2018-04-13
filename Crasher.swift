func afunc() {
    let nestedA: (_: (@escaping (Error?) -> Void)) -> Void = { (_) in
    }

    let nestedB: (Error?) -> Void = { (error) in
        guard error == nil else {
            nestedA(nestedB)
            return
        }
    }

    nestedA(nestedB)
}

