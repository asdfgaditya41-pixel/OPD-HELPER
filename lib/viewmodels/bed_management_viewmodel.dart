import 'package:flutter/material.dart';
import '../models/hospital_room.dart';
import '../services/firestore_service.dart';

class BedManagementViewModel extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  
  List<HospitalRoom> _rooms = [];
  bool isLoading = true;

  List<HospitalRoom> get rooms => _rooms;

  void startListening(String hospitalId) {
    isLoading = true;
    notifyListeners();

    _service.watchHospitalRooms(hospitalId).listen((roomsData) {
      _rooms = roomsData;
      isLoading = false;
      notifyListeners();
    }, onError: (e) {
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> toggleBed(String hospitalId, String roomId, String bedId, String currentStatus) async {
    await _service.toggleBedStatus(hospitalId, roomId, bedId, currentStatus);
  }

  Future<void> seedInitialRooms(String hospitalId) async {
    await _service.seedMockRooms(hospitalId);
  }
  
  // Helpers for filtering B2C details map (e.g. ICU only, available only)
  int getAvailableBedsForType(String type) {
    int count = 0;
    for (var r in _rooms) {
      if (r.type.toLowerCase() == type.toLowerCase()) {
        count += r.beds.values.where((b) => b.status == 'available').length;
      }
    }
    return count;
  }

  int getTotalBedsForType(String type) {
    int count = 0;
    for (var r in _rooms) {
      if (r.type.toLowerCase() == type.toLowerCase()) {
        count += r.beds.values.length;
      }
    }
    return count;
  }
}
