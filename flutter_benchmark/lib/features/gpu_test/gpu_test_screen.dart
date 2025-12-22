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
/// - Frame build times (jank detection)
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

  // FPS Metrics
  final List<int> _frameDurations = [];
  int _droppedFrameCount = 0;
  int _totalFrameCount = 0;
  double _averageFrameTime = 0;
  int _maxFrameTime = 0;

  // Battery Metrics
  int? _batteryLevelStart;
  int? _batteryLevelEnd;
  String? _batteryDelta;

  // Timing
  int _elapsedSeconds = 0;
  Timer? _progressTimer;

  // Frame callback
  int? _frameCallbackId;
  int _lastFrameTime = 0;

  @override
  void dispose() {
    _stopFrameCallback();
    _progressTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startFrameCallback() {
    _frameCallbackId = SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }

  void _stopFrameCallback() {
    _frameCallbackId = null;
  }

  void _onFrame(Duration timestamp) {
    if (!_isScrolling) return;

    final int currentTime = timestamp.inMicroseconds;

    if (_lastFrameTime > 0) {
      final int frameDuration = currentTime - _lastFrameTime;
      _frameDurations.add(frameDuration);
      _totalFrameCount++;

      // Jank detection: frame time > 16.67ms (60 FPS target)
      if (frameDuration > BenchmarkConfig.jankThresholdUs) {
        _droppedFrameCount++;
        debugPrint(
          'Jank detected: Frame took ${(frameDuration / 1000).toStringAsFixed(2)} ms',
        );
      }

      if (frameDuration > _maxFrameTime) {
        _maxFrameTime = frameDuration;
      }
    }

    _lastFrameTime = currentTime;

    if (_isScrolling) {
      _frameCallbackId = SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
    }
  }

  Future<void> _startAutoScroll() async {
    if (_isScrolling) return;

    setState(() {
      _isScrolling = true;
      _testCompleted = false;
      _frameDurations.clear();
      _droppedFrameCount = 0;
      _totalFrameCount = 0;
      _maxFrameTime = 0;
      _elapsedSeconds = 0;
      _batteryDelta = null;
    });

    _batteryLevelStart = await BatteryService.getBatteryLevel();
    _lastFrameTime = 0;

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

    _batteryLevelEnd = await BatteryService.getBatteryLevel();

    if (_frameDurations.isNotEmpty) {
      final int sum = _frameDurations.reduce((a, b) => a + b);
      _averageFrameTime = sum / _frameDurations.length;
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
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('FLUTTER BENCHMARK - GPU TEST RESULTS');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('Total frames: $_totalFrameCount');
    debugPrint('Dropped frames (>16.67ms): $_droppedFrameCount');
    debugPrint(
      'Average frame time: ${(_averageFrameTime / 1000).toStringAsFixed(2)} ms',
    );
    debugPrint(
      'Max frame time: ${(_maxFrameTime / 1000).toStringAsFixed(2)} ms',
    );
    debugPrint(
      'Estimated FPS: ${_totalFrameCount > 0 ? (1000000 / _averageFrameTime).toStringAsFixed(1) : "N/A"}',
    );
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
              averageFrameTimeUs: _averageFrameTime,
              maxFrameTimeUs: _maxFrameTime,
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
          if (_isScrolling) ...[
            const SizedBox(height: 8),
            _buildLiveMetrics(),
          ],
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
          backgroundColor: _isScrolling ? AppTheme.errorColor : AppTheme.gpuTestColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isScrolling ? Icons.stop : Icons.play_arrow),
            const SizedBox(width: 8),
            Text(
              _isScrolling ? 'Stop Test' : 'Start 30s Auto-Scroll',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
          value: _averageFrameTime > 0
              ? '${(_averageFrameTime / 1000).toStringAsFixed(1)}ms'
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
