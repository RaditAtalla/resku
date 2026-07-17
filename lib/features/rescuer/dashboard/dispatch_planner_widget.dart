import 'package:flutter/material.dart';
import '../../../../core/models/rescuer_message.dart';
import '../../../../core/utils/design_system.dart';

// Left/Right Panel widget for Rescuer dashboard managing BLE announcements.
class DispatchPlannerWidget extends StatefulWidget {
  final List<RescuerMessage> broadcastLogs;
  final ValueChanged<String> onSendBroadcast;

  const DispatchPlannerWidget({
    super.key,
    required this.broadcastLogs,
    required this.onSendBroadcast,
  });

  @override
  State<DispatchPlannerWidget> createState() => _DispatchPlannerWidgetState();
}

class _DispatchPlannerWidgetState extends State<DispatchPlannerWidget> {
  final _announcementController = TextEditingController();

  void _handleTransmit() {
    final text = _announcementController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendBroadcast(text);
      _announcementController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // CARD 2: BLE Mesh Broadcast Console using ReskuCard
        Expanded(
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

