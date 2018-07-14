//
//  main.swift
//  MigrationDefines
//
//  Created by Anders Hasselqvist on 2018/07/14.
//  Copyright © 2018 Anders Hasselqvist. All rights reserved.
//

import Foundation

print("Hello, World!")

#if HELLO
let value = "HELLO"
#elseif WORLD
let value = "WORLD"
#endif


print("The value is: \(value)")
