//
//  main.swift
//  Protocol
//
//  Created by Anders Hasselqvist on 2018/07/14.
//  Copyright © 2018 Anders Hasselqvist. All rights reserved.
//

import Foundation


class Main {
    struct Environment {
        let api: UNApiClientManagerProtocol
    }

    let environment: Environment

    init() {
        environment = Environment(api: UNApiClientManager())
    }

    func getHomeBlockPagingInfo(pageSize: Int, pageIndex: Int, featureBlockSize: Int, completion: @escaping (Bool) -> Void) {
        let parameters: JSONDictionary = [
            "page_size": pageSize,
            "page_number": pageIndex,
            "sakuhins_per_feature": featureBlockSize,
            ]
        environment.api.postDataToServer(".getHomeBlockPagingList", data: parameters) { (response) in
            switch response {
            case true:
                print("true")
            case false:
                print("false")
            }
        }
    }
}
