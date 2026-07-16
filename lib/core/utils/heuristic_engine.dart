import 'dart:math' as math;
import '../models/survivor_record.dart';

// HeuristicEngine provides rule-based triage scoring and sorting routines.
// Primarily designed for offline tactical dispatch planning.
class HeuristicEngine {
  // Base camp coordinates: Center of the tactical canvas bounds.
  static const double baseCampLat = -6.2100;
  static const double baseCampLng = 106.8475;

  // Calculates distance between two GPS coordinates using the Haversine formula in kilometers
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double rLat1 = _degreesToRadians(lat1);
    final double rLat2 = _degreesToRadians(lat2);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(rLat1) * math.cos(rLat2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  // Calculate distance specifically from the Rescuer Base Camp
  static double calculateDistanceFromBaseCamp(double lat, double lon) {
    return calculateDistance(baseCampLat, baseCampLng, lat, lon);
  }

  // Computes the dynamic triage recommendation score (0 to 100) for a survivor record.
  // Urgency Points (Max 60) + Proximity Points (Max 25) + Starvation Prevention Wait points (Max 15)
  static int calculateTriageScore(SurvivorRecord survivor) {
    // 1. Status Urgency points
    int statusPoints = 0;
    switch (survivor.status) {
      case SurvivorStatus.critical:
        statusPoints = 60;
        break;
      case SurvivorStatus.injured:
        statusPoints = 35;
        break;
      case SurvivorStatus.safe:
        statusPoints = 5;
        break;
    }

    // 2. Proximity points (clamped to max 25 points, decays with distance)
    final double distance = calculateDistanceFromBaseCamp(survivor.latitude, survivor.longitude);
    // 25 points at 0km distance, scaling down as distance increases
    final double proximityPoints = 25.0 / (1.0 + distance);

    // 3. Starvation prevention points based on wait time (max 15 points)
    final double elapsedMinutes = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(survivor.timestamp))
            .inSeconds /
        60.0;
    // 0.2 points per minute elapsed, capped at 15 points (~75 minutes max influence)
    final double waitTimePoints = math.min(15.0, elapsedMinutes * 0.2);

    // Clamp combined score between 0 and 100
    final double total = statusPoints + proximityPoints + waitTimePoints;
    return total.round().clamp(0, 100);
  }

  // Filters out resolved (safe) survivors and sorts remaining ones descending by triage priority score
  static List<SurvivorRecord> sortDispatchQueue(List<SurvivorRecord> survivors) {
    final active = survivors.where((s) => s.status != SurvivorStatus.safe).toList();
    
    active.sort((a, b) {
      final int scoreA = calculateTriageScore(a);
      final int scoreB = calculateTriageScore(b);
      
      // Secondary sort key: distance from base camp (closer first)
      if (scoreA == scoreB) {
        final double distA = calculateDistanceFromBaseCamp(a.latitude, a.longitude);
        final double distB = calculateDistanceFromBaseCamp(b.latitude, b.longitude);
        return distA.compareTo(distB); 
      }
      
      return scoreB.compareTo(scoreA); // High score first
    });

    return active;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
