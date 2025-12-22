# iOS Benchmark App

A scientific performance benchmark application built with Native iOS (SwiftUI) to compare native framework performance against Flutter. Part of the WISA (Wissenschaftliches Arbeiten) course research project.

## 🎯 Purpose

This application provides reproducible, measurable benchmarks to scientifically compare Native iOS (SwiftUI) rendering and performance against Flutter across five key performance metrics:

1. **CPU Efficiency** - Algorithm execution time
2. **Memory (RAM) Usage** - Runtime memory footprint
3. **FPS Stability** - Frame rate consistency under load
4. **Battery Impact** - Power consumption during stress tests
5. **App Startup Time** - Time to Interactive (TTI)

## ✨ Features

| Feature | Description |
|---------|-------------|
| **CPU Test** | Sieve of Eratosthenes calculating primes up to 1,000,000 on main thread |
| **GPU Test** | 1000 complex list items with images, shadows, gradients, and animations |
| **FPS Measurement** | `CADisplayLink`-based frame timing with jank detection (>25ms for dropped frames) |
| **Battery Monitoring** | `UIDevice.current.batteryLevel` monitoring |
| **Startup Time** | `CFAbsoluteTimeGetCurrent()` measuring time from `StartupMetrics.init()` to first frame render |
| **Auto-Scroll** | 30-second linear scroll using `ScrollViewReader` for reproducible testing |

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
- Physical iOS device (recommended for battery metrics)

### Installation

1. Open `iOSBenchmark.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Select target device (physical device recommended)
4. Build and Run (⌘R)

### Running Benchmarks

1. **Launch the app** on a physical device (simulators don't report accurate battery)
2. **Startup Time** is measured automatically and displayed on the home screen
3. **CPU Test**: Tap to run the Sieve algorithm multiple times and view statistics
4. **GPU Test**: Start the 30-second auto-scroll and observe FPS/jank metrics

## 📊 Console Output

All metrics are printed to the Xcode console in a structured format for scientific logging:

```
═══════════════════════════════════════════════
iOS BENCHMARK - CPU TEST RESULTS
═══════════════════════════════════════════════
Algorithm: Sieve of Eratosthenes
Limit: 1000000
Primes found: 78498
Execution time: 42150 μs
Execution time: 42.15 ms
═══════════════════════════════════════════════
```

## 📁 Project Structure

```
iOSBenchmark/
├── iOSBenchmarkApp.swift           # App entry point with startup measurement
├── ContentView.swift               # Main navigation view
├── CPUTestView.swift               # CPU benchmark (Sieve of Eratosthenes)
├── GPUTestView.swift               # GPU/FPS/Battery stress test
└── Assets.xcassets/                # Image assets for GPU test
    ├── img_0.imageset/
    ├── img_1.imageset/
    ├── ...
    └── img_9.imageset/
```

## 🔧 Configuration

Key benchmark parameters in the code:

| Constant | Value | Description |
|----------|-------|-------------|
| Prime Limit | 1,000,000 | Upper bound for Sieve algorithm |
| Expected Primes | 78,498 | Known correct result for validation |
| List Item Count | 1,000 | Number of complex list items |
| Scroll Duration | 30 seconds | Duration of auto-scroll test |
| FPS Target | 60 FPS | 16.67ms frame time threshold |

## 📱 SwiftUI Implementation Details

### Startup Time Measurement

```swift
@main
struct iOSBenchmarkApp: App {
    let launchTime = CFAbsoluteTimeGetCurrent()
    
    var body: some Scene {
        WindowGroup {
            ContentView(launchTime: launchTime)
        }
    }
}
```

### FPS Measurement with CADisplayLink

```swift
displayLink = CADisplayLink(target: self, selector: #selector(onFrame))
displayLink?.add(to: .main, forMode: .common)

@objc func onFrame(_ link: CADisplayLink) {
    let frameDuration = link.targetTimestamp - link.timestamp
    // Jank if > 16.67ms
}
```

### Battery Monitoring

```swift
UIDevice.current.isBatteryMonitoringEnabled = true
let batteryLevel = UIDevice.current.batteryLevel
```

## 📈 Comparison with Flutter

This app is designed to run alongside the companion **Flutter Benchmark App** with identical:

- Algorithms (Sieve of Eratosthenes with same implementation)
- Test conditions (1000 items, 30s scroll, same images)
- Metrics collection methodology

### Key Findings

| Metric | iOS Native | Flutter | Analysis |
|--------|------------|---------|----------|
| **Startup Time** | ~67 ms | ~27 ms | Flutter ~2.5x faster |
| **CPU (Sieve 1M)** | ~9 ms | ~27-30 ms | iOS ~3x faster |
| **GPU/FPS** | ~58-60 FPS | ~58-60 FPS | Equivalent |
| **Jank Rate** | <1% | <1% | Equivalent |
| **Frame Interval** | ~16-17 ms | ~16-17 ms | Equivalent |

**Conclusion**: Native iOS significantly outperforms Flutter for CPU-intensive tasks (~3x faster) due to LLVM's aggressive optimizations. However, Flutter has faster startup time (~2.5x faster) and both achieve equivalent UI rendering performance since both ultimately use Metal for GPU operations.

See [TECHNICAL_DOCUMENTATION.md](../TECHNICAL_DOCUMENTATION.md) for detailed methodology.

## ⚠️ Important: Build Mode

**Always run in Release mode for accurate benchmarks!**

1. In Xcode: **Product → Scheme → Edit Scheme** (⌘<)
2. Select **Run** → Change **Build Configuration** to `Release`
3. Clean build: **⌘ Shift K**
4. Run: **⌘ R**

| Mode | Swift Optimization | Performance |
|------|-------------------|-------------|
| Debug | `-Onone` | ~10x slower |
| Release | `-O` | Full speed |

## 📄 License

This project is part of academic research for the WISA course.

## 👥 Authors

WISA Course - Scientific Framework Comparison Research Team
