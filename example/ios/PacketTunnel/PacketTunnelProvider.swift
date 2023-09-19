//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by LondonX on 2022/9/13.
//  Update on 2023/9/19
//
import NetworkExtension
import ClashKit
import Tun2SocksKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    private var trafficTotalUp: Int64 = 0
    private var trafficTotalDown: Int64 = 0
    private var trafficUp: Int64 = 0
    private var trafficDown: Int64 = 0
    private var appliedCfg: String? = nil
    
    private var userDefaults: UserDefaults? = nil
    
    private lazy var client = AppClashClient { trafficUp, trafficDown in
        self.trafficTotalUp += trafficUp
        self.trafficTotalDown += trafficDown
        self.trafficUp = trafficUp
        self.trafficDown = trafficDown
    }
    
    override func startTunnel(options: [String : NSObject]?) async throws {
        let exIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
        let identifier = exIdentifier.replacingOccurrences(of: ".PacketTunnel", with: "")
        let suiteName = "group.\(identifier)"
        self.userDefaults = UserDefaults(suiteName: suiteName)!
        
        let allowStartFromIOSSettings = userDefaults!.bool(forKey: "clash_flt_allowStartFromIOSSettings")
        
        let startFromIOSSettings = (options?["startFromApp"] as? Bool) != true
        if(startFromIOSSettings && !allowStartFromIOSSettings){
            throw MyError.runtimeError("Preventing tunnel start, allowStartFromIOSSettings is false")
        }
        let isSetup = setupClash()
        if (!isSetup) {
            throw MyError.runtimeError("Clash Setup failed")
        }
        let generalJson = String(data: ClashKit.ClashGetConfigGeneral()!, encoding: .utf8)
        let general = jsonToDictionary(generalJson)
        osLog("Clash started with config: \(String(describing: (generalJson)))")
        let port = general?["port"] as? Int ?? 7890
        let socksPort = general?["socks-port"] as? Int ?? 7891
        let host = "127.0.0.1"
        try await self.setTunnelNetworkSettings(initTunnelSettings(proxyHost: host, proxyPort: port))
        
        // start TUN
        Task.init {
            let tunConfigFile = saveTunnelConfigToFile(socksPort: socksPort)
            do {
                let tunConfig = try String(contentsOf: tunConfigFile, encoding: .utf8)
                osLog("tunConfig: \(tunConfig)")
            }catch{
                fatalError("cannot read tunConfigFile")
            }
            osLog("Socks5Tunnel.run: \(Socks5Tunnel.run(withConfig: tunConfigFile.path))")
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason) async {
        Socks5Tunnel.quit()
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
        let userDefaults = self.userDefaults!
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
        let configOverride = """
        \(config!)
        allow-lan: true
        ipv6: true
        """
        if (appliedCfg != configOverride) {
            osLog("config changed, calling ClashKit.ClashSetup.")
            ClashKit.ClashSetup(clashHomeUrl!.path, configOverride, client)
            appliedCfg = configOverride
        } else {
            osLog("config no changes, skip ClashKit.ClashSetup.")
        }
        let map = [groupName! : proxyName!]
        let json = dictionaryToJson(dic: map)
        ClashKit.ClashPatchSelector(json?.data(using: .utf8))
        return true
    }
    
    private func initTunnelSettings(proxyHost: String, proxyPort: Int) -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "254.1.1.1")
        settings.mtu = 9000
        settings.ipv4Settings = {
            let settings = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.0.0"])
            settings.includedRoutes = [NEIPv4Route.default()]
            return settings
        }()
        settings.ipv6Settings = {
            let settings = NEIPv6Settings(addresses: ["fd6e:a81b:704f:1211::1"], networkPrefixLengths: [64])
            settings.includedRoutes = [NEIPv6Route.default()]
            return settings
        }()
        settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1"])
        settings.proxySettings = {
            let settings = NEProxySettings();
            settings.httpServer = NEProxyServer(address: "::1", port: proxyPort)
            settings.httpsServer = NEProxyServer(address: "::1", port: proxyPort)
            settings.httpEnabled = true
            settings.httpsEnabled = true
            settings.matchDomains = [""]
            return settings
        }()
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

private func saveTunnelConfigToFile(socksPort: Int) -> URL {
    let content = """
    tunnel:
      mtu: 9000

    socks5:
      port: \(socksPort)
      address: ::1
      udp: 'udp'

    misc:
      task-stack-size: 20480
      connect-timeout: 5000
      read-write-timeout: 60000
      log-file: stderr
      log-level: info
      limit-nofile: 65535
    """
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let fileURL = documentsDirectory.appendingPathComponent("tunnel_config.yaml")
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            fatalError("Error writing to file: \(error)")
        }
    } else {
        fatalError("Error finding the documents directory.")
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
