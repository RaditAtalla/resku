import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../database/local_db.dart';
import '../../models/survivor_record.dart';
import '../../models/rescuer_message.dart';
import '../../models/network_link.dart';

enum MeshState {
  idle,
  searching,
  broadcasting, // Advertising state
  receiving,    // Scanning/Handshake/Sync state
  connected,    // Peer connected and syncing
  success,      // Successful cycle complete
  waiting,      // Waiting 30 seconds before next cycle
}

// BleMeshManager manages the role-switching BLE cycle (Scanning & Advertising).
class BleMeshManager {
  static final BleMeshManager _instance = BleMeshManager._internal();
  factory BleMeshManager() => _instance;
  BleMeshManager._internal();

  final ValueNotifier<MeshState> stateNotifier = ValueNotifier<MeshState>(MeshState.idle);
  final ValueNotifier<int> otherDevicesCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> cooldownSecondsNotifier = ValueNotifier<int>(0);

  bool _isMeshRunning = false;
  bool _isRescuer = false;
  Timer? _cycleTimer;
  Timer? _countdownTimer;
  int _waitingCountdown = 30;

  VoidCallback? onDataSynced;
  final Battery _battery = Battery();

  MeshState get state => stateNotifier.value;

  // Custom Service and Characteristic UUIDs for Resku Mesh
  static const String serviceUuid = '8f7b3e0c-d3a9-4672-9b2f-7a4c6a8b79d2';
  static const String charUuid = 'a3f5b2c9-e7d1-42a8-9b8f-3c6d4e5f0a1b';



  // Request Bluetooth and Location permissions at runtime
  Future<bool> requestBlePermissions() async {
    if (kIsWeb) return true;
    try {
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
      final advGranted = statuses[Permission.bluetoothAdvertise]?.isGranted ?? false;
      final connGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
      final locationGranted = statuses[Permission.location]?.isGranted ?? false;

      final hasModernBle = scanGranted && advGranted && connGranted;
      debugPrint('Mesh Permissions: scan=$scanGranted, advertise=$advGranted, connect=$connGranted, location=$locationGranted');
      return hasModernBle || locationGranted;
    } catch (e) {
      debugPrint('Mesh Permissions Error: Failed to request permissions: $e');
      return false;
    }
  }

  // Initialize and load local other devices count on startup
  Future<void> init() async {
    await _updateOtherDevicesCount();
  }

  Future<void> _updateOtherDevicesCount() async {
    final all = await LocalDB().getAllSurvivors();
    final myId = await LocalDB().getOrCreateDeviceUUID(isRescuer: _isRescuer);
    final otherDevices = all.where((s) => s.id != myId).toList();
    otherDevicesCountNotifier.value = otherDevices.length;
    debugPrint('Mesh: Counted ${otherDevices.length} other devices in local DB.');
  }

  // Start the BLE Dynamic Role-Switching Cycle
  Future<void> startMeshCycle({bool isRescuer = false}) async {
    if (_isMeshRunning) return;
    _isMeshRunning = true;
    _isRescuer = isRescuer;
    debugPrint('Mesh: Starting Resku BLE Ad-Hoc Mesh Sync Cycle (isRescuer: $_isRescuer)...');
    
    // Trigger runtime permissions prompt
    await requestBlePermissions();
    
    await _updateOtherDevicesCount();
    _runCycle();
  }

  // Stop the cycle
  Future<void> stopMeshCycle() async {
    _isMeshRunning = false;
    _cycleTimer?.cancel();
    _countdownTimer?.cancel();
    stateNotifier.value = MeshState.idle;
    cooldownSecondsNotifier.value = 0;

    await _stopRealBle();
    debugPrint('Mesh: Resku BLE Mesh stopped.');
  }

  void _runCycle() {
    if (!_isMeshRunning) return;

    stateNotifier.value = MeshState.searching;
    debugPrint('Mesh: Loop restarted. Asymmetric, jittered switching starting.');
    _toggleRole(isBroadcasting: true);
  }

