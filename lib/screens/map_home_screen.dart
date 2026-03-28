import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hospital.dart';
import '../viewmodels/hospital_viewmodel.dart';
import 'tomtom_map_screen.dart';
import 'home_screen.dart';

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> with SingleTickerProviderStateMixin {
  bool _isLoadingLocation = true;
  bool _isFetchingLocation = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final vm = Provider.of<HospitalViewModel>(context, listen: false);
    vm.loadHospitals();
    _fetchLocation(vm);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation(HospitalViewModel vm) async {
    setState(() => _isFetchingLocation = true);
    await vm.getUserLocation(); // properly await so location is ready before map renders
    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
        _isFetchingLocation = false;
      });
      _animController.forward();
    }
  }

  Future<void> _retryLocation(HospitalViewModel vm) async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);
    await vm.getUserLocation();
    if (mounted) setState(() => _isFetchingLocation = false);
  }

  void _handleEmergency(HospitalViewModel vm) {
    if (vm.hospitals.isEmpty || vm.userLat == null || vm.userLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot locate nearest hospital at the moment.', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF122A34),
        ),
      );
      return;
    }

    Hospital? nearest;
    double minDistance = double.infinity;

    for (final h in vm.hospitals) {
      final dist = vm.getDistance(h.lat, h.lng);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = h;
      }
    }

    if (nearest != null) {
      _showEmergencyDialog(nearest, minDistance);
    }
  }

  void _showEmergencyDialog(Hospital nearest, double distance) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFF122A34),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 12),
              Text(
                "Emergency",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 0.3),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nearest Hospital:",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                nearest.name,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFF00E5CC), size: 16),
                  const SizedBox(width: 4),
                  Text("${distance.toStringAsFixed(1)} km away", style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.redAccent, Color(0xFFD32F2F)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final url = Uri.parse('tel:${nearest.contactNumber}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.phone_rounded, size: 22),
                    label: Text(
                      "Call Ambulance (${nearest.contactNumber})",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HospitalViewModel>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-screen map or loading
          if (!vm.isLoading && !_isLoadingLocation)
            TomTomMapScreen(
              hospitals: vm.hospitals,
              userLat: vm.userLat,
              userLng: vm.userLng,
              hideAppBar: true,
              bestHospitalId: vm.bestHospital?.id,
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A1A20), Color(0xFF0F2B35)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00BFA5).withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: Color(0xFF00E5CC),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      color: Color(0xFF00E5CC),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Finding hospitals near you...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Top Header — "Hospitals Near You" + stats
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Header pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1A20).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00BFA5).withOpacity(0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA5).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Color(0xFF00E5CC), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Hospitals Near You",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.4,
                        ),
                      ),
                      if (!vm.isLoading && vm.hospitals.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${vm.hospitals.length}",
                            style: const TextStyle(
                              color: Color(0xFF00E5CC),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Stats Card
                if (!vm.isLoading && vm.hospitals.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1A20).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem(Icons.timer_rounded, "Avg Wait", "${vm.avgWaitTime.toStringAsFixed(0)}m", const Color(0xFFFFB74D)),
                        Container(width: 1, height: 36, color: Colors.white.withOpacity(0.08)),
                        _statItem(Icons.bed_rounded, "Beds", "${vm.totalBeds}", const Color(0xFF81C784)),
                        Container(width: 1, height: 36, color: Colors.white.withOpacity(0.08)),
                        _statItem(Icons.trending_up_rounded, "Peak", vm.mostCrowded?.name.split(" ")[0] ?? "N/A", const Color(0xFFEF5350)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 3. Bottom — Show All Hospitals button
          Positioned(
            bottom: 36,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, _, _) => const HomeScreen(),
                        transitionsBuilder: (_, animation, _, child) {
                          return SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.list_alt_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          "Show All Hospitals",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. My Location Button
          Positioned(
            bottom: 180,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A1A20).withOpacity(0.92),
                border: Border.all(
                  color: vm.userLat != null
                      ? const Color(0xFF00BFA5).withOpacity(0.6)
                      : Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'location_fab',
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () => _retryLocation(vm),
                child: _isFetchingLocation
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Color(0xFF00E5CC),
                          strokeWidth: 2.5,
                        ),
                      )
                    : Icon(
                        Icons.my_location_rounded,
                        color: vm.userLat != null ? const Color(0xFF00E5CC) : Colors.white38,
                        size: 26,
                      ),
              ),
            ),
          ),

          // 5. Emergency FAB
          Positioned(
            bottom: 110,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.redAccent, Color(0xFFD32F2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'emergency_fab',
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () => _handleEmergency(vm),
                child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
