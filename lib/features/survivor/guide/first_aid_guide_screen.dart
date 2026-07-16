import 'package:flutter/material.dart';

// Offline First Aid markdown viewer screen.
class FirstAidGuideScreen extends StatelessWidget {
  const FirstAidGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline First Aid Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              title: Text('1. CPR (Cardiopulmonary Resuscitation)'),
              subtitle: Text('Place hands in center of chest and push hard and fast...'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('2. Bleeding Management'),
              subtitle: Text('Apply direct pressure to the wound with clean cloth...'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('3. Fractures and Splints'),
              subtitle: Text('Do not attempt to realign the bone. Immobilize the limb...'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('4. Severe Burns'),
              subtitle: Text('Cool the burn with cold running water for at least 10 minutes...'),
            ),
          ),
        ],
      ),
    );
  }
}
