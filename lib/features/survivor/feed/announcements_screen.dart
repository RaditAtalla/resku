import 'package:flutter/material.dart';

// View feed of status updates propagated from rescuers down into the ad-hoc mesh.
class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescuer Announcements'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            color: Colors.blueAccent,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update: Evacuation Camp Active',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'An evac center is open at the North Sports Field. Helicopter drops planned for food and fresh water.',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text('Received: 10 mins ago (via mesh)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
