import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// IoTSimulatorService
///
/// Mimics the behavior of real ESP32 sensors for development & testing.
/// Fires Firestore writes that are structurally identical to what a
/// real Bed Occupancy B.O. device would send through the Cloud Function.
///
/// Includes hardware debounce protection:
/// - Ignores bed updates within [_throttleMs] of the last write for that bed
///   (mirrors the ESP32-side 5-second bounce guard in the Cloud Function)
///
/// Usage (call from BedManagementScreen FAB):
///   final sim = IoTSimulatorService();
///   sim.startBedSimulation('hosp_123');
///   sim.startAmbulanceSimulation('hosp_123', 'AMB_001');
///   sim.stopAll();
class IoTSimulatorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random();
  final List<Timer> _timers = [];

  // Throttle: track last write timestamp per bed key (roomId_bedId)
  final Map<String, DateTime> _lastWriteTime = {};
  static const int _throttleMs = 5000; // 5 seconds — matches Cloud Fn debounce

  bool _isThrottled(String key) {
    final last = _lastWriteTime[key];
    if (last == null) return false;
    return DateTime.now().difference(last).inMilliseconds < _throttleMs;
  }

  void _markWritten(String key) => _lastWriteTime[key] = DateTime.now();

  // ─────────────────── PUBLIC API ───────────────────

  /// Simulates random bed occupancy changes every [intervalSec] seconds.
  void startBedSimulation(String hospitalId, {int intervalSec = 15}) {
    final timer = Timer.periodic(Duration(seconds: intervalSec), (_) async {
      await _simulateBedUpdate(hospitalId);
    });
    _timers.add(timer);
    print('[B.O.-SIM] Bed simulation started for $hospitalId (every ${intervalSec}s)');
  }

  /// Simulates a moving ambulance updating its GPS every [intervalSec] seconds.
  void startAmbulanceSimulation(String hospitalId, String ambulanceId, {int intervalSec = 5}) {
    double lat = 28.5672 + (_random.nextDouble() - 0.5) * 0.05;
    double lng = 77.2100 + (_random.nextDouble() - 0.5) * 0.05;

    final timer = Timer.periodic(Duration(seconds: intervalSec), (_) async {
      lat += (_random.nextDouble() - 0.5) * 0.002;
      lng += (_random.nextDouble() - 0.5) * 0.002;
      await _simulateAmbulanceUpdate(hospitalId, ambulanceId, lat, lng);
    });
    _timers.add(timer);
    print('[B.O.-SIM] Ambulance simulation started for $ambulanceId');
  }

  /// Simulates sensor-driven inventory level changes.
  void startEquipmentSimulation(String hospitalId, String itemId, {int intervalSec = 30}) {
    final timer = Timer.periodic(Duration(seconds: intervalSec), (_) async {
      await _simulateEquipmentUpdate(hospitalId, itemId);
    });
    _timers.add(timer);
    print('[B.O.-SIM] Equipment simulation started for item $itemId');
  }

  void stopAll() {
    for (final t in _timers) t.cancel();
    _timers.clear();
    _lastWriteTime.clear();
    print('[B.O.-SIM] All simulations stopped.');
  }

  // ─────────────────── PRIVATE HELPERS ───────────────────

  Future<void> _simulateBedUpdate(String hospitalId) async {
    try {
      final roomsSnap = await _db
          .collection('hospitals')
          .doc(hospitalId)
          .collection('rooms')
          .limit(5)
          .get();

      if (roomsSnap.docs.isEmpty) {
        print('[B.O.-SIM] No rooms found — seed rooms first.');
        return;
      }

      final roomDoc = roomsSnap.docs[_random.nextInt(roomsSnap.docs.length)];
      final beds = (roomDoc.data()['beds'] as Map<String, dynamic>?) ?? {};
      if (beds.isEmpty) return;

      final bedKeys = beds.keys.toList();
      final bedId = bedKeys[_random.nextInt(bedKeys.length)];
      final throttleKey = '${roomDoc.id}_$bedId';

      // Debounce guard — skip if we just wrote this bed
      if (_isThrottled(throttleKey)) {
        print('[B.O.-SIM] Throttled — skipping $throttleKey');
        return;
      }

      final bedData = beds[bedId] as Map<String, dynamic>;
      final currentStatus = bedData['status'] as String? ?? 'available';
      final newStatus = currentStatus == 'available' ? 'occupied' : 'available';

      final batch = _db.batch();
      final roomRef = roomDoc.reference;
      final hospitalRef = _db.collection('hospitals').doc(hospitalId);

      batch.update(roomRef, {
        'beds.$bedId.status': newStatus,
        'beds.$bedId.last_updated': FieldValue.serverTimestamp(),
        'beds.$bedId.source': 'iot',
        'beds.$bedId.device_id': 'esp32_sim_${roomDoc.id}_$bedId',
      });

      final diff = newStatus == 'available' ? 1 : -1;
      batch.update(hospitalRef, {
        'beds_available': FieldValue.increment(diff),
        'beds.available': FieldValue.increment(diff),
        'last_updated': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      _markWritten(throttleKey);
      print('[B.O.-SIM] Bed $bedId in Room ${roomDoc.id} → $newStatus');
    } catch (e) {
      print('[B.O.-SIM] Bed simulation error: $e');
    }
  }

  Future<void> _simulateAmbulanceUpdate(
    String hospitalId,
    String ambulanceId,
    double lat,
    double lng,
  ) async {
    try {
      await _db.collection('ambulances').doc(ambulanceId).set({
        'hospital_id': hospitalId,
        'lat': lat,
        'lng': lng,
        'speed_kmh': 30.0 + _random.nextDouble() * 40.0,
        'status': 'dispatched',
        'last_updated': FieldValue.serverTimestamp(),
        'source': 'iot',
        'device_id': 'esp32_gps_$ambulanceId',
      }, SetOptions(merge: true));
      print('[B.O.-SIM] Ambulance $ambulanceId → lat:$lat lng:$lng');
    } catch (e) {
      print('[B.O.-SIM] Ambulance error: $e');
    }
  }

  Future<void> _simulateEquipmentUpdate(String hospitalId, String itemId) async {
    try {
      final level = 20.0 + _random.nextDouble() * 80.0;
      final status = level < 30.0 ? 'critical' : (level < 50.0 ? 'low' : 'normal');
      await _db
          .collection('hospitals')
          .doc(hospitalId)
          .collection('inventory')
          .doc(itemId)
          .update({
        'sensor_level': level,
        'sensor_status': status,
        'source': 'iot',
        'last_updated': FieldValue.serverTimestamp(),
      });
      print('[B.O.-SIM] Equipment $itemId → ${level.toStringAsFixed(1)}% $status');
    } catch (e) {
      print('[B.O.-SIM] Equipment error: $e');
    }
  }
}
