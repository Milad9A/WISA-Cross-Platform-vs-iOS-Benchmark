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

### Actual Findings

Based on benchmark testing, the hypothesis was **partially confirmed**:

| Benchmark Type | Result | Explanation |
|----------------|--------|-------------|
| **Startup Time** | Flutter ~2.5x faster | AOT compilation + efficient engine init |
| **CPU Computation** | iOS ~3x faster | LLVM native ARM64 vs Dart AOT |
| **GPU/UI Rendering** | Equivalent | Both use Metal for rendering |
| **FPS Stability** | Equivalent | Both achieve ~60 FPS |
| **Jank Rate** | Equivalent | Both <1% dropped frames |

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

**Threading Context**: The CPU benchmark is **intentionally single-threaded** and runs on the **main UI thread** to:

- Compare compiler/VM performance (Dart AOT vs LLVM) directly
- Avoid scheduler differences between platforms
- Measure UI-blocking behavior (realistic for compute on main thread)
- Ensure deterministic, reproducible results

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

### 2.4 Engine Initialization Time ("Startup Time")

| Metric | Unit | Description |
|--------|------|-------------|
| Engine Init to First Frame | Milliseconds | Time from framework initialization (`didFinishLaunchingWithOptions` in Flutter, `StartupMetrics.init()` in iOS) to first frame rendered |

**Important Clarifications**:

- **Does NOT include**: OS process creation, dylib loading, or app launch from cold start
- **Does include**: Framework initialization (Flutter engine or SwiftUI runtime), widget/view tree construction, layout, and first frame rasterization
- **Measurement Point**: Starts when the app framework begins execution (after OS has loaded the process)
- **More Accurate Name**: "Engine Initialization Time" or "Framework-to-Frame Time"
- **Why ~27ms is fast**: This only measures framework overhead, not total app launch time from user tap

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
| **Framework** | Flutter 3.38.4 (stable) | SwiftUI (iOS 17.0+) |
| **Language** | Dart 3.10.3 | Swift 6.2.3 |
| **Rendering** | Impeller (Metal) | Core Animation / Metal |
| **IDE** | VS Code / Android Studio | Xcode 26.2 |
| **Build Version** | Engine a5cb96369e | Build 17C52 |
| **Compiler** | Dart AOT | LLVM (swiftlang-6.2.3.3.21) |

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
| **Single-Threaded** | Compares Dart AOT vs LLVM compiler performance directly |
| **Run on Main Thread** | Measures UI thread blocking behavior (realistic scenario) |
| **No Isolate/GCD** | Eliminates scheduler/concurrency differences between platforms |
| **Boolean Array** | Identical memory pattern and allocation strategy |
| **Post-delay Start** | Allows UI to settle, ensures consistent thermal state |
| **Multiple Iterations** | Statistical significance (mean, stddev, min, max) |

**Why Single-Threaded?**  
This benchmark intentionally avoids multi-threading to isolate **compiler/VM performance** from **scheduler efficiency**. It measures: "How fast can each platform execute the same algorithm on one core?" rather than "How well does each platform schedule work?"

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

### 6.1 Measurement Approach

Both apps measure **frame-to-frame intervals** to ensure comparable metrics:

| App | API | What's Measured |
|-----|-----|-----------------|
| Flutter | `SchedulerBinding.scheduleFrameCallback` | Time between consecutive frame callbacks |
| iOS | `CADisplayLink` | Time between consecutive VSync signals |

### 6.2 Flutter Implementation

```dart
void _startFrameCallback() {
  _lastFrameTimeUs = 0;
  SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
}

void _onFrame(Duration timestamp) {
  if (!_isScrolling) return;
  
  final int currentTimeUs = timestamp.inMicroseconds;
  
  if (_lastFrameTimeUs > 0) {
    final int frameInterval = currentTimeUs - _lastFrameTimeUs;
    _frameIntervals.add(frameInterval);
    _totalFrameCount++;
    
    // Jank detection: frame interval > 25ms (missed a 60 FPS frame)
    // Using 1.5x threshold to detect actual dropped frames
    final int jankThreshold = (16667 * 1.5).toInt(); // ~25ms
    if (frameInterval > jankThreshold) {
      _droppedFrameCount++;
    }
  }
  
  _lastFrameTimeUs = currentTimeUs;
  
  if (_isScrolling) {
    SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }
}
```

### 6.3 iOS Implementation

```dart
var displayLink: CADisplayLink?
var lastTimestamp: CFTimeInterval = 0
let targetFrameTime: CFTimeInterval = 1.0 / 60.0  // 16.67ms

func startFrameCallback() {
    displayLink = CADisplayLink(target: self, selector: #selector(onFrame))
    displayLink?.add(to: .main, forMode: .common)
}

@objc func onFrame(_ link: CADisplayLink) {
    if lastTimestamp > 0 {
        let frameDuration = link.timestamp - lastTimestamp
        frameDurations.append(frameDuration)
        totalFrameCount += 1
        
        // Jank detection: frame took significantly longer than target
        // Using 1.5x threshold to detect actual dropped frames
        let jankThreshold = targetFrameTime * 1.5  // ~25ms
        if frameDuration > jankThreshold {
            droppedFrameCount += 1
        }
    }
    lastTimestamp = link.timestamp
}
```

