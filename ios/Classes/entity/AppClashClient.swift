//
//  AppClashClient.swift
//  clash_flt
//
//  Created by LondonX on 2022/8/26.
//

import Foundation
import ClashKit

class AppClashClient: NSObject, ClashClientProtocol {
    var proxyGroups: [String : ProxyGroup] = [:]
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
    
    func load() -> Bool {
        let data = ClashKit.ClashProvidersData()
        let json = String(data: data!, encoding: .utf8)
        let dict = JsonUtil.convertToDictionary(text: json)
        if (dict == nil) {
            return false
        }
        proxyGroups.removeAll()
        for key in dict!.keys {
            let provider = dict![key] as? Dictionary<String, Any>
            let group = resolveClashGroup(provider)
            if (group == nil) {
                continue
            }
            proxyGroups[key] = group!
        }
        return true
    }
    
    func healthCheck(groupName: String) {
        print("healthCheck groupName: \(groupName)")
        let data = ClashKit.ClashHealthCheck(groupName, "https://www.google.com/")
        print("healthCheck finish")
        let json = String(data: data!, encoding: .utf8)
        let dict = JsonUtil.convertToDictionary(text: json)
        if (dict == nil) {
            return
        }
        let proxies = proxyGroups[groupName]?.proxies ?? []
        for p in proxies {
            let delay = dict![p.name] as? Int
            if (delay == 0) {
                continue
            }
            p.delay = delay ?? 0xFFFF
        }
    }
    
    private func resolveClashGroup(_ provider: Dictionary<String, Any>?) -> ProxyGroup? {
        if (provider == nil) {
            return nil
        }
        let proxies = provider!["proxies"] as? Array<Dictionary<String, Any>> ?? []
        var mappedProxies: [Proxy] = []
        for proxy in proxies {
            let rawType = proxy["type"] as? String ?? "unknown"
            let type: String
            if (rawType.uppercased() == rawType) {
                type = rawType.lowercased()
            }else{
                let first = rawType.prefix(1).lowercased()
                type = first + rawType.dropFirst()
            }
            let proxy = Proxy(
                name: proxy["name"] as? String ?? "",
                title: proxy["name"] as? String ?? "",
                subtitle: proxy["type"] as? String ?? "",
                type: type,
                delay: 0xFFFF
            )
            mappedProxies.append(proxy)
        }
        let proxyGroup = ProxyGroup(type: "unknown", proxies: mappedProxies, now: "")
        return proxyGroup
    }
}
