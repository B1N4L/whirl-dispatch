//
//  NetworkMonitor.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-14.
//

import Foundation
import Network
import Observation

@Observable
final class NetworkMonitor: @unchecked Sendable {
    static let shared = NetworkMonitor()

    var isConnected: Bool = true
    var isExpensive: Bool = false
    var connectionType: ConnectionType = .wifi

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.whirldispatch.networkmonitor")

    init() {
        self.monitor = NWPathMonitor()
        startMonitoring()
    }


    // start monitoring cellular and wifi paths
    private func startMonitoring() {
      monitor.pathUpdateHandler = { [weak self] path in
          guard let self = self else { return }

          DispatchQueue.main.async {
              self.isConnected = (path.status == .satisfied)
              self.isExpensive = path.isExpensive

              if path.usesInterfaceType(.wifi) {
                  self.connectionType = .wifi
              } else if path.usesInterfaceType(.cellular) {
                  self.connectionType = .cellular
              } else if path.usesInterfaceType(.wiredEthernet) {
                  self.connectionType = .ethernet
              } else {
                  self.connectionType = .unknown
              }
          }
      }

      monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}
