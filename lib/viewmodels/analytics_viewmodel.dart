import 'dart:async';

import 'package:flutter/material.dart';

import '../models/analytics_data.dart';
import '../services/analytics_service.dart';

class AnalyticsViewModel extends ChangeNotifier {
  final AnalyticsService _service = AnalyticsService();

  AnalyticsData? _data;
  bool _isLoading = false;
  StreamSubscription<AnalyticsData?>? _subscription;

  AnalyticsData? get data => _data;
  bool get isLoading => _isLoading;

  void startListening(String hospitalId) {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.watchAnalytics(hospitalId).listen(
      (value) {
        _data = value;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _data = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  String formatLastUpdated() {
    if (_data?.lastUpdated == null) return 'Unknown';
    final diff = DateTime.now().difference(_data!.lastUpdated!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
