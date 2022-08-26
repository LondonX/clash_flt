import Flutter
import UIKit
import ClashKit

public class SwiftClashFltPlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel
    private let clashClient = AppClashClient()
    
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
        let callbackKey = argsMap?["callbackKey"] as? String
        let callMethod = call.method
        switch(callMethod){
        case "reset":
            break
        case "forceGc":
            break
        case "suspendCore":
            break
        case "queryTunnelState":
            break
        case "queryTrafficNow":
            break
        case "queryTrafficTotal":
            break
        case "notifyDnsChanged":
            break
        case "notifyTimeZoneChanged":
            break
        case "startTun":
            break
        case "stopTun":
            break
        case "startHttp":
            break
        case "stopHttp":
            break
        case "queryGroupNames":
            break
        case "queryGroup":
            break
        case "healthCheck":
            break
        case "healthCheckAll":
            break
        case "patchSelector":
            break
        case "fetchAndValid":
            let url = argsMap?["url"] as? String
            let force = argsMap?["force"] as? Bool == true
            Task.init {
                callbackWithKey(
                    callbackKey: callbackKey,
                    params: FetchStatus(action: .fetchConfiguration).toMap()
                )
                let profileFile = await downloadProfile(url: url, force: force)
                print("downloadProfile result: ", profileFile ?? "")
                callbackWithKey(
                    callbackKey: callbackKey,
                    params: FetchStatus(action: .verifying).toMap()
                )
                if(profileFile == nil) {
                    result(FlutterError(code: "Clash.\(callMethod)", message: "Download profile failed!!!", details: nil))
                    return
                }
                var dir = URL(fileURLWithPath: profileFile!.path)
                dir.deleteLastPathComponent()
                do {
                    let config = try String(contentsOf: profileFile!)
                    clashClient.log("info", message: "LondonX")
                    ClashKit.ClashSetup(dir.path, config, clashClient)
                } catch {
                    result(FlutterError(code: "Clash.\(callMethod)", message: "Profile invalid!!!", details: nil))
                    return
                }
                result(nil)
            }
            break
        case "load":
            break
        case "queryProviders":
            break
        case "updateProvider":
            break
        case "installSideloadGeoip":
            break
        case "subscribeLogcat":
            break
        case "unsubscribeLogcat":
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
}
