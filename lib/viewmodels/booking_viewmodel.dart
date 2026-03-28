import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/firestore_service.dart';
import '../models/hospital.dart';

class BookingViewModel extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  // Form State
  String patientName = '';
  int age = 30;
  String gender = 'Male';
  String contactNumber = '';
  String symptoms = '';
  bool isEmergency = false;
  String preferredBedType = 'General'; // General, ICU, Private

  // Booking State
  bool isBooking = false;
  bool isSuccess = false;
  String? errorMessage;
  String? assignedRoom;
  String? assignedBed;

  void reset() {
    isBooking = false;
    isSuccess = false;
    errorMessage = null;
    assignedRoom = null;
    assignedBed = null;
    preferredBedType = 'General';
    isEmergency = false;
  }

  void updateName(String val) { patientName = val; notifyListeners(); }
  void updateAge(int val) { age = val; notifyListeners(); }
  void updateGender(String val) { gender = val; notifyListeners(); }
  void updateContact(String val) { contactNumber = val; notifyListeners(); }
  void updateSymptoms(String val) { symptoms = val; notifyListeners(); }
  
  void toggleEmergency(bool val) { 
    isEmergency = val;
    if (val) {
      preferredBedType = 'ICU'; // Auto-escalate
    }
    notifyListeners(); 
  }
  
  void updateBedType(String val) { 
    preferredBedType = val; 
    notifyListeners(); 
  }

  Future<void> submitBooking(String userId, Hospital hospital) async {
    if (patientName.trim().isEmpty || contactNumber.trim().isEmpty || symptoms.trim().isEmpty) {
      errorMessage = "Please fill in all required fields.";
      notifyListeners();
      return;
    }

    isBooking = true;
    errorMessage = null;
    notifyListeners();

    try {
      final appointment = Appointment(
        userId: userId,
        hospitalId: hospital.id,
        patientName: patientName.trim(),
        age: age,
        gender: gender,
        contactNumber: contactNumber.trim(),
        symptoms: symptoms.trim(),
        isEmergency: isEmergency,
        bedType: isEmergency ? 'ICU' : preferredBedType,
        status: 'confirmed',
      );

      final result = await _service.allocateBedAndBookAppointment(
        hospital.id,
        appointment,
        preferredBedType,
        isEmergency,
      );

      if (result != null) {
        isSuccess = true;
        assignedRoom = result['room'];
        assignedBed = result['bed'];
      } else {
        errorMessage = "Real-time availability not reliable, or no valid beds are currently open.\nPlease confirm directly at the hospital.";
      }
    } catch (e) {
      errorMessage = "An error occurred while communicating with the hospital servers.";
    }

    isBooking = false;
    notifyListeners();
  }
}
