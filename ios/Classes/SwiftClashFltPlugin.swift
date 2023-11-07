import Flutter
import UIKit

public class SwiftClashFltPlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel
    private let vpnManager = VPNManager.shared
    
    let suiteName: String = {
        let identifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
        return "group.\(identifier)"
    }()
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "clash_flt", binaryMessenger: registrar.messenger())
        let instance = SwiftClashFltPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let argsMap = call.arguments as? [String : Any]
        let callMethod = call.method
        switch(callMethod){
        case "queryTrafficNow":
            if (vpnManager.controller == nil) {
                result(Traffic.zero.toMap())
                break
            }
            Task.init {
                let traffic = await vpnManager.controller!.queryTrafficNow() ?? Traffic.zero
                result(traffic.toMap())
            }
            break
        case "queryTrafficTotal":
            if (vpnManager.controller == nil) {
                result(Traffic.zero.toMap())
                break
            }
            Task.init {
                let traffic = await vpnManager.controller!.queryTrafficTotal() ?? Traffic.zero
                result(traffic.toMap())
            }
            break
        case "applyConfig":
            if (argsMap == nil) {
                result(false)
                break
            }
            
            let userDefaults = UserDefaults(suiteName: suiteName)!
            let clashHome = argsMap!["clashHome"] as! String
            let profilePath = argsMap!["profilePath"] as! String
            let countryDBPath = argsMap!["countryDBPath"] as! String
            let groupName = argsMap!["groupName"] as! String
            let proxyName = argsMap!["proxyName"] as! String
            let allowStartFromIOSSettings = argsMap!["allowStartFromIOSSettings"] as! Bool
            let sharedClashHome = noneSandboxUrl(clashHome, isDir: true)
            let sharedProfilePath = noneSandboxUrl(profilePath, isDir: false)
            let sharedCountryDBPath = noneSandboxUrl(countryDBPath, isDir: false)
            userDefaults.set(sharedClashHome.absoluteString, forKey: "clash_flt_clashHome")
            userDefaults.set(sharedProfilePath, forKey: "clash_flt_profilePath")
            userDefaults.set(sharedCountryDBPath, forKey: "clash_flt_countryDBPath")
            userDefaults.set(groupName, forKey: "clash_flt_groupName")
            userDefaults.set(proxyName, forKey: "clash_flt_proxyName")
            userDefaults.set(allowStartFromIOSSettings, forKey: "clash_flt_allowStartFromIOSSettings")
            result(true)
            if (!isClashRunning()) {
                return
            }
            vpnManager.controller?.notifyConfigChanged()
            break
        case "isClashRunning":
            Task.init {
                await vpnManager.loadController()
                result(isClashRunning())
            }
            break
        case "startClash":
            Task.init {
                do {
                    try await vpnManager.installVPNConfiguration()
                    let controller = await vpnManager.loadController()
                    if(controller == nil) {
                        result(false)
                        return
                    }
                    try await Task.sleep(nanoseconds: 100_000_000)//0.1s
                    try await controller?.startVPN()
                } catch {
                    result(false)
                    return
                }
                result(true)
            }
            break
        case "stopClash":
            vpnManager.controller?.stopVPN()
            result(nil)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func callbackWithKey(callbackKey: String?, params: [String : Any?]) {
        let arguments: [String : Any?] = [
            "callbackKey" : callbackKey,
            "params" : params,
        ]
        channel.invokeMethod(
            "callbackWithKey",
            arguments: arguments
        )
    }
    
    private func isClashRunning() -> Bool {
        return vpnManager.controller?.connectionStatus == .connected
    }
    
    private func noneSandboxUrl(_ sandboxPath: String, isDir: Bool) -> URL {
        let separator = "/Library/Application Support/"
        let replace = (sandboxPath.components(separatedBy: separator).first!) + separator
        let components = sandboxPath.replacingOccurrences(of: replace, with: "")
        
        let sandboxUrl = URL(fileURLWithPath: sandboxPath)
        let data = try? Data(contentsOf: sandboxUrl)
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
        let sharedUrl = container!.appendingPathComponent(components)
        try? FileManager.default.removeItem(at: sharedUrl)
        var created = false
        if (isDir) {
            do {
                try FileManager.default.createDirectory(atPath: sharedUrl.path, withIntermediateDirectories: true)
                created = true
            } catch {
                created = false
            }
            
        } else {
            var dir = URL(fileURLWithPath: sharedUrl.path)
            dir.deleteLastPathComponent()
            do {
                try FileManager.default.createDirectory(atPath: dir.path, withIntermediateDirectories: true)
                created = FileManager.default.createFile(atPath: sharedUrl.path, contents: data)
            } catch {
                created = false
            }
        }
        if(!created) {
            print("create \(isDir ? "dir" : "file") sharedUrl(\(sharedUrl)) failed!!!")
        }
        return sharedUrl
    }
}
