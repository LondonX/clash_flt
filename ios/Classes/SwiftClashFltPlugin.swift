import Flutter
import UIKit

public class SwiftClashFltPlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel
    private let vpnManager = VPNManager.shared
    
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
            
            let suiteName: String = {
                let identifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
                return "group.\(identifier)"
            }()
            let userDefaults = UserDefaults(suiteName: suiteName)!
            let clashHome = argsMap!["clashHome"] as! String
            let profilePath = argsMap!["profilePath"] as! String
            let countryDBPath = argsMap!["countryDBPath"] as! String
            let groupName = argsMap!["groupName"] as! String
            let proxyName = argsMap!["proxyName"] as! String
            userDefaults.set(clashHome, forKey: "clash_flt_clashHome")
            userDefaults.set(profilePath, forKey: "clash_flt_profilePath")
            // /var/mobile/Containers/Data/Application/D308986C-7D80-4691-83B0-C73230D371B4/Library/Application Support/clash/Country.mmdb
            userDefaults.set(countryDBPath, forKey: "clash_flt_countryDBPath")
            userDefaults.set(groupName, forKey: "clash_flt_groupName")
            userDefaults.set(proxyName, forKey: "clash_flt_proxyName")
            result(true)
            if (!isClashRunning()) {
                return
            }
            vpnManager.controller?.notifyConfigChanged()
            break
        case "isClashRunning":
            result(isClashRunning())
            break
        case "startClash":
            Task.init {
                do {
                    try await vpnManager.installVPNConfiguration()
                    if(vpnManager.controller == nil) {
                        result(false)
                        return
                    }
                    try await vpnManager.controller?.startVPN()
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
}
