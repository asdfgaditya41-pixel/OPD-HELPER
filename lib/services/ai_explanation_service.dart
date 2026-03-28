import '../models/hospital.dart';
import '../models/hospital_room.dart';
import '../services/firestore_service.dart';
import '../viewmodels/hospital_viewmodel.dart';
import 'dart:math';

class AiExplanationService {
  // Cache: key = "question|topHospitalId", value = (response, cachedAt)
  // TTL: 60 seconds — avoids redundant Firestore room queries on repeated taps
  static final Map<String, (String, DateTime)> _responseCache = {};
  static const int _cacheTtlSeconds = 60;

  static Future<String> generateResponse(
      String question, HospitalViewModel vm) async {

    final topEmergencyHospitals = vm.getTopEmergencyHospitals();
    final topHospital = topEmergencyHospitals.isNotEmpty ? topEmergencyHospitals.first : null;
    final cacheKey = '$question|${topHospital?.id ?? "none"}';

    // Return cached response if still fresh
    final cached = _responseCache[cacheKey];
    if (cached != null) {
      final age = DateTime.now().difference(cached.$2).inSeconds;
      if (age < _cacheTtlSeconds) {
        await Future.delayed(const Duration(milliseconds: 300)); // brief UX delay
        return cached.$1;
      }
    }

    // Simulate API delay for realistic AI feel
    await Future.delayed(Duration(milliseconds: 1000 + Random().nextInt(800)));

    final hospitals = vm.filteredHospitals;
    if (hospitals.isEmpty) {
      return "I couldn't find any hospitals under your current filter settings. Try expanding your search or turning on GPS!";
    }

    if (question == "Why this hospital?") {
      if (topHospital == null) {
        return "At the moment, our algorithms don't have enough data to strongly recommend a specific hospital.";
      }
      final dist = vm.getDistance(topHospital.lat, topHospital.lng).toStringAsFixed(1);
      final wait = topHospital.waitTime;
      final queue = topHospital.opdQueue;
      final beds = vm.getPredictedBeds(topHospital);

      // AI Context Enhancement: Check specific room availability
      String roomAddendum = "";
      try {
        final roomsList = await FirestoreService().watchHospitalRooms(topHospital.id).first;
        
        HospitalRoom? bestRoom;
        int maxAvailable = 0;
        
        // Prefer citing ICU rooms first for emergencies
        for (var r in roomsList) {
          int avail = r.beds.values.where((b) => b.status == 'available').length;
          if (avail > 0) {
            if (r.type == 'ICU') {
              if (bestRoom?.type != 'ICU' || avail > maxAvailable) {
                bestRoom = r;
                maxAvailable = avail;
              }
            } else {
              if (bestRoom == null || (bestRoom.type != 'ICU' && avail > maxAvailable)) {
                bestRoom = r;
                maxAvailable = avail;
              }
            }
          }
        }

        if (bestRoom != null) {
          roomAddendum = " Most notably, it currently has $maxAvailable ${bestRoom.type} bed${maxAvailable > 1 ? 's' : ''} physically open and ready in Room ${bestRoom.roomNumber}!";
        }
      } catch (_) {
        // Safe fallback if rooms fail to load
      }

      return "I recommended **${topHospital.name}** because it strikes the perfect balance. "
             "Although it is $dist km away, it has a manageable wait time of about $wait minutes (current queue: $queue) "
             "and $beds estimated available beds overall.$roomAddendum It is statistically the safest and most efficient choice right now.";
    }

    if (question == "Is there a closer option?") {
      if (vm.userLat == null || vm.userLng == null) {
        return "I need your GPS location enabled to find the closest hospital!";
      }

      // Find the absolute closest hospital
      Hospital closest = hospitals.first;
      double minD = vm.getDistance(closest.lat, closest.lng);
      
      for (var h in hospitals) {
        final d = vm.getDistance(h.lat, h.lng);
        if (d < minD) {
          minD = d;
          closest = h;
        }
      }

      if (topHospital != null && closest.id == topHospital.id) {
        return "Actually, **${topHospital.name}** is already the absolute closest option to you at ${minD.toStringAsFixed(1)} km!";
      }

      final closestWait = closest.waitTime;
      
      return "Yes. **${closest.name}** is physically closer to you (${minD.toStringAsFixed(1)} km away). "
             "However, I didn't make it my top recommendation because it currently faces an estimated wait time of $closestWait minutes. "
             "If you have a minor issue, it might be fine, but for speed, the recommended hospital is statistically better.";
    }

    if (question == "Which has lowest wait time?") {
      Hospital lowestWait = hospitals.first;
      
      for (var h in hospitals) {
        if (h.waitTime < lowestWait.waitTime) {
          lowestWait = h;
        }
      }

      final dist = vm.getDistance(lowestWait.lat, lowestWait.lng).toStringAsFixed(1);

      if (lowestWait.waitTime == 0) {
        return "**${lowestWait.name}** currently has no reported wait time! It is $dist km away from your location.";
      }
      return "**${lowestWait.name}** boasts the fastest projected turnaround right now, with an estimated wait of only ${lowestWait.waitTime} minutes. It's $dist km away.";
    }

    // Default Fallback
    final fallback = "I analyze hundreds of data points every few seconds including real-time hospital queues, available beds, and geometric distance to instantly calculate where you will receive care the fastest.";
    _responseCache[cacheKey] = (fallback, DateTime.now());
    return fallback;
  }

  /// Evict all cached responses (call when hospital data refreshes significantly)
  static void clearCache() => _responseCache.clear();
}
