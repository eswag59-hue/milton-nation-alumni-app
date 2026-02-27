import Foundation
import Network

/// Observes device network connectivity using NWPathMonitor.
///
/// Usage:
///   `NetworkMonitor.shared.isConnected`   — current reachability
///   `NetworkMonitor.shared.connectionType` — wifi / cellular / unknown
///
/// The monitor starts automatically on init and runs on a background queue.
/// SwiftUI views can observe changes via the `@Observable` macro.
@Observable
final class NetworkMonitor {

    static let shared = NetworkMonitor()

    // MARK: - Published State

    /// Whether the device currently has a network path that is satisfied.
    private(set) var isConnected: Bool = true

    /// The primary interface type (wifi, cellular, wiredEthernet, or unknown).
    private(set) var connectionType: ConnectionType = .unknown

    // MARK: - Types

    enum ConnectionType: String {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    // MARK: - Private

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .utility)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.resolveType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Helpers

    private func resolveType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wiredEthernet }
        return .unknown
    }
}
