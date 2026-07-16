import 'package:flutter/material.dart';
import 'app/rescuer_app.dart';
import 'core/database/local_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local database
  await LocalDB().init();
  
  runApp(const RescuerApp());
}
