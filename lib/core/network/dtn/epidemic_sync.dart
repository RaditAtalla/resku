import 'package:flutter/foundation.dart';
import '../../database/local_db.dart';
import '../../models/survivor_record.dart';

// Handles Epidemic Routing and sync-metadata comparison for Delay Tolerant Networking (DTN)
class EpidemicSync {
  // Generates Latest Update Vector (LUV) mapping survivor IDs to their sequence number
  Future<Map<String, int>> generateLocalLuv() async {
    final survivors = await LocalDB().getAllSurvivors();
    return {for (var s in survivors) s.id: s.sequenceNumber};
  }

  // Synchronizes data when a peer connection is established.
  // Performs the handshake: compares LUVs and exchanges delta.
  Future<void> synchronizeWithPeer({
    required Map<String, int> peerLuv,
    required Function(List<SurvivorRecord> delta) sendDeltaToPeer,
    required Future<List<SurvivorRecord>> Function() receiveDeltaFromPeer,
  }) async {
    debugPrint('DTN: Initiating epidemic sync handshake...');

    final localSurvivors = await LocalDB().getAllSurvivors();
    final List<SurvivorRecord> outbox = [];

    for (var local in localSurvivors) {
      final peerSeq = peerLuv[local.id] ?? -1;
      if (local.sequenceNumber > peerSeq) {
        outbox.add(local); // We have newer data, add to send delta
      }
    }

    // 1. Send our newer records
    if (outbox.isNotEmpty) {
      debugPrint('DTN: Sending ${outbox.length} updated records to peer.');
      sendDeltaToPeer(outbox);
    }

    // 2. Receive newer records from the peer
    final inbox = await receiveDeltaFromPeer();
    debugPrint('DTN: Received ${inbox.length} updated records from peer.');
    
    for (var record in inbox) {
      await LocalDB().saveSurvivorRecord(record);
    }
  }
}
