class AnalyticsData {
  final String peakHours;
  final int dailyPatients;
  final List<int> waitTimes;
  final List<int> queueSizes;
  final DateTime? lastUpdated;

  AnalyticsData({
    required this.peakHours,
    required this.dailyPatients,
    required this.waitTimes,
    required this.queueSizes,
    this.lastUpdated,
  });

  bool get hasData =>
      peakHours.isNotEmpty ||
      dailyPatients > 0 ||
      waitTimes.isNotEmpty ||
      queueSizes.isNotEmpty;

  int get averageWaitTime {
    if (waitTimes.isEmpty) return 0;
    final sum = waitTimes.reduce((a, b) => a + b);
    return sum ~/ waitTimes.length;
  }

  factory AnalyticsData.fromMap(Map<dynamic, dynamic> data) {
    final rawWaits = data['wait_times'] as List<dynamic>? ?? [];
    final waits = rawWaits.map((e) {
      if (e is int) return e;
      if (e is double) return e.toInt();
      return int.tryParse(e.toString()) ?? 0;
    }).toList();

    final rawQueues = data['queue_sizes'] as List<dynamic>? ?? [];
    final queues = rawQueues.map((e) {
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
      queueSizes: queues,
      lastUpdated: last,
    );
  }
}

