import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hospital.dart';
import '../services/firestore_service.dart';
import '../viewmodels/hospital_viewmodel.dart';
import '../viewmodels/inventory_viewmodel.dart';
import 'analytics_screen.dart';
import 'inventory_screen.dart';
import 'bed_management_screen.dart';

class HospitalDashboardScreen extends StatelessWidget {
  final String hospitalId;

  const HospitalDashboardScreen({super.key, required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    final hospitalVm = Provider.of<HospitalViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1A20), Color(0xFF0F2B35), Color(0xFF122A34)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<Hospital>(
          stream: FirestoreService().watchHospital(hospitalId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading hospital',
                  style: TextStyle(color: Colors.redAccent.withOpacity(0.9)),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5CC)),
              );
            }

            final hospital = snapshot.data!;
            final loadColor = hospitalVm.getLoadColor(hospital.waitTime);
            final loadText = hospitalVm.getLoadText(hospital.waitTime);
            final lastUpdated = hospitalVm.getTimeAgoFormatted(
              hospital.lastUpdated,
            );

            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: $lastUpdated',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _metricCard(
                              icon: Icons.people_alt_rounded,
                              label: 'Current Queue',
                              value: '${hospital.opdQueue} patients',
                              color: const Color(0xFF64B5F6),
                              extra: hospital.emergencyQueue > 0
                                  ? 'Emergency: ${hospital.emergencyQueue}'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              icon: Icons.timer_rounded,
                              label: 'Est. Wait Time',
                              value: '${hospital.waitTime} mins',
                              color: const Color(0xFFFFB74D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _metricCard(
                              icon: Icons.bed_rounded,
                              label: 'Beds Available',
                              value: hospital.bedsAvailable.toString(),
                              color: const Color(0xFF81C784),
                              extra: hospital.bedsTotal > 0
                                  ? 'Total: ${hospital.bedsTotal}'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              icon: Icons.insights_rounded,
                              label: 'Load Index',
                              value:
                                  '${(hospital.loadIndex * 100).toStringAsFixed(0)}%',
                              color: loadColor,
                              extra: loadText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Hospital Management Tools',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _toolTile(
                        context: context,
                        icon: Icons.playlist_add_check_rounded,
                        title: 'Patient Queue Manager',
                        subtitle: 'Add, remove, or flag emergencies',
                        color: const Color(0xFF42A5F5),
                        onTap: () {
                          _showQueueManager(context, hospital);
                        },
                      ),
                      _toolTile(
                        context: context,
                        icon: Icons.bedroom_child_rounded,
                        title: 'Bed Tracking Module',
                        subtitle: 'Toggle live bed availability by room',
                        color: const Color(0xFF66BB6A),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BedManagementScreen(hospitalId: hospital.id),
                            ),
                          );
                        },
                      ),
                      _toolTile(
                        context: context,
                        icon: Icons.medication_rounded,
                        title: 'Inventory Module',
                        subtitle: 'Track medicines, automated low-stock alerts',
                        color: const Color(0xFFFFA726),
                        onTap: () {
                          final inventoryVm = Provider.of<InventoryViewModel>(
                            context,
                            listen: false,
                          );
                          inventoryVm.startListening(hospitalId);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  InventoryScreen(hospitalId: hospitalId),
                            ),
                          );
                        },
                      ),
                      _toolTile(
                        context: context,
                        icon: Icons.analytics_rounded,
                        title: 'Analytics Dashboard',
                        subtitle: 'Peak hours and OPD demand trends',
                        color: const Color(0xFFAB47BC),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AnalyticsScreen(hospitalId: hospital.id),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? extra,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF122A34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          if (extra != null) ...[
            const SizedBox(height: 4),
            Text(
              extra,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toolTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white38,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  void _showQueueManager(BuildContext context, Hospital hospital) {
    final service = FirestoreService();
    int opd = hospital.opdQueue;
    int emergency = hospital.emergencyQueue;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF122A34),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF42A5F5).withOpacity(0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.playlist_add_check_rounded,
                          color: Color(0xFF42A5F5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Patient Queue Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _counterRow(
                    label: 'OPD queue',
                    value: opd,
                    onChanged: (v) {
                      setState(() {
                        opd = v >= 0 ? v : 0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _counterRow(
                    label: 'Emergency queue',
                    value: emergency,
                    onChanged: (v) {
                      setState(() {
                        emergency = v >= 0 ? v : 0;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (opd < 0 || emergency < 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Queue counts cannot be negative.',
                                    ),
                                    backgroundColor: Color(0xFF122A34),
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                isSaving = true;
                              });
                              try {
                                await service.updateQueueModule(
                                  hospital.id,
                                  opd,
                                  emergency,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Queue updated.'),
                                      backgroundColor: Color(0xFF122A34),
                                    ),
                                  );
                                }
                              } catch (_) {
                                setState(() {
                                  isSaving = false;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to update queue.'),
                                      backgroundColor: Color(0xFF122A34),
                                    ),
                                  );
                                }
                              }
                            },
                      child: Text(isSaving ? 'Saving...' : 'Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _counterRow({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            if (value > 0) {
              onChanged(value - 1);
            }
          },
          icon: const Icon(
            Icons.remove_circle_outline_rounded,
            color: Colors.white70,
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        IconButton(
          onPressed: () {
            onChanged(value + 1);
          },
          icon: const Icon(
            Icons.add_circle_outline_rounded,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
