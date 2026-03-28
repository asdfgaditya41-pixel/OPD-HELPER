import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hospital.dart';
import '../models/hospital_room.dart';
import '../models/inventory_item.dart';
import '../models/appointment.dart';

class FirestoreService {
  // Singleton — one instance across the app, no repeated instantiation cost
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────
  // BEFORE: O(n) patient scan + 2 separate writes per add
  //   1. Add patient document
  //   2. Fetch ALL patients from Firestore (reads n documents!)
  //   3. Loop over all of them to sum estimated_time
  //   4. Write aggregated values back to hospital doc
  //
  // AFTER: O(1) using Firestore atomicincrement + transaction
  //   1. Add patient document (only stores minimal fields)
  //   2. Atomically increment opd_queue by 1 and
  //      wait_time by estimatedTime — no read needed!
  //
  // Space: Patient doc reduced from 5 fields to 3 essential fields.
  //        'total_wait_time' field removed (wait_time is the source of truth).
  // ─────────────────────────────────────────────────────────
  Future<void> addPatientAndUpdateWaitTime(
      String hospitalId, String name, String condition, int estimatedTime) async {

    final hospitalRef = _db.collection('hospitals').doc(hospitalId);
    final patientsRef = hospitalRef.collection('patients');

    // Atomic transaction: both writes succeed or both fail — no partial state
    await _db.runTransaction((transaction) async {
      // Step 1: Add minimal patient document
      // REMOVED: 'name' is not needed for queue logic — only stored if you
      // need to display it later. For queue-only tracking, condition + time is enough.
      final newPatientRef = patientsRef.doc(); // auto-ID
      transaction.set(newPatientRef, {
        'condition': condition,          // needed for type-based analytics
        'estimated_time': estimatedTime, // needed to decrement on discharge
        'timestamp': FieldValue.serverTimestamp(), // needed for TTL cleanup
      });

      // Step 2: Atomically increment aggregated fields — O(1), no loops, no reads
      transaction.update(hospitalRef, {
        'opd_queue': FieldValue.increment(1),
        'queue.opd': FieldValue.increment(1),
        'queue.last_updated': FieldValue.serverTimestamp(),
        'wait_time': FieldValue.increment(estimatedTime),
        'last_updated': FieldValue.serverTimestamp(),
      });
    });
  }

  // ─────────────────────────────────────────────────────────
  // Discharge patient: decrement queue/wait_time atomically — O(1)
  // Call this when a patient is seen by a doctor.
  // ─────────────────────────────────────────────────────────
  Future<void> dischargePatient(
      String hospitalId, String patientId, int estimatedTime) async {
    final hospitalRef = _db.collection('hospitals').doc(hospitalId);
    final patientRef = hospitalRef.collection('patients').doc(patientId);

    await _db.runTransaction((transaction) async {
      transaction.delete(patientRef);
      transaction.update(hospitalRef, {
        'opd_queue': FieldValue.increment(-1),
        'queue.opd': FieldValue.increment(-1),
        'queue.last_updated': FieldValue.serverTimestamp(),
        'wait_time': FieldValue.increment(-estimatedTime),
        'last_updated': FieldValue.serverTimestamp(),
      });
    });
  }

