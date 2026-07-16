import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/survivor_record.dart';
import '../../../core/models/rescuer_message.dart';
import '../../../core/utils/design_system.dart';
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
  final List<RescuerMessage> _broadcastLogs = [
    RescuerMessage(
      id: 'ann-1',
      message: 'An evac center is open at the North Sports Field. Helicopter drops planned for food and fresh water.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startClock();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _loadInitialData() {
    setState(() {
      _survivors = [
        SurvivorRecord(
          id: 'john',
          name: 'John Doe',
          latitude: -6.2088,
          longitude: 106.8456,
          status: SurvivorStatus.critical,
          needs: 'First Aid, Water, Fracture Splint',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
          sequenceNumber: 1,
        ),
        SurvivorRecord(
          id: 'jane',
          name: 'Jane Smith',
          latitude: -6.2100,
          longitude: 106.8480,
          status: SurvivorStatus.injured,
          needs: 'Blankets, Thermal Wear, Water',
          timestamp: DateTime.now().subtract(const Duration(minutes: 12)).millisecondsSinceEpoch,
          sequenceNumber: 2,
        ),
        SurvivorRecord(
          id: 'budi',
          name: 'Budi Santoso',
          latitude: -6.2112,
          longitude: 106.8415,
          status: SurvivorStatus.critical,
          needs: 'Asthma Inhaler, Oxygen',
          timestamp: DateTime.now().subtract(const Duration(minutes: 18)).millisecondsSinceEpoch,
          sequenceNumber: 3,
        ),
        SurvivorRecord(
          id: 'alice',
          name: 'Alice Green',
          latitude: -6.2135,
          longitude: 106.8522,
          status: SurvivorStatus.safe,
          needs: 'None (Holding Shelter Area)',
          timestamp: DateTime.now().subtract(const Duration(minutes: 22)).millisecondsSinceEpoch,
          sequenceNumber: 4,
        ),
      ];
    });
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
      
      final active = _survivors.where((s) => s.status != SurvivorStatus.safe).toList();
      
      // Sort: Critical first, then Injured.
      active.sort((a, b) {
        int scoreA = a.status == SurvivorStatus.critical ? (a.name == 'John Doe' ? 98 : 95) : 85;
        int scoreB = b.status == SurvivorStatus.critical ? (b.name == 'John Doe' ? 98 : 95) : 85;
        return scoreB.compareTo(scoreA); // high to low
      });

      setState(() {
        _aiPlan = active;
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

    setState(() {
      _survivors[survivorIndex] = SurvivorRecord(
        id: survivor.id,
        name: survivor.name,
        latitude: survivor.latitude,
        longitude: survivor.longitude,
        status: SurvivorStatus.safe,
        needs: 'None (Rescue unit arrived)',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sequenceNumber: survivor.sequenceNumber + 1,
      );
      
      // Remove from AI Plan or update it
      _aiPlan.removeWhere((s) => s.id == id);
      _focusedSurvivorId = null;
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

    triggerToast('Announcement broadcasted to BLE mesh network!', Icons.rss_feed);
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
