//
//  AppClashClient.swift
//  clash_flt
//
//  Created by LondonX on 2022/8/26.
//

import Foundation
import ClashKit

class AppClashClient: NSObject, ClashClientProtocol {
    func log(_ level: String?, message: String?) {
        print("AppClashClient[\(level ?? "")]: \(message ?? "")")
    }
    
    func traffic(_ up: Int64, down: Int64) {
//        print("AppClashClient[traffic]: ⬆️\(up)|⬇️\(down)")
    }
}
