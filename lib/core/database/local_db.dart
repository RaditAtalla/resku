import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/survivor_record.dart';
import '../models/rescuer_message.dart';
import '../models/network_link.dart';

// LocalDB manages local storage (using Hive) for survivors and rescuer data.
class LocalDB {
  static final LocalDB _instance = LocalDB._internal();
  factory LocalDB() => _instance;
  LocalDB._internal();

  late Box _survivorsBox;
  late Box _messagesBox;
  late Box _linksBox;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    debugPrint('Initializing local offline database (Hive)...');
    await Hive.initFlutter();
    _survivorsBox = await Hive.openBox('survivor_records_box');
    _messagesBox = await Hive.openBox('rescuer_messages_box');
    _linksBox = await Hive.openBox('network_links_box');
    _initialized = true;

    // Auto-prune stale logs on database load
    await pruneStaleData();
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
      if (key == 'device_uuid' || key == 'device_uuid_survivor' || key == 'device_uuid_rescuer') continue;
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
      if (key == 'device_uuid' || key == 'device_uuid_survivor' || key == 'device_uuid_rescuer') continue;
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

  // Save or update a rescuer message synchronously
  void saveRescuerMessageSync(RescuerMessage message) {
    if (!_initialized) return;
    _messagesBox.put(message.id, message.toMap());
    debugPrint('Saving rescuer broadcast message to DB synchronously: ${message.id}');
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

  // Fetch all received rescuer broadcast announcements synchronously
  List<RescuerMessage> getAllRescuerMessagesSync() {
    if (!_initialized) return [];
    final List<RescuerMessage> list = [];
    for (var key in _messagesBox.keys) {
      final val = _messagesBox.get(key);
      if (val != null) {
        try {
          list.add(RescuerMessage.fromMap(Map<String, dynamic>.from(val)));
        } catch (e) {
          debugPrint('Error parsing rescuer message synchronously for key $key: $e');
        }
      }
    }
    return list;
  }

  // Prunes survivor records and rescuer messages older than 72 hours (3 days)
  Future<void> pruneStaleData() async {
    debugPrint('LocalDB Pruner: Starting database stale log cleanup check...');
    final cutoff = DateTime.now().subtract(const Duration(hours: 72)).millisecondsSinceEpoch;

    // 1. Prune stale survivor records
    final survivorKeys = _survivorsBox.keys.toList();
    int prunedSurvivors = 0;
    for (var key in survivorKeys) {
      if (key == 'device_uuid' || key == 'device_uuid_survivor' || key == 'device_uuid_rescuer') continue;
      final val = _survivorsBox.get(key);
      if (val != null) {
        try {
          final record = SurvivorRecord.fromMap(Map<String, dynamic>.from(val));
          if (record.timestamp < cutoff) {
            await _survivorsBox.delete(key);
            prunedSurvivors++;
            debugPrint('LocalDB Pruner: Deleted stale survivor: ${record.name} (${record.id})');
          }
        } catch (e) {
          debugPrint('LocalDB Pruner: Error parsing record during prune for key $key: $e');
        }
      }
    }

    // 2. Prune stale rescuer messages
    final messageKeys = _messagesBox.keys.toList();
    int prunedMessages = 0;
    for (var key in messageKeys) {
      final val = _messagesBox.get(key);
      if (val != null) {
        try {
          final msg = RescuerMessage.fromMap(Map<String, dynamic>.from(val));
          if (msg.timestamp < cutoff) {
            await _messagesBox.delete(key);
            prunedMessages++;
            debugPrint('LocalDB Pruner: Deleted stale announcement message: ${msg.id}');
          }
        } catch (e) {
          debugPrint('LocalDB Pruner: Error parsing message during prune for key $key: $e');
        }
      }
    }

    // 3. Prune stale network links (older than 15 minutes = 900,000 ms)
    final linkCutoff = DateTime.now().subtract(const Duration(minutes: 15)).millisecondsSinceEpoch;
    final linkKeys = _linksBox.keys.toList();
    int prunedLinks = 0;
    for (var key in linkKeys) {
      final val = _linksBox.get(key);
      if (val != null) {
        try {
          final link = NetworkLink.fromMap(Map<String, dynamic>.from(val));
          if (link.timestamp < linkCutoff) {
            await _linksBox.delete(key);
            prunedLinks++;
          }
        } catch (e) {
          debugPrint('LocalDB Pruner: Error parsing link during prune for key $key: $e');
        }
      }
    }

    debugPrint('LocalDB Pruner: Cleanup complete. Pruned: $prunedSurvivors survivor logs, $prunedMessages announcements, $prunedLinks network links.');
  }

  // Save or update a network link
  Future<void> saveNetworkLink(NetworkLink link) async {
    await init();
    await _linksBox.put(link.key, link.toMap());
    debugPrint('Saving network link to DB: ${link.key}');
  }

  // Save or update a network link synchronously
  void saveNetworkLinkSync(NetworkLink link) {
    if (!_initialized) return;
    _linksBox.put(link.key, link.toMap());
  }

  // Fetch all known network links
  Future<List<NetworkLink>> getAllNetworkLinks() async {
    await init();
    final List<NetworkLink> list = [];
    for (var key in _linksBox.keys) {
      final val = _linksBox.get(key);
      if (val != null) {
        try {
          list.add(NetworkLink.fromMap(Map<String, dynamic>.from(val)));
        } catch (e) {
          debugPrint('Error parsing network link for key $key: $e');
        }
      }
    }
    return list;
  }

  // Fetch all known network links synchronously
  List<NetworkLink> getAllNetworkLinksSync() {
    if (!_initialized) return [];
    final List<NetworkLink> list = [];
    for (var key in _linksBox.keys) {
      final val = _linksBox.get(key);
      if (val != null) {
        try {
          list.add(NetworkLink.fromMap(Map<String, dynamic>.from(val)));
        } catch (e) {
          debugPrint('Error parsing network link synchronously for key $key: $e');
        }
      }
    }
    return list;
  }
}

