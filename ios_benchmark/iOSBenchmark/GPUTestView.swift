//
//  GPUTestView.swift
//  iOSBenchmark
//
//  GPU/Memory/FPS Stress Test
//  - 1000 complex list items
//  - 30-second auto-scroll with ScrollViewReader
//  - CADisplayLink for FPS measurement
//  - Battery level monitoring
//

import SwiftUI

// MARK: - Display Link Wrapper for FPS Measurement

class DisplayLinkManager: ObservableObject {
    private var displayLink: CADisplayLink?

    @Published var totalFrameCount = 0
    @Published var droppedFrameCount = 0
    @Published var frameDurations: [CFTimeInterval] = []
    @Published var maxFrameTime: CFTimeInterval = 0

    private var lastTimestamp: CFTimeInterval = 0
    private var isActive = false

    // Target frame time for 60 FPS = 16.67ms
    private let targetFrameTime: CFTimeInterval = 1.0 / 60.0

    func start() {
        guard !isActive else { return }

        reset()
        isActive = true

        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        isActive = false
        displayLink?.invalidate()
        displayLink = nil
    }

    func reset() {
        totalFrameCount = 0
        droppedFrameCount = 0
        frameDurations.removeAll()
        maxFrameTime = 0
        lastTimestamp = 0
    }

    @objc private func handleDisplayLink(_ link: CADisplayLink) {
        guard isActive else { return }

        let currentTime = link.timestamp

        if lastTimestamp > 0 {
            let frameDuration = currentTime - lastTimestamp
            frameDurations.append(frameDuration)
            totalFrameCount += 1

            // Jank detection: frame time > 16.67ms (missing 60 FPS target)
            if frameDuration > targetFrameTime * 1.5 {  // Allow 50% buffer
                droppedFrameCount += 1
                print(
                    "Jank detected: Frame took \(String(format: "%.2f", frameDuration * 1000)) ms")
            }

            if frameDuration > maxFrameTime {
                maxFrameTime = frameDuration
            }
        }

        lastTimestamp = currentTime
    }

    var averageFrameTime: CFTimeInterval {
        guard !frameDurations.isEmpty else { return 0 }
        return frameDurations.reduce(0, +) / Double(frameDurations.count)
    }

    var estimatedFPS: Double {
        guard averageFrameTime > 0 else { return 0 }
        return 1.0 / averageFrameTime
    }
}

// MARK: - Battery Monitor

class BatteryMonitor {
    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    var batteryLevel: Int {
        let level = UIDevice.current.batteryLevel
        if level < 0 {
            return -1  // Battery level unknown (simulator)
        }
        return Int(level * 100)
    }

