import 'package:cloud_firestore/cloud_firestore.dart';

class Hospital {
  final String id;
  final String name;
  final String location;
  final int opdQueue;
  final int doctors;
  final int avgConsultTime;
  final int bedsAvailable;
  final double lat;
  final double lng;
  final int waitTime;
  final String city;
  final String zone;
  final double loadIndex;
  final String contactNumber;
  final DateTime? lastUpdated;
  final int noBedsReports;

  Hospital({
    required this.id,
    required this.name,
    required this.location,
    required this.opdQueue,
    required this.doctors,
    required this.avgConsultTime,
    required this.bedsAvailable,
    required this.lat,
    required this.lng,
    required this.waitTime,
    required this.city,
    required this.zone,
    required this.loadIndex,
    required this.contactNumber,
    this.lastUpdated,
    this.noBedsReports = 0,
  });

  factory Hospital.fromFirestore(Map<String, dynamic> data, String id) {
    return Hospital(
      id: id,
      name: data['name'],
      location: data['location'],
      opdQueue: data['opd_queue'],
      doctors: data['doctors'],
      avgConsultTime: data['avg_consult_time'],
      bedsAvailable: data['beds_available'],
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      city: data['city'] ?? 'Delhi',
      zone: data['zone'] ?? 'Unknown',
      loadIndex: (data['load_index'] ?? 0).toDouble(),
      contactNumber: data['contact_number'] ?? '102',
      lastUpdated: data['last_updated'] != null
          ? (data['last_updated'] as Timestamp).toDate()
          : null,
      noBedsReports: data['no_beds_reports'] ?? 0,
      waitTime:
          data['wait_time'] ??
          (data['doctors'] == 0
              ? 0
              : (((data['opd_queue'] ?? 0) / data['doctors']) *
                        (data['avg_consult_time'] ?? 0))
                    .toInt()),
    );
  }
}
