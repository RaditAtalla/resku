import 'package:flutter/material.dart';

// Displays mapped survivor locations using OpenStreetMap via flutter_map.
class OsmMapWidget extends StatelessWidget {
  const OsmMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey[100],
      child: Stack(
        children: [
          // OpenStreetMap placeholder
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 48, color: Colors.blueGrey),
                SizedBox(height: 8),
                Text('[Offline Map Canvas - OpenStreetMap Placeholder]'),
              ],
            ),
          ),
          // Floating Controls
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  onPressed: () {},
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
