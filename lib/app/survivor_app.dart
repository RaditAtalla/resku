import 'package:flutter/material.dart';
import '../core/utils/design_system.dart';
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.orange,
          primary: AppColors.orange,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.grayBg,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.black,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.black,
            letterSpacing: -0.5,
          ),
          shape: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.orange,
            unselectedItemColor: AppColors.muted,
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.normal,
              fontSize: 10,
            ),
            currentIndex: _currentIndex,
            elevation: 0,
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
      ),
    );
  }
}
