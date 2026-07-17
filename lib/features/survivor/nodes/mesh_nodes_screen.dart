import 'package:flutter/material.dart';
import '../../../core/database/local_db.dart';
import '../../../core/models/survivor_record.dart';
import '../../../core/utils/design_system.dart';
import '../../../core/network/ble/ble_mesh_manager.dart';

class MeshNodesScreen extends StatefulWidget {
  const MeshNodesScreen({super.key});

  @override
  State<MeshNodesScreen> createState() => _MeshNodesScreenState();
}

class _MeshNodesScreenState extends State<MeshNodesScreen> {
  List<SurvivorRecord> _nodes = [];
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Critical, Injured, Safe
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNodes();
    // Register listener so that as soon as the background sync merges new data, the UI updates
    BleMeshManager().otherDevicesCountNotifier.addListener(_loadNodes);
  }

  @override
  void dispose() {
    BleMeshManager().otherDevicesCountNotifier.removeListener(_loadNodes);
    super.dispose();
  }

  Future<void> _loadNodes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final db = LocalDB();
    final myId = await db.getOrCreateDeviceUUID();
    final all = await db.getAllSurvivors();

    // Filter out our own device's record, keeping only peer nodes
    final otherDevices = all.where((s) => s.id != myId).toList();

    // Sort by timestamp desc (newest first)
    otherDevices.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mounted) {
      setState(() {
        _nodes = otherDevices;
        _isLoading = false;
      });
    }
  }

  List<SurvivorRecord> getFilteredNodes() {
    return _nodes.where((node) {
      final matchesSearch = node.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          node.needs.toLowerCase().contains(_searchQuery.toLowerCase());

      if (_statusFilter == 'All') return matchesSearch;

      final filterString = _statusFilter.toLowerCase();
      final matchesFilter = node.status.name == filterString;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Color _getStatusColor(SurvivorStatus status) {
    switch (status) {
      case SurvivorStatus.safe:
        return AppColors.safe;
      case SurvivorStatus.injured:
        return AppColors.injured;
      case SurvivorStatus.critical:
        return AppColors.critical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNodes = getFilteredNodes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SYNCED MESH NODES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadNodes,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Box
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 12, color: AppColors.black),
                  decoration: const InputDecoration(
                    hintText: 'Search node name or needs...',
                    hintStyle: TextStyle(color: Color(0xFFD0D0D5), fontSize: 11),
                    prefixIcon: Icon(Icons.search, color: AppColors.muted, size: 18),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // 2. Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['All', 'Critical', 'Injured', 'Safe'].map((filter) {
                  final isSelected = _statusFilter == filter;
                  Color pillColor = AppColors.orange;
                  Color textColor = Colors.white;

                  if (filter == 'Critical') pillColor = AppColors.critical;
                  if (filter == 'Injured') pillColor = AppColors.injured;
                  if (filter == 'Safe') pillColor = AppColors.safe;

                  return GestureDetector(
                    onTap: () => setState(() => _statusFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? pillColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? pillColor : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        filter.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? textColor : AppColors.muted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // 3. Nodes List
            Expanded(
              child: _isLoading && _nodes.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                  : filteredNodes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                          itemCount: filteredNodes.length,
                          itemBuilder: (context, index) {
                            final node = filteredNodes[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildNodeCard(node),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeCard(SurvivorRecord node) {
    final statusColor = _getStatusColor(node.status);
    final timeString = DateTime.fromMillisecondsSinceEpoch(node.timestamp)
        .toLocal()
        .toString()
        .substring(11, 16);

    return ReskuCard(
      accentColor: statusColor,
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Name and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                node.name,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    node.batteryPercentage > 50
                        ? Icons.battery_full
                        : node.batteryPercentage > 20
                            ? Icons.battery_charging_full
                            : Icons.battery_alert,
                    size: 10,
                    color: node.batteryPercentage > 50
                        ? AppColors.safe
                        : node.batteryPercentage > 20
                            ? AppColors.injured
                            : AppColors.critical,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${node.batteryPercentage}%',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: node.batteryPercentage > 50
                          ? AppColors.safe
                          : node.batteryPercentage > 20
                              ? AppColors.injured
                              : AppColors.critical,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ReskuBadge(status: node.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Synced Coordinate information
          Row(
            children: [
              const Icon(Icons.my_location, color: AppColors.orange, size: 12),
              const SizedBox(width: 6),
              Text(
                'LAT: ${node.latitude.toStringAsFixed(4)} • LON: ${node.longitude.toStringAsFixed(4)}',
                style: AppTextStyles.monospaceLabel.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Needs tag/details
          if (node.needs.isNotEmpty) ...[
            const Text(
              'REQUESTED RESOURCES:',
              style: TextStyle(
                fontSize: 8,
                color: AppColors.muted,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 3),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: node.needs.split(', ').where((need) => need.trim().isNotEmpty).map((need) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.grayBg,
                    border: Border.all(color: AppColors.border, width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getNeedIcon(need), size: 10, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        need.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: AppColors.muted,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Footer: Timestamp and Sequence
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Synced via Mesh • $timeString',
                style: AppTextStyles.monospaceLabel,
              ),
              Text(
                'SEQ: ${node.sequenceNumber}',
                style: AppTextStyles.monospaceLabel.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getNeedIcon(String need) {
    final lower = need.toLowerCase();
    if (lower.contains('water') || lower.contains('food')) return Icons.local_drink;
    if (lower.contains('medical') || lower.contains('aid') || lower.contains('heal')) return Icons.healing;
    if (lower.contains('shelter') || lower.contains('blanket')) return Icons.home;
    if (lower.contains('tool') || lower.contains('warm')) return Icons.build;
    return Icons.star_border;
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ReskuCard(
          accentColor: AppColors.orange,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.hub_outlined,
                size: 48,
                color: AppColors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'NO MESH DATA DETECTED',
                style: AppTextStyles.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'This device has not established an offline BLE peer connection cycle yet. Once you connect to another Resku node, their location and triage databases will be stored and listed here.',
                style: AppTextStyles.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Please go to the Home tab and tap the Broadcast button to start.'),
                    ),
                  );
                },
                icon: const Icon(Icons.sensors, size: 16),
                label: const Text(
                  'Start Scanning',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
