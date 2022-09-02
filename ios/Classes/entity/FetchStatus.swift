//
//  FetchStatus.swift
//  clash_flt
//
//  Created by LondonX on 2022/8/26.
//

import Foundation

class FetchStatus : NSObject{
    let action: Action
    let args: [String]
    let progress: Int
    let max: Int
    init(
        action: Action,
        args: [String] = [],
        progress: Int = 0xFFFF,
        max: Int = 0xFFFF
    ){
        self.action = action
        self.args = args
        self.progress = progress
        self.max = max
    }
    
    func toMap() -> [String : Any] {
        return [
            "action" : action.rawValue,
            "args" : args,
            "progress" : progress,
            "max" : max,
        ]
    }
}

enum Action: String{
    case fetchConfiguration
    case fetchProviders
    case verifying
}
