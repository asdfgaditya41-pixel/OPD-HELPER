import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final int stock;
  final int threshold;
  final DateTime? lastUpdated;

  InventoryItem({
    required this.id,
    required this.name,
    required this.stock,
    required this.threshold,
    this.lastUpdated,
  });

  bool get isLowStock => stock <= threshold;

  factory InventoryItem.fromFirestore(Map<String, dynamic> data, String id) {
    return InventoryItem(
      id: id,
      name: data['name'] ?? '',
      stock: (data['stock'] ?? 0) as int,
      threshold: (data['threshold'] ?? 0) as int,
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
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      stock: stock ?? this.stock,
      threshold: threshold ?? this.threshold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

