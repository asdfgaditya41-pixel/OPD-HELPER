import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hospital.dart';
import '../viewmodels/hospital_viewmodel.dart';
import 'tomtom_map_screen.dart';
import 'hospital_detail_screen.dart';

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
          content: Text('Cannot locate any hospitals at the moment.', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF122A34),
        ),
      );
      return;
    }

    final topHospitals = vm.getTopEmergencyHospitals(count: 3);
    
    if (topHospitals.isNotEmpty) {
      _showEmergencyDialog(vm, topHospitals);
    }
  }

  void _showEmergencyDialog(HospitalViewModel vm, List<Hospital> hospitals) {
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
                "Emergency Options",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.3),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Recommended optimal hospitals based on distance, beds, and reliability:",
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...hospitals.map((h) {
                final distance = vm.getDistance(h.lat, h.lng);
                final confidence = vm.getConfidenceLevel(h);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: confidence == ConfidenceLevel.Low
                          ? Colors.orange.withOpacity(0.3)
                          : const Color(0xFF00BFA5).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.name,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: Color(0xFF00E5CC), size: 14),
                                const SizedBox(width: 4),
                                Text("${distance.toStringAsFixed(1)} km", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(width: 10),
                                const Icon(Icons.bed_rounded, color: Color(0xFF81C784), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  "${vm.getPredictedBeds(h)} beds",
                                  style: TextStyle(
                                    color: confidence == ConfidenceLevel.Low ? Colors.orange : Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.phone_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () async {
                          final url = Uri.parse('tel:${h.contactNumber}');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              }),
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

  void _showAllHospitalsBottomSheet(HospitalViewModel vm) {
    if (vm.hospitals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hospitals available.', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF122A34)));
      return;
    }

    final sortedHospitals = List<Hospital>.from(vm.hospitals);
    sortedHospitals.sort((a, b) {
      final distA = vm.getDistance(a.lat, a.lng);
      final distB = vm.getDistance(b.lat, b.lng);
      return distA.compareTo(distB);
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF0A1A20),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Hospitals Near You",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedHospitals.length,
                  itemBuilder: (context, index) {
                    final h = sortedHospitals[index];
                    final dist = vm.getDistance(h.lat, h.lng);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: h)));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00BFA5).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF00E5CC), size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        h.name,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded, color: Color(0xFF00E5CC), size: 14),
                                          const SizedBox(width: 4),
                                          Text("${dist.toStringAsFixed(1)} km", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.bed_rounded, color: Color(0xFF81C784), size: 14),
                                          const SizedBox(width: 4),
                                          Text("${vm.getPredictedBeds(h)} beds", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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

          // 4. My Location Button
          Positioned(
            bottom: 110,
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
            bottom: 36,
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

          // 6. Show All Hospitals Button
          Positioned(
            bottom: 36,
            left: 20,
            right: 88, // Reserve space for the Emergency FAB (20 + 56 + 12 gap = 88)
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00E5CC)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _showAllHospitalsBottomSheet(vm),
                icon: const Icon(Icons.list_rounded, size: 24),
                label: const Text(
                  "Show All Hospitals",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
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
