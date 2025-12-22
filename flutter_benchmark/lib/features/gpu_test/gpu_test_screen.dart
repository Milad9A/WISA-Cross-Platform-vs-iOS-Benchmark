import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/constants/benchmark_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/battery_service.dart';
import '../../widgets/metric_card.dart';
import 'widgets/complex_list_item.dart';
import 'widgets/results_panel.dart';

/// GPU/Memory/FPS Test Screen
///
/// Implements a stress test with 1000 complex list items containing:
/// - High-resolution images (cycling through 10 assets)
/// - Complex UI elements with shadows and gradients
/// - Auto-scroll functionality for reproducible testing
///
/// Measures:
/// - Frame build times (jank detection) using FrameTiming API
/// - Battery drain during test
/// - Memory pressure through image loading
class GPUTestScreen extends StatefulWidget {
  const GPUTestScreen({super.key});

  @override
  State<GPUTestScreen> createState() => _GPUTestScreenState();
}

class _GPUTestScreenState extends State<GPUTestScreen> {
  final ScrollController _scrollController = ScrollController();

  // Test State
  bool _isScrolling = false;
  bool _testCompleted = false;

  // Frame interval tracking (comparable to iOS CADisplayLink)
  final List<int> _frameIntervals =
      []; // Frame-to-frame intervals in microseconds
  int _droppedFrameCount = 0;
  int _totalFrameCount = 0;
  double _averageFrameInterval = 0;
  int _maxFrameInterval = 0;
  int _lastFrameTimeUs = 0;

  // Elapsed time tracking for accurate FPS
  int _testStartTimeUs = 0;
  int _testEndTimeUs = 0;
  double _actualFps = 0;

  // Battery Metrics
  int? _batteryLevelStart;
  int? _batteryLevelEnd;
  String? _batteryDelta;

  // Timing
  int _elapsedSeconds = 0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _stopFrameCallback();
    _progressTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Uses scheduleFrameCallback to measure frame-to-frame intervals
  /// This is comparable to iOS's CADisplayLink measurement
  void _startFrameCallback() {
    _lastFrameTimeUs = 0;
    SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }

  void _stopFrameCallback() {
    _lastFrameTimeUs = -1; // Signal to stop
  }

  /// Callback for each frame - measures interval between frames
  /// Comparable to iOS CADisplayLink's timestamp-based measurement
  void _onFrame(Duration timestamp) {
    if (!_isScrolling || _lastFrameTimeUs == -1) return;

    final int currentTimeUs = timestamp.inMicroseconds;

    if (_lastFrameTimeUs > 0) {
      final int frameInterval = currentTimeUs - _lastFrameTimeUs;
      _frameIntervals.add(frameInterval);
      _totalFrameCount++;

      // Jank detection: frame interval > 25ms (missed a 60 FPS frame)
      // Using 1.5x threshold like iOS to detect actual dropped frames
      final int jankThreshold = (BenchmarkConfig.jankThresholdUs * 1.5).toInt();
      if (frameInterval > jankThreshold) {
        _droppedFrameCount++;
        debugPrint(
          'Jank detected: Frame interval=${(frameInterval / 1000).toStringAsFixed(2)}ms',
        );
      }

      if (frameInterval > _maxFrameInterval) {
        _maxFrameInterval = frameInterval;
      }

      // Update average in real-time
      if (_frameIntervals.isNotEmpty) {
        final int sum = _frameIntervals.reduce((a, b) => a + b);
        _averageFrameInterval = sum / _frameIntervals.length;
      }
    }

    _lastFrameTimeUs = currentTimeUs;

    // Schedule next frame
    if (_isScrolling) {
      SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
    }
  }

  Future<void> _startAutoScroll() async {
    if (_isScrolling) return;

    setState(() {
      _isScrolling = true;
      _testCompleted = false;
      _frameIntervals.clear();
      _droppedFrameCount = 0;
      _totalFrameCount = 0;
      _maxFrameInterval = 0;
      _averageFrameInterval = 0;
      _actualFps = 0;
      _elapsedSeconds = 0;
      _batteryDelta = null;
    });

    _batteryLevelStart = await BatteryService.getBatteryLevel();
    _testStartTimeUs = DateTime.now().microsecondsSinceEpoch;

    _logTestStart();
    _startFrameCallback();
    _startProgressTimer();

    _scrollController.jumpTo(0);
    await Future.delayed(const Duration(milliseconds: 100));

    final double maxScroll = _scrollController.position.maxScrollExtent;

    await _scrollController.animateTo(
      maxScroll,
      duration: Duration(seconds: BenchmarkConfig.scrollDurationSeconds),
      curve: Curves.linear,
    );

    await _completeTest();
  }

