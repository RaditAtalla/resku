import 'package:flutter/material.dart';
import '../../../core/database/local_db.dart';
import '../../../core/models/survivor_record.dart';
import '../../../core/models/rescuer_message.dart';
import '../../../core/utils/design_system.dart';
import '../../../core/network/ble/ble_mesh_manager.dart';
import 'dart:async';

class SurvivorFormScreen extends StatefulWidget {
  const SurvivorFormScreen({super.key});

  @override
  State<SurvivorFormScreen> createState() => _SurvivorFormScreenState();
}

class _SurvivorFormScreenState extends State<SurvivorFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  SurvivorStatus _status = SurvivorStatus.safe;
  final List<String> _needs = [];

  // Mesh state variables
  int _otherDevicesCount = 0;
  MeshState _meshState = MeshState.idle;
  int _cooldownSeconds = 0;

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
      message:
          'ALL SURVIVORS: Evacuation Camp active at North Sports Field. Helicopter water drop at 18:00.',
      timestamp: DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch,
    ),
    RescuerMessage(
      id: 'mock_2',
      message:
          'MEDICAL NOTICE: First aid tent established at Sector 2 grid. Bring ID if possible.',
      timestamp: DateTime.now()
          .subtract(const Duration(minutes: 25))
          .millisecondsSinceEpoch,
    ),
    RescuerMessage(
      id: 'mock_3',
      message:
          'COMMUNICATION ADVISORY: Keep your BLE active. Mesh sync is running via passing rescuers.',
      timestamp: DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();

    final mesh = BleMeshManager();
    _otherDevicesCount = mesh.otherDevicesCountNotifier.value;
    _meshState = mesh.state;
    _cooldownSeconds = mesh.cooldownSecondsNotifier.value;

    mesh.otherDevicesCountNotifier.addListener(_onCountChanged);
    mesh.stateNotifier.addListener(_onStateChanged);
    mesh.cooldownSecondsNotifier.addListener(_onCooldownChanged);
    mesh.onDataSynced = _loadAnnouncements;

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
    final mesh = BleMeshManager();
    mesh.otherDevicesCountNotifier.removeListener(_onCountChanged);
    mesh.stateNotifier.removeListener(_onStateChanged);
    mesh.cooldownSecondsNotifier.removeListener(_onCooldownChanged);
    if (mesh.onDataSynced == _loadAnnouncements) {
      mesh.onDataSynced = null;
    }

    _pulseController.dispose();
    _nameController.dispose();
    _pageController.dispose();
    _pageTimer?.cancel();
    super.dispose();
  }

  void _onCountChanged() {
    if (mounted) {
      setState(() {
        _otherDevicesCount = BleMeshManager().otherDevicesCountNotifier.value;
      });
    }
  }

  void _onStateChanged() {
    if (mounted) {
      final newState = BleMeshManager().stateNotifier.value;
      
      // Notify user when a sync completes successfully
      if (newState == MeshState.success && _meshState != MeshState.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            content: Center(
              child: ReskuToast(
                text: 'Sync complete! Stored: ${BleMeshManager().otherDevicesCountNotifier.value} other nodes.',
                icon: Icons.done_all,
              ),
            ),
          ),
        );
      }
      
      setState(() {
        _meshState = newState;
      });
    }
  }

  void _onCooldownChanged() {
    if (mounted) {
      setState(() {
        _cooldownSeconds = BleMeshManager().cooldownSecondsNotifier.value;
      });
    }
  }

  String _getConnectionStatusText() {
    switch (_meshState) {
      case MeshState.idle:
        return 'Disconnected';
      case MeshState.searching:
        return 'Searching Mesh...';
      case MeshState.broadcasting:
        return 'Broadcasting...';
      case MeshState.receiving:
        return 'Receiving...';
      case MeshState.connected:
        return 'Mesh Connected';
      case MeshState.success:
        return 'Sync Success';
      case MeshState.waiting:
        return 'Waiting (${_cooldownSeconds}s)';
    }
  }

  Color _getConnectionStatusColor() {
    switch (_meshState) {
      case MeshState.idle:
        return AppColors.muted;
      case MeshState.searching:
        return AppColors.injured;
      case MeshState.broadcasting:
        return AppColors.orange;
      case MeshState.receiving:
        return Colors.blue;
      case MeshState.connected:
      case MeshState.success:
        return AppColors.safe;
      case MeshState.waiting:
        return AppColors.muted;
    }
  }

  Color _getConnectionStatusBgColor() {
    switch (_meshState) {
      case MeshState.idle:
      case MeshState.waiting:
        return AppColors.grayBg;
      case MeshState.searching:
        return AppColors.injuredBg;
      case MeshState.broadcasting:
        return AppColors.orange.withValues(alpha: 0.1);
      case MeshState.receiving:
        return Colors.blue.withValues(alpha: 0.1);
      case MeshState.connected:
      case MeshState.success:
        return AppColors.safeBg;
    }
  }

  Color _getConnectionStatusBorderColor() {
    switch (_meshState) {
      case MeshState.idle:
      case MeshState.waiting:
        return AppColors.border;
      case MeshState.searching:
        return AppColors.injuredBorder;
      case MeshState.broadcasting:
        return AppColors.orange.withValues(alpha: 0.3);
      case MeshState.receiving:
        return Colors.blue.withValues(alpha: 0.3);
      case MeshState.connected:
      case MeshState.success:
        return AppColors.safeBorder;
    }
  }

  Future<void> _loadAnnouncements() async {
    final list = await LocalDB().getAllRescuerMessages();
    final db = LocalDB();
    final myId = await db.getOrCreateDeviceUUID();
    final all = await db.getAllSurvivors();
    final existing = all.where((s) => s.id == myId).toList();
    
    if (existing.isNotEmpty && mounted) {
      final localRecord = existing.first;
      setState(() {
        _nameController.text = localRecord.name == 'Anonymous' ? '' : localRecord.name;
        _status = localRecord.status;
        _needs.clear();
        if (localRecord.needs.isNotEmpty) {
          _needs.addAll(localRecord.needs.split(', ').where((s) => s.isNotEmpty));
        }
      });
    }

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
        return AppColors.safe;
      case SurvivorStatus.injured:
        return AppColors.injured;
      case SurvivorStatus.critical:
        return AppColors.critical;
    }
  }

  Color _getStatusBgColor(SurvivorStatus status) {
    switch (status) {
      case SurvivorStatus.safe:
        return AppColors.safeBg;
      case SurvivorStatus.injured:
        return AppColors.injuredBg;
      case SurvivorStatus.critical:
        return AppColors.criticalBg;
    }
  }

  Color _getStatusBorderColor(SurvivorStatus status) {
    switch (status) {
      case SurvivorStatus.safe:
        return AppColors.safeBorder;
      case SurvivorStatus.injured:
        return AppColors.injuredBorder;
      case SurvivorStatus.critical:
        return AppColors.criticalBorder;
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

  void _triggerBroadcast() async {
    final name = _nameController.text.trim();
    final db = LocalDB();
    final myId = await db.getOrCreateDeviceUUID();

    final all = await db.getAllSurvivors();
    int seqNum = 1;
    final existing = all.where((s) => s.id == myId).toList();
    if (existing.isNotEmpty) {
      seqNum = existing.first.sequenceNumber + 1;
    }

    final record = SurvivorRecord(
      id: myId,
      name: name.isEmpty ? 'Anonymous' : name,
      latitude: -6.2000,
      longitude: 106.8166,
      status: _status,
      needs: _needs.join(', '),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sequenceNumber: seqNum,
    );

    // Save to local database
    await db.saveSurvivorRecord(record);

    // Start mesh cycle
    await BleMeshManager().startMeshCycle();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMeshActive = _meshState != MeshState.idle;
    final bool isConnectingOrSyncing = _meshState == MeshState.searching || 
                                        _meshState == MeshState.broadcasting ||
                                        _meshState == MeshState.receiving ||
                                        _meshState == MeshState.connected;

    return Scaffold(
      appBar: AppBar(
        title: Text('Resku $_otherDevicesCount'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getConnectionStatusBgColor(),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getConnectionStatusBorderColor(),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getConnectionStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _getConnectionStatusText().toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _getConnectionStatusColor(),
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
                // 1. Rescuer Announcement Message Box using ReskuCard
                if (_announcements.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign,
                            color: AppColors.orange, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'RESCUER BROADCASTS',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: AppColors.orange,
                            fontSize: 11,
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
                            final timeString =
                                DateTime.fromMillisecondsSinceEpoch(
                                        msg.timestamp)
                                    .toLocal()
                                    .toString()
                                    .substring(11, 16);
                            return ReskuCard(
                              accentColor: AppColors.orange,
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      msg.message,
                                      style: AppTextStyles.bodyBold.copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Received via Mesh • $timeString',
                                        style: AppTextStyles.monospaceLabel,
                                      ),
                                      Text(
                                        '${index + 1}/${_announcements.length}',
                                        style: const TextStyle(
                                          color: AppColors.orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                        onTap: isMeshActive ? null : _triggerBroadcast,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            double scale = _pulseAnimation.value;
                            if (!isMeshActive) {
                              scale = 1.0 + (scale - 1.0) * 0.4; // subtle breath
                            } else if (isConnectingOrSyncing) {
                              scale = _pulseAnimation.value; // intense pulse
                            } else {
                              scale = 1.0; // stable success
                            }

                            Color buttonColor = AppColors.orange;
                            IconData buttonIcon = Icons.sensors;
                            
                            switch (_meshState) {
                              case MeshState.idle:
                                buttonColor = AppColors.orange;
                                buttonIcon = Icons.sensors;
                                break;
                              case MeshState.searching:
                                buttonColor = AppColors.injured;
                                buttonIcon = Icons.sync;
                                break;
                              case MeshState.broadcasting:
                                buttonColor = AppColors.orange;
                                buttonIcon = Icons.wifi_tethering;
                                break;
                              case MeshState.receiving:
                                buttonColor = Colors.blue;
                                buttonIcon = Icons.wifi_tethering_off;
                                break;
                              case MeshState.connected:
                                buttonColor = AppColors.safe;
                                buttonIcon = Icons.check_circle_outline;
                                break;
                              case MeshState.success:
                                buttonColor = AppColors.safe;
                                buttonIcon = Icons.done_all;
                                break;
                              case MeshState.waiting:
                                buttonColor = AppColors.muted;
                                buttonIcon = Icons.hourglass_empty;
                                break;
                            }

                            return Container(
                              width: 160,
                              height: 160,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
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
                                        color: buttonColor.withValues(alpha: 0.2),
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
                                        color: buttonColor.withValues(alpha: 0.4),
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
                                      color: buttonColor,
                                    ),
                                    child: Icon(
                                      buttonIcon,
                                      size: 44,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _meshState == MeshState.idle
                            ? 'TAP TO BROADCAST STATUS'
                            : _meshState == MeshState.waiting
                                ? 'WAITING FOR NEXT CYCLE (${_cooldownSeconds}s)'
                                : _getConnectionStatusText().toUpperCase(),
                        style: TextStyle(
                          color: _getConnectionStatusColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3. Survivor Form Card containing Inputs
                ReskuCard(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'SURVIVOR DETAILS',
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 16),

                      // Nama Survivor (Optional input) using ReskuTextField
                      SizedBox(
                        height: 58,
                        child: ReskuTextField(
                          controller: _nameController,
                          hintText: 'Name / Anonymous ID (Optional)',
                          maxCount: 50,
                          prefixIcon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Triage Status Dropdown in Color
                      Text(
                        'Triage Status Severity',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(_status),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _getStatusBorderColor(_status),
                              width: 1.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<SurvivorStatus>(
                            value: _status,
                            dropdownColor: Colors.white,
                            icon: Icon(Icons.arrow_drop_down,
                                color: _getStatusColor(_status)),
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
                                        fontSize: 12,
                                        fontFamily: 'Inter',
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
                      Text(
                        'Needed Resources',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.muted),
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
                  ? AppColors.orange.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.orange : AppColors.border,
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                )
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.orange : AppColors.muted,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.black : AppColors.muted,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.orange : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.orange : AppColors.border,
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