    var batteryState: String {
        switch UIDevice.current.batteryState {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "Unplugged"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - GPU Test View

struct GPUTestView: View {
    @StateObject private var displayLinkManager = DisplayLinkManager()

    @State private var isScrolling = false
    @State private var testCompleted = false
    @State private var elapsedSeconds = 0
    @State private var scrollProgress: CGFloat = 0

    // Battery
    @State private var batteryLevelStart: Int?
    @State private var batteryLevelEnd: Int?
    @State private var batteryDelta: String?

    // Timer
    @State private var progressTimer: Timer?

    private let itemCount = 1000
    private let scrollDurationSeconds = 30
    private let batteryMonitor = BatteryMonitor()

    var body: some View {
        VStack(spacing: 0) {
            // Control Panel
            controlPanel

            // Results Panel (shown after test)
            if testCompleted {
                resultsPanel
            }

            // Scrollable List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<itemCount, id: \.self) { index in
                            ComplexListItem(index: index, imageIndex: index % 10)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .onChange(of: isScrolling) { _, newValue in
                    if newValue {
                        startAutoScroll(proxy: proxy)
                    }
                }
            }
        }
        .navigationTitle("GPU/Memory/FPS Test")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            stopTest()
        }
    }

    // MARK: - Control Panel

    private var controlPanel: some View {
        VStack(spacing: 12) {
            // Progress indicator during test
            if isScrolling {
                HStack {
                    ProgressView(
                        value: Double(elapsedSeconds), total: Double(scrollDurationSeconds)
                    )
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))

                    Text("\(elapsedSeconds) / \(scrollDurationSeconds) s")
                        .fontWeight(.bold)
                        .frame(width: 80)
                }
            }

            // Test Button
            Button(action: {
                if isScrolling {
                    stopTest()
                } else {
                    isScrolling = true
                }
            }) {
                HStack {
                    Image(systemName: isScrolling ? "stop.fill" : "play.fill")
                    Text(isScrolling ? "Stop Test" : "Start 30s Auto-Scroll")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isScrolling ? Color.red : Color.purple)
                .cornerRadius(8)
            }

            // Live metrics during test
            if isScrolling {
                HStack(spacing: 20) {
                    LiveMetric(label: "Frames", value: "\(displayLinkManager.totalFrameCount)")
                    LiveMetric(label: "Jank", value: "\(displayLinkManager.droppedFrameCount)")
                    LiveMetric(
                        label: "Avg",
                        value: displayLinkManager.averageFrameTime > 0
                            ? String(format: "%.1fms", displayLinkManager.averageFrameTime * 1000)
                            : "..."
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Results Panel

    private var resultsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Test Completed")
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            Divider()

            // Metrics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ResultCard(
                    label: "Total Frames",
                    value: "\(displayLinkManager.totalFrameCount)",
                    icon: "square.grid.2x2",
                    color: .blue
                )
                ResultCard(
                    label: "Dropped Frames",
                    value: "\(displayLinkManager.droppedFrameCount)",
                    icon: "exclamationmark.triangle",
                    color: displayLinkManager.droppedFrameCount > 0 ? .orange : .green
                )
                ResultCard(
                    label: "Jank Rate",
                    value: String(format: "%.1f%%", jankPercentage),
                    icon: "speedometer",
                    color: jankPercentage > 5 ? .red : .green
                )
                ResultCard(
                    label: "Est. FPS",
                    value: String(format: "%.1f", displayLinkManager.estimatedFPS),
                    icon: "timer",
                    color: displayLinkManager.estimatedFPS >= 55 ? .green : .orange
                )
                ResultCard(
                    label: "Avg Frame",
                    value: String(format: "%.2f ms", displayLinkManager.averageFrameTime * 1000),
                    icon: "chart.bar",
                    color: .purple
                )
                ResultCard(
                    label: "Max Frame",
                    value: String(format: "%.2f ms", displayLinkManager.maxFrameTime * 1000),
                    icon: "arrow.up.right",
                    color: displayLinkManager.maxFrameTime > 0.033 ? .red : .blue
                )
            }

            ResultCard(
                label: "Battery Drain",
                value: batteryDelta ?? "N/A",
                icon: "battery.25",
                color: .yellow
            )
        }
        .padding()
        .background(Color.green.opacity(0.1))
    }

    private var jankPercentage: Double {
        guard displayLinkManager.totalFrameCount > 0 else { return 0 }
        return
            (Double(displayLinkManager.droppedFrameCount)
            / Double(displayLinkManager.totalFrameCount)) * 100
    }

    // MARK: - Auto-Scroll Logic

    private func startAutoScroll(proxy: ScrollViewProxy) {
        // Reset metrics
        displayLinkManager.reset()
        testCompleted = false
        elapsedSeconds = 0
        batteryDelta = nil

        // Get battery level before test
        batteryLevelStart = batteryMonitor.batteryLevel

        // Log start
        print("═══════════════════════════════════════════════")
        print("iOS BENCHMARK - GPU TEST STARTED")
        print("═══════════════════════════════════════════════")
        print("Items: \(itemCount)")
        print("Duration: \(scrollDurationSeconds) seconds")
        print("Battery at start: \(batteryLevelStart ?? -1)%")
        print("═══════════════════════════════════════════════")

        // Start FPS measurement
        displayLinkManager.start()

        // Start progress timer
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1

            if elapsedSeconds >= scrollDurationSeconds {
                completeTest()
            }
        }

