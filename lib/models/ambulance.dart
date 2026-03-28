import 'package:cloud_firestore/cloud_firestore.dart';

class Ambulance {
  final String id;
  final String hospitalId;
  final String registrationNumber;
  final double lat;
  final double lng;
  final String status; // 'available', 'dispatched', 'returning'
  final DateTime lastUpdated;

  Ambulance({
    required this.id,
    required this.hospitalId,
    required this.registrationNumber,
    required this.lat,
    required this.lng,
    required this.status,
    required this.lastUpdated,
  });

  factory Ambulance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Ambulance(
      id: doc.id,
      hospitalId: data['hospital_id'] ?? '',
      registrationNumber: data['registration_number'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'available',
      lastUpdated: data['last_updated'] != null
          ? (data['last_updated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hospital_id': hospitalId,
      'registration_number': registrationNumber,
      'lat': lat,
      'lng': lng,
      'status': status,
      'last_updated': FieldValue.serverTimestamp(),
    };
  }
}
