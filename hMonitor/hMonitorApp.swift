//
//  hMonitorApp.swift
//  hMonitor
//
//  Created by Riddle Ling on 2025/8/9.
//

import SwiftUI

@main
struct hMonitorApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
        }
    }
}
