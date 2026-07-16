import 'package:flutter/material.dart';
import '../../../../core/models/survivor_record.dart';
import '../../../../core/models/rescuer_message.dart';
import '../../../../core/utils/design_system.dart';
import '../../../../core/utils/heuristic_engine.dart';

// Left/Right Panel widget for Rescuer dashboard managing AI plan and announcements.
class AiPlannerWidget extends StatefulWidget {
  final List<SurvivorRecord> survivors;
  final bool isAiLoading;
  final List<SurvivorRecord> aiPlan;
  final List<RescuerMessage> broadcastLogs;
  final VoidCallback onGeneratePlan;
  final ValueChanged<String> onDeployRescueUnit;
  final ValueChanged<String> onSendBroadcast;

  const AiPlannerWidget({
    super.key,
    required this.survivors,
    required this.isAiLoading,
    required this.aiPlan,
    required this.broadcastLogs,
    required this.onGeneratePlan,
    required this.onDeployRescueUnit,
    required this.onSendBroadcast,
  });

  @override
  State<AiPlannerWidget> createState() => _AiPlannerWidgetState();
}

class _AiPlannerWidgetState extends State<AiPlannerWidget> {
  final _announcementController = TextEditingController();

  void _handleTransmit() {
    final text = _announcementController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendBroadcast(text);
      _announcementController.clear();
    }
  }

  int _calculateTriageScore(SurvivorRecord s) {
    return HeuristicEngine.calculateTriageScore(s);
  }

  double _calculateDistance(SurvivorRecord s) {
    return HeuristicEngine.calculateDistanceFromBaseCamp(s.latitude, s.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // CARD 1: AI Action Planner Card using ReskuCard
        Expanded(
          flex: 3,
          child: ReskuCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.psychology, color: AppColors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'AI Priority Rescue Plan',
                          style: AppTextStyles.cardTitle,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.grayBg,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TRIAGE SCORE',
                        style: AppTextStyles.monospaceLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Generate Button using ReskuButton
                ReskuButton.primary(
                  label: 'Generate Rescue Priority',
                  icon: Icons.auto_awesome,
                  onPressed: widget.onGeneratePlan,
                ),
                const SizedBox(height: 12),

                // AI Results / Loading / Empty State Area
                Expanded(
                  child: widget.isAiLoading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.orange,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Calculating priority queue using rule-based Heuristics...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 9,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : widget.aiPlan.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.construction, color: AppColors.muted, size: 32),
                                SizedBox(height: 8),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'Calculate dispatch queue priority based on triage urgency, location distance, and time elapsed.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Scrollbar(
                              child: ListView.separated(
                                padding: const EdgeInsets.only(right: 4),
                                itemCount: widget.aiPlan.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final s = widget.aiPlan[index];
                                  final score = _calculateTriageScore(s);
                                  final dist = _calculateDistance(s);
                                  
                                  // Color for left accent bar and score text
                                  Color statusColor;
                                  switch (s.status) {
                                    case SurvivorStatus.critical:
                                      statusColor = AppColors.critical;
                                      break;
                                    case SurvivorStatus.injured:
                                      statusColor = AppColors.injured;
                                      break;
                                    case SurvivorStatus.safe:
                                      statusColor = AppColors.safe;
                                      break;
                                  }

                                  return ReskuCard(
                                    accentColor: statusColor,
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              s.name,
                                              style: AppTextStyles.bodyBold,
                                            ),
                                            Text(
                                              '$score',
                                              style: AppTextStyles.monospaceBold.copyWith(
                                                color: statusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Dist: ${dist.toStringAsFixed(1)}km • Needs: ${s.needs.substring(0, s.needs.length > 20 ? 20 : s.needs.length)}...',
                                              style: AppTextStyles.bodyMuted.copyWith(fontFamily: 'monospace'),
                                            ),
                                            const Text(
                                              'TRIAGE SCORE',
                                              style: AppTextStyles.monospaceLabel,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        if (s.status == SurvivorStatus.critical)
                                          ReskuButton.primary(
                                            label: 'Deploy Rescue Unit',
                                            icon: Icons.flight_takeoff,
                                            height: 28,
                                            onPressed: () => widget.onDeployRescueUnit(s.id),
                                          )
                                        else
                                          ReskuButton.outlined(
                                            label: 'Deploy Rescue Unit',
                                            icon: Icons.flight_takeoff,
                                            height: 28,
                                            onPressed: () => widget.onDeployRescueUnit(s.id),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // CARD 2: BLE Mesh Broadcast Console using ReskuCard
        Expanded(
          flex: 2,
          child: ReskuCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Header
                Row(
                  children: const [
                    Icon(Icons.campaign, color: AppColors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'BLE Mesh Broadcast Console',
                      style: AppTextStyles.cardTitle,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Announcements will propagate dynamically through ad-hoc mobile networks.',
                  style: TextStyle(color: AppColors.muted, fontSize: 10, height: 1.3),
                ),
                const SizedBox(height: 10),

                // Text Input Area using ReskuTextField
                Expanded(
                  child: ReskuTextField(
                    controller: _announcementController,
                    hintText: 'Enter broadcast message (e.g., Evacuation post set up at Sector 7...)',
                    maxCount: 160,
                  ),
                ),
                const SizedBox(height: 10),

                // Transmit button using ReskuButton
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _announcementController,
                  builder: (context, value, child) {
                    final text = value.text.trim();
                    final isOverLimit = value.text.length > 160;
                    return ReskuButton.secondary(
                      label: 'Transmit to BLE Mesh',
                      icon: Icons.rss_feed,
                      onPressed: (text.isEmpty || isOverLimit) ? null : _handleTransmit,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
