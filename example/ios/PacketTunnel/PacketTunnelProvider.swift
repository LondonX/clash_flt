//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by LondonX on 2022/9/13.
//

import NetworkExtension
import ClashKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    private var trafficTotalUp: Int64 = 0
    private var trafficTotalDown: Int64 = 0
    private var trafficUp: Int64 = 0
    private var trafficDown: Int64 = 0
    
    private lazy var client = AppClashClient { trafficUp, trafficDown in
        self.trafficTotalUp += trafficUp
        self.trafficTotalDown += trafficDown
        self.trafficUp = trafficUp
        self.trafficDown = trafficDown
    }
    
    override func startTunnel(options: [String : NSObject]?) async throws {
        let isSetup = setupClash()
        if (!isSetup) {
            throw MyError.runtimeError("Clash Setup failed")
        }
        let generalJson = String(data: ClashKit.ClashGetConfigGeneral()!, encoding: .utf8)
        let general = jsonToDictionary(generalJson)
        osLog("startTunnel with config: \(String(describing: (generalJson)))")
        let port = general?["port"] as? Int ?? 7890
        //192.168.0.29
        let host = "127.0.0.1"
        try await self.setTunnelNetworkSettings(initTunnelSettings(proxyHost: host, proxyPort: port))
    }
    
    override func stopTunnel(with reason: NEProviderStopReason) async {
    }
    
    override func handleAppMessage(_ messageData: Data) async -> Data? {
        let message = String(data: messageData, encoding: .utf8)
        switch(message) {
        case "notifyConfigChanged":
            _ = setupClash()
            break
        case "queryTrafficNow":
            return "\(trafficUp),\(trafficDown)".data(using: .utf8)
        case "queryTrafficTotal":
            return "\(trafficTotalUp),\(trafficTotalDown)".data(using: .utf8)
        default:
            break
        }
        return nil
    }
    
    private func setupClash() -> Bool {
        let exIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
        let identifier = exIdentifier.replacingOccurrences(of: ".PacketTunnel", with: "")
        let suiteName = "group.\(identifier)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let clashHome = userDefaults.string(forKey: "clash_flt_clashHome")
        let clashHomeUrl = resolvePath(clashHome, isDir: true)
        let profilePath = userDefaults.string(forKey: "clash_flt_profilePath")
        let profileUrl = resolvePath(profilePath, isDir: false)
        let countryDBPath = userDefaults.string(forKey: "clash_flt_countryDBPath")
        let countryDBUrl = resolvePath(countryDBPath, isDir: false)
        let groupName = userDefaults.string(forKey: "clash_flt_groupName")
        let proxyName = userDefaults.string(forKey: "clash_flt_proxyName")
        osLog("setup with clashHome: \(clashHomeUrl?.path ?? ""), profilePath: \(profileUrl?.path ?? ""), countryDBPath: \(countryDBUrl?.path ?? ""), groupName: \(groupName ?? ""), proxyName: \(proxyName ?? "")")
        
        if(clashHomeUrl == nil ||
           profileUrl == nil ||
           countryDBUrl == nil ||
           groupName == nil ||
           proxyName == nil
        ) {
            osLog("\(String(describing: clashHomeUrl)), \(String(describing: profileUrl)), \(String(describing: countryDBUrl)), \(String(describing: groupName)), \(String(describing: proxyName))")
            return false
        }
        let cacheDBUrl = clashHomeUrl!.appendingPathComponent("cache.db")
        FileManager.default.createFile(atPath: cacheDBUrl.path, contents: nil)
        let fileExists = FileManager.default.fileExists(atPath: profileUrl!.path)
        osLog("profileUrl: \(profileUrl!), fileExists: \(fileExists)")
        
        let config = try? String(contentsOfFile: profilePath!)
        osLog("config: \(config ?? "")")
        if(config == nil) {
            return false
        }
        ClashKit.ClashSetup(clashHomeUrl!.path, config, client)
        let data = ClashKit.ClashGetConfigGeneral()
        let map = [groupName! : proxyName!]
        let json = dictionaryToJson(dic: map)
        ClashKit.ClashPatchSelector(json?.data(using: .utf8))
        return data != nil
    }
    
    private func initTunnelSettings(proxyHost: String, proxyPort: Int) -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "254.1.1.1")
        settings.mtu = 1440
        
        /* proxy settings */
        let proxySettings = NEProxySettings()
        proxySettings.httpServer = NEProxyServer(
            address: proxyHost,
            port: proxyPort
        )
        proxySettings.httpsServer = NEProxyServer(
            address: proxyHost,
            port: proxyPort
        )
        proxySettings.httpEnabled = true
        proxySettings.httpsEnabled = true
        proxySettings.exceptionList = [
            "192.168.0.0/16",
            "10.0.0.0/8",
            "172.16.0.0/12",
            "127.0.0.1",
            "localhost",
            "*.local"
        ]
        proxySettings.matchDomains = [""]
        
        let ipv4Settings = NEIPv4Settings(
            addresses: ["198.18.0.1", "0.0.0.0"],
            subnetMasks: ["255.255.0.0"]
        )
        settings.ipv4Settings = ipv4Settings
        settings.proxySettings = proxySettings
        return settings
    }
}

class AppClashClient: NSObject, ClashClientProtocol {
    private let trafficListener: (_ up: Int64, _ down: Int64) -> Void
    
    init(trafficListener: @escaping (_ up: Int64, _ down: Int64) -> Void) {
        self.trafficListener = trafficListener
    }
    
    func log(_ level: String?, message: String?) {
        osLog("AppClashClient[\(level ?? "")]: \(message ?? "")")
    }
    
    func traffic(_ up: Int64, down: Int64) {
        trafficListener(up, down)
    }
}


private func jsonToDictionary(_ text: String?) -> [String: Any]? {
    if (text == nil) {
        return nil
    }
    if let data = text!.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            osLog("\(error.localizedDescription)")
        }
    }
    return nil
}

private func dictionaryToJson(dic: Dictionary<String, Any>?) -> String? {
    var jsonData: Data? = nil
    do {
        if let dic = dic {
            jsonData = try JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
        }
    } catch {
    }
    if let jsonData = jsonData {
        return String(data: jsonData, encoding: .utf8)
    }
    return nil
}

enum MyError: Error {
    case runtimeError(String)
}


private func resolvePath(_ nonSandboxPath: String?, isDir: Bool) -> URL? {
    if (nonSandboxPath == nil) {
        return nil
    }
    //"/private/var/mobile/Containers/Shared/AppGroup/604455A2-AD91-4DD7-AC82-F7DCE3BE448E/clash/profile/1ab43c05"
    return URL(string: nonSandboxPath!)
}

func osLog(_ any: Any?) {
    NSLog("[ClashFlt.PacketTunnel]\(any ?? "")")
}
