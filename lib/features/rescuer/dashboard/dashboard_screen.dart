import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../../../core/database/local_db.dart';
import '../../../core/models/survivor_record.dart';
import '../../../core/models/rescuer_message.dart';
import '../../../core/models/network_link.dart';
import '../../../core/network/network_analysis_engine.dart';
import '../../../core/utils/design_system.dart';
import '../../../core/utils/local_llm_service.dart';
import 'map/osm_map_widget.dart';
import 'table/survivors_table_widget.dart';
import 'dispatch_planner_widget.dart';

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
  String? _focusedSurvivorId;
  Set<String> _articulationPoints = {};
  Map<String, String> _nodeToCentroid = {}; // maps nodeId -> medoid node ID
  
  // AI Triage States
  bool _isAiTriageLoading = false;
  SurvivorStatus? _aiSuggestedStatus;
  String? _aiSuggestedNeeds;

  // Centroid Logistics States
  String? _focusedCentroidId;
  List<String>? _focusedCentroidComponent;
  
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

  void _seedShowcaseData() async {
    final db = LocalDB();
    await db.init();
    
    // Clear all entries
    final survivorsBox = Hive.box('survivor_records_box');
    final linksBox = Hive.box('network_links_box');
    
    await survivorsBox.clear();
    await linksBox.clear();
    
    // Create seed records
    final seedSurvivors = [
      SurvivorRecord(
        id: 'survivor_alice',
        name: 'Alice Cooper',
        latitude: -6.2120,
        longitude: 106.8480,
        status: SurvivorStatus.injured,
        needs: 'First Aid / Medical',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sequenceNumber: 1,
        batteryPercentage: 78,
        message: 'My leg is broken and I cannot walk. We are hiding in the lobby of the office building. Need medical help and bandages.',
      ),
      SurvivorRecord(
        id: 'survivor_bob',
        name: 'Bob Marley',
        latitude: -6.2110,
        longitude: 106.8490,
        status: SurvivorStatus.critical,
        needs: 'Tools / Warmth, First Aid / Medical',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sequenceNumber: 1,
        batteryPercentage: 92,
        message: 'URGENT! A concrete slab collapsed. My friend is trapped under debris and breathing is shallow. We need rescue tools and heavy lifters immediately!',
      ),
      SurvivorRecord(
        id: 'survivor_charlie',
        name: 'Charlie Brown',
        latitude: -6.2100,
        longitude: 106.8500,
        status: SurvivorStatus.injured,
        needs: 'Food & Water, Shelter',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sequenceNumber: 1,
        batteryPercentage: 45,
        message: 'We are group of 5 people. Low on water and baby formula. Shelter roof collapsed. No major injuries but need water.',
      ),
      SurvivorRecord(
        id: 'survivor_david',
        name: 'David Beckham',
        latitude: -6.2090,
        longitude: 106.8510,
        status: SurvivorStatus.safe,
        needs: 'Food & Water',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sequenceNumber: 1,
        batteryPercentage: 23,
        message: 'Safe here on the roof, but looking for updates on evacuation. Phone battery is low.',
      ),
      SurvivorRecord(
        id: 'survivor_emma',
        name: 'Emma Watson',
        latitude: -6.2200,
        longitude: 106.8400,
        status: SurvivorStatus.injured,
        needs: 'Food & Water, First Aid / Medical',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sequenceNumber: 1,
        batteryPercentage: 88,
        message: 'Safe from flooding on 2nd floor, but diabetic patient needs insulin refill. Running out of drinking water.',
      ),
      SurvivorRecord(
        id: 'survivor_frank',
        name: 'Frank Sinatra',
        latitude: -6.2210,
        longitude: 106.8410,
        status: SurvivorStatus.safe,
        needs: 'Food & Water',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sequenceNumber: 1,
        batteryPercentage: 62,
        message: 'No injuries here, just staying warm. Food supplies are okay for 24 hours.',
      ),
      SurvivorRecord(
        id: 'survivor_grace',
        name: 'Grace Kelly',
        latitude: -6.2190,
        longitude: 106.8390,
        status: SurvivorStatus.injured,
        needs: 'First Aid / Medical',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sequenceNumber: 1,
        batteryPercentage: 54,
        message: 'Need basic first aid kit. Cut my hand on broken glass. Still bleeding slightly.',
      ),
    ];

    final seedLinks = [
      NetworkLink(sourceId: 'survivor_alice', targetId: 'survivor_bob', timestamp: DateTime.now().millisecondsSinceEpoch),
      NetworkLink(sourceId: 'survivor_bob', targetId: 'survivor_charlie', timestamp: DateTime.now().millisecondsSinceEpoch),
      NetworkLink(sourceId: 'survivor_charlie', targetId: 'survivor_david', timestamp: DateTime.now().millisecondsSinceEpoch),
      NetworkLink(sourceId: 'survivor_emma', targetId: 'survivor_frank', timestamp: DateTime.now().millisecondsSinceEpoch),
      NetworkLink(sourceId: 'survivor_emma', targetId: 'survivor_grace', timestamp: DateTime.now().millisecondsSinceEpoch),
    ];

    for (var s in seedSurvivors) {
      await db.saveSurvivorRecord(s);
    }
    for (var l in seedLinks) {
      await db.saveNetworkLink(l);
    }

    // Reload state
    await _loadSurvivorsFromDb();
    triggerToast('Showcase dummy data seeded successfully!', Icons.playlist_add_check);
  }

  Future<void> _loadSurvivorsFromDb() async {
    final db = LocalDB();
    final list = await db.getAllSurvivors();
    final links = await db.getAllNetworkLinks();

    // Run SPAN topological network graph computations
    final nodeIds = list.map((s) => s.id).toList();
    final adj = NetworkAnalysisEngine.buildAdjacencyList(list, links);
    final components = NetworkAnalysisEngine.findConnectedComponents(nodeIds, adj);

    final Map<String, String> nodeToCentroid = {};
    for (var component in components) {
      final centroidId = NetworkAnalysisEngine.findTopologicalCentroid(component, adj);
      for (var nodeId in component) {
        nodeToCentroid[nodeId] = centroidId;
      }
    }

    final articulationPoints = NetworkAnalysisEngine.findArticulationPoints(nodeIds, adj);

    if (mounted) {
      setState(() {
        _survivors = list;
        _nodeToCentroid = nodeToCentroid;
        _articulationPoints = articulationPoints;
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
      batteryPercentage: survivor.batteryPercentage,
      message: survivor.message,
    );

    setState(() {
      _survivors[survivorIndex] = updated;
      _focusedSurvivorId = null;
    });

    LocalDB().saveSurvivorRecord(updated);
  }

  // Run AI Triage using Local Ollama Qwen 2.5 SLM
  void _runAiTriage(SurvivorRecord survivor) async {
    setState(() {
      _isAiTriageLoading = true;
      _aiSuggestedStatus = null;
      _aiSuggestedNeeds = null;
    });

    final result = await LocalLlmService().analyzeEmergency(survivor.message);

    if (!mounted) return;

    setState(() {
      _isAiTriageLoading = false;
      if (result != null) {
        final statusStr = result['status'] as String;
        _aiSuggestedStatus = SurvivorStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => SurvivorStatus.injured,
        );
        _aiSuggestedNeeds = result['needs'] as String;
        triggerToast('AI Triage complete!', Icons.auto_awesome);
      } else {
        triggerToast('Failed to connect to local AI server.', Icons.error_outline);
      }
    });
  }

  // Apply AI triage recommendations and save to database
  void _applyAiTriage(SurvivorRecord survivor) async {
    if (_aiSuggestedStatus == null) return;

    final survivorIndex = _survivors.indexWhere((s) => s.id == survivor.id);
    if (survivorIndex == -1) return;

    final updated = SurvivorRecord(
      id: survivor.id,
      name: survivor.name,
      latitude: survivor.latitude,
      longitude: survivor.longitude,
      status: _aiSuggestedStatus!,
      needs: _aiSuggestedNeeds ?? survivor.needs,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sequenceNumber: survivor.sequenceNumber + 1,
      batteryPercentage: survivor.batteryPercentage,
      message: survivor.message,
    );

    setState(() {
      _survivors[survivorIndex] = updated;
      _focusedSurvivorId = null;
      _aiSuggestedStatus = null;
      _aiSuggestedNeeds = null;
    });

    await LocalDB().saveSurvivorRecord(updated);
    triggerToast('AI triage suggestions applied!', Icons.done_all);
  }

  // Focus a centroid cluster and save component node IDs
  void _focusCentroid(String centroidId, List<String> nodeIds) {
    setState(() {
      _focusedCentroidId = centroidId;
      _focusedCentroidComponent = nodeIds;
    });
  }

  // Deploy supplies to all nodes in a centroid component bulk update
  void _deployCentroidSupplies(String centroidId, List<String> nodeIds) async {
    final db = LocalDB();
    final centroidSurvivor = _survivors.firstWhere((s) => s.id == centroidId, orElse: () => _survivors.first);
    triggerToast('Bulk supplies deployed to Centroid Hub: ${centroidSurvivor.name}', Icons.local_shipping);

    for (var nodeId in nodeIds) {
      final survivorIndex = _survivors.indexWhere((s) => s.id == nodeId);
      if (survivorIndex != -1) {
        final survivor = _survivors[survivorIndex];
        final updated = SurvivorRecord(
          id: survivor.id,
          name: survivor.name,
          latitude: survivor.latitude,
          longitude: survivor.longitude,
          status: SurvivorStatus.safe,
          needs: 'None (Supplied by Bulk Centroid Drop)',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          sequenceNumber: survivor.sequenceNumber + 1,
          batteryPercentage: survivor.batteryPercentage,
          message: survivor.message,
        );

        setState(() {
          _survivors[survivorIndex] = updated;
        });

        await db.saveSurvivorRecord(updated);
      }
    }

    setState(() {
      _focusedCentroidId = null;
      _focusedCentroidComponent = null;
    });
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
                
                final db = LocalDB();
                final myMessages = await db.getAllRescuerMessages();
                final postPayload = {
                  'messages': myMessages.map((m) => m.toMap()).toList(),
                };

                final response = await http.post(
                  uri,
                  headers: {'content-type': 'application/json'},
                  body: jsonEncode(postPayload),
                ).timeout(const Duration(seconds: 10));
                
                if (response.statusCode == 200) {
                  setDialogState(() {
                    status = 'SYNCHRONIZING';
                    details = 'Downloading and merging survivor databases...';
                  });

                  final decoded = jsonDecode(response.body);
                  List<dynamic> recordsJson = [];
                  List<dynamic> linksJson = [];
                  List<dynamic> messagesJson = [];
                  
                  if (decoded is Map) {
                    recordsJson = decoded['survivors'] as List<dynamic>? ?? [];
                    linksJson = decoded['links'] as List<dynamic>? ?? [];
                    messagesJson = decoded['messages'] as List<dynamic>? ?? [];
                  } else if (decoded is List) {
                    recordsJson = decoded;
                  }
                  
                  retrievedCount = recordsJson.length;
                  
                  for (var item in recordsJson) {
                    final record = SurvivorRecord.fromMap(Map<String, dynamic>.from(item));
                    await db.saveSurvivorRecord(record);
                  }

                  for (var item in linksJson) {
                    final link = NetworkLink.fromMap(Map<String, dynamic>.from(item));
                    await db.saveNetworkLink(link);
                  }

                  for (var item in messagesJson) {
                    final msg = RescuerMessage.fromMap(Map<String, dynamic>.from(item));
                    await db.saveRescuerMessage(msg);
                  }

                  // Reload dashboard data
                  await _loadSurvivorsFromDb();
                  await _loadBroadcastLogs();

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
          // Seed Showcase Data Button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: ReskuButton.outlined(
                label: 'SEED DATA',
                icon: Icons.playlist_add,
                height: 28,
                onPressed: _seedShowcaseData,
              ),
            ),
          ),
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
                message: focusedSurvivor.message,
                isAnalyzing: _isAiTriageLoading,
                aiSuggestedStatus: _aiSuggestedStatus,
                aiSuggestedNeeds: _aiSuggestedNeeds,
                onAiTriage: () => _runAiTriage(focusedSurvivor),
                onApplyAiTriage: () => _applyAiTriage(focusedSurvivor),
                onDismiss: () {
                  setState(() {
                    _focusedSurvivorId = null;
                    _aiSuggestedStatus = null;
                    _aiSuggestedNeeds = null;
                    _isAiTriageLoading = false;
                  });
                },
                onDeploy: () {
                  _deployRescueUnit(focusedSurvivor.id);
                },
              ),
            ),

          // Centroid Logistics Modal Overlay
          if (_focusedCentroidId != null && _focusedCentroidComponent != null) ...[
            (() {
              final centroidSurvivor = _survivors.firstWhere((s) => s.id == _focusedCentroidId, orElse: () => _survivors.first);
              final aggregateNeeds = NetworkAnalysisEngine.aggregateComponentNeeds(_focusedCentroidComponent!, _survivors);
              final survivorNames = _focusedCentroidComponent!.map((id) {
                return _survivors.firstWhere((s) => s.id == id, orElse: () => centroidSurvivor).name;
              }).toList();

              return Positioned.fill(
                child: ReskuCentroidModal(
                  centroidName: centroidSurvivor.name,
                  totalSurvivors: _focusedCentroidComponent!.length,
                  aggregateNeeds: aggregateNeeds,
                  survivorNames: survivorNames,
                  onDismiss: () {
                    setState(() {
                      _focusedCentroidId = null;
                      _focusedCentroidComponent = null;
                    });
                  },
                  onDeployBulk: () {
                    _deployCentroidSupplies(_focusedCentroidId!, _focusedCentroidComponent!);
                  },
                ),
              );
            })(),
          ],

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
                    onCentroidSelected: _focusCentroid,
                    onRefocusBaseCamp: _refocusBaseCamp,
                    articulationPoints: _articulationPoints,
                    nodeToCentroid: _nodeToCentroid,
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
          // Right Panel (Broadcast Control)
          SizedBox(
            width: 360,
            child: DispatchPlannerWidget(
              broadcastLogs: _broadcastLogs,
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
                Tab(icon: Icon(Icons.campaign), text: 'Broadcast'),
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
                    onCentroidSelected: _focusCentroid,
                    onRefocusBaseCamp: _refocusBaseCamp,
                    articulationPoints: _articulationPoints,
                    nodeToCentroid: _nodeToCentroid,
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
                  child: DispatchPlannerWidget(
                    broadcastLogs: _broadcastLogs,
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
