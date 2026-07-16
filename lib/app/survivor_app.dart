import 'package:flutter/material.dart';
import '../features/survivor/forms/survivor_form_screen.dart';
import '../features/survivor/guide/first_aid_guide_screen.dart';
import '../features/survivor/feed/announcements_screen.dart';

// Survivor Mobile App shell layout and bottom navigation.
class SurvivorApp extends StatefulWidget {
  const SurvivorApp({super.key});

  @override
  State<SurvivorApp> createState() => _SurvivorAppState();
}

class _SurvivorAppState extends State<SurvivorApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SurvivorFormScreen(),
    FirstAidGuideScreen(),
    AnnouncementsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resku Survivor',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_note),
              label: 'Broadcast Status',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services),
              label: 'First Aid Guide',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign),
              label: 'Announcements',
            ),
          ],
        ),
      ),
    );
  }
}
