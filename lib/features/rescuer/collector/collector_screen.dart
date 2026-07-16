import 'package:flutter/material.dart';
import '../../../core/database/local_db.dart';
import '../../../core/models/survivor_record.dart';
import '../../../core/network/ble/ble_mesh_manager.dart';
import '../../../core/network/server/sync_server.dart';
import '../../../core/utils/design_system.dart';

// Collector UI for field rescuers to scan and gather survivor data, and serve it via local Wi-Fi.
// Refactored to fully support the design system and display the live database feed.
class CollectorScreen extends StatefulWidget {
  const CollectorScreen({super.key});

  @override
  State<CollectorScreen> createState() => _CollectorScreenState();
}

class _CollectorScreenState extends State<CollectorScreen> {
  bool _isServerRunning = false;
  List<SurvivorRecord> _collectedSurvivors = [];

  @override
  void initState() {
    super.initState();
    _isServerRunning = SyncServer().isServerRunning;
    
    // Register listeners for real-time updates from BLE mesh syncing
    BleMeshManager().stateNotifier.addListener(_onMeshStateChanged);
    BleMeshManager().otherDevicesCountNotifier.addListener(_onDevicesCountChanged);
    
    _loadCollectedSurvivors();
  }

  @override
  void dispose() {
    BleMeshManager().stateNotifier.removeListener(_onMeshStateChanged);
    BleMeshManager().otherDevicesCountNotifier.removeListener(_onDevicesCountChanged);
    super.dispose();
  }

  void _onMeshStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onDevicesCountChanged() {
    _loadCollectedSurvivors();
  }

  Future<void> _loadCollectedSurvivors() async {
    final db = LocalDB();
    final all = await db.getAllSurvivors();
    // Exclude the rescuer itself
    final myId = await db.getOrCreateDeviceUUID(isRescuer: true);
    final otherDevices = all.where((s) => s.id != myId).toList();
    
    // Sort: newest first
    otherDevices.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (mounted) {
      setState(() {
        _collectedSurvivors = otherDevices;
      });
    }
  }

  void _toggleCollection() async {
    final manager = BleMeshManager();
    if (manager.state == MeshState.idle) {
      await manager.startMeshCycle(isRescuer: true);
    } else {
      await manager.stopMeshCycle();
    }
    if (mounted) setState(() {});
  }

  void _toggleSyncServer() async {
    final server = SyncServer();
    try {
      if (_isServerRunning) {
        await server.stopServer();
      } else {
        await server.startServer(8080);
      }
      setState(() {
        _isServerRunning = server.isServerRunning;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.critical,
          content: Text('Server Error: Failed to start sync server. $e'),
        ),
      );
    }
  }

  String _getMeshStateLabel(MeshState state) {
    switch (state) {
      case MeshState.idle:
        return 'IDLE';
      case MeshState.searching:
        return 'SEARCHING PEERS';
      case MeshState.broadcasting:
        return 'BROADCASTING NODE';
      case MeshState.receiving:
        return 'RECEIVING DATA';
      case MeshState.connected:
        return 'EXCHANGING PAYLOADS';
      case MeshState.success:
        return 'SYNC SUCCESSFUL';
      case MeshState.waiting:
        final seconds = BleMeshManager().cooldownSecondsNotifier.value;
        return 'COOLDOWN (${seconds}S)';
    }
  }

