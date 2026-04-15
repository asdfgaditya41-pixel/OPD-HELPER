import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/hospital.dart';
import 'hospital_detail_screen.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../utils/translations.dart';

class GoogleMapScreen extends StatefulWidget {
  final List<Hospital> hospitals;
  final double? userLat;
  final double? userLng;
  final bool hideAppBar;
  final String? bestHospitalId;

  const GoogleMapScreen({
    super.key,
    required this.hospitals,
    this.userLat,
    this.userLng,
    this.hideAppBar = false,
    this.bestHospitalId,
  });

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  String _locale = 'en';
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Set<Marker> _markers = {};
  Hospital? _selectedHospital;

  @override
  void initState() {
    super.initState();
    _locale = Provider.of<LanguageService>(context, listen: false).currentLocale;
    _initMarkers();
  }

  @override
  void didUpdateWidget(covariant GoogleMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hospitals != oldWidget.hospitals || 
        widget.userLat != oldWidget.userLat || 
        widget.userLng != oldWidget.userLng) {
      _initMarkers();
    }
  }

  void _initMarkers() {
    Set<Marker> newMarkers = {};
    
    // User location marker
    if (widget.userLat != null && widget.userLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('user_loc'),
          position: LatLng(widget.userLat!, widget.userLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: AppTranslations.getText('your_location', _locale)),
        )
      );
    }

    // Hospitals
    for (var h in widget.hospitals) {
      bool isBest = h.id == widget.bestHospitalId;
      double hue = isBest 
          ? BitmapDescriptor.hueYellow 
          : h.type == 'government' 
              ? BitmapDescriptor.hueGreen 
              : BitmapDescriptor.hueAzure;
      
      newMarkers.add(
        Marker(
          markerId: MarkerId(h.id),
          position: LatLng(h.lat, h.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () {
            setState(() {
              _selectedHospital = h;
            });
            _moveCameraTo(LatLng(h.lat, h.lng));
          },
        )
      );
    }

    setState(() {
      _markers = newMarkers;
    });
    
    if (_markers.isNotEmpty) {
      _fitBounds();
    }
  }

  Future<void> _moveCameraTo(LatLng target) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: 14)
    ));
  }

  Future<void> _fitBounds() async {
    if (widget.hospitals.isEmpty && widget.userLat == null) return;
    
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    if (widget.userLat != null && widget.userLng != null) {
      minLat = widget.userLat!;
      maxLat = widget.userLat!;
      minLng = widget.userLng!;
      maxLng = widget.userLng!;
    } else {
      minLat = widget.hospitals[0].lat;
      maxLat = widget.hospitals[0].lat;
      minLng = widget.hospitals[0].lng;
      maxLng = widget.hospitals[0].lng;
    }

    for (var h in widget.hospitals) {
      if (h.lat < minLat) minLat = h.lat;
      if (h.lat > maxLat) maxLat = h.lat;
      if (h.lng < minLng) minLng = h.lng;
      if (h.lng > maxLng) maxLng = h.lng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    final GoogleMapController controller = await _controller.future;
    // adding a small delay so layout is complete
    await Future.delayed(const Duration(milliseconds: 200));
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  Widget _buildMap() {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.userLat ?? 28.6139, widget.userLng ?? 77.2090),
            zoom: 12,
          ),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            _fitBounds();
          },
          onTap: (_) {
            setState(() {
              _selectedHospital = null;
            });
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        ),
        
        // Custom Info Card (Slide Up)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          bottom: _selectedHospital != null ? (widget.hideAppBar ? 115 : 20) : -200,
          left: 16,
          right: 16,
          child: _selectedHospital != null ? _buildInfoCard(_selectedHospital!, _locale) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Hospital hospital, String locale) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1A20).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00BFA5).withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 4)),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hospital.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () {
                  setState(() {
                    _selectedHospital = null;
                  });
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBadge(AppTranslations.getText('wait_label', locale), "${hospital.waitTime} ${AppTranslations.getText('mins_label', locale)}", locale),
              const SizedBox(width: 10),
              _buildBadge(AppTranslations.getText('beds_text', locale), "${hospital.bedsAvailable}", locale),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HospitalDetailScreen(hospital: hospital),
                  ),
                );
              },
              child: Text(AppTranslations.getText('view_full_details', locale), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBadge(String label, String value, String locale) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _locale = Provider.of<LanguageService>(context).currentLocale;
    if (widget.hideAppBar) {
      return Scaffold(
        body: SafeArea(child: _buildMap()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.getText('google_map', _locale))),
      body: _buildMap(),
    );
  }
}
