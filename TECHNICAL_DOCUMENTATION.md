# Technical Documentation: Flutter vs Native iOS Benchmark

## Scientific Framework Comparison - WISA Course

This document provides comprehensive technical details about the benchmark methodology, implementation specifics, and measurement approaches used in comparing Flutter (cross-platform) against Native iOS (SwiftUI).

---

## Table of Contents

1. [Research Objective](#1-research-objective)
2. [Benchmark Metrics](#2-benchmark-metrics)
3. [Test Environment](#3-test-environment)
4. [CPU Benchmark Implementation](#4-cpu-benchmark-implementation)
5. [GPU/Rendering Benchmark Implementation](#5-gpurendering-benchmark-implementation)
6. [FPS Measurement Methodology](#6-fps-measurement-methodology)
7. [Battery Consumption Measurement](#7-battery-consumption-measurement)
8. [Startup Time Measurement](#8-startup-time-measurement)
9. [Memory Profiling](#9-memory-profiling)
10. [Data Collection & Analysis](#10-data-collection--analysis)
11. [Controlling Variables](#11-controlling-variables)
12. [Known Limitations](#12-known-limitations)
13. [Reproducing Results](#13-reproducing-results)

---

## 1. Research Objective

### Primary Question
>
> How does Flutter's performance compare to Native iOS (SwiftUI) across CPU efficiency, GPU rendering, memory usage, battery consumption, and startup time?

### Hypothesis

Native iOS should theoretically outperform Flutter due to:

- Direct access to Metal/Core Animation without abstraction layers
- No Dart VM overhead
- Tighter integration with iOS runtime

However, Flutter's Impeller rendering engine (introduced in Flutter 3.10+) claims to match or exceed native performance in certain scenarios.

### Scientific Approach

- **Controlled Variables**: Identical algorithms, UI complexity, test duration, device, and conditions
- **Reproducibility**: Fixed random seeds, deterministic scroll behavior, multiple iterations
- **Statistical Significance**: Multiple runs with mean, standard deviation, min/max reporting

---

## 2. Benchmark Metrics

### 2.1 CPU Efficiency

| Metric | Unit | Description |
|--------|------|-------------|
| Execution Time | Microseconds (μs) | Wall-clock time for algorithm completion |
| Validation | Boolean | Correctness check (78,498 primes expected) |

### 2.2 GPU/Rendering Performance

| Metric | Unit | Description |
|--------|------|-------------|
| Total Frames | Count | Frames rendered during 30s test |
| Dropped Frames | Count | Frames exceeding 16.67ms threshold |
| Jank Rate | Percentage | (Dropped / Total) × 100 |
| Average Frame Time | Milliseconds | Mean frame duration |
| Max Frame Time | Milliseconds | Worst-case frame duration |
| Estimated FPS | Frames/second | 1,000,000 / Avg Frame Time (μs) |

### 2.3 Battery Consumption

| Metric | Unit | Description |
|--------|------|-------------|
| Start Level | Percentage | Battery level before test |
| End Level | Percentage | Battery level after test |
| Delta | Percentage points | Drain during 30s stress test |

### 2.4 Startup Time

| Metric | Unit | Description |
|--------|------|-------------|
| Time to Interactive (TTI) | Milliseconds | Time from process start to first frame render |

### 2.5 Memory Usage

| Metric | Unit | Description |
|--------|------|-------------|
| Peak Memory | Megabytes | Maximum RAM usage during test |
| Baseline Memory | Megabytes | Idle app memory footprint |

---

## 3. Test Environment

### 3.1 Hardware Requirements

- **Device**: Physical iOS device (iPhone recommended)
- **Rationale**: Simulators don't report accurate battery levels and have different performance characteristics

### 3.2 Software Versions

| Component | Flutter App | iOS App |
|-----------|-------------|---------|
| Framework | Flutter 3.10+ | SwiftUI (iOS 17+) |
| Language | Dart 3.0+ | Swift 5.9+ |
| Rendering | Impeller (Metal) | Core Animation / Metal |
| IDE | VS Code / Android Studio | Xcode 15.0+ |

### 3.3 Test Conditions

- **Build Mode**: Release (Flutter: `--release`, iOS: Release scheme)
- **Device State**: Airplane mode enabled, background apps closed
- **Battery**: Device charged between 20-80% (avoids throttling)
- **Temperature**: Device at room temperature, not hot from recent use

---

## 4. CPU Benchmark Implementation

### 4.1 Algorithm: Sieve of Eratosthenes

The Sieve of Eratosthenes is chosen because:

1. **CPU-bound**: No I/O or network dependencies
2. **Deterministic**: Always produces the same result
3. **Verifiable**: Known output (78,498 primes ≤ 1,000,000)
4. **Memory-intensive**: Tests memory allocation performance

### 4.2 Flutter Implementation

```dart
// lib/features/cpu_test/algorithms/sieve_of_eratosthenes.dart

class SieveOfEratosthenes {
  static int countPrimes(int limit) {
    final isPrime = List<bool>.filled(limit + 1, true);
    isPrime[0] = false;
    isPrime[1] = false;

    for (int p = 2; p * p <= limit; p++) {
      if (isPrime[p]) {
        for (int i = p * p; i <= limit; i += p) {
          isPrime[i] = false;
        }
      }
    }

    int count = 0;
    for (int i = 2; i <= limit; i++) {
      if (isPrime[i]) count++;
    }
    return count;
  }
}
```

**Timing Method:**

```dart
final Stopwatch stopwatch = Stopwatch()..start();
final int primeCount = SieveOfEratosthenes.countPrimes(1000000);
stopwatch.stop();
final int executionTimeUs = stopwatch.elapsedMicroseconds;
```

### 4.3 iOS (Swift) Implementation

```swift
// CPUTestView.swift

func sieveOfEratosthenes(limit: Int) -> Int {
    var isPrime = [Bool](repeating: true, count: limit + 1)
    isPrime[0] = false
    isPrime[1] = false
    
    var p = 2
    while p * p <= limit {
        if isPrime[p] {
            var i = p * p
            while i <= limit {
                isPrime[i] = false
                i += p
            }
        }
        p += 1
    }
    
    var count = 0
    for i in 2...limit {
        if isPrime[i] { count += 1 }
    }
    return count
}
```

**Timing Method:**

```swift
let startTime = CFAbsoluteTimeGetCurrent()
let primeCount = sieveOfEratosthenes(limit: 1_000_000)
let executionTime = CFAbsoluteTimeGetCurrent() - startTime
let executionTimeUs = Int(executionTime * 1_000_000)
```

### 4.4 Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Run on Main Thread | Measures UI thread blocking behavior |
| No Isolate/GCD | Tests single-threaded performance |
| Boolean Array | Identical memory pattern in both languages |
| Post-delay Start | Allows UI to settle before blocking |

---

## 5. GPU/Rendering Benchmark Implementation

### 5.1 Complex List Item Design

Each of the 1,000 list items contains:

| Component | Complexity Factor |
|-----------|-------------------|
| Image (180px height) | Texture memory, decoding |
| Gradient Overlay | Alpha compositing |
| Box Shadow | Blur computation |
| Rounded Corners | Clipping/masking |
| 4 Tag Chips | Border rendering |
| Progress Bar | Animation state |
| 2 Outlined Buttons | Touch target rendering |

### 5.2 Flutter Implementation

```dart
// lib/features/gpu_test/widgets/complex_list_item.dart

Widget build(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        // Image with gradient overlay
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          child: Stack(
            children: [
              Image.asset('assets/images/img_$imageIndex.jpg'),
              // Gradient overlay
              Container(decoration: BoxDecoration(gradient: ...)),
              // Badge
              Positioned(child: Container(...)),
            ],
          ),
        ),
        // Content section with tags, progress, buttons
        Padding(child: Column(...)),
      ],
    ),
  );
}
```

### 5.3 iOS (SwiftUI) Implementation

```swift
// GPUTestView.swift

var body: some View {
    VStack(spacing: 0) {
        // Image section
        ZStack(alignment: .topTrailing) {
            Image("img_\(imageIndex)")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 180)
            
            // Gradient overlay
            LinearGradient(...)
            
            // Badge
            Text("#\(index + 1)")
                .padding()
                .background(.black.opacity(0.5))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        
        // Content section
        VStack { ... }
    }
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(radius: 10, y: 4)
}
```

### 5.4 Auto-Scroll Implementation

**Flutter:**

```dart
await _scrollController.animateTo(
  maxScroll,
  duration: Duration(seconds: 30),
  curve: Curves.linear, // Constant velocity
);
```

**iOS:**

```swift
withAnimation(.linear(duration: 30)) {
    scrollProxy.scrollTo(999, anchor: .bottom)
}
```

---

## 6. FPS Measurement Methodology

### 6.1 Flutter: SchedulerBinding

```dart
void _startFrameCallback() {
  SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
}

void _onFrame(Duration timestamp) {
  final int currentTime = timestamp.inMicroseconds;
  
  if (_lastFrameTime > 0) {
    final int frameDuration = currentTime - _lastFrameTime;
    _frameDurations.add(frameDuration);
    
    // Jank detection: > 16.67ms (60 FPS target)
    if (frameDuration > 16667) {
      _droppedFrameCount++;
    }
  }
  
  _lastFrameTime = currentTime;
  
  // Schedule next frame
  SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
}
```

### 6.2 iOS: CADisplayLink

```swift
var displayLink: CADisplayLink?
var lastTimestamp: CFTimeInterval = 0

func startFrameCallback() {
    displayLink = CADisplayLink(target: self, selector: #selector(onFrame))
    displayLink?.add(to: .main, forMode: .common)
}

@objc func onFrame(_ link: CADisplayLink) {
    if lastTimestamp > 0 {
        let frameDuration = (link.timestamp - lastTimestamp) * 1_000_000 // to μs
        frameDurations.append(Int(frameDuration))
        
        if frameDuration > 16667 {
            droppedFrameCount += 1
        }
    }
    lastTimestamp = link.timestamp
}
```

### 6.3 Jank Detection Threshold

| FPS Target | Frame Budget | Threshold |
|------------|--------------|-----------|
| 60 FPS | 16.67 ms | 16,667 μs |
| 120 FPS (ProMotion) | 8.33 ms | 8,333 μs |

Both apps use **16,667 μs** as the jank threshold for consistency.

---

## 7. Battery Consumption Measurement

### 7.1 Flutter: Platform Channel

**Dart Side:**

```dart
// lib/services/battery_service.dart
class BatteryService {
  static const MethodChannel _channel = MethodChannel('flutter_benchmark/battery');
  
  static Future<int?> getBatteryLevel() async {
    try {
      return await _channel.invokeMethod('getBatteryLevel');
    } catch (e) {
      return null;
    }
  }
}
```

**iOS Side (AppDelegate.swift):**

```swift
let batteryChannel = FlutterMethodChannel(
    name: "flutter_benchmark/battery",
    binaryMessenger: controller.binaryMessenger
)

batteryChannel.setMethodCallHandler { call, result in
    if call.method == "getBatteryLevel" {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = Int(UIDevice.current.batteryLevel * 100)
        result(level)
    }
}
```

### 7.2 iOS: Direct UIDevice Access

```swift
UIDevice.current.isBatteryMonitoringEnabled = true
let batteryStart = Int(UIDevice.current.batteryLevel * 100)

// ... run test ...

let batteryEnd = Int(UIDevice.current.batteryLevel * 100)
let drain = batteryStart - batteryEnd
```

### 7.3 Measurement Considerations

- Battery level granularity is typically 1%
- Short tests (30s) may show 0% drain
- Multiple consecutive tests recommended for observable drain
- Device should not be charging during test

---

## 8. Startup Time Measurement

### 8.1 Definition: Time to Interactive (TTI)

TTI measures the time from when the app process starts until the first frame is rendered and the UI is interactive.

### 8.2 Flutter Implementation

```dart
// main.dart
void main() {
  final int mainStartTime = DateTime.now().microsecondsSinceEpoch;
  WidgetsFlutterBinding.ensureInitialized();
  runApp(BenchmarkApp(mainStartTime: mainStartTime));
}

// home_screen.dart
void _measureStartupTime() {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    final int firstFrameTime = DateTime.now().microsecondsSinceEpoch;
    final int startupTime = firstFrameTime - widget.mainStartTime;
    // startupTime is TTI in microseconds
  });
}
```

### 8.3 iOS Implementation

```swift
// iOSBenchmarkApp.swift
@main
struct iOSBenchmarkApp: App {
    let launchTime = CFAbsoluteTimeGetCurrent()
    
    var body: some Scene {
        WindowGroup {
            ContentView(launchTime: launchTime)
        }
    }
}

// ContentView.swift
struct ContentView: View {
    let launchTime: CFAbsoluteTime
    @State private var startupTime: Double?
    
    var body: some View {
        // ...
        .onAppear {
            let now = CFAbsoluteTimeGetCurrent()
            startupTime = (now - launchTime) * 1000 // to ms
        }
    }
}
```

### 8.4 What TTI Includes

| Flutter | iOS |
|---------|-----|
| Dart VM initialization | App process creation |
| Widget tree construction | View hierarchy creation |
| Layout pass | Layout pass |
| First frame rasterization | First frame render |
| `addPostFrameCallback` trigger | `onAppear` trigger |

---

## 9. Memory Profiling

### 9.1 Tools

| Platform | Tool | Metrics |
|----------|------|---------|
| Flutter | Flutter DevTools | Dart heap, widget rebuilds |
| Flutter | Xcode Instruments | Native memory (iOS) |
| iOS | Xcode Memory Debugger | Heap allocations, leaks |
| iOS | Instruments (Allocations) | Detailed memory timeline |

### 9.2 Measurement Procedure

1. Launch app in **profile mode** (Flutter) or **Release** with debugging (iOS)
2. Record baseline memory after app settles (~5 seconds)
3. Start GPU test
4. Record peak memory during 30s scroll
5. Record memory after test completes (check for leaks)

### 9.3 Expected Memory Components

| Component | Flutter | iOS |
|-----------|---------|-----|
| Framework Overhead | ~40-60 MB | ~15-25 MB |
| Image Cache | Variable | Variable |
| Widget/View Tree | ~10-20 MB | ~5-10 MB |

---

## 10. Data Collection & Analysis

### 10.1 Recommended Test Protocol

1. **Warm-up**: Run each test once (discard results)
2. **Iterations**: Run each test 10 times
3. **Cool-down**: Wait 30 seconds between tests
4. **Order**: Alternate between Flutter and iOS to avoid thermal bias

### 10.2 Statistical Measures

| Measure | Purpose |
|---------|---------|
| Mean | Central tendency |
| Standard Deviation | Variance/consistency |
| Min/Max | Range of results |
| Median | Robust central tendency (outlier-resistant) |

### 10.3 Data Export

Both apps print results to console in a parseable format:

```
═══════════════════════════════════════════════
FLUTTER BENCHMARK - CPU TEST RESULTS
═══════════════════════════════════════════════
Algorithm: Sieve of Eratosthenes
Limit: 1000000
Primes found: 78498
Execution time: 45230 μs
═══════════════════════════════════════════════
```

**Recommended**: Copy console output to CSV for analysis.

---

## 11. Controlling Variables

### 11.1 Identical Conditions

| Variable | Flutter | iOS |
|----------|---------|-----|
| Algorithm | Sieve of Eratosthenes | Sieve of Eratosthenes |
| Prime Limit | 1,000,000 | 1,000,000 |
| List Items | 1,000 | 1,000 |
| Scroll Duration | 30 seconds | 30 seconds |
| Scroll Curve | Linear | Linear |
| Images | 10 cycling JPGs | Same 10 JPGs |
| Image Size | ~180px height | ~180px height |
| UI Complexity | Shadows, gradients, chips | Shadows, gradients, chips |
| Build Mode | Release | Release |

### 11.2 Uncontrollable Variables

| Variable | Mitigation |
|----------|------------|
| Background Processes | Close all apps, airplane mode |
| Thermal Throttling | Wait between tests, start from cool state |
| Battery State | Test between 20-80% charge |
| iOS Version Differences | Document exact iOS version |

---

## 12. Known Limitations

### 12.1 Measurement Limitations

1. **Battery Granularity**: 1% resolution may miss small differences
2. **Startup Time**: Includes varying amounts of initialization work
3. **FPS Jitter**: Frame scheduling varies based on system load
4. **Memory**: Managed runtimes (Dart) have GC pauses

### 12.2 Comparison Limitations

1. **Different Rendering Engines**: Impeller vs Core Animation/Metal
2. **Language Overhead**: Dart VM vs Swift native compilation
3. **Widget vs View**: Different abstraction models
4. **Image Decoding**: Different caching strategies

### 12.3 Validity Considerations

- Results are **relative** comparisons, not absolute performance measures
- Performance varies by device (A-series chip, RAM, iOS version)
- Real-world apps have different optimization opportunities

---

## 13. Reproducing Results

### 13.1 Checklist

- [ ] Physical iOS device (not simulator)
- [ ] Flutter SDK 3.10+ with Impeller enabled
- [ ] Both apps built in Release mode
- [ ] Device in Airplane mode
- [ ] All background apps closed
- [ ] Device at room temperature
- [ ] Battery between 20-80%
- [ ] Screen brightness consistent (affects battery test)
- [ ] Wait 30s between tests

### 13.2 Running Benchmarks

**Flutter:**

```bash
cd flutter_benchmark
flutter pub get
flutter run --release
```

**iOS:**

1. Open `iOSBenchmark.xcodeproj`
2. Select Release scheme
3. Build and Run (⌘R)

### 13.3 Recording Results

Create a spreadsheet with columns:

- Platform (Flutter/iOS)
- Test (CPU/GPU)
- Run Number
- Metric Value
- Timestamp

---

## Appendix A: File Checksums

To verify identical test conditions, compare image assets:

```bash
# Flutter
md5 flutter_benchmark/assets/images/img_*.jpg

# iOS  
md5 ios_benchmark/iOSBenchmark/Assets.xcassets/img_*/img_*.jpg
```

---

## Appendix B: Console Output Reference

### CPU Test Output

```
═══════════════════════════════════════════════
[PLATFORM] BENCHMARK - CPU TEST RESULTS
═══════════════════════════════════════════════
Algorithm: Sieve of Eratosthenes
Limit: 1000000
Primes found: 78498
Execution time: XXXXX μs
Execution time: XX.XX ms
═══════════════════════════════════════════════
```

### GPU Test Output

```
═══════════════════════════════════════════════
[PLATFORM] BENCHMARK - GPU TEST STARTED
═══════════════════════════════════════════════
Items: 1000
Duration: 30 seconds
Battery at start: XX%
═══════════════════════════════════════════════

═══════════════════════════════════════════════
[PLATFORM] BENCHMARK - GPU TEST RESULTS
═══════════════════════════════════════════════
Total frames: XXXX
Dropped frames (>16.67ms): XX
Average frame time: XX.XX ms
Max frame time: XX.XX ms
Estimated FPS: XX.X
Battery at end: XX%
Battery drain: X%
═══════════════════════════════════════════════
```

### Startup Output

```
═══════════════════════════════════════════════
[PLATFORM] BENCHMARK - STARTUP TIME MEASUREMENT
═══════════════════════════════════════════════
Main() called at: XXXXXXXXXX μs
First frame at: XXXXXXXXXX μs
Time to Interactive (TTI): XXXXX μs
Time to Interactive (TTI): XX.XX ms
═══════════════════════════════════════════════
```

---

*Document Version: 1.0*  
*Last Updated: December 2025*  
*WISA Course - Scientific Framework Comparison*
