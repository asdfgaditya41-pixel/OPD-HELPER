import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hospital.dart';
import '../viewmodels/hospital_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/hospital_room.dart';
import '../services/firestore_service.dart';
import 'components/auth_options_bottom_sheet.dart';
import 'booking_screen.dart';

class HospitalDetailScreen extends StatefulWidget {
  final Hospital hospital;

  const HospitalDetailScreen({super.key, required this.hospital});

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isReporting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HospitalViewModel>(context, listen: false);
    final authVm = Provider.of<AuthViewModel>(context);
    final h = widget.hospital;

    int expectedTime = vm.getExpectedConsultationTime(h);
    String expectedTimeString = vm.formatDuration(expectedTime);
    String totalWaitTimeString = vm.formatDuration(h.waitTime);
    Color loadColor = vm.getLoadColor(h.waitTime);
    String loadText = vm.getLoadText(h.waitTime);
    String bestTime = vm.getBestTimeToVisit(h);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          h.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          _buildProfileIndicator(authVm),
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BFA5).withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.phone_rounded,
                color: Colors.white,
                size: 20,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: () async {
                final url = Uri.parse('tel:${h.contactNumber}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cannot call ${h.contactNumber}'),
                        backgroundColor: const Color(0xFF122A34),
                      ),
                    );
                  }
                }
              },
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              bottom: 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Prediction Card
                _buildAnimatedChild(
                  0,
                  _buildPredictionCard(expectedTimeString, bestTime),
                ),
                const SizedBox(height: 16),

                // 2. Bed Availability Card
                _buildAnimatedChild(1, _buildBedAvailabilityCard(vm, h)),
                const SizedBox(height: 16),

                // 3. Stats Grid (3 items)
                _buildAnimatedChild(
                  2,
                  _buildStatsGrid(
                    totalWaitTimeString,
                    loadText,
                    loadColor,
                    h.opdQueue,
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Report Action
                _buildAnimatedChild(3, _buildReportButton(vm, h)),
                const SizedBox(height: 28),

                // 5. Chart Title
                _buildAnimatedChild(
                  4,
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64B5F6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: Color(0xFF64B5F6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Wait Time Trend",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Past 6 Hours",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Chart
                _buildAnimatedChild(
                  5,
                  _buildChartCard(vm.generateHistoricalWaitTimes(h), loadColor),
                ),
                const SizedBox(height: 32),

                // 7. Book Appointment
                _buildAnimatedChild(6, _buildBookAppointmentButton(authVm, h)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedChild(int index, Widget child) {
    final delay = (index * 0.2).clamp(0.0, 1.0);
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(
          delay,
          (delay + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 24 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildPredictionCard(String expectedTimeString, String bestTime) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BFA5).withOpacity(0.12),
            const Color(0xFF00897B).withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF00BFA5).withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.batch_prediction_rounded,
                  color: Color(0xFF00E5CC),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Consultation Prediction",
                      style: TextStyle(
                        color: Color(0xFF00E5CC),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Based on current load & doctors",
                      style: TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "~$expectedTimeString",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "estimated wait",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time_filled_rounded,
                  color: Color(0xFF00E5CC),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "Best time: $bestTime",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    String waitTime,
    String loadText,
    Color loadColor,
    int queue,
  ) {
    return Row(
      children: [
        _statCard(
          "Wait Time",
          waitTime,
          Icons.hourglass_bottom_rounded,
          const Color(0xFFFFB74D),
        ),
        const SizedBox(width: 10),
        _statCard("Load", loadText, Icons.speed_rounded, loadColor),
        const SizedBox(width: 10),
        _statCard(
          "Queue",
          "$queue",
          Icons.people_alt_rounded,
          const Color(0xFF64B5F6),
        ),
      ],
    );
  }

  Widget _buildBedAvailabilityCard(HospitalViewModel vm, Hospital h) {
    ConfidenceLevel confidence = vm.getConfidenceLevel(h);
    int displayBeds = vm.getPredictedBeds(h);
    bool isPredicted = confidence == ConfidenceLevel.Low;

    Color confidenceColor;
    String statusText;
    switch (confidence) {
      case ConfidenceLevel.High:
        confidenceColor = const Color(0xFF00E676);
        statusText = "High Confidence";
        break;
      case ConfidenceLevel.Medium:
        confidenceColor = const Color(0xFFFFB300);
        statusText = "Medium Confidence";
        break;
      case ConfidenceLevel.Low:
        confidenceColor = const Color(0xFFFF5252);
        statusText = "Low Conf (estimated)";
        break;
    }

    String timeAgo = vm.getTimeAgoFormatted(h.lastUpdated);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF81C784).withOpacity(0.12),
            const Color(0xFF81C784).withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF81C784).withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF81C784).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF81C784).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bed_rounded,
                  color: Color(0xFF81C784),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Bed Availability",
                style: TextStyle(
                  color: Color(0xFF81C784),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: confidenceColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: confidenceColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: confidenceColor.withOpacity(0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: confidenceColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$displayBeds",
                style: TextStyle(
                  color: isPredicted ? Colors.white70 : Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  decoration: h.bedsAvailable == 0 && !isPredicted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  isPredicted
                      ? "estimated beds available"
                      : "beds currently available",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<HospitalRoom>>(
            stream: FirestoreService().watchHospitalRooms(h.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const SizedBox.shrink();

              final rooms = snapshot.data!;
              int icu = 0;
              int gen = 0;

              for (var r in rooms) {
                int count = r.beds.values
                    .where((b) => b.status == 'available')
                    .length;
                if (r.type == 'ICU') {
                  icu += count;
                } else {
                  gen += count;
                }
              }

              if (icu == 0 && gen == 0) return const SizedBox.shrink();

              // Build Categorized Room Lists
              Map<String, List<HospitalRoom>> categorizedRooms = {};
              for (var r in rooms) {
                int count = r.beds.values
                    .where((b) => b.status == 'available')
                    .length;
                if (count > 0) {
                  categorizedRooms.putIfAbsent(r.type, () => []).add(r);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (icu > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              "$icu ICU Available",
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (gen > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BFA5).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00BFA5).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              "$gen General Available",
                              style: const TextStyle(
                                color: Color(0xFF00BFA5),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (categorizedRooms.isNotEmpty) const SizedBox(height: 16),
                    ...categorizedRooms.entries.map((entry) {
                      String category = entry.key;
                      List<HospitalRoom> catRooms = entry.value;
                      bool showMore = catRooms.length > 3;
                      int extra = catRooms.length - 3;
                      List<HospitalRoom> displayRooms = catRooms
                          .take(3)
                          .toList();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...displayRooms.map((r) {
                              int availableBeds = r.beds.values
                                  .where((b) => b.status == 'available')
                                  .length;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.meeting_room_rounded,
                                      color: Colors.white30,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Room ${r.roomNumber}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      availableBeds == 1
                                          ? "1 Bed"
                                          : "$availableBeds Beds",
                                      style: TextStyle(
                                        color: category == 'ICU'
                                            ? Colors.redAccent
                                            : const Color(0xFF00BFA5),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (showMore)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  "+ $extra more $category room${extra > 1 ? 's' : ''}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          Row(
            children: [
              const Icon(Icons.update_rounded, color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              Text(
                "Last updated: $timeAgo",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton(HospitalViewModel vm, Hospital h) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isReporting
              ? null
              : () async {
                  setState(() => _isReporting = true);
                  await vm.reportNoBeds(h.id);
                  if (mounted) {
                    setState(() => _isReporting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Thank you! Beds reported as unavailable.',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF122A34),
                      ),
                    );
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isReporting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orangeAccent,
                    ),
                  )
                else
                  const Icon(
                    Icons.feedback_rounded,
                    color: Colors.orangeAccent,
                    size: 20,
                  ),
                const SizedBox(width: 10),
                Text(
                  _isReporting ? "Reporting..." : "Report: No beds available",
                  style: TextStyle(
                    color: _isReporting ? Colors.white54 : Colors.orangeAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.03)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(List<double> spots, Color primaryColor) {
    double maxSpot = spots.reduce((a, b) => a > b ? a : b);
    // Add 40% padding on top for the curve, ensure minimum height of 60
    double rawMaxY = (maxSpot * 1.4);
    if (rawMaxY < 60) rawMaxY = 60;

    // Dynamically adjust Y-axis labels to prevent crowding
    double yInterval = 30;
    if (rawMaxY > 600) {
      yInterval = 120;
    } else if (rawMaxY > 300) {
      yInterval = 60;
    }

    // Snap the maxY to exactly a multiple of yInterval to prevent label overlaps
    double maxYValue = (rawMaxY / yInterval).ceilToDouble() * yInterval;

    return Container(
      height: 280,
      padding: const EdgeInsets.only(right: 24, left: 12, top: 28, bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final style = TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  );
                  String text;
                  switch (value.toInt()) {
                    case 0:
                      text = '5h ago';
                      break;
                    case 2:
                      text = '3h ago';
                      break;
                    case 4:
                      text = '1h ago';
                      break;
                    case 5:
                      text = 'Now';
                      break;
                    default:
                      text = '';
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(text, style: style),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  // Ensure we don't draw an out-of-interval label that might overlap
                  if (value % yInterval != 0 &&
                      value != maxYValue &&
                      value != 0) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    "${value.toInt()}m",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
                reservedSize: 36,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: maxYValue,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                spots.length,
                (index) => FlSpot(index.toDouble(), spots[index]),
              ),
              isCurved: true,
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.6)],
              ),
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFF0A1A20),
                      strokeWidth: 2.5,
                      strokeColor: primaryColor,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.2),
                    primaryColor.withOpacity(0.01),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1E3C48),
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    "${spot.y.toStringAsFixed(0)} min",
                    TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  void _showAuthSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AuthOptionsBottomSheet(
        onAuthenticated: () {
          // Once authenticated via sheet, proceed to booking seamlessly
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingScreen(hospital: widget.hospital),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileIndicator(AuthViewModel authVm) {
    return GestureDetector(
      onTap: () {
        if (authVm.isLoggedIn) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF122A34),
              title: const Text(
                "Account",
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                "Logged in as ${authVm.appUser?.name ?? authVm.appUser?.email}",
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    authVm.signOut();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Sign Out",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        } else {
          _showAuthSheet();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: authVm.isLoggedIn
              ? (authVm.appUser?.photoUrl != null
                    ? Image.network(
                        authVm.appUser!.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _buildFallbackIcon(),
                      )
                    : Center(
                        child: Text(
                          authVm.appUser?.name.isNotEmpty == true
                              ? authVm.appUser!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF00E5CC),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ))
              : _buildFallbackIcon(),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.network(
        "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png",
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.person_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildBookAppointmentButton(AuthViewModel authVm, Hospital h) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00E5CC)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withOpacity(0.4),
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () {
          if (authVm.isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookingScreen(hospital: h)),
            );
          } else {
            _showAuthSheet();
          }
        },
        icon: const Icon(Icons.calendar_month_rounded, size: 24),
        label: const Text(
          "Book Appointment",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
    );
  }
}
