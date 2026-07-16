import 'package:flutter/material.dart';
import 'app/survivor_app.dart';
import 'core/database/local_db.dart';
import 'core/network/ble/ble_mesh_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local offline database
  await LocalDB().init();
  
  // Start BLE Ad-Hoc mesh loops
  await BleMeshManager().startMeshCycle();
  
  runApp(const SurvivorApp());
}
