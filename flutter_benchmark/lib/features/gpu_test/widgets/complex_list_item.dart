import 'package:flutter/material.dart';
import '../../../core/constants/benchmark_config.dart';
import '../../../core/theme/app_theme.dart';

/// Complex list item widget designed to stress the GPU rasterizer
class ComplexListItem extends StatelessWidget {
  final int index;
  final int imageIndex;

  const ComplexListItem({
    super.key,
    required this.index,
    required this.imageIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildImageSection(), _buildContentSection()],
      ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [_buildImage(), _buildGradientOverlay(), _buildItemBadge()],
      ),
    );
  }

  Widget _buildImage() {
    return Image.asset(
      BenchmarkConfig.getImagePath(imageIndex),
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_getColor(imageIndex), _getColor((imageIndex + 3) % 10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(
              _getIcon(imageIndex),
              size: 64,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildItemBadge() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '#${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complex Item ${index + 1}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This is a complex list item designed to stress test the GPU rasterizer with shadows, gradients, and multiple layers.',
            style: TextStyle(color: Colors.grey.shade400, height: 1.4),
          ),
          const SizedBox(height: 12),
          _buildTagsRow(),
          const SizedBox(height: 12),
          _buildProgressBar(),
          const SizedBox(height: 12),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTagsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        4,
        (i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getColor((imageIndex + i) % 10).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getColor((imageIndex + i) % 10).withOpacity(0.3),
            ),
          ),
          child: Text(
            'Tag ${i + 1}',
            style: TextStyle(
              color: _getColor((imageIndex + i) % 10),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: (index % 100) / 100,
        backgroundColor: Colors.grey.shade800,
        valueColor: AlwaysStoppedAnimation<Color>(_getColor(imageIndex)),
        minHeight: 6,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border, size: 18),
            label: const Text('Like'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.pink),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ),
      ],
    );
  }

  Color _getColor(int index) {
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  IconData _getIcon(int index) {
    const icons = [
      Icons.image,
      Icons.photo_camera,
      Icons.landscape,
      Icons.beach_access,
      Icons.nature,
      Icons.pets,
      Icons.directions_car,
      Icons.flight,
      Icons.restaurant,
      Icons.sports_soccer,
    ];
    return icons[index % icons.length];
  }
}
