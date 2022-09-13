//
//  Traffic.swift
//  clash_flt
//
//  Created by LondonX on 2022/8/29.
//

import Foundation

public class Traffic : NSObject{
    static let zero = Traffic(up: 0, down: 0)
    
    let up: Int64
    let down: Int64
    
    init(up: Int64, down: Int64) {
        self.up = up
        self.down = down
    }
    
    func toMap() -> [String : Int64] {
        return [
            "up" : up,
            "down" : down
        ]
    }
}
