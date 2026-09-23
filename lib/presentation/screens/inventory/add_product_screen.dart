import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';

/// Screen for creating a new product or editing an existing one.
class AddProductScreen extends StatefulWidget {
  final ProductModel? productToEdit;

  const AddProductScreen({super.key, this.productToEdit});

  bool get isEditing => productToEdit != null;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _buyPriceController;
  late TextEditingController _sellPriceController;
  late TextEditingController _initialStockController;
  late TextEditingController _minStockController;
  late TextEditingController _initialStockNoteController;

  int? _selectedCategoryId;
  String _selectedUnit = 'pcs';

  final List<String> _commonUnits = [
    'pcs',
    'kg',
    'g',
    'box',
    'pack',
    'bottle',
    'can',
    'liter',
    'meter',
    'pair',
    'dozen',
    'set',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;

    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _buyPriceController = TextEditingController(
      text: p != null ? (p.buyPriceCents / 100.0).toStringAsFixed(2) : '',
    );
    _sellPriceController = TextEditingController(
      text: p != null ? (p.sellPriceCents / 100.0).toStringAsFixed(2) : '',
    );
    _initialStockController = TextEditingController(text: '0');
    _minStockController = TextEditingController(
      text: p != null
          ? p.minStockAlert.toString().replaceAll(RegExp(r'\.0$'), '')
          : '5',
    );
    _initialStockNoteController = TextEditingController();

    _selectedCategoryId = p?.categoryId;
    _selectedUnit = p?.unit ?? 'pcs';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _initialStockController.dispose();
    _minStockController.dispose();
    _initialStockNoteController.dispose();
    super.dispose();
  }