### 6.4 Jank Detection Threshold

Both apps use **1.5x the target frame time** (~25ms for 60 FPS) as the jank threshold:

| FPS Target | Frame Budget | Jank Threshold (1.5x) |
|------------|--------------|----------------------|
| 60 FPS | 16.67 ms | ~25 ms |
| 120 FPS (ProMotion) | 8.33 ms | ~12.5 ms |

**Rationale**: Using exactly 16.67ms would flag normal VSync timing variations as jank. The 1.5x buffer detects when a frame actually **missed its deadline** (took longer than one VSync interval).

### 6.5 Actual FPS Calculation

Both apps calculate **Actual FPS** based on elapsed time:

```
Actual FPS = Total Frames Rendered / Elapsed Time (seconds)
```

This provides a consistent metric regardless of internal frame timing variations.

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

## 8. Engine Initialization Time Measurement

### 8.1 Definition: Framework-to-Frame Time (Commonly Called "Startup Time")

This metric measures the time from **framework initialization** to **first frame rendered**.

**Critical Clarification - What Is NOT Measured**:

- ❌ OS process creation and launch
- ❌ Dynamic library (dylib) loading
- ❌ App binary loading into memory
- ❌ Code signing verification
- ❌ Cold start from device home screen

**What IS Measured**:

- ✅ Framework initialization (Flutter engine or SwiftUI runtime)
- ✅ App delegate/main struct initialization
- ✅ Widget/view tree construction
- ✅ Initial layout pass
- ✅ First frame rasterization to screen

**Why the measurement is ~27-67ms (not seconds)**:  
Both apps start measuring **after** the OS has already launched the process. The measurement begins when the application framework (Flutter or SwiftUI) starts executing.

**More Accurate Terminology**: "Engine Initialization Time" or "Framework-to-Frame Time"

### 8.2 Flutter Implementation

Flutter measures via a native `MethodChannel` that captures elapsed time from `didFinishLaunchingWithOptions` (earliest framework hook) to first frame:

```swift
// ios/Runner/AppDelegate.swift
@objc class AppDelegate: FlutterAppDelegate {
    private var appLaunchTime: CFAbsoluteTime = 0
    
    override func application(...) -> Bool {
        appLaunchTime = CFAbsoluteTimeGetCurrent()  // Capture immediately
        
        // Method channel returns elapsed time when called
        startupChannel.setMethodCallHandler { [weak self] ... in
            if call.method == "getElapsedStartupTime" {
                let now = CFAbsoluteTimeGetCurrent()
                let elapsed = now - self.appLaunchTime
                result(Int(elapsed * 1_000_000))  // microseconds
            }
        }
    }
}
```

```dart
// home_screen.dart
void _measureStartupTime() {
  SchedulerBinding.instance.addPostFrameCallback((_) async {
    final result = await _startupChannel.invokeMethod('getElapsedStartupTime');
    // result is TTI in microseconds from native app launch
  });
}
```

### 8.3 iOS Implementation

iOS measures from `StartupMetrics.init()` (first access in App struct) to first frame:

```swift
// iOSBenchmarkApp.swift
class StartupMetrics: ObservableObject {
    static let shared = StartupMetrics()
    @Published var appInitTime: CFAbsoluteTime
    
    private init() {
        appInitTime = CFAbsoluteTimeGetCurrent()  // Captured on first access
    }
    
    func recordFirstFrame() {
        firstFrameTime = CFAbsoluteTimeGetCurrent()
        timeToInteractive = (firstFrameTime - appInitTime) * 1_000_000
    }
}

// ContentView.swift
.onAppear {
    startupMetrics.recordFirstFrame()
}
```

### 8.4 What TTI Includes (Aligned Measurement)

| Flutter | iOS |
|---------|-----|
| `didFinishLaunchingWithOptions` start | `StartupMetrics.init()` |
| Flutter engine initialization | SwiftUI App body creation |
| Widget tree construction | View hierarchy creation |
| Layout pass | Layout pass |
| First frame rasterization | First frame render |
| `addPostFrameCallback` + method channel | `onAppear` trigger |

### 8.5 Startup Time Results

| Metric | Flutter | iOS Native | Difference |
|--------|---------|------------|------------|
| **Engine Init → First Frame** | ~27 ms | ~67 ms | **Flutter ~2.5x faster** |

**Measurement Boundaries**:

- **Start**: Framework initialization (`didFinishLaunchingWithOptions` for Flutter, `StartupMetrics.init()` for iOS)
- **End**: First frame rendered and `onAppear`/`addPostFrameCallback` triggered
- **Excludes**: OS process creation, dylib loading (adds ~100-300ms on cold launch)

**Analysis**: Flutter's faster framework initialization is attributed to:

