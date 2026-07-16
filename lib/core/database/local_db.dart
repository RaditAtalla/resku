import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/survivor_record.dart';
import '../models/rescuer_message.dart';

// LocalDB manages local storage (using Hive) for survivors and rescuer data.
class LocalDB {
  static final LocalDB _instance = LocalDB._internal();
  factory LocalDB() => _instance;
  LocalDB._internal();

  late Box _survivorsBox;
  late Box _messagesBox;
  bool _initialized = false;

  // Initialize storage adapters and open boxes
  Future<void> init() async {
    if (_initialized) return;
    debugPrint('Initializing local offline database (Hive)...');
    await Hive.initFlutter();
    _survivorsBox = await Hive.openBox('survivor_records_box');
    _messagesBox = await Hive.openBox('rescuer_messages_box');
    _initialized = true;

    // Seed mock data if empty (excluding metadata keys)
    final nonMetaKeys = _survivorsBox.keys.where((k) => k != 'device_uuid' && k != 'device_uuid_survivor' && k != 'device_uuid_rescuer');
    if (nonMetaKeys.isEmpty) {
      debugPrint('LocalDB: Seeding initial mock survivor records...');
      final defaultSurvivors = [
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
      for (var s in defaultSurvivors) {
        await _survivorsBox.put(s.id, s.toMap());
      }
    }
  }

  // Generate or retrieve a persistent stable unique identifier for this device
  Future<String> getOrCreateDeviceUUID({bool isRescuer = false}) async {
    await init();
    final key = isRescuer ? 'device_uuid_rescuer' : 'device_uuid_survivor';
    String? uuid = _survivorsBox.get(key) as String?;
    if (uuid == null) {
      final prefix = isRescuer ? 'rescuer' : 'survivor';
      uuid = '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_randomString(4)}';
      await _survivorsBox.put(key, uuid);
      debugPrint('Generated and stored new device UUID: $uuid');
    }
    return uuid;
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = math.Random();
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  // Save or update a survivor location record
  Future<void> saveSurvivorRecord(SurvivorRecord record) async {
    await init();
    await _survivorsBox.put(record.id, record.toMap());
    debugPrint('Saving survivor record to DB: ${record.id}');
  }

  // Save or update a survivor record synchronously (Hive writes to disk in background)
  void saveSurvivorRecordSync(SurvivorRecord record) {
    if (!_initialized) return;
    _survivorsBox.put(record.id, record.toMap());
    debugPrint('Saving survivor record to DB synchronously: ${record.id}');
  }

  // Fetch all known survivor records
  Future<List<SurvivorRecord>> getAllSurvivors() async {
    await init();
    final List<SurvivorRecord> list = [];
    for (var key in _survivorsBox.keys) {
      if (key == 'device_uuid') continue;
      final val = _survivorsBox.get(key);
      if (val != null) {
        try {
          list.add(SurvivorRecord.fromMap(Map<String, dynamic>.from(val)));
        } catch (e) {
          debugPrint('Error parsing survivor record for key $key: $e');
        }
      }
    }
    return list;
  }

  // Fetch all known survivor records synchronously
  List<SurvivorRecord> getAllSurvivorsSync() {
    if (!_initialized) return [];
    final List<SurvivorRecord> list = [];
    for (var key in _survivorsBox.keys) {
      if (key == 'device_uuid') continue;
      final val = _survivorsBox.get(key);
      if (val != null) {
        try {
          list.add(SurvivorRecord.fromMap(Map<String, dynamic>.from(val)));
        } catch (e) {
          debugPrint('Error parsing survivor record synchronously for key $key: $e');
        }
      }
    }
    return list;
  }

  // Get or create device UUID synchronously
  String getOrCreateDeviceUUIDSync({bool isRescuer = false}) {
    if (!_initialized) return isRescuer ? 'rescuer_unknown' : 'survivor_unknown';
    final key = isRescuer ? 'device_uuid_rescuer' : 'device_uuid_survivor';
    String? uuid = _survivorsBox.get(key) as String?;
    if (uuid == null) {
      final prefix = isRescuer ? 'rescuer' : 'survivor';
      uuid = '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_randomString(4)}';
      _survivorsBox.put(key, uuid);
    }
    return uuid;
  }

  // Save or update a rescuer message
  Future<void> saveRescuerMessage(RescuerMessage message) async {
    await init();
    await _messagesBox.put(message.id, message.toMap());
    debugPrint('Saving rescuer broadcast message to DB: ${message.id}');
  }

  // Fetch all received rescuer broadcast announcements
  Future<List<RescuerMessage>> getAllRescuerMessages() async {
    await init();
    final List<RescuerMessage> list = [];
    for (var key in _messagesBox.keys) {
      final val = _messagesBox.get(key);
      if (val != null) {
        try {
          list.add(RescuerMessage.fromMap(Map<String, dynamic>.from(val)));
        } catch (e) {
          debugPrint('Error parsing rescuer message for key $key: $e');
        }
      }
    }
    return list;
  }
}

