import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/inventory_transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import 'add_product_screen.dart';
import 'restock_screen.dart';
import 'stock_adjustment_dialog.dart';

/// Comprehensive product detail screen with KPI indicators, quick action hub, and transaction audit timeline.
class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  List<InventoryTransactionModel> _productTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    try {
      // Find product from provider or reload
      await invProvider.loadData(userId);
      ProductModel? found;
      try {
        found = invProvider.products.firstWhere((p) => p.id == widget.productId);
      } catch (_) {
        found = null;
      }

      final txs = invProvider.transactions.where((t) => t.productId == widget.productId).toList();

      if (mounted) {
        setState(() {
          _product = found;
          _productTransactions = txs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDeleteProduct(BuildContext context) async {
    if (_product == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    // Check if safe to delete
    final check = await invProvider.canDeleteProduct(userId, _product!.id!);

    if (!context.mounted) return;

    if (!check.canDelete) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.shield_outlined, color: AppColors.error),
              SizedBox(width: 8),
              Text('Cannot Delete Product'),
            ],
          ),
          content: Text(
            check.reason ??
                'This product has recorded sales or financial movement history. To preserve ledger integrity, it cannot be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understand'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${_product!.name}"? This action will remove the product and its initial record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await invProvider.deleteProduct(userId, _product!.id!);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product "${_product!.name}" deleted.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(invProvider.errorMessage ?? 'Failed to delete product.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found or has been removed.')),
      );
    }

    final p = _product!;
    final isOutOfStock = p.stockQuantity <= 0;
    final isLowStock = !isOutOfStock && p.stockQuantity <= p.minStockAlert;
    final profit = p.sellPrice - p.buyPrice;
    final marginPct = p.sellPrice > 0 ? (profit / p.sellPrice * 100) : 0.0;
    final totalCostValuation = p.stockQuantity * p.buyPrice;
    final totalRetailValuation = p.stockQuantity * p.sellPrice;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Product',
            onPressed: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddProductScreen(productToEdit: p),
                ),
              );
              if (updated == true) {
                _loadProductDetails();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Product',
            onPressed: () => _handleDeleteProduct(context),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProductDetails,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Stock Status Hero Card
              Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOutOfStock
                        ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                        : isLowStock
                            ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                            : [AppColors.secondary, const Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isOutOfStock
                              ? AppColors.error
                              : isLowStock
                                  ? AppColors.warning
                                  : AppColors.secondary)
                          .withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isOutOfStock
                                ? 'OUT OF STOCK'
                                : isLowStock
                                    ? 'LOW STOCK ALERT'
                                    : 'IN STOCK',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          'Unit: ${p.unit}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          p.stockQuantity.toStringAsFixed(
                            p.stockQuantity.truncateToDouble() == p.stockQuantity ? 0 : 2,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          p.unit,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Min alert threshold: ${p.minStockAlert} ${p.unit}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Quick Action Bar (Restock & Adjust)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final res = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => RestockScreen(initialProduct: p),
                          ),
                        );
                        if (res == true) _loadProductDetails();
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: const Text('Restock Stock'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final res = await showDialog<bool>(
                          context: context,
                          builder: (_) => StockAdjustmentDialog(product: p),
                        );
                        if (res == true) _loadProductDetails();
                      },
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Adjust Count'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Pricing & Valuation Card
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
                      const Text(
                        'Pricing & Asset Valuation',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20),
                      _buildInfoRow('Cost Price / Unit', p.formattedBuyPrice, isDark),
                      const SizedBox(height: 8),
                      _buildInfoRow('Selling Price / Unit', p.formattedSellPrice, isDark),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Unit Profit Margin',
                        '₱${profit.toStringAsFixed(2)} (${marginPct.toStringAsFixed(1)}%)',
                        isDark,
                        valueColor: profit >= 0 ? AppColors.success : AppColors.error,
                      ),
                      const Divider(height: 20),
                      _buildInfoRow('Total Stock Cost Valuation', '₱${totalCostValuation.toStringAsFixed(2)}', isDark),
                      const SizedBox(height: 8),
                      _buildInfoRow('Total Stock Retail Valuation', '₱${totalRetailValuation.toStringAsFixed(2)}', isDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Product Identifiers & Meta
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
                      const Text(
                        'Identification & Timestamps',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20),
                      _buildInfoRow('SKU Code', p.sku ?? 'None', isDark),
                      const SizedBox(height: 8),
                      _buildInfoRow('Barcode', p.barcode ?? 'None', isDark),
                      const SizedBox(height: 8),
                      _buildInfoRow('Created Date', DateFormat('MMM dd, yyyy - hh:mm a').format(p.createdAt), isDark),
                      const SizedBox(height: 8),
                      _buildInfoRow('Last Updated', DateFormat('MMM dd, yyyy - hh:mm a').format(p.updatedAt), isDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 5. Stock Movement Timeline Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stock Movement History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_productTransactions.length} records',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stock Movement List
              if (_productTransactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'No inventory movements recorded yet.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._productTransactions.map((tx) => _buildTransactionTile(tx, isDark)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : Colors.grey.shade900),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(InventoryTransactionModel tx, bool isDark) {
    final isIncrease = tx.transactionType == 'STOCK_IN' || tx.transactionType == 'RETURN';
    final isDecrease = tx.transactionType == 'STOCK_OUT' ||
        tx.transactionType == 'SALE' ||
        tx.transactionType == 'DAMAGE';

    Color color;
    IconData icon;
    String sign;

    if (isIncrease) {
      color = AppColors.success;
      icon = Icons.add_circle_outline_rounded;
      sign = '+';
    } else if (isDecrease) {
      color = AppColors.error;
      icon = Icons.remove_circle_outline_rounded;
      sign = '-';
    } else {
      color = AppColors.info;
      icon = Icons.tune_rounded;
      sign = tx.quantity >= 0 ? '+' : '';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tx.transactionType.replaceAll('_', ' '),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '$sign${tx.quantity.abs()} ${_product?.unit ?? ""}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.note ?? (tx.referenceId ?? 'Movement recorded'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(tx.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
