import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/rescuer/collector/collector_screen.dart';
import '../features/rescuer/dashboard/dashboard_screen.dart';

// Rescuer App shell that dynamically switches layouts.
// Mobile displays the Collector Screen, while Web/Desktop displays the Command Dashboard.
class RescuerApp extends StatelessWidget {
  const RescuerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resku Rescuer',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
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
