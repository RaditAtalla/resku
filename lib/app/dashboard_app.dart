import 'package:flutter/material.dart';
import '../core/utils/design_system.dart';
import '../features/rescuer/dashboard/dashboard_screen.dart';

// Dedicated Rescuer Dashboard root MaterialApp
class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resku Rescuer Dashboard',
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
          shape: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
      ),
      home: const RescuerDashboardScreen(),
    );
  }
}
