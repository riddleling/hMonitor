//
//  DashboardView.swift
//  hMonitor
//
//  Created by Riddle Ling on 2025/8/9.
//

import SwiftUI

// MARK: - SwiftUI Views
struct DashboardView: View {
    @StateObject private var sampler = Sampler()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    CPUCard(snapshots: sampler.snapshots)
                    MemoryCard(snapshots: sampler.snapshots)
                    HStack(spacing: 16) {
                        ThermalCard(snapshots: sampler.snapshots)
                                .frame(maxWidth: .infinity)
                            BatteryCard(snapshots: sampler.snapshots)
                                .frame(maxWidth: .infinity)
                    }
                    DiskNetworkCard(snapshots: sampler.snapshots)
                    AppCard(snapshots: sampler.snapshots)
                }
                .padding()
            }
            .navigationTitle("hMonitor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: toggleSampling) {
                        Image(systemName: sampler.isRunning ? "pause.circle" : "play.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { sampler.clear() }) {
                        Image(systemName: "arrow.clockwise.circle")
                    }
                }
            }
        }
        .onAppear { sampler.start() }
        .onDisappear { sampler.stop() }
    }

    private var samplerRunning: Bool { sampler.snapshots.count > 0 }
    private func toggleSampling() {
        sampler.isRunning ? sampler.stop() : sampler.start()
    }
}
