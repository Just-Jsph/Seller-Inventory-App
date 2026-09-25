import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/sale_model.dart';
import '../../../data/models/sale_item_model.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/inventory_provider.dart';

class CartItem {
  final ProductModel product;
  double quantity;
  int unitPriceCents;

  CartItem({
    required this.product,
    this.quantity = 1.0,
    required this.unitPriceCents,
  });

  int get subtotalCents => (quantity * unitPriceCents).round();
  int get costCents => (quantity * product.buyPriceCents).round();
}

/// Screen for registering a new sale with item selection, payment methods, and inventory deduction.
class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final SaleRepository _saleRepository = SaleRepository();

  final List<CartItem> _cart = [];
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0.00');
  final TextEditingController _notesController = TextEditingController();

  String _paymentMethod = 'CASH';
  final List<String> _paymentMethods = ['CASH', 'E-WALLET', 'CARD', 'DEBT', 'OTHER'];

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addProductToCart(ProductModel product) {
    setState(() {
      final index = _cart.indexWhere((item) => item.product.id == product.id);
      if (index >= 0) {
        _cart[index].quantity += 1.0;
      } else {
        _cart.add(
          CartItem(
            product: product,
            quantity: 1.0,
            unitPriceCents: product.sellPriceCents,
          ),
        );
      }
    });
  }

  void _removeProductFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  int get _grossTotalCents {
    return _cart.fold<int>(0, (sum, item) => sum + item.subtotalCents);
  }

  int get _discountCents {
    final d = double.tryParse(_discountController.text.trim()) ?? 0.0;
    return Money.fromDouble(d);
  }

  int get _netTotalCents {
    final net = _grossTotalCents - _discountCents;
    return net < 0 ? 0 : net;
  }

  Future<void> _showProductSelectorDialog(List<ProductModel> products) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = products.where((p) {
              return p.name.toLowerCase().contains(query.toLowerCase()) ||
                  (p.sku != null && p.sku!.toLowerCase().contains(query.toLowerCase())) ||
                  (p.barcode != null && p.barcode!.contains(query));
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Product for Cart',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search product name, SKU, or barcode...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        query = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No matching products found.'))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final p = filtered[idx];
                              final isOutOfStock = p.stockQuantity <= 0;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isOutOfStock
                                      ? AppColors.error.withValues(alpha: 0.15)
                                      : AppColors.primary.withValues(alpha: 0.15),
                                  child: Icon(
                                    Icons.inventory_2_rounded,
                                    size: 18,
                                    color: isOutOfStock ? AppColors.error : AppColors.primary,
                                  ),
                                ),
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Stock: ${p.stockQuantity} ${p.unit} • ${p.formattedSellPrice}',
                                  style: TextStyle(
                                    color: isOutOfStock ? AppColors.error : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  ),
                                ),
                                trailing: ElevatedButton.icon(
                                  onPressed: isOutOfStock
                                      ? null
                                      : () {
                                          _addProductToCart(p);
                                          Navigator.of(ctx).pop();
                                        },
                                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                                  label: const Text('Add'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleCompleteSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product to the sale cart.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final customerName = _customerNameController.text.trim().isNotEmpty ? _customerNameController.text.trim() : 'Walk-in Customer';
    final customerPhone = _customerPhoneController.text.trim().isNotEmpty ? _customerPhoneController.text.trim() : null;

    final saleModel = SaleModel(
      userId: userId,
      invoiceNumber: invoiceNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      totalAmountCents: _grossTotalCents,
      discountCents: _discountCents,
      paidAmountCents: _netTotalCents,
      paymentMethod: _paymentMethod,
      paymentStatus: 'PAID',
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final saleItems = _cart.map((item) {
      return SaleItemModel(
        saleId: 0, // Assigned in transaction
        productId: item.product.id!,
        productName: item.product.name,
        quantity: item.quantity,
        unitPriceCents: item.unitPriceCents,
        subtotalCents: item.subtotalCents,
        costCents: item.product.buyPriceCents,
      );
    }).toList();

    try {
      await _saleRepository.createSaleWithItems(saleModel, saleItems);

      if (!mounted) return;

      // Refresh Dashboard & Inventory Providers
      final dashProvider = Provider.of<DashboardProvider>(context, listen: false);
      final invProvider = Provider.of<InventoryProvider>(context, listen: false);
      await dashProvider.loadDashboardData(userId);
      await invProvider.loadData(userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sale #$invoiceNumber completed successfully (₱${Money.format(_netTotalCents)}).'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to record sale: $e'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Sale'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Section 1: Customer Details
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 18),
                                SizedBox(width: 8),
                                Text('Customer Information', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _customerNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Customer Name',
                                      hintText: 'Walk-in Customer',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _customerPhoneController,
                                    decoration: InputDecoration(
                                      labelText: 'Phone (Optional)',
                                      hintText: '0917xxxxxxx',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 2: Cart Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sale Items',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showProductSelectorDialog(products),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_cart.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text(
                              'Cart is empty',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap "Add Product" above to add items to this transaction.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final item = _cart[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${Money.format(item.unitPriceCents)} / ${item.product.unit}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            if (item.quantity > 1) {
                                              item.quantity -= 1;
                                            } else {
                                              _removeProductFromCart(index);
                                            }
                                          });
                                        },
                                      ),
                                      Text(
                                        '${item.quantity.toInt()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            item.quantity += 1;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    Money.format(item.subtotalCents),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                    onPressed: () => _removeProductFromCart(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),

                    // Section 3: Payment Method & Discount
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                DropdownButton<String>(
                                  value: _paymentMethod,
                                  underline: const SizedBox(),
                                  items: _paymentMethods.map((m) {
                                    return DropdownMenuItem(value: m, child: Text(m));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _paymentMethod = val);
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              children: [
                                const Text('Discount (₱):', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 110,
                                  child: TextFormField(
                                    controller: _discountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Summary Bar & Submit Button
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Net Amount:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        Text(
                          Money.format(_netTotalCents),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _cart.isEmpty ? null : _handleCompleteSale,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Complete Sale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
