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

/// Records the exact timestamp when the app process starts
/// This is captured as early as possible in the app lifecycle
let appProcessStartTime = CFAbsoluteTimeGetCurrent()

/// Shared startup metrics accessible across the app
class StartupMetrics: ObservableObject {
    static let shared = StartupMetrics()
    
    @Published var mainStartTime: CFAbsoluteTime = 0
    @Published var firstFrameTime: CFAbsoluteTime = 0
    @Published var timeToInteractive: Double = 0
    @Published var isFirstFrameRendered = false
    
    private init() {
        mainStartTime = appProcessStartTime
    }
    
    func recordFirstFrame() {
        guard !isFirstFrameRendered else { return }
        
        firstFrameTime = CFAbsoluteTimeGetCurrent()
        timeToInteractive = (firstFrameTime - mainStartTime) * 1_000_000 // Convert to microseconds
        isFirstFrameRendered = true
        
        // Log to console for scientific measurement
        print("═══════════════════════════════════════════════")
        print("iOS BENCHMARK - STARTUP TIME MEASUREMENT")
        print("═══════════════════════════════════════════════")
        print("App process started at: \(mainStartTime)")
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
