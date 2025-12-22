import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/metric_card.dart';

/// Panel displaying GPU test results after completion
class ResultsPanel extends StatelessWidget {
  final int totalFrameCount;
  final int droppedFrameCount;
  final double averageFrameTimeUs;
  final int maxFrameTimeUs;
  final String? batteryDelta;

  const ResultsPanel({
    super.key,
    required this.totalFrameCount,
    required this.droppedFrameCount,
    required this.averageFrameTimeUs,
    required this.maxFrameTimeUs,
    this.batteryDelta,
  });

  double get jankPercentage => totalFrameCount > 0
      ? (droppedFrameCount / totalFrameCount) * 100
      : 0;

  double get estimatedFps => averageFrameTimeUs > 0
      ? 1000000 / averageFrameTimeUs
      : 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(),
          _buildFrameMetrics(),
          const SizedBox(height: 8),
          _buildPerformanceMetrics(),
          const SizedBox(height: 8),
          _buildTimingMetrics(),
          const SizedBox(height: 8),
          MetricCard(
            label: 'Battery Drain',
            value: batteryDelta ?? 'N/A',
            icon: Icons.battery_alert,
            color: AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppTheme.successColor),
        const SizedBox(width: 8),
        const Text(
          'Test Completed',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFrameMetrics() {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            label: 'Total Frames',
            value: '$totalFrameCount',
            icon: Icons.grid_view,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: MetricCard(
            label: 'Dropped Frames',
            value: '$droppedFrameCount',
            icon: Icons.warning,
            color: droppedFrameCount > 0 ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            label: 'Jank Rate',
            value: '${jankPercentage.toStringAsFixed(1)}%',
            icon: Icons.speed,
            color: jankPercentage > 5 ? AppTheme.errorColor : Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: MetricCard(
            label: 'Est. FPS',
            value: estimatedFps.toStringAsFixed(1),
            icon: Icons.timer,
            color: estimatedFps >= 55 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildTimingMetrics() {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            label: 'Avg Frame',
            value: '${(averageFrameTimeUs / 1000).toStringAsFixed(2)} ms',
            icon: Icons.analytics,
            color: AppTheme.gpuTestColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: MetricCard(
            label: 'Max Frame',
            value: '${(maxFrameTimeUs / 1000).toStringAsFixed(2)} ms',
            icon: Icons.trending_up,
            color: maxFrameTimeUs > 33333 ? AppTheme.errorColor : Colors.blue,
          ),
        ),
      ],
    );
  }
}
