import 'package:flutter/material.dart';
import 'app/dashboard_app.dart';
import 'core/database/local_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local offline database
  await LocalDB().init();
  
  runApp(const DashboardApp());
}
