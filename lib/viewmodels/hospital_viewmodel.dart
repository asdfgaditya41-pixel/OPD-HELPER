import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/hospital.dart';
import '../services/firestore_service.dart';

enum ConfidenceLevel { High, Medium, Low }

class HospitalViewModel extends ChangeNotifier {

  // ─────────────────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────────────────
  List<Hospital> hospitals = [];        // filtered: within 50km of user
  List<Hospital> _allHospitals = [];    // raw: all from Firestore
  bool isLoading = true;
  static const double _radiusKm = 50.0;
  
  String selectedTypeFilter = 'all';

  List<Hospital> get filteredHospitals {
    if (selectedTypeFilter == 'all') return hospitals;
    return hospitals.where((h) => h.type.toLowerCase() == selectedTypeFilter).toList();
  }

  void setHospitalTypeFilter(String filter) {
    if (selectedTypeFilter != filter) {
      selectedTypeFilter = filter;
      notifyListeners();
    }
  }

  double? userLat;
  double? userLng;

  // ─────────────────────────────────────────────────────────
  // CACHED COMPUTED VALUES
  // BEFORE: avgWaitTime, totalBeds, mostCrowded, bestHospital were all
  //   getters computed inside build() on every repaint → O(n) per frame
  //
  // AFTER: Computed once when hospitals list changes, stored in private fields.
  //   UI reads _cachedAvgWait — O(1) access per frame.
  // ─────────────────────────────────────────────────────────
  double _cachedAvgWait = 0.0;
  int _cachedTotalBeds = 0;
  Hospital? _cachedMostCrowded;
  Hospital? _cachedBestHospital;

  double get avgWaitTime => _cachedAvgWait;
  int get totalBeds => _cachedTotalBeds;
  Hospital? get mostCrowded => _cachedMostCrowded;
  Hospital? get bestHospital => _cachedBestHospital;

  // Stream subscription — keep a reference so we can cancel on city change
  // BEFORE: each changeCity() call added a new listener but never cancelled the old one
  //   → memory leak: multiple active listeners accumulating over time
  StreamSubscription<List<Hospital>>? _hospitalsSubscription;

  // Singleton service — no repeated instantiation
  final FirestoreService _service = FirestoreService();

  final Map<String, int> conditionTimes = {
    'Fever': 10,
    'Cold': 8,
    'Injury': 20,
    'Chest Pain': 25,
    'Others': 15,
  };

