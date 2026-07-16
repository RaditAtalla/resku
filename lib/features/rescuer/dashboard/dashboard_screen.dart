import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/database/local_db.dart';
import '../../../core/models/survivor_record.dart';
import '../../../core/models/rescuer_message.dart';
import '../../../core/utils/design_system.dart';
import '../../../core/utils/heuristic_engine.dart';
import 'map/osm_map_widget.dart';
import 'table/survivors_table_widget.dart';
import 'ai/ai_planner_widget.dart';

// Central Rescuer Dashboard UI for Desktop / Web.
// Refactored to leverage the unified design system.
class RescuerDashboardScreen extends StatefulWidget {
  const RescuerDashboardScreen({super.key});

  @override
  State<RescuerDashboardScreen> createState() => _RescuerDashboardScreenState();
}

class _RescuerDashboardScreenState extends State<RescuerDashboardScreen> {
  // Global States
  List<SurvivorRecord> _survivors = [];
  String _searchQuery = '';
  String _triageFilter = 'all';
  bool _isAiLoading = false;
  List<SurvivorRecord> _aiPlan = [];
  String? _focusedSurvivorId;
  
  // Toast notifications state
  String? _toastText;
  IconData _toastIcon = Icons.sensors;
  bool _showToast = false;
  Timer? _toastTimer;

  // Realtime clock
  String _systemTime = '18:20';
  Timer? _clockTimer;

  // Broadcast Logs
  final List<RescuerMessage> _broadcastLogs = [];
  