  Color _getMeshStateColor(MeshState state) {
    switch (state) {
      case MeshState.idle:
        return AppColors.muted;
      case MeshState.searching:
      case MeshState.broadcasting:
        return AppColors.injured;
      case MeshState.receiving:
      case MeshState.connected:
      case MeshState.success:
        return AppColors.safe;
      case MeshState.waiting:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = BleMeshManager();
    final isCollecting = manager.state != MeshState.idle;
    final stateColor = _getMeshStateColor(manager.state);
    final count = _collectedSurvivors.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sensors, color: AppColors.orange, size: 24),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: AppTextStyles.headerLogo,
                children: [
                  TextSpan(text: 'RESKU '),
                  TextSpan(
                    text: 'MULE',
                    style: TextStyle(color: AppColors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            // Display server running badge status in AppBar
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isServerRunning ? AppColors.safeBg : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _isServerRunning ? AppColors.safeBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isServerRunning ? Icons.wifi_tethering : Icons.portable_wifi_off,
                      size: 10,
                      color: _isServerRunning ? AppColors.safe : AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isServerRunning ? 'AP SERVER ON' : 'AP SERVER OFF',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: _isServerRunning ? AppColors.safe : AppColors.muted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Mule explanation block
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'DATA MULE OPERATION MODE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Carry survivor database updates from the field mesh networks. Walk through disaster zones to sync BLE records, then start the AP Server at the Command Post to dump the data to the Tactical Dashboard.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Controls Grid (BLE Collector & Wi-Fi Hotspot Server)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Auto-Collector
                    Expanded(
                      child: ReskuCard(
                        accentColor: AppColors.orange,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.radar, color: AppColors.orange, size: 16),
                                SizedBox(width: 6),
                                Text('AUTO-COLLECTOR', style: AppTextStyles.cardTitle),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Status indicator
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: stateColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getMeshStateLabel(manager.state),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color: stateColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ReskuButton.primary(
                              label: isCollecting ? 'STOP COLLECTING' : 'START COLLECTING',
                              icon: isCollecting ? Icons.stop : Icons.sensors,
                              height: 32,
                              onPressed: _toggleCollection,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Card 2: Hotspot Sync Server
                    Expanded(
                      child: ReskuCard(
                        accentColor: AppColors.black,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.wifi_tethering, color: AppColors.black, size: 16),
                                SizedBox(width: 6),
                                Text('AP SYNC SERVER', style: AppTextStyles.cardTitle),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Status indicator
                            Text(
                              _isServerRunning ? 'IP: 192.168.43.1:8080' : 'SERVER OFFLINE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: _isServerRunning ? AppColors.safe : AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isServerRunning ? AppColors.critical : AppColors.black,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                fixedSize: const Size.fromHeight(32),
                              ),
                              onPressed: _toggleSyncServer,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_isServerRunning ? Icons.portable_wifi_off : Icons.wifi, size: 12),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isServerRunning ? 'STOP SERVER' : 'START SERVER',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Header for Synced database list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FIELD SYNCED RECORDS LOG ($count)',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    if (count > 0)
                      GestureDetector(
                        onTap: _loadCollectedSurvivors,
                        child: const Icon(Icons.refresh, size: 14, color: AppColors.muted),
                      ),
                  ],
                ),
              ),
            ),

            // Database items or empty state
            if (_collectedSurvivors.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.storage, color: AppColors.border, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'NO COLLECTED SURVIVOR RECORDS',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.muted,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Start scanning auto-collector mode to sync databases with survivors connected to the ad-hoc mesh network.',
                          style: AppTextStyles.bodyMuted,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final s = _collectedSurvivors[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildSurvivorCard(s),
                      );
                    },
                    childCount: _collectedSurvivors.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurvivorCard(SurvivorRecord s) {
    Color statusColor;
    switch (s.status) {
      case SurvivorStatus.safe:
        statusColor = AppColors.safe;
        break;
      case SurvivorStatus.injured:
        statusColor = AppColors.injured;
        break;
      case SurvivorStatus.critical:
        statusColor = AppColors.critical;
        break;
    }

    final relativeTime = _formatRelativeTime(s.timestamp);

    return ReskuCard(
      accentColor: statusColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.name, style: AppTextStyles.bodyBold),
              ReskuBadge(status: s.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.orange, size: 12),
              const SizedBox(width: 4),
              Text(
                'LAT: ${s.latitude.toStringAsFixed(4)} • LON: ${s.longitude.toStringAsFixed(4)}',
                style: AppTextStyles.bodyMuted.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'NEEDS: ${s.needs.isNotEmpty ? s.needs : "None reported"}',
            style: AppTextStyles.bodyMuted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Synced $relativeTime',
                style: AppTextStyles.monospaceLabel.copyWith(fontSize: 8),
              ),
              Text(
                'SEQ: ${s.sequenceNumber}',
                style: AppTextStyles.monospaceLabel.copyWith(fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(int ms) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
