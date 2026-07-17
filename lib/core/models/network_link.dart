// Represents a network link (edge) between two nodes in the ad-hoc mesh.
class NetworkLink {
  final String sourceId;
  final String targetId;
  final int timestamp; // Milliseconds since epoch

  NetworkLink({
    required this.sourceId,
    required this.targetId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'sourceId': sourceId,
      'targetId': targetId,
      'timestamp': timestamp,
    };
  }

  factory NetworkLink.fromMap(Map<String, dynamic> map) {
    return NetworkLink(
      sourceId: map['sourceId'] as String,
      targetId: map['targetId'] as String,
      timestamp: map['timestamp'] as int,
    );
  }

  // Helper to generate a unique bidirectional key for local Hive mapping
  String get key => sourceId.compareTo(targetId) < 0 
      ? '${sourceId}_$targetId' 
      : '${targetId}_$sourceId';
}
