// Represents a broadcast message sent by a rescuer.
// Propagates from rescuer nodes down into the survivor ad-hoc mesh.
class RescuerMessage {
  final String id;
  final String message;
  final int timestamp; // Milliseconds since epoch

  RescuerMessage({
    required this.id,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'timestamp': timestamp,
    };
  }

  factory RescuerMessage.fromMap(Map<String, dynamic> map) {
    return RescuerMessage(
      id: map['id'] as String,
      message: map['message'] as String,
      timestamp: map['timestamp'] as int,
    );
  }
}
