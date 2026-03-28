import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hospital.dart';
import '../viewmodels/hospital_viewmodel.dart';
import 'hospital_dashboard_screen.dart';

class HospitalSelectionScreen extends StatefulWidget {
  const HospitalSelectionScreen({super.key});

  @override
  State<HospitalSelectionScreen> createState() =>
      _HospitalSelectionScreenState();
}

class _HospitalSelectionScreenState extends State<HospitalSelectionScreen> {
  String? _selectedHospitalId;

  @override
  void initState() {
    super.initState();
    final vm = Provider.of<HospitalViewModel>(context, listen: false);
    vm.loadHospitals();
    vm.getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Hospital'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A1A20),
              Color(0xFF0F2B35),
              Color(0xFF122A34),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<HospitalViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00E5CC),
                ),
              );
            }

            final hospitals = List<Hospital>.from(vm.hospitals);
            if (hospitals.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_hospital_rounded,
                        color: Colors.white54,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hospitals found nearby.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your location permissions or try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          vm.loadHospitals();
                          vm.getUserLocation();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (vm.userLat != null && vm.userLng != null) {
              hospitals.sort((a, b) {
                final da = vm.getDistance(a.lat, a.lng);
                final db = vm.getDistance(b.lat, b.lng);
                return da.compareTo(db);
              });
            }

            _selectedHospitalId ??= hospitals.first.id;

            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select your hospital',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We use your location to show hospitals closest to you.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedHospitalId,
                          dropdownColor: const Color(0xFF122A34),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70,
                          ),
                          items: hospitals.map((h) {
                            final distance = vm.userLat != null &&
                                    vm.userLng != null
                                ? vm.getDistance(h.lat, h.lng).toStringAsFixed(1)
                                : null;
                            final text = distance != null
                                ? '${h.name} • $distance km'
                                : h.name;
                            return DropdownMenuItem(
                              value: h.id,
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedHospitalId = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: hospitals.length,
                        itemBuilder: (context, index) {
                          final h = hospitals[index];
                          final isSelected = h.id == _selectedHospitalId;
                          final distance = vm.userLat != null &&
                                  vm.userLng != null
                              ? vm.getDistance(h.lat, h.lng).toStringAsFixed(1)
                              : null;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00E5CC)
                                        .withOpacity(0.8)
                                    : Colors.white.withOpacity(0.06),
                              ),
                            ),
                            child: ListTile(
                              onTap: () {
                                setState(() {
                                  _selectedHospitalId = h.id;
                                });
                              },
                              title: Text(
                                h.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                distance != null
                                    ? '${h.location} • $distance km away'
                                    : h.location,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedHospitalId == null
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HospitalDashboardScreen(
                                      hospitalId: _selectedHospitalId!,
                                    ),
                                  ),
                                );
                              },
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

