// Run this ONCE to seed hospitals into Firestore.
// Command: flutter run -t lib/seed_hospital.dart
// After done, delete this file.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await seedHospitals();
  runApp(const _DoneApp());
}

Future<void> seedHospitals() async {
  final db = FirebaseFirestore.instance;

  final hospitals = [
    {
      'id': 'metro_hospital_heart_institute',
      'name': 'Metro Hospital & Heart Institute',
      'location': 'Delhi Road, Meerut, Uttar Pradesh',
      'city': 'Meerut',
      'zone': 'North Meerut',
      'lat': 28.9962847,
      'lng': 77.7085658,
      'opd_queue': 22,
      'doctors': 15,
      'avg_consult_time': 10,
      'beds_available': 80,
      'wait_time': 15,
      'load_index': 0.48,
      'contact_number': '0121-4040404',
    },
    {
      'id': 'lokpriya_hospital',
      'name': 'Lokpriya Hospital',
      'location': 'Meerut, Uttar Pradesh',
      'city': 'Meerut',
      'zone': 'Central Meerut',
      'lat': 28.9687701,
      'lng': 77.7305075,
      'opd_queue': 14,
      'doctors': 8,
      'avg_consult_time': 12,
      'beds_available': 35,
      'wait_time': 21,
      'load_index': 0.38,
      'contact_number': '102',
    },
    {
      'id': 'mrityunjay_hospital',
      'name': 'Mrityunjay Hospital',
      'location': 'Meerut, Uttar Pradesh',
      'city': 'Meerut',
      'zone': 'Central Meerut',
      'lat': 28.9875536,
      'lng': 77.706705,
      'opd_queue': 10,
      'doctors': 7,
      'avg_consult_time': 10,
      'beds_available': 30,
      'wait_time': 14,
      'load_index': 0.33,
      'contact_number': '102',
    },
    {
      'id': 'military_hospital_meerut',
      'name': 'Military Hospital Meerut Cantt',
      'location': 'Meerut Cantonment, Uttar Pradesh',
      'city': 'Meerut',
      'zone': 'Cantt Area',
      'lat': 28.9872682,
      'lng': 77.6894486,
      'opd_queue': 8,
      'doctors': 20,
      'avg_consult_time': 8,
      'beds_available': 120,
      'wait_time': 3,
      'load_index': 0.18,
      'contact_number': '0121-2640143',
    },
    {
      'id': 'prem_hospital',
      'name': 'Prem Hospital',
      'location': 'Meerut, Uttar Pradesh',
      'city': 'Meerut',
      'zone': 'South Meerut',
      'lat': 28.9440738,
      'lng': 77.6810149,
      'opd_queue': 12,
      'doctors': 6,
      'avg_consult_time': 12,
      'beds_available': 25,
      'wait_time': 24,
      'load_index': 0.45,
      'contact_number': '102',
    },
    {
      'id': 'vedant_hospital_meerut',
      'name': 'Vedant Hospital Meerut',
      'location': 'Meerut, Uttar Pradesh',
      'city': 'Meerut',
      'zone': 'East Meerut',
      'lat': 28.9619181,
      'lng': 77.7406008,
      'opd_queue': 9,
      'doctors': 5,
      'avg_consult_time': 10,
      'beds_available': 20,
      'wait_time': 18,
      'load_index': 0.35,
      'contact_number': '102',
    },
    {
      'id': 'aastha_hospital',
      'name': 'Aastha Hospital',
      'location': 'Meerut, Uttar Pradesh',
      'city': 'Meerut',
      'zone': 'West Meerut',
      'lat': 28.9708201,
      'lng': 77.6631934,
      'opd_queue': 7,
      'doctors': 5,
      'avg_consult_time': 10,
      'beds_available': 18,
      'wait_time': 14,
      'load_index': 0.28,
      'contact_number': '102',
    },
    {
      'id': 'kmc_hospital_meerut',
      'name': 'KMC Hospital Meerut',
      'location': 'Meerut, Uttar Pradesh',
      'city': 'Meerut',
      'zone': 'Central Meerut',
      'lat': 28.972817,
      'lng': 77.6889956,
      'opd_queue': 16,
      'doctors': 10,
      'avg_consult_time': 11,
      'beds_available': 50,
      'wait_time': 18,
      'load_index': 0.40,
      'contact_number': '0121-2600000',
    },
    {
      'id': 'anand_hospital',
      'name': 'Anand Hospital',
      'location': 'Meerut, Uttar Pradesh',
      'city': 'Meerut',
      'zone': 'East Meerut',
      'lat': 28.9616986,
      'lng': 77.7463143,
      'opd_queue': 11,
      'doctors': 6,
      'avg_consult_time': 10,
      'beds_available': 22,
      'wait_time': 18,
      'load_index': 0.36,
      'contact_number': '102',
    },
  ];

  final batch = db.batch();

  for (final h in hospitals) {
    final docRef = db.collection('hospitals').doc(h['id'] as String);
    batch.set(docRef, {
      'name': h['name'],
      'location': h['location'],
      'city': h['city'],
      'zone': h['zone'],
      'lat': h['lat'],
      'lng': h['lng'],
      'opd_queue': h['opd_queue'],
      'doctors': h['doctors'],
      'avg_consult_time': h['avg_consult_time'],
      'beds_available': h['beds_available'],
      'wait_time': h['wait_time'],
      'load_index': h['load_index'],
      'contact_number': h['contact_number'],
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  debugPrint('✅ All 9 hospitals added to Firestore successfully!');
}

class _DoneApp extends StatelessWidget {
  const _DoneApp();
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF0A1A20),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF00E5CC), size: 80),
              SizedBox(height: 20),
              Text(
                '✅ 9 Hospitals Added!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'All Meerut hospitals successfully\nadded to Firestore.\n\nYou can close the app now.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
