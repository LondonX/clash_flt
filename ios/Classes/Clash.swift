import Foundation

public enum Clash {
    
    public static let appGroup: String = Bundle.main.infoDictionary?["CLASH_APP_GROUP"] as! String
    
    public static let tunnelMode: String = "ClashTunnelMode"
    
    public static let logLevel: String = "ClashLogLevel"
    
    public static let theme: String = "ClashTheme"
    
    public static let currentConfigUUID: String = "CurrentConfigUUID"
    
    public static let homeDirectoryURL: URL = {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Clash.appGroup) else {
            fatalError("无法加载共享文件路径")
        }
        let url = containerURL.appendingPathComponent("Library/Application Support/Clash")
        guard FileManager.default.fileExists(atPath: url.path) == false else {
            return url
        }
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError(error.localizedDescription)
        }
        return url
    }()
}

extension Clash {
    
    public enum Command: Codable {
        case setConfig
        case setTunnelMode
        case setLogLevel
        case setSelectGroup
        case mergedProxyData
        case patchData
        case healthCheck(String, URL, Int)
    }
    
    public enum LogLevel: String, Identifiable, CaseIterable {
            
        public var id: Self { self }
        
        case silent, info, debug, warning, error
    }
    
    public enum Traffic: String {
        case up     = "ClashTrafficUP"
        case down   = "ClashTrafficDOWN"
    }
    
    public enum TunnelMode: String, Hashable, Identifiable, CaseIterable {
        
        public var id: Self { self }
        
        case global, rule, direct
    }
}
