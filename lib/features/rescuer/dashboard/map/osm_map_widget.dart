import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/models/survivor_record.dart';
import '../../../../core/utils/design_system.dart';

// Displays mapped survivor locations on a real interactive OpenStreetMap widget.
class OsmMapWidget extends StatefulWidget {
  final List<SurvivorRecord> survivors;
  final String? focusedSurvivorId;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSurvivorSelected;
  final VoidCallback onRefocusBaseCamp;
  final Set<String> articulationPoints;
  final Map<String, String> nodeToCentroid;

  const OsmMapWidget({
    super.key,
    required this.survivors,
    required this.focusedSurvivorId,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSurvivorSelected,
    required this.onRefocusBaseCamp,
    required this.articulationPoints,
    required this.nodeToCentroid,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> with SingleTickerProviderStateMixin {
  late MapController _mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _searchController = TextEditingController();

  static const double baseCampLat = -6.2100;
  static const double baseCampLng = 106.8475;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController.text = widget.searchQuery;

    // Animation for critical status pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 3.0, end: 12.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant OsmMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }

    if (widget.focusedSurvivorId != oldWidget.focusedSurvivorId && widget.focusedSurvivorId != null) {
      final focusedIndex = widget.survivors.indexWhere((s) => s.id == widget.focusedSurvivorId);
      if (focusedIndex != -1) {
        final focusedSurvivor = widget.survivors[focusedIndex];
        try {
          _mapController.move(LatLng(focusedSurvivor.latitude, focusedSurvivor.longitude), 16.0);
        } catch (e) {
          debugPrint('OsmMapWidget Error: MapController move failed (map likely not ready yet): $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _refocusBaseCamp() {
    _mapController.move(LatLng(baseCampLat, baseCampLng), 15.0);
    widget.onRefocusBaseCamp();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 1. Real Interactive OpenStreetMap Widget
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(baseCampLat, baseCampLng),
                  initialZoom: 15.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.resku.app',
                  ),
                  
                  MarkerLayer(
                    markers: [
                      // Base camp marker with concentric rings
                      Marker(
                        point: const LatLng(baseCampLat, baseCampLng),
                        width: 120.0,
                        height: 120.0,
                        child: IgnorePointer(
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(120, 120),
                                  painter: RingsPainter(),
                                ),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.orange,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: const Icon(Icons.home, color: Colors.white, size: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Survivor markers
                      ...widget.survivors.map((survivor) {
                        final isFocused = survivor.id == widget.focusedSurvivorId;

                        Color pinColor;
                        bool isCritical = survivor.status == SurvivorStatus.critical;
                        switch (survivor.status) {
                          case SurvivorStatus.critical:
                            pinColor = AppColors.critical;
                            break;
                          case SurvivorStatus.injured:
                            pinColor = AppColors.injured;
                            break;
                          case SurvivorStatus.safe:
                            pinColor = AppColors.safe;
                            break;
                        }

                        final isArticulationPoint = widget.articulationPoints.contains(survivor.id);
                        final isCentroid = widget.nodeToCentroid.values.contains(survivor.id) &&
                            widget.nodeToCentroid[survivor.id] == survivor.id;

                        return Marker(
                          point: LatLng(survivor.latitude, survivor.longitude),
                          width: 100.0,
                          height: 70.0,
                          child: GestureDetector(
                            onTap: () => widget.onSurvivorSelected(survivor.id),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isCritical || isArticulationPoint)
                                      AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Container(
                                            width: 14 + _pulseAnimation.value,
                                            height: 14 + _pulseAnimation.value,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: (isArticulationPoint ? AppColors.orange : AppColors.critical).withValues(
                                                alpha: (1.0 - (_pulseAnimation.value / 12.0)).clamp(0.0, 1.0) * 0.5,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: pinColor,
                                        border: Border.all(
                                          color: isFocused
                                              ? AppColors.orange
                                              : isCentroid
                                                  ? Colors.yellowAccent
                                                  : Colors.white,
                                          width: (isFocused || isCentroid) ? 3 : 2,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: isCentroid
                                          ? const Icon(Icons.star, color: Colors.white, size: 8)
                                          : null,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isFocused ? AppColors.orange : AppColors.black,
                                    borderRadius: BorderRadius.circular(4),
                                    border: isCentroid
                                        ? Border.all(color: Colors.yellowAccent, width: 1)
                                        : null,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    '${survivor.name}${isCentroid ? " ✦ HUB" : ""}',
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Search Bar Overlay (Top Left)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                width: 240,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.muted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: widget.onSearchChanged,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.black,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search survivors by name...',
                          hintStyle: TextStyle(
                            color: Color(0x996D6D78),
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Map Controls Overlay (Top Right)
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Refocus Button
                  GestureDetector(
                    onTap: _refocusBaseCamp,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.center_focus_strong,
                        color: AppColors.black,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Legend Card
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Critical', AppColors.critical),
                        const SizedBox(height: 4),
                        _buildLegendItem('Injured', AppColors.injured),
                        const SizedBox(height: 4),
                        _buildLegendItem('Safe', AppColors.safe),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.muted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Custom Painter for drawing concentric rings from center base camp
class RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, 25.0, paint);
    canvas.drawCircle(center, 50.0, paint);

    final outerPaint = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 80.0, outerPaint);
  }

  @override
  bool shouldRepaint(covariant RingsPainter oldDelegate) => false;
}
