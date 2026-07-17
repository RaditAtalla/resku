import 'package:flutter/material.dart';
import '../core/utils/design_system.dart';
import '../features/rescuer/collector/collector_screen.dart';

// Dedicated Data Mule root MaterialApp
class MuleApp extends StatelessWidget {
  const MuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resku Data Mule',
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
      home: const CollectorScreen(),
    );
  }
}
