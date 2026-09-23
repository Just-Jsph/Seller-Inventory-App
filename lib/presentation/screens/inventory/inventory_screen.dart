import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'add_product_screen.dart';
import 'current_inventory_view.dart';
import 'restock_screen.dart';
import 'inventory_history_view.dart';

/// Main Inventory management hub containing Current Inventory, Restock, and History tabs.
class InventoryScreen extends StatefulWidget {
  final int initialTabIndex;

  const InventoryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.tertiary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.inventory_2_rounded, size: 20),
              text: 'Stock',
            ),
            Tab(
              icon: Icon(Icons.published_with_changes_rounded, size: 20),
              text: 'Restock',
            ),
            Tab(
              icon: Icon(Icons.history_rounded, size: 20),
              text: 'History',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CurrentInventoryView(),
          RestockScreen(),
          InventoryHistoryView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box_rounded),
        label: const Text('Add Product'),
      ),
    );
  }
}
