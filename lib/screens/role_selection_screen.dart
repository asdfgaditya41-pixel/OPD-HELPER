import 'package:flutter/material.dart';

import 'hospital_selection_screen.dart';
import 'map_home_screen.dart';
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  static const String defaultHospitalId = 'lokpriya_hospital';
  bool isHindi = false;

  final Map<String, Map<String, String>> localizedStrings = {
    'en': {
      'welcome': 'Welcome to City Pulse',
      'subtitle': 'Choose how you want to use the app.',
      'civilian_title': 'I am a Civilian',
      'civilian_desc': 'Find nearby hospitals, beds and wait times.',
      'hospital_title': 'I am a Hospital',
      'hospital_desc': 'Manage queues, beds and medicine inventory.',
    },
    'hi': {
      'welcome': 'सिटी पल्स में आपका स्वागत है',
      'subtitle': 'चुनें कि आप ऐप का उपयोग कैसे करना चाहते हैं।',
      'civilian_title': 'मैं एक नागरिक हूँ',
      'civilian_desc': 'आस-पास के अस्पताल, बिस्तर और प्रतीक्षा समय खोजें।',
      'hospital_title': 'मैं एक अस्पताल हूँ',
      'hospital_desc': 'कतारों, बिस्तरों और दवा सूची का प्रबंधन करें।',
    },
  };

  String t(String key) {
    return localizedStrings[isHindi ? 'hi' : 'en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1A20), Color(0xFF0F2B35), Color(0xFF122A34)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), // Spacer for balance
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(height: 80),
                      ),
                    ),
                    PopupMenuButton<bool>(
                      icon: const Icon(Icons.language_rounded,
                          color: Color(0xFF00E5CC)),
                      onSelected: (bool value) {
                        setState(() {
                          isHindi = value;
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: false,
                          child: Text('English',
                              style: TextStyle(
                                  color: !isHindi ? const Color(0xFF00E5CC) : Colors.white)),
                        ),
                        PopupMenuItem(
                          value: true,
                          child: Text('हिंदी',
                              style: TextStyle(
                                  color: isHindi ? const Color(0xFF00E5CC) : Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  t('welcome'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('subtitle'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                _buildRoleCard(
                  context: context,
                  icon: Icons.location_on_rounded,
                  title: t('civilian_title'),
                  subtitle: t('civilian_desc'),
                  color: const Color(0xFF00E5CC),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapHomeScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildRoleCard(
                  context: context,
                  icon: Icons.local_hospital_rounded,
                  title: t('hospital_title'),
                  subtitle: t('hospital_desc'),
                  color: const Color(0xFFFFB74D),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HospitalSelectionScreen(),
                      ),
                    );
                  },
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
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
    );
  }
}