  void _logTestStart() {
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('FLUTTER BENCHMARK - GPU TEST STARTED');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('Items: ${BenchmarkConfig.gpuTestItemCount}');
    debugPrint('Duration: ${BenchmarkConfig.scrollDurationSeconds} seconds');
    debugPrint('Battery at start: ${_batteryLevelStart ?? "N/A"}%');
    debugPrint('═══════════════════════════════════════════════');
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isScrolling) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  Future<void> _completeTest() async {
    _stopFrameCallback();
    _progressTimer?.cancel();
    _testEndTimeUs = DateTime.now().microsecondsSinceEpoch;

    _batteryLevelEnd = await BatteryService.getBatteryLevel();

    if (_frameIntervals.isNotEmpty) {
      final int sum = _frameIntervals.reduce((a, b) => a + b);
      _averageFrameInterval = sum / _frameIntervals.length;
    }

    // Calculate actual FPS based on elapsed time (same as iOS CADisplayLink approach)
    final int elapsedUs = _testEndTimeUs - _testStartTimeUs;
    if (elapsedUs > 0 && _totalFrameCount > 0) {
      _actualFps = _totalFrameCount / (elapsedUs / 1000000.0);
    }

    _batteryDelta = BatteryService.calculateDrain(
      _batteryLevelStart,
      _batteryLevelEnd,
    );

    setState(() {
      _isScrolling = false;
      _testCompleted = true;
    });

    _logTestResults();
  }

  void _logTestResults() {
    final double jankPercentage = _totalFrameCount > 0
        ? (_droppedFrameCount / _totalFrameCount) * 100
        : 0;
    final int elapsedUs = _testEndTimeUs - _testStartTimeUs;
    final double elapsedSeconds = elapsedUs / 1000000.0;

    debugPrint('═══════════════════════════════════════════════');
    debugPrint('FLUTTER BENCHMARK - GPU TEST RESULTS');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('Test duration: ${elapsedSeconds.toStringAsFixed(2)} seconds');
    debugPrint('Total frames rendered: $_totalFrameCount');
    debugPrint('Janky frames (>25ms): $_droppedFrameCount');
    debugPrint('Jank percentage: ${jankPercentage.toStringAsFixed(1)}%');
    debugPrint('');
    debugPrint(
      'Avg frame interval: ${(_averageFrameInterval / 1000).toStringAsFixed(2)} ms',
    );
    debugPrint(
      'Max frame interval: ${(_maxFrameInterval / 1000).toStringAsFixed(2)} ms',
    );
    debugPrint('Actual FPS (frames/elapsed): ${_actualFps.toStringAsFixed(1)}');
    debugPrint('');
    debugPrint('Battery at end: ${_batteryLevelEnd ?? "N/A"}%');
    debugPrint('Battery drain: $_batteryDelta');
    debugPrint('═══════════════════════════════════════════════');
  }

  void _stopTest() {
    _stopFrameCallback();
    _progressTimer?.cancel();
    _scrollController.jumpTo(_scrollController.offset);

    setState(() {
      _isScrolling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPU/Memory/FPS Test'),
        backgroundColor: AppTheme.gpuTestColor.withOpacity(0.2),
      ),
      body: Column(
        children: [
          _buildControlPanel(),
          if (_testCompleted)
            ResultsPanel(
              totalFrameCount: _totalFrameCount,
              droppedFrameCount: _droppedFrameCount,
              averageFrameTimeUs: _averageFrameInterval,
              maxFrameTimeUs: _maxFrameInterval.toDouble(),
              actualFps: _actualFps,
              batteryDelta: _batteryDelta,
            ),
          _buildScrollableList(),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardBackground,
      child: Column(
        children: [
          if (_isScrolling) ...[
            _buildProgressIndicator(),
            const SizedBox(height: 12),
          ],
          _buildTestButton(),
          if (_isScrolling) ...[const SizedBox(height: 8), _buildLiveMetrics()],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: _elapsedSeconds / BenchmarkConfig.scrollDurationSeconds,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$_elapsedSeconds / ${BenchmarkConfig.scrollDurationSeconds} s',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isScrolling ? _stopTest : _startAutoScroll,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isScrolling
              ? AppTheme.errorColor
              : AppTheme.gpuTestColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isScrolling ? Icons.stop : Icons.play_arrow),
            const SizedBox(width: 8),
            Text(
              _isScrolling ? 'Stop Test' : 'Start 30s Auto-Scroll',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMetrics() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        LiveMetric(label: 'Frames', value: '$_totalFrameCount'),
        LiveMetric(label: 'Jank', value: '$_droppedFrameCount'),
        LiveMetric(
          label: 'Avg',
          value: _averageFrameInterval > 0
              ? '${(_averageFrameInterval / 1000).toStringAsFixed(1)}ms'
              : '...',
        ),
      ],
    );
  }

  Widget _buildScrollableList() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: BenchmarkConfig.gpuTestItemCount,
        cacheExtent: BenchmarkConfig.listCacheExtent,
        itemBuilder: (context, index) {
          return ComplexListItem(
            index: index,
            imageIndex: index % BenchmarkConfig.imageCycleCount,
          );
        },
      ),
    );
  }
}
