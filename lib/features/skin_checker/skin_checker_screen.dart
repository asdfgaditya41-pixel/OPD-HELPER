import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/hospital.dart';
import '../../viewmodels/hospital_viewmodel.dart';
import '../../screens/booking_screen.dart';
import 'skin_checker_service.dart';
import 'skin_result.dart';

/// Full-screen Skin Disease Checker — pick/take an image, analyze it via the
/// FastAPI backend, and display the top 3 results with confidence meters.
class SkinCheckerScreen extends StatefulWidget {
  const SkinCheckerScreen({super.key});

  @override
  State<SkinCheckerScreen> createState() => _SkinCheckerScreenState();
}

class _SkinCheckerScreenState extends State<SkinCheckerScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  final _service = SkinCheckerService();

  File? _imageFile;
  List<SkinResult> _results = [];
  bool _loading = false;

  /// Tracks which result card is currently expanded (-1 = none).
  int _expandedIndex = -1;

  /// Whether the nearby hospitals section is visible.
  bool _showHospitals = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (xFile == null) return;
    setState(() {
      _imageFile = File(xFile.path);
      _results = [];
      _expandedIndex = -1;
    });
  }

  // ── Inference ─────────────────────────────────────────────────────────────

  Future<void> _analyze() async {
    if (_imageFile == null) return;
    setState(() {
      _loading = true;
      _results = [];
      _expandedIndex = -1;
    });

    try {
      final results = await _service.predictTop(_imageFile!, count: 3);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: const Color(0xFFFF5252),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.biotech_rounded, color: Color(0xFFCE93D8), size: 24),
            SizedBox(width: 8),
            Text(
              'Skin Checker',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1A20), Color(0xFF0F2B35), Color(0xFF122A34)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                _buildImageSection(),
                const SizedBox(height: 20),
                _buildPickerButtons(),
                const SizedBox(height: 24),
                _buildAnalyzeButton(),
                const SizedBox(height: 24),
                if (_loading) _buildLoadingIndicator(),
                if (_results.isNotEmpty) _buildResultsSection(),
                if (_results.isNotEmpty) ...
                [
                  const SizedBox(height: 20),
                  _buildFindHospitalsButton(),
                ],
                if (_showHospitals && _results.isNotEmpty) ...
                [
                  const SizedBox(height: 16),
                  _buildNearbyHospitalsSection(),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Image preview ─────────────────────────────────────────────────────────

  Widget _buildImageSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _imageFile != null
          ? _imagePreviewCard()
          : _emptyPlaceholder(),
    );
  }

  Widget _imagePreviewCard() {
    return Container(
      key: ValueKey(_imageFile!.path),
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFCE93D8).withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCE93D8).withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }

  Widget _emptyPlaceholder() {
    return Container(
      key: const ValueKey('empty'),
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_rounded,
              color: Colors.white.withOpacity(0.2), size: 56),
          const SizedBox(height: 14),
          Text(
            'Select or capture a skin image',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Source buttons ─────────────────────────────────────────────────────────

  Widget _buildPickerButtons() {
    return Row(
      children: [
        Expanded(child: _sourceButton(Icons.camera_alt_rounded, 'Camera', ImageSource.camera)),
        const SizedBox(width: 14),
        Expanded(child: _sourceButton(Icons.photo_library_rounded, 'Gallery', ImageSource.gallery)),
      ],
    );
  }

  Widget _sourceButton(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => _pickImage(source),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFCE93D8), size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Analyze button ────────────────────────────────────────────────────────

  Widget _buildAnalyzeButton() {
    final enabled = _imageFile != null && !_loading;
    return GestureDetector(
      onTap: enabled ? _analyze : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFFAB47BC), Color(0xFFCE93D8)])
              : LinearGradient(colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.04),
                ]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFAB47BC).withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_rounded,
              color: enabled ? Colors.white : Colors.white38,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Analyze Skin',
              style: TextStyle(
                color: enabled ? Colors.white : Colors.white38,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading indicator ─────────────────────────────────────────────────────

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.15),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB47BC).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    color: Color(0xFFCE93D8),
                    strokeWidth: 3,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing image…',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Results section (top 3) ──────────────────────────────────────────────

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.07),
                Colors.white.withOpacity(0.03),
              ],
            ),
            border: Border.all(color: const Color(0xFFCE93D8).withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCE93D8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fact_check_rounded,
                    color: Color(0xFFCE93D8), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Possible Diagnoses',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFCE93D8).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Top ${_results.length}',
                  style: const TextStyle(
                    color: Color(0xFFCE93D8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Result cards
        ...List.generate(_results.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildResultCard(index),
          );
        }),

        const SizedBox(height: 8),

        // Disclaimer
        _buildDisclaimer(),
      ],
    );
  }

  // ── Individual result card ───────────────────────────────────────────────

  Widget _buildResultCard(int index) {
    final r = _results[index];
    final confPercent = (r.confidence * 100).toStringAsFixed(1);
    final isExpanded = _expandedIndex == index;

    // Rank-based styling
    final List<Color> rankColors = [
      const Color(0xFFCE93D8), // #1 — Purple (primary)
      const Color(0xFF64B5F6), // #2 — Blue
      const Color(0xFF81C784), // #3 — Green
    ];
    final List<IconData> rankIcons = [
      Icons.looks_one_rounded,
      Icons.looks_two_rounded,
      Icons.looks_3_rounded,
    ];

    final accentColor = rankColors[index.clamp(0, rankColors.length - 1)];
    final rankIcon = rankIcons[index.clamp(0, rankIcons.length - 1)];

    // Confidence color
    final Color confColor;
    if (r.confidence >= 0.7) {
      confColor = const Color(0xFF81C784);
    } else if (r.confidence >= 0.4) {
      confColor = const Color(0xFFFFB74D);
    } else {
      confColor = const Color(0xFFEF5350);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? -1 : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              accentColor.withOpacity(isExpanded ? 0.12 : 0.06),
              Colors.white.withOpacity(isExpanded ? 0.06 : 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: accentColor.withOpacity(isExpanded ? 0.35 : 0.15),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: rank icon + disease name + expand arrow ──
                Row(
                  children: [
                    // Rank badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(rankIcon, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // Disease name + confidence %
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.disease,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$confPercent% confidence',
                            style: TextStyle(
                              color: confColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expand/collapse arrow
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withOpacity(0.5),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Confidence bar (always visible) ──
                _buildConfidenceBar(r.confidence, confColor),

                // ── Expanded details ──
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildExpandedDetails(r, confColor),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                  sizeCurve: Curves.easeInOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Confidence bar widget ────────────────────────────────────────────────

  Widget _buildConfidenceBar(double confidence, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confidence',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Track
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            // Fill
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  width: constraints.maxWidth * confidence,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ── Expanded detail section ──────────────────────────────────────────────

  Widget _buildExpandedDetails(SkinResult r, Color confColor) {
    final severity = _getSeverityLevel(r.confidence);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.08),
          ),
          const SizedBox(height: 16),

          // Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.white.withOpacity(0.5), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'About this condition',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  r.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Severity + confidence detail row
          Row(
            children: [
              // Severity badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: confColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: confColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Confidence',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        severity,
                        style: TextStyle(
                          color: confColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Circular confidence meter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 38,
                        height: 38,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: r.confidence,
                              strokeWidth: 4,
                              backgroundColor: Colors.white.withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation(confColor),
                            ),
                            Text(
                              '${(r.confidence * 100).toInt()}',
                              style: TextStyle(
                                color: confColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Match\nScore',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Maps confidence to a human-readable label.
  String _getSeverityLevel(double confidence) {
    if (confidence >= 0.85) return 'Very High';
    if (confidence >= 0.7) return 'High';
    if (confidence >= 0.5) return 'Moderate';
    if (confidence >= 0.3) return 'Low';
    return 'Very Low';
  }

  // ── Disclaimer ───────────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5252).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF5252).withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFFF8A80), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is an AI prediction and not a medical diagnosis. '
              'Please consult a dermatologist for professional advice.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Find Hospitals button ────────────────────────────────────────────────

  Widget _buildFindHospitalsButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _showHospitals = !_showHospitals);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _showHospitals
              ? LinearGradient(colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ])
              : const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00E5CC)],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: !_showHospitals
              ? [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
          border: _showHospitals
              ? Border.all(color: Colors.white.withOpacity(0.1))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showHospitals
                  ? Icons.expand_less_rounded
                  : Icons.local_hospital_rounded,
              color: _showHospitals ? Colors.white70 : Colors.black87,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              _showHospitals ? 'Hide Hospitals' : 'Find Nearby Hospitals',
              style: TextStyle(
                color: _showHospitals ? Colors.white70 : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Nearby hospitals section ─────────────────────────────────────────────

  Widget _buildNearbyHospitalsSection() {
    final vm = Provider.of<HospitalViewModel>(context);

    if (vm.hospitals.isEmpty || vm.userLat == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Icon(Icons.location_off_rounded,
                color: Colors.white.withOpacity(0.3), size: 36),
            const SizedBox(height: 12),
            Text(
              'Location not available or no hospital data.\nPlease enable location and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final topHospitals = vm.getTopEmergencyHospitals(count: 3);

    if (topHospitals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          'No hospitals found nearby.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      );
    }

    final detectedCondition =
        _results.isNotEmpty ? _results.first.disease : 'Skin Condition';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF00BFA5).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_hospital_rounded,
                    color: Color(0xFF00E5CC), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended Hospitals',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'For: $detectedCondition',
                      style: TextStyle(
                        color: const Color(0xFF00E5CC).withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Sorted by distance, bed availability & data reliability',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 16),

          // Hospital tiles
          ...List.generate(topHospitals.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index < topHospitals.length - 1 ? 10 : 0),
              child: _buildHospitalTile(vm, topHospitals[index], index),
            );
          }),
        ],
      ),
    );
  }

  // ── Individual hospital tile ─────────────────────────────────────────────

  Widget _buildHospitalTile(
      HospitalViewModel vm, Hospital hospital, int index) {
    final distance = vm.getDistance(hospital.lat, hospital.lng);
    final predictedBeds = vm.getPredictedBeds(hospital);
    final confidence = vm.getConfidenceLevel(hospital);

    final isLowConfidence = confidence == ConfidenceLevel.Low;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowConfidence
              ? Colors.orange.withOpacity(0.25)
              : const Color(0xFF00BFA5).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hospital name + rank
          Row(
            children: [
              // Rank circle
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF00E5CC),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Name
              Expanded(
                child: Text(
                  hospital.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Stats row: distance + beds + wait time
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Color(0xFF00E5CC), size: 14),
              const SizedBox(width: 4),
              Text(
                '${distance.toStringAsFixed(1)} km',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 14),
              Icon(Icons.bed_rounded,
                  color: isLowConfidence
                      ? Colors.orange
                      : const Color(0xFF81C784),
                  size: 14),
              const SizedBox(width: 4),
              Text(
                '$predictedBeds beds',
                style: TextStyle(
                  color: isLowConfidence ? Colors.orange : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.timer_outlined,
                  color: Color(0xFFFFB74D), size: 14),
              const SizedBox(width: 4),
              Text(
                '~${hospital.waitTime}m wait',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Book Appointment button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingScreen(hospital: hospital),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00E5CC)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_rounded,
                      color: Colors.black87, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Book Appointment',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
