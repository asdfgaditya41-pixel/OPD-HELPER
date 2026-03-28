class AnalyticsData {
  final String peakHours;
  final int dailyPatients;
  final List<int> waitTimes;
  final DateTime? lastUpdated;

  AnalyticsData({
    required this.peakHours,
    required this.dailyPatients,
    required this.waitTimes,
    this.lastUpdated,
  });

  bool get hasData =>
      peakHours.isNotEmpty ||
      dailyPatients > 0 ||
      waitTimes.isNotEmpty;

  factory AnalyticsData.fromMap(Map<dynamic, dynamic> data) {
    final rawWaits = data['wait_times'] as List<dynamic>? ?? [];
    final waits = rawWaits.map((e) {
      if (e is int) return e;
      if (e is double) return e.toInt();
      return int.tryParse(e.toString()) ?? 0;
    }).toList();

    DateTime? last;
    final rawLast = data['last_updated'];
    if (rawLast is int) {
      last = DateTime.fromMillisecondsSinceEpoch(rawLast);
    } else if (rawLast is String) {
      last = DateTime.tryParse(rawLast);
    }

    return AnalyticsData(
      peakHours: data['peak_hours']?.toString() ?? '',
      dailyPatients: data['daily_patients'] is int
          ? data['daily_patients'] as int
          : int.tryParse(data['daily_patients']?.toString() ?? '') ?? 0,
      waitTimes: waits,
      lastUpdated: last,
    );
  }
}

