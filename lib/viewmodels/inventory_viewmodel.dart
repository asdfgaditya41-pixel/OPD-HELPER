import 'dart:async';

import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../services/firestore_service.dart';

class InventoryViewModel extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  String? _hospitalId;
  StreamSubscription<List<InventoryItem>>? _subscription;

  List<InventoryItem> _items = [];
  bool _isLoading = false;

  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;

  bool get hasCriticalStock =>
      _items.any((item) => item.stock <= item.threshold);

  void startListening(String hospitalId) {
    if (_hospitalId == hospitalId && _subscription != null) {
      return;
    }

    _hospitalId = hospitalId;
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.inventoryStream(hospitalId).listen((data) {
      _items = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addItem({
    required String name,
    required int stock,
    required int threshold,
  }) async {
    if (_hospitalId == null) return;
    final item = InventoryItem(
      id: '',
      name: name,
      stock: stock,
      threshold: threshold,
    );
    await _service.upsertInventoryItem(_hospitalId!, item);
  }

  Future<void> updateItem(InventoryItem item) async {
    if (_hospitalId == null) return;
    await _service.upsertInventoryItem(_hospitalId!, item);
  }

  Future<void> deleteItem(String itemId) async {
    if (_hospitalId == null) return;
    await _service.deleteInventoryItem(_hospitalId!, itemId);
  }

  String formatLastUpdated(DateTime? time) {
    if (time == null) return 'Unknown';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

