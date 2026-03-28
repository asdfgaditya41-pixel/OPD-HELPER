import 'package:firebase_database/firebase_database.dart';

import '../models/analytics_data.dart';

class AnalyticsService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Stream<AnalyticsData?> watchAnalytics(String hospitalId) {
    final ref = _db.ref('hospitals/$hospitalId/analytics');
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      final map = value as Map<dynamic, dynamic>;
      return AnalyticsData.fromMap(map);
    });
  }
}

