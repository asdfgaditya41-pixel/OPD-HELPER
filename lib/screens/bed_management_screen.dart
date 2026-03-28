import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/bed_management_viewmodel.dart';


class BedManagementScreen extends StatefulWidget {
  final String hospitalId;
  const BedManagementScreen({super.key, required this.hospitalId});

  @override
  State<BedManagementScreen> createState() => _BedManagementScreenState();
}

class _BedManagementScreenState extends State<BedManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BedManagementViewModel>(context, listen: false)
          .startListening(widget.hospitalId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Bed Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1A20), Color(0xFF0F2B35)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<BedManagementViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5CC)),
              );
            }

            if (vm.rooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.meeting_room_rounded, color: Colors.white54, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'No rooms found.',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => vm.seedInitialRooms(widget.hospitalId),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Seed Example Rooms'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
                    )
                  ],
                ),
              );
            }

            // Summary Header
            int totalICU = vm.getTotalBedsForType('ICU');
            int availICU = vm.getAvailableBedsForType('ICU');

            int totalGen = vm.getTotalBedsForType('General');
            int availGen = vm.getAvailableBedsForType('General');

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  color: const Color(0xFF122A34),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryStat('ICU Beds', availICU, totalICU, Colors.redAccent),
                      Container(width: 1, height: 40, color: Colors.white12),
                      _summaryStat('General', availGen, totalGen, const Color(0xFF00BFA5)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.rooms.length,
                    itemBuilder: (context, i) {
                      final room = vm.rooms[i];
                      
                      // Sort beds by ID so bed_1, bed_2 are in order
                      final bedsList = room.beds.entries.toList()
                        ..sort((a, b) => a.key.compareTo(b.key));
                      
                      int availableInRoom = room.beds.values.where((b) => b.status == 'available').length;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFF122A34),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: const Color(0xFF00E5CC),
                            collapsedIconColor: Colors.white54,
                            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    room.type == 'ICU' ? Icons.monitor_heart_rounded : Icons.bed_rounded,
                                    color: room.type == 'ICU' ? Colors.redAccent : const Color(0xFF00BFA5),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Room ${room.roomNumber} (${room.type})",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "$availableInRoom of ${room.beds.length} Available",
                                        style: TextStyle(
                                          color: availableInRoom == 0 ? Colors.redAccent : Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 2.5,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: bedsList.length,
                                itemBuilder: (context, index) {
                                  final bedData = bedsList[index];
                                  final bedId = bedData.key;
                                  final bed = bedData.value;
                                  final isAvailable = bed.status == 'available';

                                  return InkWell(
                                    onTap: () {
                                      // Toggle State instantly
                                      vm.toggleBed(widget.hospitalId, room.id, bedId, bed.status);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isAvailable 
                                            ? const Color(0xFF4CAF50).withOpacity(0.15)
                                            : Colors.redAccent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isAvailable 
                                              ? const Color(0xFF4CAF50).withOpacity(0.4)
                                              : Colors.redAccent.withOpacity(0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isAvailable ? Icons.check_circle_rounded : Icons.person_rounded,
                                            color: isAvailable ? const Color(0xFF4CAF50) : Colors.redAccent,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            bedId.toUpperCase(),
                                            style: TextStyle(
                                              color: isAvailable ? const Color(0xFF4CAF50) : Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryStat(String title, int available, int total, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: available.toString(), style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
              TextSpan(text: " / $total", style: const TextStyle(color: Colors.white70, fontSize: 16)),
            ]
          ),
        ),
      ],
    );
  }
}
