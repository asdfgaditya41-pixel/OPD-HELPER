import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String? id;
  final String userId;
  final String hospitalId;
  final String patientName;
  final int age;
  final String gender;
  final String contactNumber;
  final String symptoms;
  final bool isEmergency;
  final String bedType;
  final String? assignedRoom;
  final String? assignedBed;
  final String status;
  final DateTime? createdAt;

  Appointment({
    this.id,
    required this.userId,
    required this.hospitalId,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.contactNumber,
    required this.symptoms,
    required this.isEmergency,
    required this.bedType,
    this.assignedRoom,
    this.assignedBed,
    required this.status,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'hospital_id': hospitalId,
      'patient_name': patientName,
      'age': age,
      'gender': gender,
      'contact_number': contactNumber,
      'symptoms': symptoms,
      'is_emergency': isEmergency,
      'bed_type': bedType,
      'assigned_room': assignedRoom,
      'assigned_bed': assignedBed,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
