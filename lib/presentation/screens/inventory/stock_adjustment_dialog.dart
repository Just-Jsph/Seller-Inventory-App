import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';

/// Modal dialog for recording a manual stock level adjustment (audit count, damage, expired, etc.)
class StockAdjustmentDialog extends StatefulWidget {
  final ProductModel product;

  const StockAdjustmentDialog({super.key, required this.product});

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _newQtyController;
  final _reasonController = TextEditingController();
  String _selectedReasonPreset = 'Physical Count Correction (Audit)';

  final List<String> _reasonPresets = [
    'Physical Count Correction (Audit)',
    'Damaged / Broken Items',
    'Expired Product Write-off',
    'Customer Returned Good Condition',
    'Inventory Shrinkage / Missing',
    'Other (Custom Reason)',
  ];

  @override
  void initState() {
    super.initState();
    _newQtyController = TextEditingController(
      text: widget.product.stockQuantity.toString().replaceAll(RegExp(r'\.0$'), ''),
    );
  }

  @override
  void dispose() {
    _newQtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitAdjustment() async {
    if (!_formKey.currentState!.validate()) return;

    final newQty = double.tryParse(_newQtyController.text.trim());
    if (newQty == null || newQty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid non-negative quantity.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final reason = _selectedReasonPreset == 'Other (Custom Reason)'
        ? _reasonController.text.trim()
        : _selectedReasonPreset + (_reasonController.text.trim().isNotEmpty ? ' - ${_reasonController.text.trim()}' : '');

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for the adjustment.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    final success = await inventoryProvider.adjustStock(
      userId: userId,
      productId: widget.product.id!,
      newQuantity: newQty,
      reason: reason,
      unitCostCents: widget.product.buyPriceCents,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock level adjusted for ${widget.product.name}.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(inventoryProvider.errorMessage ?? 'Failed to adjust stock.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQty = widget.product.stockQuantity;
    final unit = widget.product.unit;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Stock Adjustment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Current count: ${currentQty.toStringAsFixed(currentQty.truncateToDouble() == currentQty ? 0 : 2)} $unit',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const Divider(height: 24),

              // New Quantity field
              TextFormField(
                controller: _newQtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'New Stock Quantity ($unit) *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter new quantity';
                  final n = double.tryParse(val.trim());
                  if (n == null || n < 0) return 'Must be >= 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Reason Preset Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedReasonPreset,
                decoration: InputDecoration(
                  labelText: 'Adjustment Reason *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.help_outline_rounded),
                ),
                isExpanded: true,
                items: _reasonPresets.map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text(
                      r,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedReasonPreset = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Optional additional notes
              TextFormField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Additional Notes / Reference',
                  hintText: 'e.g., Audit batch #2026-A',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _submitAdjustment,
          child: const Text('Apply Adjustment'),
        ),
      ],
    );
  }
}
