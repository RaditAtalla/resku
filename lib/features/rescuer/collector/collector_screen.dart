import 'package:flutter/material.dart';

// Collector UI for field rescuers to scan and gather survivor data, and serve it via local Wi-Fi.
class CollectorScreen extends StatefulWidget {
  const CollectorScreen({super.key});

  @override
  State<CollectorScreen> createState() => _CollectorScreenState();
}

class _CollectorScreenState extends State<CollectorScreen> {
  bool _isCollecting = false;
  bool _isServerRunning = false;
  int _collectedCount = 0;

  void _toggleCollection() {
    setState(() {
      _isCollecting = !_isCollecting;
      if (_isCollecting) {
        _collectedCount = 12; // Mock database updates
      }
    });
  }

  void _toggleSyncServer() {
    setState(() {
      _isServerRunning = !_isServerRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescuer Mobile Collector'),
      ),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24.0),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _isCollecting ? 'Scanning & Syncing Nearby Devices...' : 'Sync Idle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isCollecting ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Total Collected Survivor Records: $_collectedCount'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _toggleCollection,
                      icon: Icon(_isCollecting ? Icons.stop : Icons.sensors),
                      label: Text(_isCollecting ? 'Stop Collection' : 'Start Auto-Collector'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCollecting ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Dashboard Sync Wi-Fi Hotspot Server',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isServerRunning ? 'HTTP Server active on http://192.168.43.1:8080' : 'Sync Server Offline',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _isServerRunning ? Colors.green : Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _toggleSyncServer,
                      icon: Icon(_isServerRunning ? Icons.portable_wifi_off : Icons.wifi_tethering),
                      label: Text(_isServerRunning ? 'Stop Sync Server' : 'Start Hotspot Sync Server'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
