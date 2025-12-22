# Benchmark Test Images

This folder is reserved for high-resolution test images.

## Adding Images

To add actual images for more realistic GPU stress testing:

1. Add 10 JPEG images named `img_0.jpg` through `img_9.jpg`
2. Recommended resolution: 1080x1920 or higher
3. Use diverse, colorful images for varied rendering workload

## Current Implementation

The current implementation uses **gradient placeholders** instead of actual images.
This provides consistent, reproducible testing without requiring external assets.

The gradient implementation still effectively stresses:

- GPU shader pipeline
- Memory allocation for complex widgets
- Compositing layers with shadows and overlays
