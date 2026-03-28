import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item.dart';
import '../viewmodels/inventory_viewmodel.dart';

class InventoryScreen extends StatefulWidget {
  final String hospitalId;

  const InventoryScreen({
    super.key,
    required this.hospitalId,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    final vm = Provider.of<InventoryViewModel>(context, listen: false);
    vm.startListening(widget.hospitalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Module'),
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
        child: Consumer<InventoryViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading && vm.items.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00E5CC),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vm.hasCriticalStock)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFF5252).withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFFF5252),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Low stock detected',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Some medicines are at or below their configured thresholds.',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      'Inventory',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage medicines, stock levels and low-stock alerts in real time.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: vm.items.isEmpty
                          ? Center(
                              child: Text(
                                'No inventory items yet.\nTap the + button to add one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: vm.items.length,
                              itemBuilder: (context, index) {
                                final item = vm.items[index];
                                final isLow = item.isLowStock;
                                final color = isLow
                                    ? const Color(0xFFFF5252)
                                    : const Color(0xFF00E5CC);

                                return Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: color.withOpacity(0.4),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.18),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.medication_rounded,
                                        color: color,
                                      ),
                                    ),
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Stock: ${item.stock}   •   Threshold: ${item.threshold}',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Last updated: ${vm.formatLastUpdated(item.lastUpdated)}',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.5),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_rounded,
                                            color: Colors.white70,
                                          ),
                                          onPressed: () {
                                            _showItemFormDialog(
                                              context: context,
                                              vm: vm,
                                              existing: item,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.white54,
                                          ),
                                          onPressed: () async {
                                            await vm.deleteItem(item.id);
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
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final vm = Provider.of<InventoryViewModel>(context, listen: false);
          _showItemFormDialog(context: context, vm: vm);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
    );
  }

  Future<void> _showItemFormDialog({
    required BuildContext context,
    required InventoryViewModel vm,
    InventoryItem? existing,
  }) async {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final stockController = TextEditingController(
      text: existing != null ? existing.stock.toString() : '',
    );
    final thresholdController = TextEditingController(
      text: existing != null ? existing.threshold.toString() : '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF122A34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            existing == null ? 'Add Inventory Item' : 'Edit Inventory Item',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Medicine / Product Name',
                    labelStyle:
                        const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.medication_rounded,
                      color: Color(0xFF00E5CC),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF00E5CC),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Current Stock',
                    labelStyle:
                        const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.inventory_2_rounded,
                      color: Color(0xFF64B5F6),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF64B5F6),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: thresholdController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Low Stock Threshold',
                    labelStyle:
                        const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.flag_rounded,
                      color: Color(0xFFFFB74D),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFB74D),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final stock = int.tryParse(stockController.text.trim());
                final threshold =
                    int.tryParse(thresholdController.text.trim());

                if (name.isEmpty || stock == null || threshold == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter valid name, stock and threshold.',
                      ),
                      backgroundColor: Color(0xFF122A34),
                    ),
                  );
                  return;
                }

                if (existing == null) {
                  await vm.addItem(
                    name: name,
                    stock: stock,
                    threshold: threshold,
                  );
                } else {
                  final updated = existing.copyWith(
                    name: name,
                    stock: stock,
                    threshold: threshold,
                  );
                  await vm.updateItem(updated);
                }

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