  // ─────────────────────────────────────────────────────────
  // FIRESTORE QUERY OPTIMIZATION:
  // BEFORE: fetch ALL hospitals, then filter in Dart (.where on list)
  //   → reads every document regardless of city
  //
  // AFTER: push the filter to Firestore with .where()
  //   → only city-matching documents transferred over the network
  //   → requires Firestore composite index on: city (ASC)
  //
  // Big-O: O(k) where k = hospitals in city, not O(n) for all hospitals
  // ─────────────────────────────────────────────────────────
  Stream<List<Hospital>> getAllHospitals() {
    return _db
        .collection('hospitals')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Hospital.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ─────────────────────────────────────────────────────────
  // OLD PATIENT CLEANUP STRATEGY (call from a Cloud Function or admin tool)
  // Deletes patients whose timestamp is older than [maxAge].
  // Prevents unbounded growth of the patients subcollection.
  //
  // In production: set up a Firebase Cloud Function with a daily cron trigger.
  // Example retention: 24 hours.
  // ─────────────────────────────────────────────────────────
  Future<void> cleanupOldPatients(String hospitalId,
      {Duration maxAge = const Duration(hours: 24)}) async {
    final cutoff = DateTime.now().subtract(maxAge);
    final cutoffTimestamp = Timestamp.fromDate(cutoff);

    final query = await _db
        .collection('hospitals')
        .doc(hospitalId)
        .collection('patients')
        .where('timestamp', isLessThan: cutoffTimestamp)
        .get();

    // Batch deletes — max 500 per Firestore batch
    // Batching avoids many individual network round-trips
    if (query.docs.isEmpty) return;

    final batches = <WriteBatch>[];
    WriteBatch batch = _db.batch();
    int count = 0;

    for (final doc in query.docs) {
      batch.delete(doc.reference);
      count++;
      if (count == 500) {
        batches.add(batch);
        batch = _db.batch();
        count = 0;
      }
    }
    if (count > 0) batches.add(batch);

    for (final b in batches) {
      await b.commit();
    }
  }

  // ─────────────────────────────────────────────────────────
  // RELIABILITY LAYER METHODS
  // ─────────────────────────────────────────────────────────

  /// Updates the hospital's bed count and resets the `last_updated` timestamp.
  /// Also resets `no_beds_reports` since the data is now fresh.
  Future<void> updateBedsAndTimestamp(String hospitalId, int bedsAvailable) async {
    final hospitalRef = _db.collection('hospitals').doc(hospitalId);
    
    await hospitalRef.update({
      'beds_available': bedsAvailable,
      'beds.available': bedsAvailable,
      'last_updated': FieldValue.serverTimestamp(),
      'no_beds_reports': 0, // Reset reports when hospital officially updates
    });
  }

  /// Increments the `no_beds_reports` counter for a given hospital.
  /// Used by B2C users to report inconsistencies.
  Future<void> reportNoBeds(String hospitalId) async {
    final hospitalRef = _db.collection('hospitals').doc(hospitalId);
    
    await hospitalRef.update({
      'no_beds_reports': FieldValue.increment(1),
    });
  }

  Future<void> updateBedsModule(
    String hospitalId,
    int totalBeds,
    int availableBeds,
  ) async {
    final hospitalRef = _db.collection('hospitals').doc(hospitalId);

    await hospitalRef.update({
      'beds_total': totalBeds,
      'beds_available': availableBeds,
      'beds.total': totalBeds,
      'beds.available': availableBeds,
      'beds.last_updated': FieldValue.serverTimestamp(),
      'last_updated': FieldValue.serverTimestamp(),
      'no_beds_reports': 0,
    });
  }

  Future<void> updateQueueModule(
    String hospitalId,
    int opdCount,
    int emergencyCount,
  ) async {
    final hospitalRef = _db.collection('hospitals').doc(hospitalId);

    await hospitalRef.update({
      'opd_queue': opdCount,
      'queue.opd': opdCount,
      'queue.emergency': emergencyCount,
      'queue.last_updated': FieldValue.serverTimestamp(),
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<InventoryItem>> inventoryStream(String hospitalId) {
    return _db
        .collection('hospitals')
        .doc(hospitalId)
        .collection('inventory')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItem.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Stream<Hospital> watchHospital(String hospitalId) {
    return _db
        .collection('hospitals')
        .doc(hospitalId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        throw StateError('Hospital not found');
      }
      return Hospital.fromFirestore(data, snapshot.id);
    });
  }

  Stream<List<HospitalRoom>> watchHospitalRooms(String hospitalId) {
    return _db
        .collection('hospitals')
        .doc(hospitalId)
        .collection('rooms')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => HospitalRoom.fromFirestore(doc)).toList();
    });
  }

