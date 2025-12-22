import 'package:flutter/material.dart';
import '../../core/constants/benchmark_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/statistics_utils.dart';
import 'algorithms/sieve_of_eratosthenes.dart';
import 'models/cpu_test_result.dart';
import 'widgets/cpu_result_card.dart';

/// CPU Efficiency Test Screen
///
/// Implements the Sieve of Eratosthenes algorithm to calculate all primes
/// up to 1,000,000. Runs on the MAIN UI THREAD intentionally to measure
/// UI blocking/freezing behavior.
class CPUTestScreen extends StatefulWidget {
  const CPUTestScreen({super.key});

  @override
  State<CPUTestScreen> createState() => _CPUTestScreenState();
}

class _CPUTestScreenState extends State<CPUTestScreen> {
  bool _isRunning = false;
  int? _executionTimeUs;
  int? _primeCount;
  String _status = 'Ready to run test';
  List<CPUTestResult> _testHistory = [];

  void _runTest() {
    setState(() {
      _isRunning = true;
      _status = 'Running Sieve of Eratosthenes...';
      _executionTimeUs = null;
      _primeCount = null;
    });

    // Use Future.delayed to allow UI to update before blocking
    Future.delayed(const Duration(milliseconds: 50), () {
      final Stopwatch stopwatch = Stopwatch()..start();

      // Run the algorithm on the MAIN THREAD (intentionally blocking)
      final int primeCount = SieveOfEratosthenes.countPrimes(
        BenchmarkConfig.sievePrimeLimit,
      );

      stopwatch.stop();
      final int executionTimeUs = stopwatch.elapsedMicroseconds;

      _logResult(primeCount, executionTimeUs);

      setState(() {
        _isRunning = false;
        _executionTimeUs = executionTimeUs;
        _primeCount = primeCount;
        _status = 'Test completed';
        _addToHistory(executionTimeUs, primeCount);
      });
    });
  }

  void _logResult(int primeCount, int executionTimeUs) {
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('FLUTTER BENCHMARK - CPU TEST RESULTS');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('Algorithm: Sieve of Eratosthenes');
    debugPrint('Limit: ${BenchmarkConfig.sievePrimeLimit}');
    debugPrint('Primes found: $primeCount');
    debugPrint('Execution time: $executionTimeUs μs');
    debugPrint(
      'Execution time: ${(executionTimeUs / 1000).toStringAsFixed(2)} ms',
    );
    debugPrint('═══════════════════════════════════════════════');
  }

  void _addToHistory(int executionTimeUs, int primeCount) {
    _testHistory.insert(
      0,
      CPUTestResult(
        executionTimeUs: executionTimeUs,
        primeCount: primeCount,
        timestamp: DateTime.now(),
      ),
    );
    if (_testHistory.length > BenchmarkConfig.maxTestHistory) {
      _testHistory = _testHistory.sublist(0, BenchmarkConfig.maxTestHistory);
    }
  }

  void _clearHistory() {
    setState(() {
      _testHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CPU Efficiency Test'),
        backgroundColor: AppTheme.cpuTestColor.withOpacity(0.2),
        actions: [
          if (_testHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildRunButton(),
              const SizedBox(height: 16),
              _buildStatus(),
              const SizedBox(height: 24),
              if (_executionTimeUs != null)
                CPUResultCard(
                  executionTimeUs: _executionTimeUs!,
                  primeCount: _primeCount!,
                ),
              if (_testHistory.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildHistorySection(),
              ],
              if (_testHistory.length >= 2) ...[
                const SizedBox(height: 24),
                _buildStatisticsCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: AppTheme.cpuTestColor.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Text(
                  'Test Configuration',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Algorithm', 'Sieve of Eratosthenes'),
            _buildInfoRow('Range', '2 to 1,000,000'),
            _buildInfoRow('Thread', 'Main UI Thread (blocking)'),
            _buildInfoRow('Expected Result', '78,498 primes'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade400)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isRunning ? null : _runTest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.cpuTestColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isRunning
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Running...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text(
                    'Run CPU Test',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatus() {
    return Center(
      child: Text(
        _status,
        style: TextStyle(
          color: _isRunning ? AppTheme.cpuTestColor : Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test History',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _testHistory.length,
          itemBuilder: (context, index) {
            final result = _testHistory[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.cpuTestColor.withOpacity(0.2),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                ),
                title: Text(
                  result.formattedTime,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${result.primeCount} primes • ${StatisticsUtils.formatTime(result.timestamp)}',
                ),
                trailing: Icon(
                  result.isValid ? Icons.check_circle : Icons.error,
                  color: result.isValid ? Colors.green : Colors.red,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    final times = _testHistory.map((r) => r.executionTimeUs).toList();

    return Card(
      color: AppTheme.cardBackgroundLight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Average',
              StatisticsUtils.formatMicroseconds(
                StatisticsUtils.average(times).round(),
              ),
            ),
            _buildStatRow(
              'Min',
              StatisticsUtils.formatMicroseconds(StatisticsUtils.min(times)),
            ),
            _buildStatRow(
              'Max',
              StatisticsUtils.formatMicroseconds(StatisticsUtils.max(times)),
            ),
            _buildStatRow(
              'Std Dev',
              StatisticsUtils.formatMicroseconds(
                StatisticsUtils.standardDeviation(times).round(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
