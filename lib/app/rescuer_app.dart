import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/rescuer/collector/collector_screen.dart';
import '../features/rescuer/dashboard/dashboard_screen.dart';

import '../core/utils/design_system.dart';

// Rescuer App shell that dynamically switches layouts.
// Mobile displays the Collector Screen, while Web/Desktop displays the Command Dashboard.
class RescuerApp extends StatelessWidget {
  const RescuerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resku Rescuer',
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
      home: const RescuerHomeGatekeeper(),
    );
  }
}

class RescuerHomeGatekeeper extends StatelessWidget {
  const RescuerHomeGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    // If running on web, macOS, Windows, or Linux, present the full desktop dashboard.
    // Otherwise (iOS/Android), present the mobile data collector.
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return const RescuerDashboardScreen();
    }
    
    return const CollectorScreen();
  }
}
