import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../cpu_test/cpu_test_screen.dart';
import '../gpu_test/gpu_test_screen.dart';
import 'widgets/benchmark_card.dart';

/// Home screen displaying startup time and benchmark test options
class HomeScreen extends StatefulWidget {
  final int mainStartTime;

  const HomeScreen({super.key, required this.mainStartTime});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _startupTimeUs;
  bool _startupMeasured = false;

  static const _startupChannel = MethodChannel('flutter_benchmark/startup');

  @override
  void initState() {
    super.initState();
    _measureStartupTime();
  }

  void _measureStartupTime() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!_startupMeasured) {
        final int firstFrameTime = DateTime.now().microsecondsSinceEpoch;
        final int dartOnlyStartup = firstFrameTime - widget.mainStartTime;

        // Try to get elapsed time from native process start
        int? nativeStartupTime;
        try {
          final result = await _startupChannel.invokeMethod(
            'getElapsedStartupTime',
          );
          if (result != null) {
            nativeStartupTime = (result as num).toInt();
          }
        } catch (e) {
          // Native startup time not available, use Dart-only measurement
        }

        setState(() {
          _startupTimeUs = nativeStartupTime ?? dartOnlyStartup;
          _startupMeasured = true;
        });

        _logStartupTime(firstFrameTime, _startupTimeUs!, dartOnlyStartup);
      }
    });
  }

  void _logStartupTime(
    int firstFrameTime,
    int totalStartup,
    int dartOnlyStartup,
  ) {
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('FLUTTER BENCHMARK - STARTUP TIME MEASUREMENT');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('First frame at: $firstFrameTime μs');
    debugPrint(
      'Dart-only startup (main→frame): $dartOnlyStartup μs (${(dartOnlyStartup / 1000).toStringAsFixed(2)} ms)',
    );
    debugPrint(
      'Total startup (process→frame): $totalStartup μs (${(totalStartup / 1000).toStringAsFixed(2)} ms)',
    );
    debugPrint('═══════════════════════════════════════════════');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Benchmark'),
        backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),
              const Text(
                'Select Benchmark Test',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildCPUTestCard(),
              const SizedBox(height: 12),
              _buildGPUTestCard(),
              const Spacer(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.speed, size: 48, color: AppTheme.primaryBlue),
            const SizedBox(height: 12),
            const Text(
              'Performance Benchmark Suite',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Flutter (Impeller/Skia)',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
            const Divider(height: 24),
            _buildStartupTimeDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartupTimeDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: AppTheme.successColor),
          const SizedBox(width: 8),
          Text(
            _startupTimeUs != null
                ? 'Startup Time: ${(_startupTimeUs! / 1000).toStringAsFixed(2)} ms'
                : 'Measuring startup...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCPUTestCard() {
    return BenchmarkCard(
      icon: Icons.memory,
      title: 'CPU Efficiency Test',
      subtitle: 'Sieve of Eratosthenes (1M primes)',
      description:
          'Measures single-thread CPU performance by calculating primes on the main UI thread.',
      color: AppTheme.cpuTestColor,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CPUTestScreen()),
      ),
    );
  }

  Widget _buildGPUTestCard() {
    return BenchmarkCard(
      icon: Icons.view_list,
      title: 'GPU/Memory/FPS Test',
      subtitle: '1000 items • 30s auto-scroll • Battery',
      description:
          'Stresses GPU rasterizer with complex list items. Measures FPS, memory, and battery drain.',
      color: AppTheme.gpuTestColor,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GPUTestScreen()),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'WISA Course - Scientific Framework Comparison',
      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      textAlign: TextAlign.center,
    );
  }
}
