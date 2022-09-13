//
//  VPNController.swift
//  clash_flt
//
//  Created by LondonX on 2022/9/13.
//

import Foundation
import Combine
import NetworkExtension

public final class VPNController: ObservableObject {
    
    private var cancellables: Set<AnyCancellable> = []
    private let providerManager: NETunnelProviderManager
    
    public var connectedDate: Date? {
        self.providerManager.connection.connectedDate
    }
    
    @Published public var connectionStatus: NEVPNStatus
    
    public init(providerManager: NETunnelProviderManager) {
        self.providerManager = providerManager
        self.connectionStatus = providerManager.connection.status
        NotificationCenter.default
            .publisher(for: Notification.Name.NEVPNStatusDidChange, object: self.providerManager.connection)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in self.handleVPNStatusDidChangeNotification($0) }
            .store(in: &self.cancellables)
    }
    
    private func handleVPNStatusDidChangeNotification(_ notification: Notification) {
        guard let connection = notification.object as? NEVPNConnection, connection === self.providerManager.connection else {
            return
        }
        self.connectionStatus = connection.status
    }
    
    public func isEqually(manager: NETunnelProviderManager) -> Bool {
        self.providerManager === manager
    }
    
    public func startVPN() async throws {
        switch self.providerManager.connection.status {
        case .disconnecting, .disconnected:
            break
        case .connecting, .connected, .reasserting, .invalid:
            return
        @unknown default:
            break
        }
        if !self.providerManager.isEnabled {
            self.providerManager.isEnabled = true
            try await self.providerManager.saveToPreferences()
        }
        do {
            try self.providerManager.connection.startVPNTunnel()
        } catch {
            print("error: \(error)")
        }
    }
    
    public func stopVPN() {
        switch self.providerManager.connection.status {
        case .disconnecting, .disconnected, .invalid:
            return
        case .connecting, .connected, .reasserting:
            break
        @unknown default:
            break
        }
        self.providerManager.connection.stopVPNTunnel()
    }
    
    public func notifyConfigChanged() {
        Task.init {
            await sendProviderMessage("notifyConfigChanged")
        }
    }
    
    public func queryTrafficNow() async -> Traffic? {
        let data = await sendProviderMessage("queryTrafficNow")
        if (data == nil) {
            return nil
        }
        let raw = String(data: data!, encoding: .utf8)!.split(separator: ",")
        let up = Int64(raw[0])!
        let down = Int64(raw[1])!
        return Traffic(up: up, down: down)
    }
    
    public func queryTrafficTotal() async -> Traffic? {
        let data = await sendProviderMessage("queryTrafficTotal")
        if (data == nil) {
            return nil
        }
        let raw = String(data: data!, encoding: .utf8)!.split(separator: ",")
        let up = Int64(raw[0])!
        let down = Int64(raw[1])!
        return Traffic(up: up, down: down)
    }
    
    private func sendProviderMessage(_ command: String) async -> Data? {
        let data = command.data(using: .utf8)!
        guard self.connectionStatus != .invalid || self.connectionStatus != .disconnected else {
            return nil
        }
        return try? await withCheckedThrowingContinuation { continuation in
            do {
                try (self.providerManager.connection as! NETunnelProviderSession).sendProviderMessage(data) {
                    continuation.resume(with: .success($0))
                }
            } catch {
                continuation.resume(with: .failure(error))
            }
        }
    }
}