  @override
  void initState() {
    super.initState();
    _loadSurvivorsFromDb();
    _loadBroadcastLogs();
    _startClock();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSurvivorsFromDb() async {
    final db = LocalDB();
    final list = await db.getAllSurvivors();
    if (mounted) {
      setState(() {
        _survivors = list;
      });
    }
  }

  Future<void> _loadBroadcastLogs() async {
    final db = LocalDB();
    final list = await db.getAllRescuerMessages();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (mounted) {
      setState(() {
        _broadcastLogs.clear();
        _broadcastLogs.addAll(list);
        if (_broadcastLogs.isEmpty) {
          final seedMsg = RescuerMessage(
            id: 'ann-1',
            message: 'An evac center is open at the North Sports Field. Helicopter drops planned for food and fresh water.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
          );
          _broadcastLogs.add(seedMsg);
          db.saveRescuerMessage(seedMsg);
        }
      });
    }
  }

  void _startClock() {
    _updateClockTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateClockTime();
    });
  }

  void _updateClockTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        _systemTime = '$hour:$minute';
      });
    }
  }

  // Toast helper
  void triggerToast(String text, IconData icon) {
    _toastTimer?.cancel();
    setState(() {
      _toastText = text;
      _toastIcon = icon;
      _showToast = true;
    });

    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showToast = false;
        });
      }
    });
  }

  // Handle Search Query
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  // Handle Triage Filter
  void _onFilterChanged(String filter) {
    setState(() {
      _triageFilter = filter;
    });
  }

  // Get survivors list with search and triage filters applied
  List<SurvivorRecord> getFilteredSurvivors() {
    return _survivors.where((s) {
      final matchesSearch = s.name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final filterString = _triageFilter.toLowerCase();
      bool matchesFilter = true;
      if (filterString != 'all') {
        matchesFilter = s.status.name == filterString;
      }
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  // Focus a survivor and open modal
  void _focusSurvivor(String id) {
    setState(() {
      _focusedSurvivorId = id;
    });
  }

  // Refocus map on base camp
  void _refocusBaseCamp() {
    triggerToast('Map coordinates refocused onto base camp', Icons.my_location);
  }

  // Generate AI Prioritization
  void _generateAiPlan() {
    setState(() {
      _isAiLoading = true;
    });

    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      final prioritizedQueue = HeuristicEngine.sortDispatchQueue(_survivors);

      setState(() {
        _aiPlan = prioritizedQueue;
        _isAiLoading = false;
      });

      triggerToast('AI Optimal Rescue Schedule Calculated!', Icons.auto_awesome);
    });
  }

  // Deploy Team (Marks survivor as safe, triggers toast, updates list)
  void _deployRescueUnit(String id) {
    final survivorIndex = _survivors.indexWhere((s) => s.id == id);
    if (survivorIndex == -1) return;

    final survivor = _survivors[survivorIndex];
    triggerToast('Rescue unit dispatched to locate ${survivor.name}', Icons.flight_takeoff);

    final updated = SurvivorRecord(
      id: survivor.id,
      name: survivor.name,
      latitude: survivor.latitude,
      longitude: survivor.longitude,
      status: SurvivorStatus.safe,
      needs: 'None (Rescue unit arrived)',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sequenceNumber: survivor.sequenceNumber + 1,
    );

    setState(() {
      _survivors[survivorIndex] = updated;
      _aiPlan.removeWhere((s) => s.id == id);
      _focusedSurvivorId = null;
    });

    LocalDB().saveSurvivorRecord(updated);
  }

  // Send Broadcast Message
  void _sendBroadcast(String message) {
    if (message.trim().isEmpty) return;

    final newMessage = RescuerMessage(
      id: 'ann-${DateTime.now().millisecondsSinceEpoch}',
      message: message,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _broadcastLogs.insert(0, newMessage);
    });

    LocalDB().saveRescuerMessage(newMessage);
    triggerToast('Announcement broadcasted to BLE mesh network!', Icons.rss_feed);
  }

  // Tactical Glassmorphic Sync Dialog to pull databases from Data Mule
  void _showMuleSyncDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        final addressController = TextEditingController(text: 'http://192.168.43.1:8080');
        String status = 'READY'; // READY, CONNECTING, SYNCHRONIZING, SUCCESS, ERROR
        String details = 'Connect to the mobile mule\'s Wi-Fi hotspot and trigger harvest sync.';
        int retrievedCount = 0;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isLoading = status == 'CONNECTING' || status == 'SYNCHRONIZING';
            Color statusColor = AppColors.muted;
            if (status == 'CONNECTING' || status == 'SYNCHRONIZING') statusColor = AppColors.injured;
            if (status == 'SUCCESS') statusColor = AppColors.safe;
            if (status == 'ERROR') statusColor = AppColors.critical;

            void runSync() async {
              setDialogState(() {
                status = 'CONNECTING';
                details = 'Attempting to handshake with mobile sync server...';
              });

              try {
                final url = addressController.text.trim();
                final uri = Uri.parse(url.endsWith('/') ? '${url}api/sync' : '$url/api/sync');
                
                final response = await http.get(uri).timeout(const Duration(seconds: 10));
                
                if (response.statusCode == 200) {
                  setDialogState(() {
                    status = 'SYNCHRONIZING';
                    details = 'Downloading and merging survivor databases...';
                  });

                  final List<dynamic> recordsJson = jsonDecode(response.body);
                  retrievedCount = recordsJson.length;
                  
                  final db = LocalDB();
                  for (var item in recordsJson) {
                    final record = SurvivorRecord.fromMap(Map<String, dynamic>.from(item));
                    await db.saveSurvivorRecord(record);
                  }

                  // Reload dashboard data
                  await _loadSurvivorsFromDb();

                  setDialogState(() {
                    status = 'SUCCESS';
                    details = 'Database synchronization complete. $retrievedCount records integrated.';
                  });

                  triggerToast('Successfully synced $retrievedCount records from Data Mule!', Icons.cloud_download);
                } else {
                  throw Exception('HTTP Error ${response.statusCode}');
                }
              } catch (e) {
                setDialogState(() {
                  status = 'ERROR';
                  details = 'Sync failed: $e\n\nEnsure:\n1. Your device is connected to the Rescuer Mobile Hotspot.\n2. The Hotspot Sync Server is active on the mobile app.\n3. The Server URL matches exactly.';
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ReskuCard(
                  accentColor: statusColor,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.hub_outlined, color: AppColors.orange, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'MULE SYNC MANAGER',
                                style: AppTextStyles.cardTitle,
                              ),
                            ],
                          ),
                          if (!isLoading)
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.close, color: AppColors.muted, size: 18),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Text Input
                      const Text(
                        'DATA MULE API ENDPOINT:',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.muted,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.grayBg,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: addressController,
                          enabled: !isLoading,
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.black),
                          decoration: const InputDecoration(
                            hintText: 'http://192.168.43.1:8080',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Status Area
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.grayBg,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'SYNC STATUS:',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              details,
                              style: const TextStyle(
                                fontSize: 10,
                                height: 1.35,
                                color: AppColors.muted,
                              ),
                            ),
                            if (isLoading) ...[
                              const SizedBox(height: 10),
                              const LinearProgressIndicator(
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: isLoading ? null : () => Navigator.pop(context),
                              child: const Text(
                                'Dismiss',
                                style: TextStyle(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: isLoading ? null : runSync,
                              child: const Text(
                                'HARVEST SYNC',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final filteredList = getFilteredSurvivors();
    
    // Find focused survivor record
    final SurvivorRecord? focusedSurvivor = _focusedSurvivorId != null
        ? _survivors.firstWhere((s) => s.id == _focusedSurvivorId, orElse: () => _survivors.first)
        : null;

    return Scaffold(
      appBar: AppBar(
        // Custom Strava branding
        title: Row(
          children: [
            const Icon(Icons.sensors, color: AppColors.orange, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: AppTextStyles.headerLogo,
                    children: [
                      TextSpan(text: 'RESKU '),
                      TextSpan(
                        text: 'COMMAND',
                        style: TextStyle(color: AppColors.orange),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Base Post Tactical Dashboard • Sector: Alpha-7',
                  style: AppTextStyles.headerSubtitle,
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Mule Sync Action Button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: ReskuButton.outlined(
                label: 'SYNC MULE',
                icon: Icons.sync,
                height: 28,
                onPressed: _showMuleSyncDialog,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.systemTime,
                  children: [
                    const TextSpan(text: 'System Time: '),
                    TextSpan(
                      text: _systemTime,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Body
          Positioned.fill(
            child: isDesktop
                ? _buildDesktopLayout(filteredList)
                : _buildMobileLayout(filteredList),
          ),
          
          // Toast Notification Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: _showToast ? 16 : -80,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showToast ? 1.0 : 0.0,
                child: ReskuToast(
                  text: _toastText ?? '',
                  icon: _toastIcon,
                ),
              ),
            ),
          ),

          // Detail Modal Overlay using Design System
          if (focusedSurvivor != null)
            Positioned.fill(
              child: ReskuModal(
                name: focusedSurvivor.name,
                status: focusedSurvivor.status,
                lastUpdate: _formatTime(focusedSurvivor.timestamp),
                coordinates: '${focusedSurvivor.latitude.toStringAsFixed(4)}, ${focusedSurvivor.longitude.toStringAsFixed(4)}',
                needs: focusedSurvivor.needs,
                onDismiss: () {
                  setState(() {
                    _focusedSurvivorId = null;
                  });
                },
                onDeploy: () {
                  _deployRescueUnit(focusedSurvivor.id);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(List<SurvivorRecord> filteredList) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel (Map & Table)
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: OsmMapWidget(
                    survivors: filteredList,
                    focusedSurvivorId: _focusedSurvivorId,
                    searchQuery: _searchQuery,
                    onSearchChanged: _onSearchChanged,
                    onSurvivorSelected: _focusSurvivor,
                    onRefocusBaseCamp: _refocusBaseCamp,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 2,
                  child: SurvivorsTableWidget(
                    survivors: _survivors,
                    filteredSurvivors: filteredList,
                    triageFilter: _triageFilter,
                    focusedSurvivorId: _focusedSurvivorId,
                    onFilterChanged: _onFilterChanged,
                    onSurvivorSelected: _focusSurvivor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Panel (AI Decision Hub & Broadcast Control)
          SizedBox(
            width: 360,
            child: AiPlannerWidget(
              survivors: _survivors,
              isAiLoading: _isAiLoading,
              aiPlan: _aiPlan,
              broadcastLogs: _broadcastLogs,
              onGeneratePlan: _generateAiPlan,
              onDeployRescueUnit: _deployRescueUnit,
              onSendBroadcast: _sendBroadcast,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(List<SurvivorRecord> filteredList) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: AppColors.orange,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.orange,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(icon: Icon(Icons.map), text: 'Map'),
                Tab(icon: Icon(Icons.list), text: 'Survivors'),
                Tab(icon: Icon(Icons.psychology), text: 'AI Plan'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OsmMapWidget(
                    survivors: filteredList,
                    focusedSurvivorId: _focusedSurvivorId,
                    searchQuery: _searchQuery,
                    onSearchChanged: _onSearchChanged,
                    onSurvivorSelected: _focusSurvivor,
                    onRefocusBaseCamp: _refocusBaseCamp,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SurvivorsTableWidget(
                    survivors: _survivors,
                    filteredSurvivors: filteredList,
                    triageFilter: _triageFilter,
                    focusedSurvivorId: _focusedSurvivorId,
                    onFilterChanged: _onFilterChanged,
                    onSurvivorSelected: _focusSurvivor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AiPlannerWidget(
                    survivors: _survivors,
                    isAiLoading: _isAiLoading,
                    aiPlan: _aiPlan,
                    broadcastLogs: _broadcastLogs,
                    onGeneratePlan: _generateAiPlan,
                    onDeployRescueUnit: _deployRescueUnit,
                    onSendBroadcast: _sendBroadcast,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    return '${diff.inHours} hours ago';
  }
}