  Future<Map<String, int>> _getIntervalSettings() async {
    try {
      final level = await _battery.batteryLevel;
      if (level < 20) {
        debugPrint('Mesh Battery Saver active (Battery: $level%). Adjusting timing intervals.');
        return {
          'advertiseMs': 4000,
          'scanMs': 2000,
          'cooldownS': 90,
        };
      }
    } catch (e) {
      debugPrint('Battery Saver: Battery check unavailable on this platform ($e). Using default intervals.');
    }
    return {
      'advertiseMs': 8000,
      'scanMs': 4000,
      'cooldownS': 30,
    };
  }

  void _toggleRole({required bool isBroadcasting}) async {
    if (!_isMeshRunning) return;

    final rnd = math.Random();
    final intervals = await _getIntervalSettings();

    if (isBroadcasting) {
      stateNotifier.value = MeshState.broadcasting;
      debugPrint('Mesh State: Broadcasting (Advertising).');

      final bool advertiseSuccess = await _startRealAdvertising();
      if (!advertiseSuccess) {
        debugPrint('Mesh Warning: Real Advertising failed to start.');
      }

      final baseMs = intervals['advertiseMs']!;
      final durationMs = baseMs + rnd.nextInt((baseMs * 0.25).toInt().clamp(1, 2000));

      // Wait for advertising period to end, then switch role
      _cycleTimer = Timer(Duration(milliseconds: durationMs), () async {
        await _stopRealAdvertising();
        _toggleRole(isBroadcasting: false);
      });
    } else {
      stateNotifier.value = MeshState.receiving;
      debugPrint('Mesh State: Receiving (Scanning).');

      final bool scanSuccess = await _startRealScanning();
      if (!scanSuccess) {
        debugPrint('Mesh Warning: Real Scanning failed to start.');
      }

      final baseMs = intervals['scanMs']!;
      final durationMs = baseMs + rnd.nextInt((baseMs * 0.25).toInt().clamp(1, 1000));

      // Wait for scanning period to end, then switch role
      _cycleTimer = Timer(Duration(milliseconds: durationMs), () async {
        await _stopRealScanning();
        _toggleRole(isBroadcasting: true);
      });
    }
  }

  void _startCooldown() async {
    if (!_isMeshRunning) return;
    stateNotifier.value = MeshState.waiting;
    final intervals = await _getIntervalSettings();
    if (!_isMeshRunning) return;
    _waitingCountdown = intervals['cooldownS']!;
    cooldownSecondsNotifier.value = _waitingCountdown;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isMeshRunning) {
        timer.cancel();
        return;
      }
      _waitingCountdown--;
      cooldownSecondsNotifier.value = _waitingCountdown;

