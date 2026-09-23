import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';

/// Screen and Tab for restocking products with atomic STOCK_IN movements and purchase costs.
class RestockScreen extends StatefulWidget {
  final ProductModel? initialProduct;

  const RestockScreen({super.key, this.initialProduct});

  @override
  State<RestockScreen> createState() => _RestockScreenState();
}

class _RestockScreenState extends State<RestockScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedProductId;
  late TextEditingController _quantityController;
  late TextEditingController _unitCostController;
  late TextEditingController _referenceController;
  late TextEditingController _noteController;

  DateTime _selectedDate = DateTime.now();
  bool _updateCostPrice = false;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProduct?.id;
    _quantityController = TextEditingController();
    _unitCostController = TextEditingController(
      text: widget.initialProduct != null
          ? (widget.initialProduct!.buyPriceCents / 100.0).toStringAsFixed(2)
          : '',
    );
    _referenceController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onProductChanged(ProductModel? product) {
    if (product != null) {
      setState(() {
        _selectedProductId = product.id;
        _unitCostController.text = (product.buyPriceCents / 100.0).toStringAsFixed(2);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleRestock() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product to restock.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final unitCostDouble = double.tryParse(_unitCostController.text.trim()) ?? 0.0;
    final unitCostCents = Money.fromDouble(unitCostDouble);

    final success = await invProvider.restockProduct(
      userId: userId,
      productId: _selectedProductId!,
      quantity: quantity,
      unitCostCents: unitCostCents,
      referenceId: _referenceController.text.trim().isNotEmpty ? _referenceController.text.trim() : null,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : 'Stock Restock',
      date: _selectedDate,
      updateProductCostPrice: _updateCostPrice,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock added successfully! Inventory movement recorded.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        // Clear form if in tab view
        setState(() {
          _quantityController.clear();
          _referenceController.clear();
          _noteController.clear();
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(invProvider.errorMessage ?? 'Failed to restock product.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final invProvider = Provider.of<InventoryProvider>(context);
    final products = invProvider.products;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Find selected product
    ProductModel? selectedProduct;
    if (_selectedProductId != null) {
      try {
        selectedProduct = products.firstWhere((p) => p.id == _selectedProductId);
      } catch (_) {
        selectedProduct = null;
      }
    }

    final qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final unitCost = double.tryParse(_unitCostController.text.trim()) ?? 0.0;
    final totalCost = qty * unitCost;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restock Products'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Product Selection Card
              Card(
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
                        children: const [
                          Icon(Icons.inventory_2_outlined, color: AppColors.secondary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Select Product to Restock',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      if (products.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline_rounded, color: Colors.amber),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'No products found. Please add a product first before restocking.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<int?>(
                          initialValue: _selectedProductId,
                          decoration: InputDecoration(
                            labelText: 'Product *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.shopping_basket_outlined),
                          ),
                          isExpanded: true,
                          hint: const Text('Choose a product...'),
                          items: products.map((p) {
                            final isLow = p.stockQuantity <= p.minStockAlert;
                            return DropdownMenuItem<int?>(
                              value: p.id,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isLow
                                          ? AppColors.error.withValues(alpha: 0.15)
                                          : AppColors.success.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${p.stockQuantity.toStringAsFixed(p.stockQuantity.truncateToDouble() == p.stockQuantity ? 0 : 2)} ${p.unit}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isLow ? AppColors.error : AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final p = products.firstWhere((item) => item.id == val);
                              _onProductChanged(p);
                            }
                          },
                          validator: (val) => val == null ? 'Select a product' : null,
                        ),

                      if (selectedProduct != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.secondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Stock',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${selectedProduct.stockQuantity} ${selectedProduct.unit}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Default Cost Price',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₱${(selectedProduct.buyPriceCents / 100.0).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Restock Details Card
              Card(
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
                        children: const [
                          Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Restock Movement Details',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Quantity and Unit Cost
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Quantity to Add *',
                                hintText: '0',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.add_box_rounded, color: AppColors.secondary),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter quantity';
                                final n = double.tryParse(val.trim());
                                if (n == null || n <= 0) return 'Must be > 0';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _unitCostController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Unit Cost (₱) *',
                                hintText: '0.00',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.payments_outlined),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter unit cost';
                                final n = double.tryParse(val.trim());
                                if (n == null || n < 0) return 'Must be >= 0';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Total Cost Summary Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Batch Purchase Cost:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '₱${totalCost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Date picker trigger
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Date: ${DateFormat('MMMM dd, yyyy').format(_selectedDate)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_drop_down_rounded),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Reference / Supplier
                      TextFormField(
                        controller: _referenceController,
                        decoration: InputDecoration(
                          labelText: 'Supplier / PO / Invoice # (Optional)',
                          hintText: 'e.g., Supplier XYZ - Invoice #9921',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.tag_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Note
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: 'Reason / Note (Optional)',
                          hintText: 'e.g., Weekly stock replenishment',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Checkbox: Update master product cost price
                      CheckboxListTile(
                        value: _updateCostPrice,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Update product default cost price to this unit cost',
                          style: TextStyle(fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (val) {
                          setState(() {
                            _updateCostPrice = val ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Restock Button
              FilledButton.icon(
                onPressed: products.isEmpty ? null : _handleRestock,
                icon: const Icon(Icons.published_with_changes_rounded),
                label: const Text(
                  'Confirm Restock & Record Movement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
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
}
