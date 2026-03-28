import 'package:flutter_test/flutter_test.dart';
import 'package:hostpital_2/models/hospital.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Unit Tests: Hospital Scoring & Bed Allocation Logic
//
// Run with:  flutter test test/scoring_test.dart
// ─────────────────────────────────────────────────────────────────────────────

Hospital _makeHospital({
  required String id,
  required String name,
  required int waitTime,
  required int bedsAvailable,
  required int opdQueue,
  required double lat,
  required double lng,
  int doctors = 5,
  int noBedsReports = 0,
  DateTime? lastUpdated,
}) {
  return Hospital(
    id: id,
    name: name,
    location: 'Test Location',
    opdQueue: opdQueue,
    doctors: doctors,
    avgConsultTime: 15,
    bedsAvailable: bedsAvailable,
    bedsTotal: 20,
    lat: lat,
    lng: lng,
    waitTime: waitTime,
    city: 'Delhi',
    zone: 'Unknown',
    loadIndex: 1.0,
    contactNumber: '102',
    lastUpdated: lastUpdated ?? DateTime.now(),
    noBedsReports: noBedsReports,
    type: 'government',
  );
}

// ─── SCORING ALGORITHM (mirror of hospital_viewmodel.dart) ───────────────────
double _score(Hospital h, double userLat, double userLng) {
  double dist = _distKm(h.lat, h.lng, userLat, userLng);
  final predictedBeds = h.noBedsReports >= 3 ? 0 : h.bedsAvailable;
  double score = 0;
  score -= (dist * 10);
  score += (predictedBeds * 2);
  final freshness = h.lastUpdated != null
      ? DateTime.now().difference(h.lastUpdated!).inMinutes
      : 999;
  if (freshness <= 30) score += 15;
  if (freshness > 120 || h.noBedsReports >= 3) score -= 15;
  return score;
}

double _distKm(double lat1, double lng1, double lat2, double lng2) {
  // Simple Pythagorean approx for small deltas — good enough for unit tests
  final dlat = lat1 - lat2;
  final dlng = lng1 - lng2;
  return (dlat * dlat + dlng * dlng) * 111; // rough km
}

void main() {
  const double userLat = 28.5672;
  const double userLng = 77.2100;

  group('Hospital Scoring Algorithm', () {
    test('closer hospital with equal beds ranks higher', () {
      final near = _makeHospital(
        id: 'h1', name: 'Near', waitTime: 30,
        bedsAvailable: 5, opdQueue: 10, lat: 28.57, lng: 77.21,
      );
      final far = _makeHospital(
        id: 'h2', name: 'Far', waitTime: 30,
        bedsAvailable: 5, opdQueue: 10, lat: 28.70, lng: 77.40,
      );
      expect(_score(near, userLat, userLng), greaterThan(_score(far, userLat, userLng)));
    });

    test('hospital with more beds ranks higher at same distance', () {
      final moreBeds = _makeHospital(
        id: 'h3', name: 'MoreBeds', waitTime: 30,
        bedsAvailable: 20, opdQueue: 10, lat: 28.57, lng: 77.21,
      );
      final lessBeds = _makeHospital(
        id: 'h4', name: 'LessBeds', waitTime: 30,
        bedsAvailable: 2, opdQueue: 10, lat: 28.57, lng: 77.21,
      );
      expect(_score(moreBeds, userLat, userLng), greaterThan(_score(lessBeds, userLat, userLng)));
    });

    test('stale data (> 120 min) heavily penalizes score', () {
      final freshHosp = _makeHospital(
        id: 'h5', name: 'Fresh', waitTime: 50, bedsAvailable: 5,
        opdQueue: 20, lat: 28.57, lng: 77.21,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      final staleHosp = _makeHospital(
        id: 'h6', name: 'Stale', waitTime: 50, bedsAvailable: 5,
        opdQueue: 20, lat: 28.57, lng: 77.21,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(_score(freshHosp, userLat, userLng), greaterThan(_score(staleHosp, userLat, userLng)));
    });

    test('hospital with 3+ noBedsReports has score reduced', () {
      final trustedHosp = _makeHospital(
        id: 'h7', name: 'Trusted', waitTime: 30, bedsAvailable: 5,
        opdQueue: 10, lat: 28.57, lng: 77.21, noBedsReports: 0,
      );
      final reportedHosp = _makeHospital(
        id: 'h8', name: 'FlaggedNobed', waitTime: 30, bedsAvailable: 5,
        opdQueue: 10, lat: 28.57, lng: 77.21, noBedsReports: 3,
      );
      expect(_score(trustedHosp, userLat, userLng), greaterThan(_score(reportedHosp, userLat, userLng)));
    });
  });

  group('Bed Allocation Eligibility Logic', () {
    // Mirror the core check from FirestoreService.allocateBedAndBookAppointment
    bool _isBedEligible(Map<String, dynamic> bedData) {
      final status = bedData['status'];
      if (status != 'available') return false;
      final lastUpdated = bedData['last_updated'] as DateTime?;
      if (lastUpdated == null) return true; // legacy bed — allow
      final diff = DateTime.now().difference(lastUpdated);
      return diff.inMinutes <= 30;
    }

    test('available bed with fresh timestamp is eligible', () {
      final bed = {
        'status': 'available',
        'last_updated': DateTime.now().subtract(const Duration(minutes: 5)),
      };
      expect(_isBedEligible(bed), isTrue);
    });

    test('occupied bed is not eligible', () {
      final bed = {
        'status': 'occupied',
        'last_updated': DateTime.now().subtract(const Duration(minutes: 5)),
      };
      expect(_isBedEligible(bed), isFalse);
    });

    test('available bed with stale timestamp (> 30 min) is not eligible', () {
      final bed = {
        'status': 'available',
        'last_updated': DateTime.now().subtract(const Duration(minutes: 45)),
      };
      expect(_isBedEligible(bed), isFalse);
    });

    test('available bed with no timestamp (legacy) is still eligible', () {
      final bed = {
        'status': 'available',
        'last_updated': null,
      };
      expect(_isBedEligible(bed), isTrue);
    });

    test('IoT bed (source=iot) eligible when fresh', () {
      final bed = {
        'status': 'available',
        'source': 'iot',
        'last_updated': DateTime.now().subtract(const Duration(minutes: 2)),
      };
      expect(_isBedEligible(bed), isTrue);
    });

    test('IoT bed stale (> 30 min) is not eligible', () {
      final bed = {
        'status': 'available',
        'source': 'iot',
        'last_updated': DateTime.now().subtract(const Duration(minutes: 60)),
      };
      expect(_isBedEligible(bed), isFalse);
    });
  });
}
