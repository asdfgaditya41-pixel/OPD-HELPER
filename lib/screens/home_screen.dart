import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/hospital_viewmodel.dart';
import 'tomtom_map_screen.dart';
import 'hospital_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  void _showAddPatientDialog(BuildContext context, String hospitalId) {
    final nameController = TextEditingController();
    String selectedCondition = 'Fever';
    final conditions = ['Fever', 'Cold', 'Injury', 'Chest Pain', 'Others'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: const Color(0xFF122A34),
              title: Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFF00BFA5),
                      width: 2,
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_add_rounded, color: Color(0xFF00E5CC), size: 28),
                    SizedBox(width: 12),
                    Text(
                      "Add Patient",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Patient Name',
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00BFA5)),
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCondition,
                    dropdownColor: const Color(0xFF122A34),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Condition',
                      prefixIcon: const Icon(Icons.medical_services_outlined, color: Color(0xFF00BFA5)),
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 2),
                      ),
                    ),
                    items: conditions.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCondition = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BFA5), Color(0xFF00E5CC)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        final vm = Provider.of<HospitalViewModel>(
                          context,
                          listen: false,
                        );
                        await vm.addPatient(hospitalId, name, selectedCondition);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      "Add Patient",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSortOptions(BuildContext context) {
    final vm = Provider.of<HospitalViewModel>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF122A34),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sort Hospitals",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 16),
            _sortTile(Icons.location_on_rounded, "By Distance", "Nearest first",
                Colors.cyan, () {
              vm.sortByDistance();
              Navigator.pop(context);
            }),
            _sortTile(Icons.timer_rounded, "By Wait Time", "Shortest wait first",
                Colors.orangeAccent, () {
              vm.sortByWaitTime();
              Navigator.pop(context);
            }),
            _sortTile(Icons.groups_rounded, "By Doctors", "Most doctors first",
                Colors.purpleAccent, () {
              vm.sortByDoctors();
              Navigator.pop(context);
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HospitalViewModel>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_hospital_rounded, color: Color(0xFF00E5CC), size: 26),
            SizedBox(width: 10),
            Text(
              "OPD Helper",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0A1A20).withOpacity(0.95),
                const Color(0xFF0A1A20).withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.sort_rounded, color: Color(0xFF00E5CC)),
              onPressed: () => _showSortOptions(context),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1A20), Color(0xFF0F2B35), Color(0xFF122A34)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: vm.isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        color: Color(0xFF00E5CC),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Loading hospitals...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 100, bottom: 20),
                itemCount: vm.hospitals.length,
                itemBuilder: (context, index) {
                  final h = vm.hospitals[index];

                  // Staggered fade+slide animation
                  final delay = (index * 0.15).clamp(0.0, 1.0);
                  final itemAnimation = Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _listController,
                      curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
                    ),
                  );

                  return AnimatedBuilder(
                    animation: itemAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - itemAnimation.value)),
                        child: Opacity(
                          opacity: itemAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: h)),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.03),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: const Color(0xFF00BFA5).withOpacity(0.15),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Column(
                              children: [
                                // Top accent line
                                Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF00BFA5).withOpacity(0.6),
                                        const Color(0xFF00E5CC).withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      /// NAME + STATUS
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              h.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                          _statusChip(h.opdQueue),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      /// DISTANCE + ZONE
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded, color: Color(0xFF00E5CC), size: 15),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${vm.getDistance(h.lat, h.lng).toStringAsFixed(1)} km",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            h.zone,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.45),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 18),

                                      /// INFO CARDS ROW
                                      Row(
                                        children: [
                                          _infoCard(Icons.people_alt_rounded, "Queue", h.opdQueue.toString(), const Color(0xFF64B5F6)),
                                          const SizedBox(width: 10),
                                          _infoCard(Icons.bed_rounded, "Beds", h.bedsAvailable.toString(), const Color(0xFF81C784)),
                                          const SizedBox(width: 10),
                                          _infoCard(Icons.timer_rounded, "Wait", "${h.waitTime}m", const Color(0xFFFFB74D)),
                                        ],
                                      ),

                                      const SizedBox(height: 18),

                                      /// BUTTONS
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF00BFA5), Color(0xFF00E5CC)],
                                                ),
                                                borderRadius: BorderRadius.circular(14),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF00BFA5).withOpacity(0.3),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.transparent,
                                                  shadowColor: Colors.transparent,
                                                  foregroundColor: Colors.black,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                                ),
                                                onPressed: () => _showAddPatientDialog(context, h.id),
                                                icon: const Icon(Icons.person_add_rounded, size: 18),
                                                label: const Text(
                                                  "Add Patient",
                                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                                            ),
                                            child: IconButton(
                                              padding: const EdgeInsets.all(12),
                                              icon: const Icon(
                                                Icons.navigation_rounded,
                                                color: Color(0xFF00E5CC),
                                                size: 22,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => TomTomMapScreen(
                                                      hospitals: [h],
                                                      userLat: vm.userLat,
                                                      userLng: vm.userLng,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                                            ),
                                            child: IconButton(
                                              padding: const EdgeInsets.all(12),
                                              icon: const Icon(
                                                Icons.analytics_rounded,
                                                color: Color(0xFF64B5F6),
                                                size: 22,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => HospitalDetailScreen(hospital: h),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
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
        ),
      ),
    );
  }

  Widget _statusChip(int queue) {
    Color bgStart, bgEnd;
    String text;
    IconData icon;

    if (queue < 10) {
      bgStart = const Color(0xFF00C853);
      bgEnd = const Color(0xFF69F0AE);
      text = "Low";
      icon = Icons.check_circle_rounded;
    } else if (queue < 30) {
      bgStart = const Color(0xFFFF9100);
      bgEnd = const Color(0xFFFFAB40);
      text = "Medium";
      icon = Icons.remove_circle_rounded;
    } else {
      bgStart = const Color(0xFFFF1744);
      bgEnd = const Color(0xFFFF5252);
      text = "High";
      icon = Icons.warning_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bgStart.withOpacity(0.25), bgEnd.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgStart.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: bgStart, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: bgStart,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