  // ─────────────────────────────────────────────────────────
  // LOAD HOSPITALS
  // ─────────────────────────────────────────────────────────
  // BEFORE: fetched ALL hospitals, then filtered in Dart → O(n) reads
  // AFTER:  Firestore .where('city') server-side filter → O(k) reads
  //         where k = hospitals in selected city only
  // ─────────────────────────────────────────────────────────
  void loadHospitals() {
    // Cancel old subscription to prevent memory leak + stale data
    _hospitalsSubscription?.cancel();

    _hospitalsSubscription = _service
        .getAllHospitals()
        .listen((incoming) {
      _allHospitals = incoming;
      _applyRadiusFilter();
      isLoading = false;
      _recomputeCache();
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────────────────
  // RADIUS FILTER — keep only hospitals within 50km
  // If location not available yet, show all (will re-filter when location arrives)
  // ─────────────────────────────────────────────────────────
  void _applyRadiusFilter() {
    if (userLat == null || userLng == null) {
      // Location not yet known — show all hospitals so map isn't empty
      hospitals = List.from(_allHospitals);
    } else {
      hospitals = _allHospitals
          .where((h) => _distanceKm(h.lat, h.lng) <= _radiusKm)
          .toList();
    }
  }

  // ─────────────────────────────────────────────────────────
  // CACHE RECOMPUTATION — called once per Firestore update
  // Single pass over hospitals list computes ALL aggregates: O(n)
  // BEFORE: 4 separate O(n) passes (avgWait, totalBeds, mostCrowded, bestHospital)
  //         called individually inside build() on every frame
  // AFTER:  1 combined O(n) pass, result stored; UI reads are O(1)
  // ─────────────────────────────────────────────────────────
  void _recomputeCache() {
    if (hospitals.isEmpty) {
      _cachedAvgWait = 0.0;
      _cachedTotalBeds = 0;
      _cachedMostCrowded = null;
      _cachedBestHospital = null;
      return;
    }

    int totalWait = 0;
    int totalBeds = 0;
    Hospital? mostCrowded = hospitals.first;
    Hospital? best;
    double minScore = double.infinity;

    for (final h in hospitals) {
      // Aggregate stats
      totalWait += h.waitTime;
      totalBeds += h.bedsAvailable;

      // Most crowded — single pass max
      if (h.waitTime > mostCrowded!.waitTime) mostCrowded = h;

      // Best hospital score — single pass min
      if (userLat != null && userLng != null) {
        final dist = _distanceKm(h.lat, h.lng);
        final score = (h.waitTime * 0.4) + (dist * 0.4) - (h.bedsAvailable * 0.2);
        if (score < minScore) {
          minScore = score;
          best = h;
        }
      }
    }

    _cachedAvgWait = hospitals.isNotEmpty ? totalWait / hospitals.length : 0.0;
    _cachedTotalBeds = totalBeds;
    _cachedMostCrowded = mostCrowded;
    _cachedBestHospital = best;
  }

  // ─────────────────────────────────────────────────────────
  // ADD PATIENT — delegates to FirestoreService (O(1))
  // ─────────────────────────────────────────────────────────
  Future<void> addPatient(String id, String name, String condition) async {
    final estimatedTime = conditionTimes[condition] ?? 15;
    await _service.addPatientAndUpdateWaitTime(id, name, condition, estimatedTime);
    // No manual list update needed — Firestore stream pushes updated hospital doc
  }

  // ─────────────────────────────────────────────────────────
  // RELIABILITY LAYER & BED UPDATES
  // ─────────────────────────────────────────────────────────
  Future<void> updateBeds(String id, int bedsAvailable) async {
    await _service.updateBedsAndTimestamp(id, bedsAvailable);
  }

  Future<void> reportNoBeds(String id) async {
    await _service.reportNoBeds(id);
  }

  String getTimeAgoFormatted(DateTime? lastUpdated) {
    if (lastUpdated == null) return "Unknown";
    final diff = DateTime.now().difference(lastUpdated);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    return "${diff.inDays} days ago";
  }

  ConfidenceLevel getConfidenceLevel(Hospital h) {
    // High reports force Low Confidence immediately
    if (h.noBedsReports >= 3) return ConfidenceLevel.Low;

    if (h.lastUpdated == null) return ConfidenceLevel.Low;

    final diff = DateTime.now().difference(h.lastUpdated!);
    if (diff.inMinutes <= 30) return ConfidenceLevel.High;
    if (diff.inMinutes <= 120) return ConfidenceLevel.Medium;
    return ConfidenceLevel.Low;
  }

  int getPredictedBeds(Hospital h) {
    // If we have high/medium confidence, trust the actual stated beds
    if (getConfidenceLevel(h) != ConfidenceLevel.Low) {
      return h.bedsAvailable;
    }

    // Heuristic Fallback
    // Assume up to 10% of the current queue might occupy beds
    int potentialBedAdmissions = (h.opdQueue * 0.10).ceil();
    int currentHour = DateTime.now().hour;

    // Optional Time-of-day logic
    // Evictions/Discharges usually happen in the morning, meaning more beds open up.
    // Admissions without discharges often pile up in the evening/night.
    double timeMultiplier = 1.0;
    if (currentHour >= 18 || currentHour < 6) {
      timeMultiplier = 1.5; // Evening/Night: Admissions drain beds faster
    } else if (currentHour >= 8 && currentHour <= 12) {
      timeMultiplier = 0.5; // Morning: Discharges happening, beds might actually free up
    }

    int projectedTakenBeds = (potentialBedAdmissions * timeMultiplier).ceil();
    int predictedBeds = h.bedsAvailable - projectedTakenBeds;
    
    // Safety fallback: if noBedsReports are high, predict 0
    if (h.noBedsReports >= 3) predictedBeds = 0;

    return predictedBeds > 0 ? predictedBeds : 0;
  }

  List<Hospital> getTopEmergencyHospitals({int count = 3}) {
    if (hospitals.isEmpty || userLat == null || userLng == null) return [];

    final List<Map<String, dynamic>> scoredHospitals = [];

    for (var h in hospitals) {
      final dist = getDistance(h.lat, h.lng);
      final predictedBeds = getPredictedBeds(h);
      final confidence = getConfidenceLevel(h);

      // Scoring Weights
      // Distance is very important (lower is better, we will penalize distance)
      // Beds are important (more is better)
      // Confidence acts as a modifier
      
      double score = 0;
      score -= (dist * 10); // penalize distance heavily
      score += (predictedBeds * 2); // reward beds
      
      if (confidence == ConfidenceLevel.High) {
        score += 15;
      } else if (confidence == ConfidenceLevel.Low) score -= 15;

      scoredHospitals.add({'hospital': h, 'score': score, 'distance': dist});
    }

    // Sort descending by score (highest score first)
    scoredHospitals.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return scoredHospitals
        .take(count)
        .map((entry) => entry['hospital'] as Hospital)
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // LOCATION
  // ─────────────────────────────────────────────────────────
  Future<void> getUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // Step 1: Try last known position first — instant, no GPS wait
      Position? position = await Geolocator.getLastKnownPosition();

      if (position != null) {
        userLat = position.latitude;
        userLng = position.longitude;
        _applyRadiusFilter();
        _recomputeCache();
        notifyListeners();
      }

      // Step 2: Get a fresh accurate fix in background (20s timeout for real devices)
      try {
        final freshPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 20),
        );
        userLat = freshPosition.latitude;
        userLng = freshPosition.longitude;
        _applyRadiusFilter();
        _recomputeCache();
        notifyListeners();
      } catch (timeoutError) {
        // If fresh fix fails/times out, we already have last known position — that's fine
        debugPrint("Fresh GPS fix timed out, using last known: $timeoutError");
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  // ─────────────────────────────────────────────────────────
  // DISTANCE HELPER — private, reused internally
  // ─────────────────────────────────────────────────────────
  double _distanceKm(double lat, double lng) {
    if (userLat == null || userLng == null) return 0;
    return Geolocator.distanceBetween(userLat!, userLng!, lat, lng) / 1000;
  }

  // Public accessor for UI use
  double getDistance(double lat, double lng) => _distanceKm(lat, lng);

  // ─────────────────────────────────────────────────────────
  // SORTING — O(n log n) Dart sort (already efficient)
  // BEFORE: sortByDistance called getDistance() twice per comparison
  //   → O(n log n) comparisons × 2 distance calculations each
  //   → each getDistance() creates a closure and runs haversine formula
  //
  // AFTER: pre-compute distances into a map, then sort map — O(n) + O(n log n)
  // ─────────────────────────────────────────────────────────
  void sortByDistance() {
    if (userLat == null || userLng == null) return;
    // Pre-compute all distances: O(n) pass
    final distMap = {for (final h in hospitals) h.id: _distanceKm(h.lat, h.lng)};
    // Sort using pre-computed values: O(n log n), each comparison is O(1)
    hospitals.sort((a, b) => distMap[a.id]!.compareTo(distMap[b.id]!));
    notifyListeners();
  }

  void sortByWaitTime() {
    hospitals.sort((a, b) => a.waitTime.compareTo(b.waitTime));
    notifyListeners();
  }

  void sortByDoctors() {
    hospitals.sort((a, b) => b.doctors.compareTo(a.doctors));
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // ANALYTICS — these are O(1) pure functions (no loops)
  // ─────────────────────────────────────────────────────────
  int getExpectedConsultationTime(Hospital h) {
    if (h.doctors == 0) return h.waitTime;
    return (h.waitTime / (h.doctors * 0.8)).toInt();
  }

  String formatDuration(int minutes) {
    if (minutes == 0) return "0 min";
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return hours > 0 ? "${hours}h ${mins}m" : "${mins}m";
  }

  String getBestTimeToVisit(Hospital h) {
    if (h.waitTime < 30) return "Right now (Low Traffic)";
    if (h.waitTime < 60) return "Within the next hour";
    return "After 8:00 PM or Early Morning";
  }

  Color getLoadColor(int waitTime) {
    if (waitTime < 30) return Colors.greenAccent;
    if (waitTime < 60) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String getLoadText(int waitTime) {
    if (waitTime < 30) return "Low";
    if (waitTime < 60) return "Moderate";
    return "High";
  }

  List<double> generateHistoricalWaitTimes(Hospital h) {
    final base = h.waitTime > 0 ? h.waitTime : 15;
    return [base * 0.4, base * 0.6, base * 1.1, base * 1.5, base * 0.9, base.toDouble()];
  }

  // ─────────────────────────────────────────────────────────
  // CLEANUP — cancel stream subscription when ViewModel is disposed
  // BEFORE: no dispose(), subscription leaked until app close
  // ─────────────────────────────────────────────────────────
  @override
  void dispose() {
    _hospitalsSubscription?.cancel();
    super.dispose();
  }
}