import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/hospital.dart';
import '../../viewmodels/auth_viewmodel.dart';

class BookingScreen extends StatefulWidget {
  final Hospital hospital;

  const BookingScreen({super.key, required this.hospital});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _isBooking = false;
  bool _success = false;

  void _confirmBooking() async {
    setState(() => _isBooking = true);
    // Simulate API booking call
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real app, send data to Firestore
    if (mounted) {
      setState(() {
        _isBooking = false;
        _success = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context);
    final user = authVm.appUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1A20),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Confirm Appointment", style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5CC)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_success) ...[
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 80),
                      const SizedBox(height: 24),
                      const Text(
                        "Booking Confirmed!",
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Your appointment at ${widget.hospital.name} has been successfully scheduled.",
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF122A34),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context); // Go back to map/home
                        },
                        child: const Text("Return Home", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ] else ...[
                      // Patient Details
                      const Text("Patient Details", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF122A34),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFF00BFA5).withOpacity(0.2),
                              backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                              child: user.photoUrl == null
                                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF00E5CC), fontSize: 24, fontWeight: FontWeight.w700))
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(user.email, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Hospital Details
                      const Text("Hospital Details", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF122A34),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFF00BFA5).withOpacity(0.15), shape: BoxShape.circle),
                                  child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF00E5CC), size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(widget.hospital.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.white.withOpacity(0.05), height: 1),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Current Queue", style: TextStyle(color: Colors.white54, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text("${widget.hospital.opdQueue} patients", style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("Est. Wait Time", style: TextStyle(color: Colors.white54, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text("${widget.hospital.waitTime} mins", style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 15, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 48),

                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF00BFA5), Color(0xFF00E5CC)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF00BFA5).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isBooking ? null : _confirmBooking,
                          child: _isBooking
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                              : const Text("Confirm Booking", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
      ),
    );
  }
}
