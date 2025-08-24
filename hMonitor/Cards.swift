//
//  Cards.swift
//  hMonitor
//
//  Created by Riddle Ling on 2025/8/9.
//


import SwiftUI
import Network

// MARK: - Cards
struct CPUCard: View {
    let snapshots: [ResourceSnapshot]
    var current: ResourceSnapshot? { snapshots.last }
    
    private func color(for usage: Double) -> Color {
        usage < 0.5 ? .green : (usage < 0.8 ? .yellow : .red)
    }

    var body: some View {
        Card {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "cpu")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 36, weight: .semibold))
                VStack(alignment: .leading) {
                    Text("CPU Usage")
                        .font(.headline)
                    Text(current?.cpuTotal.percentString ?? "--")
                        .font(.system(size: 28, weight: .bold))
                }
                Spacer()
                Gauge(value: current?.cpuTotal ?? 0) { Text("") }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(color(for: current?.cpuTotal ?? 0))
                    .frame(width: 60, height: 60)
            }
            if snapshots.count > 2 {
                LineChart(values: snapshots.suffix(120).map { $0.cpuTotal })
                    .frame(height: 56)
            }
            // 每核心列
            if let per = current?.perCoreCPU, !per.isEmpty {
                Divider().opacity(0.2)
                PerCoreBars(values: per)
            }
        }
    }
}

struct PerCoreBars: View {
    let values: [Double]
    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(values.enumerated()), id: \.0) { idx, v in
                HStack(spacing: 8) {
                    Text("Core \(idx + 1)")
                        .font(.caption2)
                        .frame(minWidth: 50, alignment: .leading)
                        .minimumScaleFactor(0.8)
                    ProgressView(value: v) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .progressViewStyle(.linear)
                    .tint(v < 0.5 ? .green : (v < 0.8 ? .yellow : .red))
                    .frame(height: 6)
                    Text(String(format: "%.0f%%", v * 100))
                        .font(.caption2)
                        .monospacedDigit()
                        .frame(minWidth: 44, alignment: .trailing)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }
}

struct MemoryCard: View {
    let snapshots: [ResourceSnapshot]
    var current: ResourceSnapshot? { snapshots.last }

    var body: some View {
        Card {
            HStack(spacing: 16) {
                Image(systemName: "memorychip")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 32, weight: .semibold))
                VStack(alignment: .leading, spacing: 6) {
                    Text("Memory")
                        .font(.headline)
                    if let s = current {
                        let used = s.memoryUsed.bytesHumanReadable
                        let total = s.memoryTotal.bytesHumanReadable
                        ProgressView(value: Double(s.memoryUsed), total: Double(s.memoryTotal))
                        HStack {
                            Text("Used: \(used)")
                            Spacer()
                            Text("Total: \(total)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    } else { Text("--") }
                }
            }
        }
    }
}

struct ThermalCard: View {
    let snapshots: [ResourceSnapshot]
    var current: ResourceSnapshot? { snapshots.last }

    var body: some View {
        Card {
            HStack { Image(systemName: "thermometer.sun"); Text("Thermal") }
                .font(.headline)
            Text(label(for: current?.thermalState ?? .nominal))
                .font(.title3.bold())
                .foregroundStyle(color(for: current?.thermalState ?? .nominal))
        }
    }

    private func label(for s: ProcessInfo.ThermalState) -> String {
        switch s { case .nominal: return "Nominal"; case .fair: return "Fair"; case .serious: return "Serious"; case .critical: return "Critical"; @unknown default: return "Unknown" }
    }
    private func color(for s: ProcessInfo.ThermalState) -> Color {
        switch s { case .nominal: return .green; case .fair: return .yellow; case .serious: return .orange; case .critical: return .red; @unknown default: return .gray }
    }
}

struct BatteryCard: View {
    let snapshots: [ResourceSnapshot]
    var current: ResourceSnapshot? { snapshots.last }
    
    private func color(for level: Float) -> Color {
        if level < 0.3 { return .red }
        else if level < 0.6 { return .yellow }
        else { return .green }
    }

    private func batteryBaseSymbol(level: Float) -> String {
        let pct = Int((level * 100).rounded())
        switch pct {
        case ..<15:    return "battery.0percent"
        case 15..<40:  return "battery.25percent"
        case 40..<65:  return "battery.50percent"
        case 65..<90:  return "battery.75percent"
        default:       return "battery.100percent"
        }
    }
    
    var body: some View {
        Card {
            HStack(spacing: 8) {
                if let level = current?.batteryLevel {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: batteryBaseSymbol(level: level))
                            .foregroundStyle(color(for: level))

                        if current?.batteryState == .charging {
                            Image(systemName: "bolt.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                                .padding(2) // 留點內距
                                .background(
                                    Circle().fill(Color(.systemBackground)) // 讓閃電在深/淺背景都清楚
                                )
                                .offset(x: 6, y: -6) // 視覺調位
                        }
                    }
                } else {
                    Image(systemName: "battery.0percent")
                        .foregroundStyle(.secondary)
                }

                Text("Battery")
                    .font(.headline)
                Spacer()
            }
            
            if let level = current?.batteryLevel {
                HStack {
                    ProgressView(value: Double(level))
                        .tint(color(for: level))
                        .progressViewStyle(.linear)
                        .frame(height: 8)
                    Text("\(Int(level * 100))%")
                        .font(.subheadline)
                        .monospacedDigit()
                }
                Text("State: \(batteryStateName(current?.batteryState ?? .unknown))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else { Text("--") }
        }
    }

    private func batteryStateName(_ s: UIDevice.BatteryState) -> String {
        switch s { case .charging: return "Charging"; case .full: return "Full"; case .unplugged: return "Unplugged"; default: return "Unknown" }
    }
}

struct DiskNetworkCard: View {
    let snapshots: [ResourceSnapshot]
    var current: ResourceSnapshot? { snapshots.last }

    var body: some View {
        Card {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("Disk")
                        .font(.headline)
                    if let a = current?.diskAvailable, let t = current?.diskTotal {
                        Text("Available: \(UInt64(a).bytesHumanReadable)")
                        Text("Total: \(UInt64(t).bytesHumanReadable)")
                    } else { Text("--") }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Network")
                        .font(.headline)
                    Text("Status: \(statusName(current?.networkStatus ?? .requiresConnection))")
                }
            }
        }
    }

    private func statusName(_ s: NWPath.Status) -> String {
        switch s { case .satisfied: return "Online"; case .requiresConnection: return "Requires Connection"; case .unsatisfied: return "Offline"; @unknown default: return "Unknown" }
    }
}

struct AppCard: View {
    let snapshots: [ResourceSnapshot]
    var current: ResourceSnapshot? { snapshots.last }

    var body: some View {
        Card {
            HStack(spacing: 16) {
                Image(systemName: "app.badge")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 28, weight: .semibold))
                VStack(alignment: .leading) {
                    Text("This App")
                        .font(.headline)
                    if let s = current {
                        Text("Memory Footprint: \(s.appMemoryFootprint.bytesHumanReadable)")
                        Text("Threads: \(s.appThreadCount)")
                    } else { Text("--") }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Reusable UI
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            content
                .frame(maxWidth: .infinity) // 讓內部內容撐滿
        }
        .padding(16)
        .frame(minHeight: 120) // 統一高度
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.separator.opacity(0.2))
        )
    }
}
