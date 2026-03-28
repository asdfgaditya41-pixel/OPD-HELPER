import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalBed {
  final String id;
  final String status; // 'available' or 'occupied'
  final DateTime? lastUpdated;
  final String? source; // "iot" or "manual"
  final String? deviceId;

  HospitalBed({
    required this.id,
    required this.status,
    this.lastUpdated,
    this.source,
    this.deviceId,
  });

  factory HospitalBed.fromMap(String id, Map<String, dynamic> data) {
    return HospitalBed(
      id: id,
      status: data['status'] ?? 'available',
      source: data['source'],
      deviceId: data['device_id'],
      lastUpdated: data['last_updated'] != null
          ? (data['last_updated'] as Timestamp).toDate()
          : null,
    );
  }
}

class HospitalRoom {
  final String id;
  final String roomNumber;
  final String type; // 'ICU', 'General', 'Private'
  final Map<String, HospitalBed> beds;

  HospitalRoom({
    required this.id,
    required this.roomNumber,
    required this.type,
    required this.beds,
  });

  factory HospitalRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    Map<String, HospitalBed> parsedBeds = {};
    if (data['beds'] != null) {
      final bedsMap = data['beds'] as Map<String, dynamic>;
      bedsMap.forEach((key, value) {
        parsedBeds[key] = HospitalBed.fromMap(key, value as Map<String, dynamic>);
      });
    }

    return HospitalRoom(
      id: doc.id,
      roomNumber: data['room_number'] ?? doc.id,
      type: data['type'] ?? 'General',
      beds: parsedBeds,
    );
  }
}
