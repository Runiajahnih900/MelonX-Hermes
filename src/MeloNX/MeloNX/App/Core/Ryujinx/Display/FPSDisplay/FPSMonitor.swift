//
//  FPSMonitor.swift
//  MeloNX
//
//  Created by Stossy11 on 21/12/2024.
//

import Foundation
import Combine

@MainActor
class FPSMonitor: ObservableObject {
    @Published private(set) var currentFPS: UInt64 = 0
    private var task: Task<Void, Never>?

    private let activePollIntervalNs: UInt64 = 250_000_000 // 250ms
    private let idlePollIntervalNs: UInt64 = 600_000_000   // 600ms

    init() {
        task = Task.detached(priority: .utility) { [weak self] in
            await self?.monitorFPS()
        }
    }

    deinit {
        task?.cancel()
    }

    private func monitorFPS() async {
        while !Task.isCancelled {
            let latestFPS = UInt64(RyujinxBridge.currentFPS)

            await MainActor.run {
                if self.currentFPS != latestFPS {
                    self.currentFPS = latestFPS
                }
            }

            let sleepNs = latestFPS > 0 ? activePollIntervalNs : idlePollIntervalNs
            try? await Task.sleep(nanoseconds: sleepNs)
        }
    }

    func formatFPS() -> String {
        String(format: "FPS: %.2f", Double(currentFPS))
    }
}
