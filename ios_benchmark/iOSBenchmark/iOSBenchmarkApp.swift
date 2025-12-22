//
//  iOSBenchmarkApp.swift
//  iOSBenchmark
//
//  WISA Course - Scientific Framework Comparison
//  Native iOS (SwiftUI) Performance Benchmark
//
//  This app mirrors the Flutter benchmark for apples-to-apples comparison.
//

import SwiftUI

// MARK: - Global Startup Time Measurement

/// Shared startup metrics accessible across the app
class StartupMetrics: ObservableObject {
    static let shared = StartupMetrics()

    /// Captured when StartupMetrics is first accessed (in App init)
    /// This is comparable to Flutter's didFinishLaunchingWithOptions timing
    @Published var appInitTime: CFAbsoluteTime
    @Published var firstFrameTime: CFAbsoluteTime = 0
    @Published var timeToInteractive: Double = 0
    @Published var isFirstFrameRendered = false

    private init() {
        appInitTime = CFAbsoluteTimeGetCurrent()
    }

    func recordFirstFrame() {
        guard !isFirstFrameRendered else { return }

        firstFrameTime = CFAbsoluteTimeGetCurrent()
        timeToInteractive = (firstFrameTime - appInitTime) * 1_000_000  // Convert to microseconds
        isFirstFrameRendered = true

        // Log to console for scientific measurement
        print("═══════════════════════════════════════════════")
        print("iOS BENCHMARK - STARTUP TIME MEASUREMENT")
        print("═══════════════════════════════════════════════")
        print("App init at: \(appInitTime)")
        print("First frame rendered at: \(firstFrameTime)")
        print("Time to Interactive (TTI): \(Int(timeToInteractive)) μs")
        print("Time to Interactive (TTI): \(String(format: "%.2f", timeToInteractive / 1000)) ms")
        print("═══════════════════════════════════════════════")
    }
}

// MARK: - App Entry Point

@main
struct iOSBenchmarkApp: App {
    @StateObject private var startupMetrics = StartupMetrics.shared

    init() {
        // Additional initialization if needed
        print("iOSBenchmarkApp initialized")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(startupMetrics)
        }
    }
}
