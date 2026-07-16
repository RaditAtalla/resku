import 'package:flutter/material.dart';
import '../../../../core/models/survivor_record.dart';
import '../../../../core/utils/design_system.dart';

// Displays mapped survivor locations on a tactical offline grid canvas.
class OsmMapWidget extends StatefulWidget {
  final List<SurvivorRecord> survivors;
  final String? focusedSurvivorId;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSurvivorSelected;
  final VoidCallback onRefocusBaseCamp;

  const OsmMapWidget({
    super.key,
    required this.survivors,
    required this.focusedSurvivorId,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSurvivorSelected,
    required this.onRefocusBaseCamp,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _searchController = TextEditingController();

  // Grid Coordinate range bounds (from HTML mockup)
  final double _minLat = -6.2050;
  final double _maxLat = -6.2150;
  final double _minLng = 106.8400;
  final double _maxLng = 106.8550;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Calculate pixel positions from GPS coordinates
  Offset _getRelativePosition(double lat, double lng, double width, double height) {
    // Interpolate latitude: minLat is 0% (top), maxLat is 100% (bottom)
    double latPct = (lat - _minLat) / (_maxLat - _minLat);
    // Clamp to 5% to 95% to avoid borders
    latPct = latPct.clamp(0.05, 0.95);
    double y = latPct * height;

    // Interpolate longitude: minLng is 0% (left), maxLng is 100% (right)
    double lngPct = (lng - _minLng) / (_maxLng - _minLng);
    // Clamp to 5% to 95%
    lngPct = lngPct.clamp(0.05, 0.95);
    double x = lngPct * width;

    return Offset(x, y);
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
            // 1. Tactical Offline Canvas (Light grey background)
            Positioned.fill(
              child: Container(color: const Color(0xFFE9E9ED)),
            ),

            // 2. Custom Grid Lines (Clean Strava Grid)
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),

            // 3. Base Camp Concentric Rings (Concentric Circles at Center)
            Positioned.fill(
              child: Center(
                child: CustomPaint(
                  painter: RingsPainter(),
                ),
              ),
            ),

            // 4. Coordinates Label HUD (Bottom Left)
            Positioned(
              bottom: 12,
              left: 12,
              child: IgnorePointer(
                child: Text(
                  'LAT: ${_minLat.toStringAsFixed(4)} TO ${_maxLat.toStringAsFixed(4)}\nLNG: ${_minLng.toStringAsFixed(4)} TO ${_maxLng.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: AppColors.muted,
                    height: 1.3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 5. Dynamic Survivor Pin Markers
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  return Stack(
                    children: widget.survivors.map((survivor) {
                      final offset = _getRelativePosition(
                        survivor.latitude,
                        survivor.longitude,
                        width,
                        height,
                      );

                      final isFocused = survivor.id == widget.focusedSurvivorId;

                      // Color based on status
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

                      return Positioned(
                        left: offset.dx - 40, // offset half width of tooltip/container
                        top: offset.dy - 20,  // offset slightly upward
                        width: 80,
                        height: 55,
                        child: GestureDetector(
                          onTap: () => widget.onSurvivorSelected(survivor.id),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pulsing effect or highlight ring
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (isCritical)
                                    AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          width: 14 + _pulseAnimation.value,
                                          height: 14 + _pulseAnimation.value,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.critical.withAlpha(
                                              (((1.0 - (_pulseAnimation.value / 12.0)).clamp(0.0, 1.0)) * 255).toInt(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  // Pin dot
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: pinColor,
                                      border: Border.all(
                                        color: isFocused ? AppColors.orange : Colors.white,
                                        width: isFocused ? 3 : 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Name Label tooltip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isFocused ? AppColors.orange : AppColors.black,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    )
                                  ],
                                ),
                                child: Text(
                                  survivor.name,
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
                    }).toList(),
                  );
                },
              ),
            ),

            // 6. Search Bar Overlay (Top Left)
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

            // 7. Map Controls Overlay (Top Right)
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Refocus Button
                  GestureDetector(
                    onTap: widget.onRefocusBaseCamp,
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

// Custom Painter for drawing the 40px grid lines
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66DFDFE5)
      ..strokeWidth = 1.0;

    const double step = 40.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => false;
}

// Custom Painter for drawing concentric rings from center base camp
class RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xB2D1D1D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);

    // Concenctric ring sizes matching the HTML style (adjusted for screen bounds)
    canvas.drawCircle(center, 60.0, paint);
    canvas.drawCircle(center, 130.0, paint);
    
    // Outer dashed/faded ring
    final outerPaint = Paint()
      ..color = const Color(0x66D1D1D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 210.0, outerPaint);
  }

  @override
  bool shouldRepaint(covariant RingsPainter oldDelegate) => false;
}