        // Scroll to top first
        proxy.scrollTo(0, anchor: .top)

        // Perform auto-scroll over exactly 30 seconds
        // We'll use a stepped approach for more control
        performSmoothScroll(proxy: proxy)
    }

    private func performSmoothScroll(proxy: ScrollViewProxy) {
        let totalSteps = scrollDurationSeconds * 10  // 10 steps per second
        let itemsPerStep = Double(itemCount) / Double(totalSteps)
        var currentStep = 0

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard isScrolling, currentStep < totalSteps else {
                timer.invalidate()
                return
            }

            let targetItem = min(Int(Double(currentStep) * itemsPerStep), itemCount - 1)

            withAnimation(.linear(duration: 0.1)) {
                proxy.scrollTo(targetItem, anchor: .top)
            }

            currentStep += 1
        }
    }

    private func completeTest() {
        displayLinkManager.stop()
        progressTimer?.invalidate()
        progressTimer = nil

        batteryLevelEnd = batteryMonitor.batteryLevel

        // Calculate battery delta
        if let start = batteryLevelStart, let end = batteryLevelEnd, start >= 0, end >= 0 {
            let delta = start - end
            batteryDelta = "\(delta)%"
        } else {
            batteryDelta = "N/A"
        }

        isScrolling = false
        testCompleted = true

        // Log results
        print("═══════════════════════════════════════════════")
        print("iOS BENCHMARK - GPU TEST RESULTS")
        print("═══════════════════════════════════════════════")
        print("Total frames: \(displayLinkManager.totalFrameCount)")
        print("Dropped frames (>16.67ms): \(displayLinkManager.droppedFrameCount)")
        print(
            "Average frame time: \(String(format: "%.2f", displayLinkManager.averageFrameTime * 1000)) ms"
        )
        print(
            "Max frame time: \(String(format: "%.2f", displayLinkManager.maxFrameTime * 1000)) ms")
        print("Estimated FPS: \(String(format: "%.1f", displayLinkManager.estimatedFPS))")
        print("Battery at end: \(batteryLevelEnd ?? -1)%")
        print("Battery drain: \(batteryDelta ?? "N/A")")
        print("═══════════════════════════════════════════════")
    }

    private func stopTest() {
        displayLinkManager.stop()
        progressTimer?.invalidate()
        progressTimer = nil
        isScrolling = false
    }
}

// MARK: - Live Metric View

struct LiveMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Result Card View

struct ResultCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Complex List Item

struct ComplexListItem: View {
    let index: Int
    let imageIndex: Int

    private let colors: [Color] = [
        .blue, .red, .green, .orange, .purple,
        .teal, .pink, .indigo, .yellow, .cyan,
    ]

    private let icons: [String] = [
        "photo", "camera", "mountain.2", "sun.max", "leaf",
        "pawprint", "car", "airplane", "fork.knife", "soccerball",
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Actual image from assets
            ZStack {
                Image("img_\(imageIndex)")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipped()

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Item number badge
                VStack {
                    HStack {
                        Spacer()
                        Text("#\(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(20)
                    }
                    Spacer()
                }
                .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Content section
            VStack(alignment: .leading, spacing: 12) {
                Text("Complex Item \(index + 1)")
                    .font(.headline)

                Text(
                    "This is a complex list item designed to stress test the GPU rasterizer with shadows, gradients, and multiple layers."
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)

                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { i in
                            Text("Tag \(i + 1)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(colors[(imageIndex + i) % 10])
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(colors[(imageIndex + i) % 10].opacity(0.1))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            colors[(imageIndex + i) % 10].opacity(0.3), lineWidth: 1
                                        )
                                )
                        }
                    }
                }

                // Progress bar
                ProgressView(value: Double(index % 100), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: colors[imageIndex]))

                // Action buttons
                HStack(spacing: 8) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "heart")
                            Text("Like")
                        }
                        .font(.subheadline)
                        .foregroundColor(.pink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.pink.opacity(0.5), lineWidth: 1)
                        )
                    }

                    Button(action: {}) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        GPUTestView()
    }
}
