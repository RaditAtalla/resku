// Represents a survivor record containing location, triage status, and requests.
// This record is designed to propagate across the delay-tolerant mesh network.
class SurvivorRecord {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final SurvivorStatus status;
  final String needs;
  final int timestamp; // Milliseconds since epoch
  final int sequenceNumber;

  SurvivorRecord({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.needs,
    required this.timestamp,
    required this.sequenceNumber,
  });

  // Convert a record to a Map for serialization (e.g., JSON or MsgPack)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'needs': needs,
      'timestamp': timestamp,
      'sequenceNumber': sequenceNumber,
    };
  }

  // Create a record from a Map
  factory SurvivorRecord.fromMap(Map<String, dynamic> map) {
    return SurvivorRecord(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      status: SurvivorStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SurvivorStatus.safe,
      ),
      needs: map['needs'] as String,
      timestamp: map['timestamp'] as int,
      sequenceNumber: map['sequenceNumber'] as int,
    );
  }
}

enum SurvivorStatus {
  safe,
  injured,
  critical,
}
