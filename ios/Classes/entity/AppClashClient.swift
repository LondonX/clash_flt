//
//  AppClashClient.swift
//  clash_flt
//
//  Created by LondonX on 2022/8/26.
//

import Foundation
import ClashKit

class AppClashClient: NSObject, ClashClientProtocol {
    private let trafficListener: (_ up: Int64, _ down: Int64) -> Void
    
    init(trafficListener: @escaping (_ up: Int64, _ down: Int64) -> Void) {
        self.trafficListener = trafficListener
    }
    
    func log(_ level: String?, message: String?) {
        print("AppClashClient[\(level ?? "")]: \(message ?? "")")
    }
    
    func traffic(_ up: Int64, down: Int64) {
        trafficListener(up, down)
    }
}