  // Quick dialog to add a new Category
  Future<void> _showAddCategoryDialog(int userId) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Category Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final newCat = await invProvider.addCategory(
        userId,
        nameController.text.trim(),
        description: descController.text.trim(),
      );
      if (!mounted) return;
      if (newCat != null) {
        setState(() {
          _selectedCategoryId = newCat.id;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Category "${newCat.name}" created.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    final name = _nameController.text.trim();
    final sku = _skuController.text.trim().isNotEmpty ? _skuController.text.trim() : null;
    final barcode = _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null;
    final buyPriceDouble = double.tryParse(_buyPriceController.text.trim()) ?? 0.0;
    final sellPriceDouble = double.tryParse(_sellPriceController.text.trim()) ?? 0.0;
    final buyPriceCents = Money.fromDouble(buyPriceDouble);
    final sellPriceCents = Money.fromDouble(sellPriceDouble);
    final minStockAlert = double.tryParse(_minStockController.text.trim()) ?? 5.0;

    if (widget.isEditing) {
      // Update existing
      final current = widget.productToEdit!;
      final updatedProduct = current.copyWith(
        name: name,
        categoryId: _selectedCategoryId,
        sku: sku,
        barcode: barcode,
        buyPriceCents: buyPriceCents,
        sellPriceCents: sellPriceCents,
        minStockAlert: minStockAlert,
        unit: _selectedUnit,
        updatedAt: DateTime.now(),
      );

      final success = await invProvider.updateProduct(updatedProduct);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(invProvider.errorMessage ?? 'Failed to update product.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      // Create new
      final initialStock = double.tryParse(_initialStockController.text.trim()) ?? 0.0;
      final newProduct = ProductModel(
        userId: userId,
        name: name,
        categoryId: _selectedCategoryId,
        sku: sku,
        barcode: barcode,
        buyPriceCents: buyPriceCents,
        sellPriceCents: sellPriceCents,
        stockQuantity: initialStock,
        minStockAlert: minStockAlert,
        unit: _selectedUnit,
      );

      final success = await invProvider.addProduct(
        product: newProduct,
        initialStock: initialStock,
        note: _initialStockNoteController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "$name" added to inventory.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(invProvider.errorMessage ?? 'Failed to add product.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final invProvider = Provider.of<InventoryProvider>(context);
    final userId = authProvider.currentUser?.id ?? 1;
    final categories = invProvider.categories;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Real-time margin preview
    final buyPrice = double.tryParse(_buyPriceController.text.trim()) ?? 0.0;
    final sellPrice = double.tryParse(_sellPriceController.text.trim()) ?? 0.0;
    final profit = sellPrice - buyPrice;
    final marginPct = sellPrice > 0 ? (profit / sellPrice * 100) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Product' : 'Add New Product'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Basic Information Card
              _buildSectionCard(
                title: 'Product Information',
                icon: Icons.info_outline_rounded,
                isDark: isDark,
                children: [
                  // Product Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name *',
                      hintText: 'e.g., Organic Whole Milk',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a product name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Category Selector + Add Category Button
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.category_outlined),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Uncategorized'),
                            ),
                            ...categories.map(
                              (c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.name, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedCategoryId = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Add Category',
                        icon: const Icon(Icons.add_rounded),
                        onPressed: () => _showAddCategoryDialog(userId),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Unit Selector
                  DropdownButtonFormField<String>(
                    initialValue: _commonUnits.contains(_selectedUnit) ? _selectedUnit : _commonUnits.first,
                    decoration: InputDecoration(
                      labelText: 'Measurement Unit *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.straighten_rounded),
                    ),
                    items: _commonUnits.map((u) {
                      return DropdownMenuItem(
                        value: u,
                        child: Text(u),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedUnit = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // SKU & Barcode Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _skuController,
                          decoration: InputDecoration(
                            labelText: 'SKU Code',
                            hintText: 'e.g., PRD-001',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.tag_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            labelText: 'Barcode',
                            hintText: 'e.g., 480001234',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.qr_code_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pricing Card
              _buildSectionCard(
                title: 'Pricing & Margins',
                icon: Icons.monetization_on_outlined,
                isDark: isDark,
                children: [
                  Row(
                    children: [
                      // Cost Price
                      Expanded(
                        child: TextFormField(
                          controller: _buyPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Cost Price (₱) *',
                            hintText: '0.00',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.arrow_downward_rounded, color: AppColors.error),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter cost price';
                            final n = double.tryParse(val.trim());
                            if (n == null || n < 0) return 'Must be >= 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Selling Price
                      Expanded(
                        child: TextFormField(
                          controller: _sellPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Selling Price (₱) *',
                            hintText: '0.00',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.arrow_upward_rounded, color: AppColors.success),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter selling price';
                            final n = double.tryParse(val.trim());
                            if (n == null || n < 0) return 'Must be >= 0';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Profit Margin Preview Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: profit >= 0
                          ? AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1)
                          : AppColors.error.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: profit >= 0
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          profit >= 0 ? 'Estimated Profit / Unit:' : 'Loss per Unit:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: profit >= 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                        Text(
                          '₱${profit.toStringAsFixed(2)} (${marginPct.toStringAsFixed(1)}% margin)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: profit >= 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stock Management Card
              _buildSectionCard(
                title: 'Stock Control',
                icon: Icons.inventory_2_outlined,
                isDark: isDark,
                children: [
                  if (!widget.isEditing) ...[
                    // Initial Stock (Only for new product creation)
                    TextFormField(
                      controller: _initialStockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Initial Opening Stock ($_selectedUnit)',
                        hintText: '0',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.add_box_outlined),
                        helperText: 'Creates an initial STOCK_IN inventory transaction.',
                      ),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final n = double.tryParse(val.trim());
                          if (n == null || n < 0) return 'Must be >= 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _initialStockNoteController,
                      decoration: InputDecoration(
                        labelText: 'Initial Stock Note (Optional)',
                        hintText: 'e.g., Initial inventory onboarding',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.note_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Minimum Stock Alert Threshold
                  TextFormField(
                    controller: _minStockController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Low Stock Alert Threshold ($_selectedUnit) *',
                      hintText: '5',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                      helperText: 'Alerts when stock level drops to or below this amount.',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter threshold';
                      final n = double.tryParse(val.trim());
                      if (n == null || n < 0) return 'Must be >= 0';
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              FilledButton.icon(
                onPressed: _handleSave,
                icon: Icon(widget.isEditing ? Icons.save_rounded : Icons.add_rounded),
                label: Text(
                  widget.isEditing ? 'Save Product Changes' : 'Create Product & Record Stock',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
