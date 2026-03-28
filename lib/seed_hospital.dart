// Run this ONCE to seed the hospital into Firestore.
// Command: flutter run -t lib/seed_hospital.dart
// After done, delete this file.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await seedHospital();
  runApp(const _DoneApp());
}

Future<void> seedHospital() async {
  final db = FirebaseFirestore.instance;

  await db.collection('hospitals').doc('chhatrapati_shivaji_subharti').set({
    'name': 'Chhatrapati Shivaji Subharti Hospital',
    'location': 'NH-58, Subhartipuram, Meerut, Uttar Pradesh 250005',
    'city': 'Meerut',
    'zone': 'West UP',
    'lat': 29.028557200000002,
    'lng': 77.668991000000005,
    'opd_queue': 18,
    'doctors': 12,
    'avg_consult_time': 10,
    'beds_available': 45,
    'wait_time': 15,
    'load_index': 0.42,
    'contact_number': '0121-2439196',
    'last_updated': FieldValue.serverTimestamp(),
  });

  debugPrint('✅ Hospital added to Firestore successfully!');
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
                '✅ Hospital Added!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Chhatrapati Shivaji Subharti Hospital\nsuccessfully added to Firestore.\n\nYou can close the app now.',
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