1. **AOT Compilation**: Dart AOT produces optimized machine code ready to execute
2. **Engine Pre-warming**: Flutter's Impeller engine initializes efficiently
3. **Widget Tree Efficiency**: Flutter's declarative widget system is highly optimized for initial layout
4. **SwiftUI Overhead**: SwiftUI's declarative resolution and `@StateObject` initialization adds overhead

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
Dropped frames (>25ms): XX
Average frame interval: XX.XX ms
Max frame interval: XX.XX ms
Actual FPS: XX.X
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

## Appendix C: Benchmark Results Summary

### Test Environment

- **Device**: iPhone 14
- **iOS Version**: 17.x
- **Build Mode**: Release (both apps)

### Exact Software Versions

| Component | Version | Details |
|-----------|---------|---------|
| **Flutter** | 3.38.4 (stable) | Channel: stable |
| **Dart** | 3.10.3 | AOT Compiler |
| **Flutter Engine** | a5cb96369e | Impeller (Metal) |
| **Xcode** | 26.2 | Build 17C52 |
| **Swift** | 6.2.3 | swiftlang-6.2.3.3.21 |
| **LLVM** | clang-1700.6.3.2 | Target: arm64-apple-macosx26.0 |

### CPU Benchmark Results

| Metric | Flutter | iOS Native | Difference |
|--------|---------|------------|------------|
| **Algorithm** | Sieve of Eratosthenes | Sieve of Eratosthenes | Identical |
| **Threading** | Single-threaded (main thread) | Single-threaded (main thread) | Identical |
| **Prime Limit** | 1,000,000 | 1,000,000 | Identical |
| **Primes Found** | 78,498 ✓ | 78,498 ✓ | Validated |
| **Execution Time** | ~27-30 ms | ~9 ms | **iOS ~3x faster** |

**Threading Context**: Both implementations are intentionally **single-threaded** and run on the **main UI thread** to compare compiler performance (Dart AOT vs LLVM) directly, without introducing scheduler/concurrency variables.

**Analysis**: The 3x performance difference is attributed to:

1. **LLVM vs Dart AOT**: Swift compiles via LLVM with aggressive optimizations (`-O`), while Dart AOT has more conservative optimizations
2. **Memory Allocation**: Swift can use stack-allocated arrays, while Dart uses heap allocation with GC tracking
3. **Loop Optimization**: LLVM applies vectorization and loop unrolling not available in Dart AOT

### GPU/Rendering Benchmark Results

| Metric | Flutter | iOS Native | Difference |
|--------|---------|------------|------------|
| **Total Frames** | ~1750-1800 | ~1750-1800 | Equivalent |
| **Actual FPS** | ~58-60 FPS | ~58-60 FPS | Equivalent |
| **Jank Rate** | <1% | <1% | Equivalent |
| **Avg Frame Interval** | ~16-17 ms | ~16-17 ms | Equivalent |
| **Max Frame Interval** | Varies | Varies | Comparable |

**Analysis**: Both frameworks achieve equivalent UI rendering performance because:

1. **Both use Metal**: Flutter's Impeller and iOS's Core Animation both ultimately render via Metal
2. **GPU-bound workload**: UI rendering is GPU-bound, not CPU-bound
3. **Optimized rendering engines**: Both frameworks have mature, optimized rendering pipelines

### Startup Time Benchmark Results

| Metric | Flutter | iOS Native | Difference |
|--------|---------|------------|------------|
| **Engine Init → First Frame** | ~27 ms | ~67 ms | **Flutter ~2.5x faster** |

**Measurement Scope**:

- ✅ **Included**: Framework initialization, widget/view tree construction, layout, first frame rasterization
- ❌ **Excluded**: OS process creation, dylib loading, code signing (adds ~100-300ms)
- **Start Point**: Framework begins execution (`didFinishLaunchingWithOptions` / `StartupMetrics.init()`)
- **End Point**: First frame rendered to screen

**Analysis**: Flutter's faster framework initialization is attributed to:

1. **AOT Compilation**: Dart AOT produces optimized machine code ready to execute immediately
2. **Efficient Engine Initialization**: Impeller engine starts quickly
3. **Widget Tree Optimization**: Flutter's element tree construction is highly optimized
4. **SwiftUI Overhead**: SwiftUI's declarative state management and view resolution adds initialization time

### Key Conclusions

| Category | Winner | Margin | Use Case Implication |
|----------|--------|--------|---------------------|
| **Startup Time** | Flutter | ~2.5x | Flutter apps launch faster |
| **CPU Computation** | iOS Native | ~3x | Use native code for compute-heavy tasks |
| **UI Rendering** | Tie | 0% | Flutter is viable for UI-heavy apps |

### Recommendations

1. **For fast-launching apps**: Flutter provides faster startup times
2. **For UI-heavy apps**: Flutter is a viable choice with no rendering performance penalty
3. **For compute-heavy features**: Consider using platform channels to execute critical algorithms in native Swift
4. **For benchmarking**: Always use Release mode for both platforms
5. **For battery testing**: Use physical devices; simulators don't report accurate battery levels

---

*Document Version: 2.0*  
*Last Updated: December 2025*  
*WISA Course - Scientific Framework Comparison*
