let q: UInt = 0

// Works
if q == 0xFFFFFFFF {
    print("==")
}

// Integer literal '4294967295' overflows when stored into 'Int'
if q != 0xFFFFFFFF {
    print("!=")
}


