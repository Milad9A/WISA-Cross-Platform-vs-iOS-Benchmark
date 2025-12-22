import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Card widget for displaying CPU test results
class CPUResultCard extends StatelessWidget {
  final int executionTimeUs;
  final int primeCount;

  const CPUResultCard({
    super.key,
    required this.executionTimeUs,
    required this.primeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Latest Result',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildExecutionTimeBox(),
            const SizedBox(height: 16),
            _buildMetricsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionTimeBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Text(
            'Execution Time',
            style: TextStyle(
              color: AppTheme.successColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(executionTimeUs / 1000).toStringAsFixed(2)} ms',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),
          Text(
            '$executionTimeUs μs',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.successColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final isValid = primeCount == 78498;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'Primes Found',
                  style: TextStyle(fontSize: 12, color: Colors.lightBlueAccent),
                ),
                const SizedBox(height: 4),
                Text(
                  '$primeCount',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlueAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isValid
                  ? Colors.green.withOpacity(0.15)
                  : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Validation',
                  style: TextStyle(
                    fontSize: 12,
                    color: isValid
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? AppTheme.successColor : AppTheme.errorColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
