# Flutter Benchmark App

A scientific performance benchmark application built with Flutter to compare cross-platform framework performance against Native iOS (SwiftUI). Part of the WISA (Wissenschaftliches Arbeiten) course research project.

## 🎯 Purpose

This application provides reproducible, measurable benchmarks to scientifically compare Flutter's rendering engine (Impeller/Skia) against Native iOS across five key performance metrics:

1. **CPU Efficiency** - Algorithm execution time
2. **Memory (RAM) Usage** - Runtime memory footprint
3. **FPS Stability** - Frame rate consistency under load
4. **Battery Impact** - Power consumption during stress tests
5. **App Startup Time** - Time to Interactive (TTI)

## ✨ Features

| Feature | Description |
|---------|-------------|
| **CPU Test** | Sieve of Eratosthenes calculating primes up to 1,000,000 on main UI thread |
| **GPU Test** | 1000 complex list items with images, shadows, gradients, and animations |
| **FPS Measurement** | `SchedulerBinding.scheduleFrameCallback` measuring frame intervals with jank detection (>25ms) |
| **Battery Monitoring** | Native `MethodChannel` for iOS `UIDevice.batteryLevel` |
| **Startup Time** | Native `MethodChannel` measuring elapsed time from `didFinishLaunchingWithOptions` to first frame |
| **Auto-Scroll** | 30-second linear scroll for reproducible GPU stress testing |

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Dart 3.0+
- Xcode 15.0+ (for iOS builds)
- Physical iOS device (recommended for battery metrics)

### Installation

```bash
# Clone or navigate to project
cd flutter_benchmark

# Get dependencies
flutter pub get

# Run in release mode for accurate benchmarks
flutter run --release

# Or profile mode for Flutter DevTools analysis
flutter run --profile
```

### Running Benchmarks

1. **Launch the app** on a physical device (simulators don't report battery)
2. **Startup Time** is measured automatically and displayed on the home screen
3. **CPU Test**: Tap to run the Sieve algorithm multiple times and view statistics
4. **GPU Test**: Start the 30-second auto-scroll and observe FPS/jank metrics

## 📊 Console Output

All metrics are printed to the debug console in a structured format for scientific logging:

```
═══════════════════════════════════════════════
FLUTTER BENCHMARK - CPU TEST RESULTS
═══════════════════════════════════════════════
Algorithm: Sieve of Eratosthenes
Limit: 1000000
Primes found: 78498
Execution time: 45230 μs
Execution time: 45.23 ms
═══════════════════════════════════════════════
```

## 📁 Project Structure

```
lib/
├── main.dart                           # Entry point
├── app.dart                            # MaterialApp configuration
├── core/
│   ├── constants/
│   │   └── benchmark_config.dart       # Test configuration constants
│   ├── theme/
│   │   └── app_theme.dart              # Dark theme configuration
│   └── utils/
│       └── statistics_utils.dart       # Statistical calculations
├── features/
│   ├── home/
│   │   ├── home_screen.dart            # Home screen with startup time
│   │   └── widgets/
│   │       └── benchmark_card.dart     # Navigation cards
│   ├── cpu_test/
│   │   ├── cpu_test_screen.dart        # CPU benchmark UI
│   │   ├── algorithms/
│   │   │   └── sieve_of_eratosthenes.dart
│   │   ├── models/
│   │   │   └── cpu_test_result.dart
│   │   └── widgets/
│   │       └── cpu_result_card.dart
│   └── gpu_test/
│       ├── gpu_test_screen.dart        # GPU/FPS/Battery benchmark UI
│       ├── models/
│       │   └── gpu_test_result.dart
│       └── widgets/
│           ├── complex_list_item.dart  # Stress test list item
│           └── results_panel.dart
├── services/
│   └── battery_service.dart            # Platform channel for battery
└── widgets/
    └── metric_card.dart                # Reusable metric display
```

## 🔧 Configuration

All benchmark parameters are centralized in `lib/core/constants/benchmark_config.dart`:

| Constant | Value | Description |
|----------|-------|-------------|
| `sievePrimeLimit` | 1,000,000 | Upper bound for prime calculation |
| `expectedPrimeCount` | 78,498 | Known correct result for validation |
| `gpuTestItemCount` | 1,000 | Number of complex list items |
| `scrollDurationSeconds` | 30 | Duration of auto-scroll test |
| `jankThresholdUs` | 16,667 | Frame time threshold (60 FPS target) |

## 📱 iOS Integration

The app uses a `MethodChannel` for battery level access:

```swift
// ios/Runner/AppDelegate.swift
let batteryChannel = FlutterMethodChannel(
    name: "flutter_benchmark/battery",
    binaryMessenger: controller.binaryMessenger
)
```

## 📈 Comparison with Native iOS

This app is designed to run alongside the companion **iOS Benchmark App** (SwiftUI) with identical:

- Algorithms (Sieve of Eratosthenes)
- Test conditions (1000 items, 30s scroll, same images)
- Metrics collection methodology

### Key Findings

| Metric | Flutter | iOS Native | Analysis |
|--------|---------|------------|----------|
| **Startup Time** | ~27 ms | ~67 ms | Flutter ~2.5x faster |
| **CPU (Sieve 1M)** | ~27-30 ms | ~9 ms | iOS ~3x faster |
| **GPU/FPS** | ~58-60 FPS | ~58-60 FPS | Equivalent |
| **Jank Rate** | <1% | <1% | Equivalent |
| **Frame Interval** | ~16-17 ms | ~16-17 ms | Equivalent |

**Conclusion**: Flutter has faster startup time (~2.5x) due to optimized AOT compilation and engine initialization. It matches native iOS for UI rendering but has ~3x overhead for CPU-intensive computation.

See [TECHNICAL_DOCUMENTATION.md](../TECHNICAL_DOCUMENTATION.md) for detailed methodology.

## ⚠️ Important: Build Mode

**Always run in release mode for accurate benchmarks:**

```bash
flutter run --release
```

Debug mode includes debugging overhead that significantly impacts performance measurements.

## 📄 License

This project is part of academic research for the WISA course.

## 👥 Authors

WISA Course - Scientific Framework Comparison Research Team
