class C {}

extension C {
    var integer: Int { return 1 }
}

protocol P {
    var integer: Int { get }
}

extension P where Self: C {
//    var anotherInteger: Int { return (self as C).integer }
    var anotherInteger: Int { return self.integer }
}