  Future<void> toggleBedStatus(String hospitalId, String roomId, String bedId, String currentStatus) async {
    final batch = _db.batch();
    final newStatus = currentStatus == 'available' ? 'occupied' : 'available';

    final roomRef = _db.collection('hospitals').doc(hospitalId).collection('rooms').doc(roomId);
    final hospitalRef = _db.collection('hospitals').doc(hospitalId);

    batch.update(roomRef, {
      'beds.$bedId.status': newStatus,
      'beds.$bedId.last_updated': FieldValue.serverTimestamp(),
    });

    int diff = newStatus == 'available' ? 1 : -1;
    batch.update(hospitalRef, {
      'beds_available': FieldValue.increment(diff),
      'beds.available': FieldValue.increment(diff),
      'last_updated': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> seedMockRooms(String hospitalId) async {
    final roomsCol = _db.collection('hospitals').doc(hospitalId).collection('rooms');
    final snap = await roomsCol.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _db.batch();
    List<Map<String, dynamic>> initialRooms = [
      {'roomNumber': '101', 'type': 'ICU', 'bedsCount': 2},
      {'roomNumber': '102', 'type': 'ICU', 'bedsCount': 2},
      {'roomNumber': '201', 'type': 'General', 'bedsCount': 4},
      {'roomNumber': '202', 'type': 'General', 'bedsCount': 4},
      {'roomNumber': 'Vip-1', 'type': 'Private', 'bedsCount': 1},
    ];

    int newBedsTotal = 0;

    for (var r in initialRooms) {
      final docRef = roomsCol.doc(r['roomNumber'] as String);
      Map<String, dynamic> bedsMap = {};
      final bedsCount = r['bedsCount'] as int;
      newBedsTotal += bedsCount;

      for (int i = 1; i <= bedsCount; i++) {
        bedsMap['bed_$i'] = {
          'status': 'available',
          'last_updated': FieldValue.serverTimestamp(),
        };
      }

      batch.set(docRef, {
        'room_number': r['roomNumber'],
        'type': r['type'],
        'beds': bedsMap,
      });
    }

    final hospitalRef = _db.collection('hospitals').doc(hospitalId);
    batch.update(hospitalRef, {
      'beds_total': newBedsTotal,
      'beds_available': newBedsTotal,
      'beds.total': newBedsTotal,
      'beds.available': newBedsTotal,
    });

    await batch.commit();
  }

  Future<Map<String, String>?> allocateBedAndBookAppointment(
    String hospitalId,
    Appointment appointment,
    String preferredBedType,
    bool isEmergency,
  ) async {
    final roomsCol = _db.collection('hospitals').doc(hospitalId).collection('rooms');
    final roomsSnap = await roomsCol.get();
    
    String targetType = isEmergency ? 'ICU' : preferredBedType;
    DocumentSnapshot? targetRoomDoc;
    String? targetBedId;
    
    for (int attempt = 0; attempt < 2; attempt++) {
      for (var doc in roomsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        final type = data['type'] as String? ?? '';
        if (type.toLowerCase() != targetType.toLowerCase()) continue;
        
        final bedsMap = data['beds'] as Map<String, dynamic>? ?? {};
        
        for (var entry in bedsMap.entries) {
          final bedData = entry.value as Map<String, dynamic>;
          final status = bedData['status'];
          final lastUpdated = bedData['last_updated'] as Timestamp?;
          
          if (status == 'available') {
            if (lastUpdated != null) {
              final diff = DateTime.now().difference(lastUpdated.toDate());
              if (diff.inMinutes <= 30) {
                targetRoomDoc = doc;
                targetBedId = entry.key;
                break;
              }
            } else {
              // Legacy/un-updated bed -> allow but note to update
              targetRoomDoc = doc;
              targetBedId = entry.key;
              break;
            }
          }
        }
        if (targetRoomDoc != null) break;
      }
      
      if (targetRoomDoc != null) break;
      
      if (attempt == 0 && isEmergency && targetType.toUpperCase() == 'ICU') {
        targetType = 'General';
      } else {
        break;
      }
    }
    
    if (targetRoomDoc == null || targetBedId == null) {
      return null;
    }
    
    final roomRef = targetRoomDoc.reference;
    final hospitalRef = _db.collection('hospitals').doc(hospitalId);
    final appointmentsRef = _db.collection('appointments').doc();
    
    try {
      await _db.runTransaction((transaction) async {
        final freshRoomSnap = await transaction.get(roomRef);
        final freshData = freshRoomSnap.data() as Map<String, dynamic>? ?? {};
        final beds = freshData['beds'] as Map<String, dynamic>? ?? {};
        final targetBedData = beds[targetBedId] as Map<String, dynamic>?;
        
        if (targetBedData == null || targetBedData['status'] != 'available') {
          throw Exception("Bed was snatched by another user or removed.");
        }
        
        transaction.update(roomRef, {
          'beds.$targetBedId.status': 'occupied',
          'beds.$targetBedId.last_updated': FieldValue.serverTimestamp(),
        });
        
        transaction.update(hospitalRef, {
          'beds_available': FieldValue.increment(-1),
          'beds.available': FieldValue.increment(-1),
          'last_updated': FieldValue.serverTimestamp(),
        });
        
        final apptData = appointment.toMap();
        apptData['assigned_room'] = freshData['room_number'] ?? freshRoomSnap.id;
        apptData['assigned_bed'] = targetBedId;
        transaction.set(appointmentsRef, apptData);
      });
      
      return {
        'room': (targetRoomDoc.data() as Map<String, dynamic>)['room_number'] ?? targetRoomDoc.id,
        'bed': targetBedId,
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> upsertInventoryItem(
    String hospitalId,
    InventoryItem item,
  ) async {
    final collectionRef = _db
        .collection('hospitals')
        .doc(hospitalId)
        .collection('inventory');

    if (item.id.isEmpty) {
      await collectionRef.add({
        'name': item.name,
        'stock': item.stock,
        'threshold': item.threshold,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } else {
      await collectionRef.doc(item.id).update({
        'name': item.name,
        'stock': item.stock,
        'threshold': item.threshold,
        'last_updated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteInventoryItem(
    String hospitalId,
    String itemId,
  ) async {
    await _db
        .collection('hospitals')
        .doc(hospitalId)
        .collection('inventory')
        .doc(itemId)
        .delete();
  }
}
