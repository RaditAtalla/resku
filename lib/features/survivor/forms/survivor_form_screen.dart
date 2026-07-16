import 'package:flutter/material.dart';
import '../../../core/database/local_db.dart';
import '../../../core/models/survivor_record.dart';
import '../../../core/models/rescuer_message.dart';
import 'dart:async';

class SurvivorFormScreen extends StatefulWidget {
  const SurvivorFormScreen({super.key});

  @override
  State<SurvivorFormScreen> createState() => _SurvivorFormScreenState();
}

class _SurvivorFormScreenState extends State<SurvivorFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  
  SurvivorStatus _status = SurvivorStatus.safe;
  final List<String> _needs = [];
  
  // Mesh state variables
  String _connectionStatus = 'Disconnected';
  bool _isBroadcasting = false;
  
  // Animation controller for pulsing central button
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  List<RescuerMessage> _announcements = [];
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  Timer? _pageTimer;

  // Static mock announcements to display as fallback
  final List<RescuerMessage> _mockAnnouncements = [
    RescuerMessage(
      id: 'mock_1',
      message: 'ALL SURVIVORS: Evacuation Camp active at North Sports Field. Helicopter water drop at 18:00.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
    ),
    RescuerMessage(
      id: 'mock_2',
      message: 'MEDICAL NOTICE: First aid tent established at Sector 2 grid. Bring ID if possible.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)).millisecondsSinceEpoch,
    ),
    RescuerMessage(
      id: 'mock_3',
      message: 'COMMUNICATION ADVISORY: Keep your BLE active. Mesh sync is running via passing rescuers.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    
    // Set up pulsing animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Auto-swipe announcements
    _pageTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_announcements.isNotEmpty && _pageController.hasClients) {
        int nextPage = (_currentPageIndex + 1) % _announcements.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    _pageController.dispose();
    _pageTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    final list = await LocalDB().getAllRescuerMessages();
    setState(() {
      if (list.isEmpty) {
        _announcements = _mockAnnouncements;
      } else {
        _announcements = list;
      }
    });
  }

  Color _getStatusColor(SurvivorStatus status) {
    switch (status) {
      case SurvivorStatus.safe:
        return const Color(0xFF10B981); // Emerald Green
      case SurvivorStatus.injured:
        return const Color(0xFFF59E0B); // Amber Orange
      case SurvivorStatus.critical:
        return const Color(0xFFEF4444); // Rose Red
    }
  }

  String _getStatusText(SurvivorStatus status) {
    switch (status) {
      case SurvivorStatus.safe:
        return 'Safe / No Direct Danger';
      case SurvivorStatus.injured:
        return 'Injured / Needs Attention';
      case SurvivorStatus.critical:
        return 'Critical / Emergency Assistance';
    }
  }

  void _triggerBroadcast() {
    setState(() {
      _isBroadcasting = true;
      _connectionStatus = 'Searching Mesh...';
    });

    // Simulate search and sync sequence
    Timer(const Duration(seconds: 2), () async {
      final name = _nameController.text.trim();
      final record = SurvivorRecord(
        id: 'survivor_${DateTime.now().millisecondsSinceEpoch}',
        name: name.isEmpty ? 'Anonymous' : name,
        latitude: -6.2000, // Simulated coordinates
        longitude: 106.8166,
        status: _status,
        needs: _needs.join(', '),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sequenceNumber: 1,
      );

      // Save to local database so background sync can pick it up
      await LocalDB().saveSurvivorRecord(record);

      if (mounted) {
        setState(() {
          _isBroadcasting = false;
          _connectionStatus = 'Mesh Connected';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _getStatusColor(_status),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Text('Status broadcasted successfully! (${_getStatusText(_status)})'),
              ],
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RESKU SURVIVOR'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _connectionStatus == 'Mesh Connected'
                  ? Colors.green.withOpacity(0.2)
                  : _connectionStatus == 'Searching Mesh...'
                      ? Colors.amber.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _connectionStatus == 'Mesh Connected'
                    ? Colors.green
                    : _connectionStatus == 'Searching Mesh...'
                        ? Colors.amber
                        : Colors.white30,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _connectionStatus == 'Mesh Connected'
                        ? Colors.green
                        : _connectionStatus == 'Searching Mesh...'
                            ? Colors.amber
                            : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _connectionStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _connectionStatus == 'Mesh Connected'
                        ? Colors.green.shade200
                        : _connectionStatus == 'Searching Mesh...'
                            ? Colors.amber.shade200
                            : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Rescuer Announcement Message Box
                if (_announcements.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.campaign, color: Colors.redAccent, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'RESCUER BROADCASTS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _announcements.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final msg = _announcements[index];
                            final timeString = DateTime.fromMillisecondsSinceEpoch(msg.timestamp)
                                .toLocal()
                                .toString()
                                .substring(11, 16);
                            return Card(
                              elevation: 4,
                              color: const Color(0xFF1E1E2C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.redAccent, width: 0.8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        msg.message,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Received via Mesh • $timeString',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${index + 1}/${_announcements.length}',
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 2. Central Big Pulse Connect/Broadcast Button
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isBroadcasting ? null : _triggerBroadcast,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            double scale = _pulseAnimation.value;
                            if (!_isBroadcasting && _connectionStatus != 'Mesh Connected') {
                              scale = 1.0 + (scale - 1.0) * 0.4; // subtle breath
                            } else if (_isBroadcasting) {
                              scale = _pulseAnimation.value; // intense pulse
                            } else {
                              scale = 1.0; // stable connected
                            }

                            return Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _isBroadcasting
                                        ? Colors.amber.withOpacity(0.4)
                                        : _connectionStatus == 'Mesh Connected'
                                            ? Colors.green.withOpacity(0.4)
                                            : Colors.redAccent.withOpacity(0.2),
                                    blurRadius: 20 * scale,
                                    spreadRadius: 4 * scale,
                                  )
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Animated Outer Pulse Rings
                                  Container(
                                    width: 150 * scale,
                                    height: 150 * scale,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _isBroadcasting
                                            ? Colors.amber.withOpacity(0.3)
                                            : _connectionStatus == 'Mesh Connected'
                                                ? Colors.green.withOpacity(0.3)
                                                : Colors.redAccent.withOpacity(0.15),
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 130 * scale,
                                    height: 130 * scale,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _isBroadcasting
                                            ? Colors.amber.withOpacity(0.5)
                                            : _connectionStatus == 'Mesh Connected'
                                                ? Colors.green.withOpacity(0.5)
                                                : Colors.redAccent.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  // Inner core button
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: _isBroadcasting
                                            ? [Colors.amber.shade400, Colors.amber.shade700]
                                            : _connectionStatus == 'Mesh Connected'
                                                ? [Colors.green.shade400, Colors.green.shade700]
                                                : [Colors.redAccent.shade400, Colors.redAccent.shade700],
                                        center: const Alignment(-0.2, -0.2),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(2, 4),
                                        )
                                      ],
                                    ),
                                    child: child,
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Icon(
                            _connectionStatus == 'Mesh Connected'
                                ? Icons.wifi_tethering
                                : _isBroadcasting
                                    ? Icons.sync
                                    : Icons.sensors,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isBroadcasting
                            ? 'BROADCASTING DATA...'
                            : _connectionStatus == 'Mesh Connected'
                                ? 'BROADCAST ACTIVE'
                                : 'TAP TO BROADCAST STATUS',
                        style: TextStyle(
                          color: _isBroadcasting
                              ? Colors.amber
                              : _connectionStatus == 'Mesh Connected'
                                  ? Colors.green.shade300
                                  : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3. Survivor Form Card containing Inputs
                Card(
                  color: const Color(0xFF1E1E2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'SURVIVOR DETAILS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nama Survivor (Optional input)
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name / Anonymous ID (Optional)',
                            labelStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.person_outline, color: Colors.redAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF13131D),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20),

                        // Triage Status Dropdown in Color
                        const Text(
                          'Triage Status Severity',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor, width: 1.5),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<SurvivorStatus>(
                              value: _status,
                              dropdownColor: const Color(0xFF1E1E2C),
                              icon: Icon(Icons.arrow_drop_down, color: statusColor),
                              items: SurvivorStatus.values.map((status) {
                                final color = _getStatusColor(status);
                                return DropdownMenuItem<SurvivorStatus>(
                                  value: status,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _getStatusText(status),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _status = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Needed Resource with Checkbox
                        const Text(
                          'Needed Resources',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            _buildResourceTile(
                              title: 'Food & Water',
                              icon: Icons.local_drink,
                              value: 'Food & Water',
                            ),
                            _buildResourceTile(
                              title: 'First Aid / Medical',
                              icon: Icons.healing,
                              value: 'First Aid / Medical',
                            ),
                            _buildResourceTile(
                              title: 'Shelter & Blanket',
                              icon: Icons.home,
                              value: 'Shelter',
                            ),
                            _buildResourceTile(
                              title: 'Tools & Warmth',
                              icon: Icons.build,
                              value: 'Tools / Warmth',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceTile({
    required String title,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _needs.contains(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _needs.remove(value);
              } else {
                _needs.add(value);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.redAccent.withOpacity(0.08)
                  : const Color(0xFF13131D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.redAccent.withOpacity(0.6)
                    : Colors.white.withOpacity(0.05),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.redAccent : Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade300,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.redAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? Colors.redAccent : Colors.grey.shade600,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
