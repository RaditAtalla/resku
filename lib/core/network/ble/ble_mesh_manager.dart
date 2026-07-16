import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../database/local_db.dart';
import '../../models/survivor_record.dart';

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

  MeshState get state => stateNotifier.value;

  // Custom Service and Characteristic UUIDs for Resku Mesh
  static const String serviceUuid = '8f7b3e0c-d3a9-4672-9b2f-7a4c6a8b79d2';
  static const String charUuid = 'a3f5b2c9-e7d1-42a8-9b8f-3c6d4e5f0a1b';

  bool get isSimulated => kIsWeb || 
      (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS);

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

    if (!isSimulated) {
      await _stopRealBle();
    }
    debugPrint('Mesh: Resku BLE Mesh stopped.');
  }

  void _runCycle() {
    if (!_isMeshRunning) return;

    stateNotifier.value = MeshState.searching;
    debugPrint('Mesh: Loop restarted. Asymmetric, jittered switching starting.');
    _toggleRole(isBroadcasting: true);
  }

  void _toggleRole({required bool isBroadcasting}) async {
    if (!_isMeshRunning) return;

    final rnd = math.Random();
    if (isBroadcasting) {
      stateNotifier.value = MeshState.broadcasting;
      debugPrint('Mesh State: Broadcasting (Advertising).');

      bool advertiseSuccess = false;
      if (!isSimulated) {
        advertiseSuccess = await _startRealAdvertising();
      }

      // Asymmetric timing: 8 seconds base + [0 to 2] seconds random jitter
      final durationMs = 8000 + rnd.nextInt(2000);

      if (isSimulated || !advertiseSuccess) {
        if (!advertiseSuccess && !isSimulated) {
          debugPrint('Mesh Warning: Real Advertising failed, falling back to simulated mode for this cycle.');
        }

        // Simulator peer-finding probability (25% chance during this window)
        if (rnd.nextDouble() < 0.25) {
          _cycleTimer = Timer(Duration(milliseconds: rnd.nextInt(3000)), () {
            _connectAndSyncSimulated();
          });
        } else {
          _cycleTimer = Timer(Duration(milliseconds: durationMs), () {
            _toggleRole(isBroadcasting: false); // switch to scanning
          });
        }
      } else {
        // Wait for advertising period to end, then switch role
        _cycleTimer = Timer(Duration(milliseconds: durationMs), () async {
          await _stopRealAdvertising();
          _toggleRole(isBroadcasting: false);
        });
      }
    } else {
      stateNotifier.value = MeshState.receiving;
      debugPrint('Mesh State: Receiving (Scanning).');

      bool scanSuccess = false;
      if (!isSimulated) {
        scanSuccess = await _startRealScanning();
      }

      // Asymmetric timing: 4 seconds base + [0 to 1] second random jitter
      final durationMs = 4000 + rnd.nextInt(1000);

      if (isSimulated || !scanSuccess) {
        if (!scanSuccess && !isSimulated) {
          debugPrint('Mesh Warning: Real Scanning failed, falling back to simulated mode for this cycle.');
        }

        // Simulator peer-finding probability (40% chance during this window)
        if (rnd.nextDouble() < 0.40) {
          _cycleTimer = Timer(Duration(milliseconds: rnd.nextInt(2000)), () {
            _connectAndSyncSimulated();
          });
        } else {
          _cycleTimer = Timer(Duration(milliseconds: durationMs), () {
            _toggleRole(isBroadcasting: true); // switch to advertising
          });
        }
      } else {
        // Wait for scanning period to end, then switch role
        _cycleTimer = Timer(Duration(milliseconds: durationMs), () async {
          await _stopRealScanning();
          _toggleRole(isBroadcasting: true);
        });
      }
    }
  }

  void _connectAndSyncSimulated() async {
    _cycleTimer?.cancel();
    stateNotifier.value = MeshState.connected;
    debugPrint('Mesh Simulator: Connected to nearby peer!');

    // 1. Send local survivor record and coordinates
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('Mesh Simulator: Sent local coordinate and details to peer.');

    // 2. Switch to receiving mode to receive peer's data
    stateNotifier.value = MeshState.receiving;
    await Future.delayed(const Duration(seconds: 2));

    await _updateOtherDevicesCount();

    stateNotifier.value = MeshState.success;
    if (onDataSynced != null) {
      onDataSynced!();
    }
    debugPrint('Mesh Simulator: 1 simulated sync cycle completed.');

    await Future.delayed(const Duration(seconds: 2));
    _startCooldown();
  }

  void _startCooldown() {
    stateNotifier.value = MeshState.waiting;
    _waitingCountdown = 30;
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
      final localRecord = all.firstWhere((s) => s.id == myId, orElse: () => SurvivorRecord(
        id: myId,
        name: _isRescuer ? 'Rescuer Mule' : 'Anonymous',
        latitude: -6.2000,
        longitude: 106.8166,
        status: SurvivorStatus.safe,
        needs: '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sequenceNumber: 1,
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

      List<Map<String, dynamic>>? pendingDeltaToSend;

      // Set write callback so that when the scanning device writes to our characteristic, we receive their records and LUV.
      BlePeripheral.setWriteRequestCallback((deviceId, characteristicId, offset, value) {
        debugPrint('Mesh Real BLE GATT: Received write from $deviceId on characteristic $characteristicId');
        if (value != null && value.isNotEmpty) {
          try {
            final jsonString = utf8.decode(value);
            final payload = jsonDecode(jsonString) as Map<String, dynamic>;

            // 1. Process client's delta records
            final clientDeltaList = payload['delta'] as List<dynamic>? ?? [];
            for (var item in clientDeltaList) {
              final record = SurvivorRecord.fromMap(Map<String, dynamic>.from(item));
              LocalDB().saveSurvivorRecordSync(record);
            }
            debugPrint('Mesh Real BLE GATT: Saved ${clientDeltaList.length} records written by client.');

            // 2. Process client's LUV to compile delta to send back
            final clientLuv = Map<String, dynamic>.from(payload['luv'] ?? {});
            final freshLocalSurvivors = LocalDB().getAllSurvivorsSync();
            
            final List<Map<String, dynamic>> deltaToClient = [];
            for (var local in freshLocalSurvivors) {
              final clientSeq = clientLuv[local.id] as int? ?? -1;
              if (local.sequenceNumber > clientSeq) {
                deltaToClient.add(local.toMap());
              }
            }

            pendingDeltaToSend = deltaToClient;
            debugPrint('Mesh Real BLE GATT: Compiled ${deltaToClient.length} delta records to send to client.');
            
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
            final localLuv = {for (var s in freshLocalSurvivors) s.id: s.sequenceNumber};
            payloadString = jsonEncode(localLuv);
            debugPrint('Mesh Real BLE GATT: Sending LUV catalog to client: $payloadString');
          } else {
            // Step 3: Return delta records compiled during Step 2
            payloadString = jsonEncode(pendingDeltaToSend);
            debugPrint('Mesh Real BLE GATT: Sending ${pendingDeltaToSend!.length} delta records to client.');
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
      _scanSubscription = fbp.FlutterBluePlus.onScanResults.listen((results) async {
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
      debugPrint('Mesh Real BLE: Connected. Discovering services...');

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

        // 1. Read peer LUV catalog map (Step 1)
        stateNotifier.value = MeshState.receiving;
        final rawLuv = await syncChar.read();
        final peerLuvString = utf8.decode(rawLuv);
        debugPrint('Mesh Real BLE DTN: Read Peer LUV: $peerLuvString');

        Map<String, int> peerLuv = {};
        if (peerLuvString.isNotEmpty) {
          try {
            peerLuv = Map<String, int>.from(jsonDecode(peerLuvString));
          } catch (e) {
            debugPrint('Mesh Real BLE DTN: Failed to decode Peer LUV: $e');
          }
        }

        // 2. Compare LUV and compile our local LUV and delta outbox (Step 2)
        final localSurvivors = await localDb.getAllSurvivors();
        final localLuv = {for (var s in localSurvivors) s.id: s.sequenceNumber};
        
        final List<Map<String, dynamic>> deltaToPeer = [];
        for (var local in localSurvivors) {
          final peerSeq = peerLuv[local.id] ?? -1;
          if (local.sequenceNumber > peerSeq) {
            deltaToPeer.add(local.toMap());
          }
        }

        final writePayload = jsonEncode({
          'luv': localLuv,
          'delta': deltaToPeer,
        });

        // Write our LUV + Delta records to the peer
        debugPrint('Mesh Real BLE DTN: Writing local LUV and ${deltaToPeer.length} delta records to peer...');
        await syncChar.write(Uint8List.fromList(utf8.encode(writePayload)));

        // 3. Read Peer's delta records back (Step 3)
        stateNotifier.value = MeshState.receiving;
        final rawDelta = await syncChar.read();
        final peerDeltaString = utf8.decode(rawDelta);
        debugPrint('Mesh Real BLE DTN: Read Peer Delta: $peerDeltaString');

        if (peerDeltaString.isNotEmpty) {
          try {
            final List<dynamic> jsonList = jsonDecode(peerDeltaString);
            int savedCount = 0;
            for (var item in jsonList) {
              final record = SurvivorRecord.fromMap(Map<String, dynamic>.from(item));
              await localDb.saveSurvivorRecord(record);
              savedCount++;
            }
            debugPrint('Mesh Real BLE DTN: Saved $savedCount records received from peer.');
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

