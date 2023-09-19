import Combine
import NetworkExtension

public final class VPNManager: ObservableObject {
    
    private var cancellables: Set<AnyCancellable> = []
    public var controller: VPNController?
    
    public static let shared = VPNManager()
    
    private let providerBundleIdentifier: String = {
        let identifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
        return "\(identifier).PacketTunnel"
    }()
    
    private init() {
        NotificationCenter.default
            .publisher(for: .NEVPNConfigurationChange, object: nil)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in self.handleVPNConfigurationChangedNotification($0) }
            .store(in: &self.cancellables)
    }
    
    private func handleVPNConfigurationChangedNotification(_ notification: Notification) {
        Task(priority: .high) {
            await self.loadController()
        }
    }
    
    private func handleVPNStateChangeNotification(_ notification: Notification) {
        let connection = notification.object as? NEVPNConnection
        if (connection == nil) {
            return
        }
        if (connection?.status == .disconnected) {
            self.controller = nil
        }
    }
    
    func loadController() async -> VPNController? {
        if let manager = try? await self.loadCurrentTunnelProviderManager() {
            if self.controller?.isEqually(manager: manager) ?? false {
                // Nothing
            } else {
                self.controller = VPNController(providerManager: manager)
            }
        } else {
            self.controller = nil
        }
        return self.controller
    }
    
    private func loadCurrentTunnelProviderManager() async throws -> NETunnelProviderManager? {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        let first = managers.first { manager in
            guard let configuration = manager.protocolConfiguration as? NETunnelProviderProtocol else {
                return false
            }
            return configuration.providerBundleIdentifier == self.providerBundleIdentifier
        }
        do {
            guard let first = first else {
                return nil
            }
            try await first.loadFromPreferences()
            return first
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    public func installVPNConfiguration() async throws {
        let manager = (try? await loadCurrentTunnelProviderManager()) ?? NETunnelProviderManager()
        let config = NETunnelProviderProtocol()
        config.providerBundleIdentifier = self.providerBundleIdentifier
        config.serverAddress = "Clash"
        config.disconnectOnSleep = false
        if #available(iOS 14.2, *) {
            config.providerConfiguration = [:]
            config.excludeLocalNetworks = true
            config.includeAllNetworks = true
        }
        manager.protocolConfiguration = config
        manager.isEnabled = true
        manager.isOnDemandEnabled = true
        try await manager.saveToPreferences()
    }
}
