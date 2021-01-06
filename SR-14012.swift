
#if WORKING
// Working
struct MYRNG: RandomNumberGenerator {
    private var n: UInt64 = 0
    mutating func next() -> UInt64 { return 0 }
}

#else

// TSAN crash
struct MYRNG: RandomNumberGenerator {
    mutating func next() -> UInt64 { return 1 }
}
#endif

func returnNext<R: RandomNumberGenerator>(using generator: inout R) -> UInt64 {
    return generator.next()
}

func callReturnNext<R: RandomNumberGenerator>(_ array: [Int], using generator: inout R) -> UInt64 {
    return returnNext(using: &generator)
}


var g = MYRNG()

_  = callReturnNext([0], using: &g)

