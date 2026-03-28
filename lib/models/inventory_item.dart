import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final int stock;
  final int threshold;
  final DateTime? lastUpdated;
  // IoT-specific fields
  final String? source;    // "iot" | "manual"
  final String? deviceId;
  final double? sensorLevel; // e.g. oxygen pressure 0.0–100.0
  final String? sensorStatus; // "normal" | "low" | "critical"

  InventoryItem({
    required this.id,
    required this.name,
    required this.stock,
    required this.threshold,
    this.lastUpdated,
    this.source,
    this.deviceId,
    this.sensorLevel,
    this.sensorStatus,
  });

  bool get isLowStock => stock <= threshold;
  bool get isIotTracked => source == 'iot';
  bool get isSensorCritical => sensorStatus == 'critical';

  factory InventoryItem.fromFirestore(Map<String, dynamic> data, String id) {
    return InventoryItem(
      id: id,
      name: data['name'] ?? '',
      stock: (data['stock'] ?? 0) as int,
      threshold: (data['threshold'] ?? 0) as int,
      source: data['source'],
      deviceId: data['device_id'],
      sensorLevel: data['sensor_level'] != null
          ? (data['sensor_level'] as num).toDouble()
          : null,
      sensorStatus: data['sensor_status'],
      lastUpdated: data['last_updated'] != null
          ? (data['last_updated'] as Timestamp).toDate()
          : null,
    );
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    int? stock,
    int? threshold,
    DateTime? lastUpdated,
    String? source,
    String? deviceId,
    double? sensorLevel,
    String? sensorStatus,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      stock: stock ?? this.stock,
      threshold: threshold ?? this.threshold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      source: source ?? this.source,
      deviceId: deviceId ?? this.deviceId,
      sensorLevel: sensorLevel ?? this.sensorLevel,
      sensorStatus: sensorStatus ?? this.sensorStatus,
    );
  }
}
