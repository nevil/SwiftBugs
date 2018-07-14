//
//  Afile.swift
//  Protocol
//
//  Created by Anders Hasselqvist on 2018/07/14.
//  Copyright © 2018 Anders Hasselqvist. All rights reserved.
//

import Foundation

typealias JSONDictionary = [String: Any]

protocol UNApiClientManagerProtocol {
    @discardableResult
    func postDataToServer(_ apiTag: String, deviceType: String, data: JSONDictionary, completionHandler: ((Bool) -> Void)?) -> URLSessionDataTask?
}

extension UNApiClientManagerProtocol {
    @discardableResult
    func postDataToServer(_ apiTag: String, data: JSONDictionary = [:], completionHandler: ((Bool) -> Void)?) -> URLSessionDataTask? {
        return self.postDataToServer(apiTag, deviceType: "UNConst.Api.DeviceType.iOS", data: data, completionHandler: completionHandler)
    }
}

class UNApiClientManager: UNApiClientManagerProtocol {
    func postDataToServer(_ apiTag: String, deviceType: String, data: JSONDictionary, completionHandler: ((Bool) -> Void)?) -> URLSessionDataTask? {
        return nil
    }
}