      if (_waitingCountdown <= 0) {
        timer.cancel();
        _runCycle(); // Start the next cycle (broadcasting and receiving)
      }
    });
  }

  // ==================== REAL ANDROID BLE IMPLEMENTATION ====================

  bool _isAdvertising = false;
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;

  Future<bool> _startRealAdvertising() async {
    if (_isAdvertising) return true;
    try {
      debugPrint('Mesh Real BLE: Setting up Peripheral GATT services...');
      await BlePeripheral.initialize();

      final myId = await LocalDB().getOrCreateDeviceUUID(isRescuer: _isRescuer);
      final all = await LocalDB().getAllSurvivors();
      int batteryLevel = 100;
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (_) {}

      final localRecord = all.firstWhere((s) => s.id == myId, orElse: () => SurvivorRecord(
        id: myId,
        name: _isRescuer ? 'Rescuer Mule' : 'Anonymous',
        latitude: -6.2000,
        longitude: 106.8166,
        status: SurvivorStatus.safe,
        needs: '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sequenceNumber: 1,
        batteryPercentage: batteryLevel,
        message: '',
      ));

      final service = BleService(
        uuid: serviceUuid,
        primary: true,
        characteristics: [
          BleCharacteristic(
            uuid: charUuid,
            properties: [CharacteristicProperties.read.index, CharacteristicProperties.write.index],
            permissions: [AttributePermissions.readable.index, AttributePermissions.writeable.index],
            value: Uint8List.fromList(utf8.encode(jsonEncode(localRecord.toMap()))),
          )
        ],
      );

      await BlePeripheral.addService(service);

      Map<String, dynamic>? pendingDeltaToSend;

      // Set write callback so that when the scanning device writes to our characteristic, we receive their records and LUV.
      BlePeripheral.setWriteRequestCallback((deviceId, characteristicId, offset, value) {
        debugPrint('Mesh Real BLE GATT: Received write from $deviceId on characteristic $characteristicId');
        if (value != null && value.isNotEmpty) {
          try {
            final jsonString = utf8.decode(value);
            final payload = jsonDecode(jsonString) as Map<String, dynamic>;

            // Record direct peer connection link
            final clientUuid = payload['senderId'] as String? ?? 'unknown';
            if (clientUuid != 'unknown') {
              LocalDB().saveNetworkLinkSync(NetworkLink(
                sourceId: myId,
                targetId: clientUuid,
                timestamp: DateTime.now().millisecondsSinceEpoch,
              ));
            }

            // 1. Process client's delta records
            final clientDelta = payload['delta'] as Map<String, dynamic>? ?? {};
            final clientDeltaSurvivors = clientDelta['survivors'] as List<dynamic>? ?? [];
            for (var item in clientDeltaSurvivors) {
              final record = SurvivorRecord.fromMap(Map<String, dynamic>.from(item));
              LocalDB().saveSurvivorRecordSync(record);
            }

            final clientDeltaMessages = clientDelta['messages'] as List<dynamic>? ?? [];
            for (var item in clientDeltaMessages) {
              final msg = RescuerMessage.fromMap(Map<String, dynamic>.from(item));
              LocalDB().saveRescuerMessageSync(msg);
            }

            final clientDeltaLinks = clientDelta['links'] as List<dynamic>? ?? [];
            for (var item in clientDeltaLinks) {
              final link = NetworkLink.fromMap(Map<String, dynamic>.from(item));
              LocalDB().saveNetworkLinkSync(link);
            }
            debugPrint('Mesh Real BLE GATT: Saved ${clientDeltaSurvivors.length} survivors, ${clientDeltaMessages.length} messages, and ${clientDeltaLinks.length} links.');

            // 2. Process client's LUV to compile delta to send back
            final clientLuv = payload['luv'] as Map<String, dynamic>? ?? {};
            final clientLuvSurvivors = Map<String, dynamic>.from(clientLuv['survivors'] ?? {});
            final clientLuvMessages = Map<String, dynamic>.from(clientLuv['messages'] ?? {});
            final clientLuvLinks = Map<String, dynamic>.from(clientLuv['links'] ?? {});

            final freshLocalSurvivors = LocalDB().getAllSurvivorsSync();
            final freshLocalMessages = LocalDB().getAllRescuerMessagesSync();
            final freshLocalLinks = LocalDB().getAllNetworkLinksSync();
            
            final List<Map<String, dynamic>> deltaSurvivors = [];
            for (var local in freshLocalSurvivors) {
              final clientSeq = clientLuvSurvivors[local.id] as int? ?? -1;
              if (local.sequenceNumber > clientSeq) {
                deltaSurvivors.add(local.toMap());
              }
            }

            final List<Map<String, dynamic>> deltaMessages = [];
            for (var local in freshLocalMessages) {
              if (!clientLuvMessages.containsKey(local.id)) {
                deltaMessages.add(local.toMap());
              }
            }

            final List<Map<String, dynamic>> deltaLinks = [];
            for (var local in freshLocalLinks) {
              final clientTime = clientLuvLinks[local.key] as int? ?? -1;
              if (local.timestamp > clientTime) {
                deltaLinks.add(local.toMap());
              }
            }

            pendingDeltaToSend = {
              'survivors': deltaSurvivors,
              'messages': deltaMessages,
              'links': deltaLinks,
            };
            debugPrint('Mesh Real BLE GATT: Compiled delta to send: ${deltaSurvivors.length} survivors, ${deltaMessages.length} messages, ${deltaLinks.length} links.');
            
            _updateOtherDevicesCount();
            if (onDataSynced != null) {
              onDataSynced!();
            }
          } catch (e) {
            debugPrint('Mesh Real BLE GATT Write Callback Error: $e');
          }
        }
        return WriteRequestResult(status: 0); // 0 = success
      });

      // Set read callback so that when the scanning device reads our characteristic, we return our LUV or compiled delta.
      BlePeripheral.setReadRequestCallback((deviceId, characteristicId, offset, value) {
        debugPrint('Mesh Real BLE GATT: Received read request from $deviceId on characteristic $characteristicId');
        try {
          String payloadString;
          if (pendingDeltaToSend == null) {
            // Step 1: Return our local LUV catalog
            final freshLocalSurvivors = LocalDB().getAllSurvivorsSync();
            final freshLocalMessages = LocalDB().getAllRescuerMessagesSync();
            final freshLocalLinks = LocalDB().getAllNetworkLinksSync();

            final catalog = {
              'senderId': myId,
              'survivors': {for (var s in freshLocalSurvivors) s.id: s.sequenceNumber},
              'messages': {for (var m in freshLocalMessages) m.id: m.timestamp},
              'links': {for (var l in freshLocalLinks) l.key: l.timestamp}
            };
            payloadString = jsonEncode(catalog);
            debugPrint('Mesh Real BLE GATT: Sending LUV catalog to client: $payloadString');
          } else {
            // Step 3: Return delta records compiled during Step 2
            payloadString = jsonEncode(pendingDeltaToSend);
            debugPrint('Mesh Real BLE GATT: Sending delta records to client.');
            pendingDeltaToSend = null; // Clear for next connections
          }

          final bytes = Uint8List.fromList(utf8.encode(payloadString));
          Uint8List responseBytes = bytes;
          if (offset > 0 && offset < bytes.length) {
            responseBytes = Uint8List.fromList(bytes.sublist(offset));
          }
          
          return ReadRequestResult(
            value: responseBytes,
            offset: offset,
            status: 0, // success
          );
        } catch (e) {
          debugPrint('Mesh Real BLE GATT Read Callback Error: $e');
          return ReadRequestResult(
            value: Uint8List(0),
            status: 1, // failure
          );
        }
      });

      // Start advertising local name based on ID
      final prefix = _isRescuer ? 'ReskuRec' : 'Resku';
      await BlePeripheral.startAdvertising(
        services: [serviceUuid],
        localName: '$prefix-${myId.substring(math.max(0, myId.length - 6))}',
      );

      _isAdvertising = true;
      debugPrint('Mesh Real BLE: Advertising started successfully.');
      return true;
    } catch (e) {
      debugPrint('Mesh Real BLE Exception (Advertising start): $e');
      return false;
    }
  }

  Future<void> _stopRealAdvertising() async {
    if (!_isAdvertising) return;
    try {
      await BlePeripheral.stopAdvertising();
      _isAdvertising = false;
      debugPrint('Mesh Real BLE: Advertising stopped.');
    } catch (e) {
      debugPrint('Mesh Real BLE Exception (Advertising stop): $e');
    }
  }

  Future<bool> _startRealScanning() async {
    if (_isScanning) return true;
    try {
      debugPrint('Mesh Real BLE: Initializing Central scan...');

      final state = await fbp.FlutterBluePlus.adapterState.first;
      if (state != fbp.BluetoothAdapterState.on) {
        debugPrint('Mesh Real BLE Error: Bluetooth hardware is off (${state.name})');
        return false;
      }

      await _scanSubscription?.cancel();
      bool isConnecting = false;
      _scanSubscription = fbp.FlutterBluePlus.onScanResults.listen((results) async {
        if (isConnecting) return;
        for (fbp.ScanResult r in results) {
          final name = r.device.platformName;
          final matchesService = r.advertisementData.serviceUuids.any(
            (uuid) => uuid.toString().toLowerCase() == serviceUuid.toLowerCase(),
          );

          if (matchesService || name.startsWith('Resku-') || name.startsWith('ReskuRec-')) {
            // Constraint: Rescuer to Rescuer connection is not possible
            if (_isRescuer && name.startsWith('ReskuRec-')) {
              debugPrint('Mesh Real BLE: Ignoring peer rescuer device: $name');
              continue;
            }
            debugPrint('Mesh Real BLE: Discovered Resku Peer: $name (${r.device.remoteId})');
            isConnecting = true;
            await _stopRealScanning();
            await _connectAndSyncReal(r.device);
            break;
          }
        }
      });

      await fbp.FlutterBluePlus.startScan(
        withServices: [fbp.Guid(serviceUuid)],
        timeout: const Duration(seconds: 4),
      );

      _isScanning = true;
      debugPrint('Mesh Real BLE: Scanning active.');
      return true;
    } catch (e) {
      debugPrint('Mesh Real BLE Exception (Scanning start): $e');
      return false;
    }
  }

  Future<void> _stopRealScanning() async {
    try {
      await fbp.FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      _isScanning = false;
      debugPrint('Mesh Real BLE: Scanning stopped.');
    } catch (e) {
      debugPrint('Mesh Real BLE Exception (Scanning stop): $e');
    }
  }

  Future<void> _connectAndSyncReal(fbp.BluetoothDevice device) async {
    _cycleTimer?.cancel();
    stateNotifier.value = MeshState.connected;
    debugPrint('Mesh Real BLE: Connecting to peer ${device.remoteId}...');

    try {
      await device.connect(timeout: const Duration(seconds: 5));
      debugPrint('Mesh Real BLE: Connected. Negotiating MTU...');
      try {
        await device.requestMtu(512, timeout: 3);
        debugPrint('Mesh Real BLE: MTU negotiated successfully.');
      } catch (e) {
        debugPrint('Mesh Real BLE: MTU negotiation skipped or failed: $e');
      }
      debugPrint('Mesh Real BLE: Discovering services...');

      final services = await device.discoverServices();
      fbp.BluetoothCharacteristic? syncChar;

      for (var s in services) {
        if (s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (var c in s.characteristics) {
            if (c.uuid.toString().toLowerCase() == charUuid.toLowerCase()) {
              syncChar = c;
              break;
            }
          }
        }
      }

      if (syncChar != null) {
        debugPrint('Mesh Real BLE DTN: Characteristic match. Initiating Epidemic handshake...');

        final localDb = LocalDB();
        final myId = await localDb.getOrCreateDeviceUUID(isRescuer: _isRescuer);

        // 1. Read peer LUV catalog map (Step 1)
        stateNotifier.value = MeshState.receiving;
        final rawLuv = await syncChar.read();
        final peerLuvString = utf8.decode(rawLuv);
        debugPrint('Mesh Real BLE DTN: Read Peer LUV: $peerLuvString');

        Map<String, dynamic> peerCatalog = {};
        if (peerLuvString.isNotEmpty) {
          try {
            peerCatalog = Map<String, dynamic>.from(jsonDecode(peerLuvString));
          } catch (e) {
            debugPrint('Mesh Real BLE DTN: Failed to decode Peer catalog: $e');
          }
        }

        // Record direct peer connection link
        final peerUuid = peerCatalog['senderId'] as String? ?? 'unknown';
        if (peerUuid != 'unknown') {
          await localDb.saveNetworkLink(NetworkLink(
            sourceId: myId,
            targetId: peerUuid,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ));
        }

        final peerLuvSurvivors = Map<String, dynamic>.from(peerCatalog['survivors'] ?? {});
        final peerLuvMessages = Map<String, dynamic>.from(peerCatalog['messages'] ?? {});
        final peerLuvLinks = Map<String, dynamic>.from(peerCatalog['links'] ?? {});

        // 2. Compare LUV and compile our local LUV and delta outbox (Step 2)
        final localSurvivors = await localDb.getAllSurvivors();
        final localMessages = await localDb.getAllRescuerMessages();
        final localLinks = await localDb.getAllNetworkLinks();

        final localLuvSurvivors = {for (var s in localSurvivors) s.id: s.sequenceNumber};
        final localLuvMessages = {for (var m in localMessages) m.id: m.timestamp};
        final localLuvLinks = {for (var l in localLinks) l.key: l.timestamp};
        
        final List<Map<String, dynamic>> deltaSurvivors = [];
        for (var local in localSurvivors) {
          final peerSeq = peerLuvSurvivors[local.id] as int? ?? -1;
          if (local.sequenceNumber > peerSeq) {
            deltaSurvivors.add(local.toMap());
          }
        }

        final List<Map<String, dynamic>> deltaMessages = [];
        for (var local in localMessages) {
          if (!peerLuvMessages.containsKey(local.id)) {
            deltaMessages.add(local.toMap());
          }
        }

        final List<Map<String, dynamic>> deltaLinks = [];
        for (var local in localLinks) {
          final peerTime = peerLuvLinks[local.key] as int? ?? -1;
          if (local.timestamp > peerTime) {
            deltaLinks.add(local.toMap());
          }
        }

        final writePayload = jsonEncode({
          'senderId': myId,
          'luv': {
            'survivors': localLuvSurvivors,
            'messages': localLuvMessages,
            'links': localLuvLinks,
          },
          'delta': {
            'survivors': deltaSurvivors,
            'messages': deltaMessages,
            'links': deltaLinks,
          },
        });

        // Write our LUV + Delta records to the peer
        debugPrint('Mesh Real BLE DTN: Writing local LUV and delta records (${deltaSurvivors.length} survivors, ${deltaMessages.length} messages, ${deltaLinks.length} links) to peer...');
        await syncChar.write(Uint8List.fromList(utf8.encode(writePayload)));

        // 3. Read Peer's delta records back (Step 3)
        stateNotifier.value = MeshState.receiving;
        final rawDelta = await syncChar.read();
        final peerDeltaString = utf8.decode(rawDelta);
        debugPrint('Mesh Real BLE DTN: Read Peer Delta: $peerDeltaString');

        if (peerDeltaString.isNotEmpty) {
          try {
            final responseDelta = jsonDecode(peerDeltaString) as Map<String, dynamic>;
            
            final peerDeltaSurvivors = responseDelta['survivors'] as List<dynamic>? ?? [];
            int savedSurvivors = 0;
            for (var item in peerDeltaSurvivors) {
              final record = SurvivorRecord.fromMap(Map<String, dynamic>.from(item));
              await localDb.saveSurvivorRecord(record);
              savedSurvivors++;
            }

            final peerDeltaMessages = responseDelta['messages'] as List<dynamic>? ?? [];
            int savedMessages = 0;
            for (var item in peerDeltaMessages) {
              final msg = RescuerMessage.fromMap(Map<String, dynamic>.from(item));
              await localDb.saveRescuerMessage(msg);
              savedMessages++;
            }

            final peerDeltaLinks = responseDelta['links'] as List<dynamic>? ?? [];
            int savedLinks = 0;
            for (var item in peerDeltaLinks) {
              final link = NetworkLink.fromMap(Map<String, dynamic>.from(item));
              await localDb.saveNetworkLink(link);
              savedLinks++;
            }

            debugPrint('Mesh Real BLE DTN: Saved $savedSurvivors survivors, $savedMessages messages, and $savedLinks links received from peer.');
          } catch (e) {
            debugPrint('Mesh Real BLE DTN: Failed to decode peer delta records: $e');
          }
        }

        await _updateOtherDevicesCount();
        stateNotifier.value = MeshState.success;
        if (onDataSynced != null) {
          onDataSynced!();
        }
        debugPrint('Mesh Real BLE DTN: Handshake sync cycle completed.');
      }
    } catch (e) {
      debugPrint('Mesh Real BLE Sync error: $e');
    } finally {
      try {
        await device.disconnect();
      } catch (_) {}
      
      await Future.delayed(const Duration(seconds: 2));
      _startCooldown();
    }
  }

  Future<void> _stopRealBle() async {
    await _stopRealAdvertising();
    await _stopRealScanning();
  }
}

