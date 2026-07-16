import 'package:flutter/material.dart';

// Left/Right Panel widget for Rescuer dashboard managing AI plan and announcements.
class AiPlannerWidget extends StatefulWidget {
  const AiPlannerWidget({super.key});

  @override
  State<AiPlannerWidget> createState() => _AiPlannerWidgetState();
}

class _AiPlannerWidgetState extends State<AiPlannerWidget> {
  final _announcementController = TextEditingController();

  void _sendBroadcast() {
    if (_announcementController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Injected announcement into sync database: "${_announcementController.text}"')),
      );
      _announcementController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'AI Action Planner',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('AI Analysis Summary'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Based on the collected data:\n\n'
                      '1. PRIORITIZE: Survivor "John Doe" at location (-6.2088, 106.8456) due to CRITICAL status requesting medical aid.\n'
                      '2. STAGE 2: Deploy search party to coordinates (-6.2100, 106.8480) for Jane Smith (Injured, needs warmth).\n'
                      '3. RECOMMENDATION: Utilize Drone 1 to drop medical supplies at first target location immediately before team arrival.',
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Rescue Plan'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Broadcast Rescuer Update',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Draft a message to propagate through the mesh network back to all survivor devices.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _announcementController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter update message for survivors...',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _sendBroadcast,
            icon: const Icon(Icons.send),
            label: const Text('Broadcast to Mesh'),
          ),
        ],
      ),
    );
  }
}
