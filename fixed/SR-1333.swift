func returnTrue() -> Bool {
    return true
}

func crashFunction() {
    guard (try? returnTrue()) != nil else {
        return
    }
}

