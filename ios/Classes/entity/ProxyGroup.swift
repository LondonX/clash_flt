//
//  ProxyGroup.swift
//  AppAuth
//
//  Created by LondonX on 2022/9/2.
//

import Foundation

class ProxyGroup : NSObject {
    let type: String
    let proxies: [Proxy]
    let now: String
    
    init(
        type: String,
        proxies: [Proxy],
        now: String
    ) {
        self.type = type
        self.proxies = proxies
        self.now = now
    }
    
    func toMap() -> [String : Any] {
        return [
            "type": type,
            "proxies": proxies.map({ p in
                return p.toMap()
            }),
            "now": "",
        ]
    }
}
