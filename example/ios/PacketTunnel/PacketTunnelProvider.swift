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
        let port = general?["port"] as? Int ?? 7890
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
        let profilePath = userDefaults.string(forKey: "clash_flt_profilePath")
        let countryDBPath = userDefaults.string(forKey: "clash_flt_countryDBPath")
        let groupName = userDefaults.string(forKey: "clash_flt_groupName")
        let proxyName = userDefaults.string(forKey: "clash_flt_proxyName")
        
        if(clashHome == nil ||
           profilePath == nil ||
           countryDBPath == nil ||
           groupName == nil ||
           proxyName == nil
        ) {
            return false
        }
        
        let config = try? String(contentsOfFile: profilePath!)
        //TODO: - reading config from file failed
        if(config == nil) {
            return false
        }
        ClashKit.ClashSetup(clashHome, config, client)
        return true
    }
    
    private func initTunnelSettings(proxyHost: String, proxyPort: Int) -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: proxyHost)
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
            addresses: [settings.tunnelRemoteAddress, "0.0.0.0"],
            subnetMasks: ["255.255.255.0"]
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
        print("AppClashClient[\(level ?? "")]: \(message ?? "")")
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
            print(error.localizedDescription)
        }
    }
    return nil
}

enum MyError: Error {
    case runtimeError(String)
}
