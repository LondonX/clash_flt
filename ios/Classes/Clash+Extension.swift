import NetworkExtension

extension NEVPNStatus {
    
    var displayString: String {
        switch self {
        case .invalid:
            return "不可用"
        case .connecting:
            return "正在连接..."
        case .connected:
            return "已连接"
        case .reasserting:
            return "正在重新连接..."
        case .disconnecting:
            return "正在断开连接..."
        case .disconnected:
            return "未连接"
        @unknown default:
            return "未知"
        }
    }
}

extension Clash.LogLevel {
    
    var displayName: String {
        switch self {
        case .silent:
            return "静默"
        case .info:
            return "信息"
        case .debug:
            return "调试"
        case .warning:
            return "警告"
        case .error:
            return "错误"
        }
    }
}

extension Clash.TunnelMode {
    
    var imageName: String {
        switch self {
        case .global:
            return "globe"
        case .rule:
            return "arrow.triangle.branch"
        case .direct:
            return "arrow.forward"
        }
    }
    
    var title: String {
        switch self {
        case .global:
            return "全局"
        case .rule:
            return "规则"
        case .direct:
            return "直连"
        }
    }
    
    var detail: String {
        switch self {
        case .global:
            return "流量全部经过指定的全局代理"
        case .rule:
            return "流量按规则分流"
        case .direct:
            return "流量不会经过任何代理"
        }
    }
}

extension Clash.Traffic {
    
    var title: String {
        switch self {
        case .up:
            return "上传"
        case .down:
            return "下载"
        }
    }
    
    var imageName: String {
        switch self {
        case .up:
            return "arrow.up"
        case .down:
            return "arrow.down"
        }
    }
}

