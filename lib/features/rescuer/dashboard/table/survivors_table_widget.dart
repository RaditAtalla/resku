import 'package:flutter/material.dart';
import '../../../../core/models/survivor_record.dart';
import '../../../../core/utils/design_system.dart';

// Table view displaying all discovered survivors in a list.
class SurvivorsTableWidget extends StatelessWidget {
  final List<SurvivorRecord> survivors;
  final List<SurvivorRecord> filteredSurvivors;
  final String triageFilter;
  final String? focusedSurvivorId;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSurvivorSelected;

  const SurvivorsTableWidget({
    super.key,
    required this.survivors,
    required this.filteredSurvivors,
    required this.triageFilter,
    required this.focusedSurvivorId,
    required this.onFilterChanged,
    required this.onSurvivorSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Leverage the ReskuCard wrapper from the Design System
    return ReskuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title, Count Badge, and Filter Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title and Count Badge
              Row(
                children: [
                  const Text(
                    'Survivor Database',
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.grayBg,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${filteredSurvivors.length} Records Found',
                      style: AppTextStyles.monospaceLabel.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Filter chips (All, Critical, Injured, Safe)
              Row(
                children: [
                  _buildFilterChip('all', 'All', AppColors.orange),
                  const SizedBox(width: 6),
                  _buildFilterChip('critical', 'Critical', AppColors.critical),
                  const SizedBox(width: 6),
                  _buildFilterChip('injured', 'Injured', AppColors.injured),
                  const SizedBox(width: 6),
                  _buildFilterChip('safe', 'Safe', AppColors.safe),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable Table Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Sticky table header row
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.grayBg,
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'NAME',
                              style: AppTextStyles.bodyMuted,
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Text(
                              'TRIAGE STATUS',
                              style: AppTextStyles.bodyMuted,
                            ),
                          ),
                          const Expanded(
                            flex: 4,
                            child: Text(
                              'PRIMARY NEEDS',
                              style: AppTextStyles.bodyMuted,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'COORDINATES',
                              textAlign: TextAlign.right,
                              style: AppTextStyles.bodyMuted,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'TIMESTAMP',
                              textAlign: TextAlign.right,
                              style: AppTextStyles.bodyMuted,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'ACTION',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Roster rows
                    if (filteredSurvivors.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No records match the current filters.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filteredSurvivors.map((survivor) {
                        final isFocused = survivor.id == focusedSurvivorId;
                        return Container(
                          decoration: BoxDecoration(
                            color: isFocused
                                ? const Color(0x0FFC5200) // ~6% opacity Strava Orange
                                : Colors.white,
                            border: const Border(
                              bottom: BorderSide(color: AppColors.border),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              // Name
                              Expanded(
                                flex: 3,
                                child: Text(
                                  survivor.name,
                                  style: AppTextStyles.bodyBold,
                                ),
                              ),

                              // Triage Status
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ReskuBadge(status: survivor.status),
                                ),
                              ),

                              // Needs
                              Expanded(
                                flex: 4,
                                child: Text(
                                  survivor.needs,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyRegular.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),

                              // Coordinates
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '${survivor.latitude.toStringAsFixed(4)}, ${survivor.longitude.toStringAsFixed(4)}',
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.monospaceLabel,
                                ),
                              ),

                              // Timestamp
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatTime(survivor.timestamp),
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.monospaceLabel,
                                ),
                              ),

                              // Locate button
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    height: 26,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: isFocused
                                              ? AppColors.orange
                                              : AppColors.border,
                                        ),
                                        backgroundColor: isFocused
                                            ? AppColors.orange
                                            : Colors.white,
                                        foregroundColor: isFocused
                                            ? Colors.white
                                            : AppColors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      onPressed: () {
                                        onSurvivorSelected(survivor.id);
                                      },
                                      child: const Text(
                                        'Locate',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = triageFilter == value;
    
    // Determine colors
    Color bg, border, text;
    if (isSelected) {
      bg = color;
      border = color;
      text = Colors.white;
    } else {
      bg = Colors.white;
      border = AppColors.border;
      text = value == 'all' ? AppColors.black : color;
    }

    return GestureDetector(
      onTap: () => onFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  String _formatTime(int ms) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
