import Flutter
import UIKit
import ClashKit

public class SwiftClashFltPlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel
    private var trafficTotal = Traffic(up: 0, down: 0)
    private var trafficNow = Traffic(up: 0, down: 0)
    private lazy var clashClient = AppClashClient(trafficListener: self.trafficListener)
    
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
            result(nil)
            break
        case "forceGc":
            result(nil)
            break
        case "queryTunnelState":
            let mode = ClashKit.ClashGetTunnelMode()
            result(["mode" : mode])
            break
        case "queryTrafficNow":
            result(trafficNow.toMap())
            break
        case "queryTrafficTotal":
            result(trafficTotal.toMap())
            break
        case "notifyDnsChanged":
            result(FlutterMethodNotImplemented)
            break
        case "notifyTimeZoneChanged":
            result(FlutterMethodNotImplemented)
            break
        case "healthCheck":
            let name = argsMap?["name"] as! String
            ClashHealthCheck(name, "https://www.google.com", 5000)
            result(nil)
            break
        case "healthCheckAll":
            result(FlutterMethodNotImplemented)
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
    
    private func trafficListener(up: Int64, down: Int64) {
        self.trafficNow = Traffic(up: up, down: down)
        self.trafficTotal = Traffic(
            up: self.trafficTotal.up + up,
            down: self.trafficTotal.down + down
        )
    }
}
