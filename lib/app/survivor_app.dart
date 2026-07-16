import 'package:flutter/material.dart';
import '../features/survivor/forms/survivor_form_screen.dart';
import '../features/survivor/guide/first_aid_guide_screen.dart';

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
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resku Survivor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
          brightness: Brightness.dark,
          primary: Colors.redAccent,
          surface: const Color(0xFF1E1E2C),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F15),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F15),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFF1E1E2C),
          selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.grey.shade500,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              activeIcon: Icon(Icons.medical_services),
              label: 'First Aid',
            ),
          ],
        ),
      ),
    );
  }
}
