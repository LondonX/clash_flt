//
//  Proxy.swift
//  AppAuth
//
//  Created by LondonX on 2022/9/2.
//

import Foundation

class Proxy : NSObject {
    let name: String
    let title: String
    let subtitle: String
    let type: String
    var delay: Int
    
    init(
        name: String,
        title: String,
        subtitle: String,
        type: String,
        delay: Int
    ) {
        self.name = name
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.delay = delay
    }
    
    
    func toMap() -> [String : Any] {
        return [
            "name" : name,
            "title" : title,
            "subtitle" : subtitle,
            "type" : type,
            "delay" : delay,
        ]
    }
}
