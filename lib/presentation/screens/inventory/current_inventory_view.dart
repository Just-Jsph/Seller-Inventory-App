import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/inventory_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';
import 'restock_screen.dart';

/// Tab view for Current Stock with search, multi-criteria filtering, asset metrics, and product management.
class CurrentInventoryView extends StatefulWidget {
  const CurrentInventoryView({super.key});

  @override
  State<CurrentInventoryView> createState() => _CurrentInventoryViewState();
}

class _CurrentInventoryViewState extends State<CurrentInventoryView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final invProvider = Provider.of<InventoryProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      if (userId != null) {
        invProvider.loadData(userId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final invProvider = Provider.of<InventoryProvider>(context);
    final userId = authProvider.currentUser?.id ?? 1;
    final products = invProvider.products;
    final categories = invProvider.categories;
    final summary = invProvider.summary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => invProvider.loadData(userId),
      child: Column(
        children: [
          // 1. Search Bar & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search products by name, SKU, or barcode...',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      invProvider.setSearchQuery('', userId);
                    },
                  ),
              ],
              onChanged: (val) {
                invProvider.setSearchQuery(val, userId);
              },
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          // 2. Stock Level Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                _buildStockFilterChip(
                  label: 'All (${summary.totalProducts})',
                  filter: StockFilter.all,
                  currentFilter: invProvider.stockFilter,
                  onSelected: () => invProvider.setStockFilter(StockFilter.all, userId),
                ),
                const SizedBox(width: 8),
                _buildStockFilterChip(
                  label: 'Low Stock (${summary.lowStockCount})',
                  filter: StockFilter.lowStock,
                  currentFilter: invProvider.stockFilter,
                  badgeColor: AppColors.warning,
                  onSelected: () => invProvider.setStockFilter(StockFilter.lowStock, userId),
                ),
                const SizedBox(width: 8),
                _buildStockFilterChip(
                  label: 'Out of Stock (${summary.outOfStockCount})',
                  filter: StockFilter.outOfStock,
                  currentFilter: invProvider.stockFilter,
                  badgeColor: AppColors.error,
                  onSelected: () => invProvider.setStockFilter(StockFilter.outOfStock, userId),
                ),
                const SizedBox(width: 8),
                _buildStockFilterChip(
                  label: 'In Stock (${summary.inStockCount})',
                  filter: StockFilter.inStock,
                  currentFilter: invProvider.stockFilter,
                  badgeColor: AppColors.success,
                  onSelected: () => invProvider.setStockFilter(StockFilter.inStock, userId),
                ),
              ],
            ),
          ),

          // 3. Category Filter Chips (if categories exist)
          if (categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Categories'),
                    selected: invProvider.selectedCategoryId == null,
                    onSelected: (selected) {
                      if (selected) {
                        invProvider.setCategoryFilter(null, userId);
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  ...categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(cat.name),
                        selected: invProvider.selectedCategoryId == cat.id,
                        onSelected: (selected) {
                          invProvider.setCategoryFilter(selected ? cat.id : null, userId);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 4. Inventory Valuation Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.secondary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.secondary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Asset Value: ₱${(summary.totalCostCents / 100.0).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  Text(
                    'Retail: ₱${(summary.totalRetailCents / 100.0).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Product List or Empty State
          Expanded(
            child: invProvider.isLoading && products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? _buildEmptyState(context, invProvider.searchQuery, userId)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _buildProductCard(context, product, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockFilterChip({
    required String label,
    required StockFilter filter,
    required StockFilter currentFilter,
    Color? badgeColor,
    required VoidCallback onSelected,
  }) {
    final isSelected = filter == currentFilter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: (badgeColor ?? AppColors.primary).withValues(alpha: 0.2),
      checkmarkColor: badgeColor ?? AppColors.primary,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product, bool isDark) {
    final isOutOfStock = product.stockQuantity <= 0;
    final isLowStock = !isOutOfStock && product.stockQuantity <= product.minStockAlert;

    Color badgeColor;
    String badgeText;
    if (isOutOfStock) {
      badgeColor = AppColors.error;
      badgeText = 'OUT OF STOCK';
    } else if (isLowStock) {
      badgeColor = AppColors.warning;
      badgeText = 'LOW STOCK';
    } else {
      badgeColor = AppColors.success;
      badgeText = 'IN STOCK';
    }

    final formattedQty = product.stockQuantity.toStringAsFixed(
      product.stockQuantity.truncateToDouble() == product.stockQuantity ? 0 : 2,
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLowStock || isOutOfStock
              ? badgeColor.withValues(alpha: 0.35)
              : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: product.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product Avatar / Stock Indicator Circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: badgeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sell: ${product.formattedSellPrice} • Cost: ${product.formattedBuyPrice}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '$formattedQty ${product.unit}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                    if (product.sku != null || product.barcode != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'SKU: ${product.sku ?? product.barcode ?? ""}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Quick Restock Shortcut
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                tooltip: 'Quick Restock',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RestockScreen(initialProduct: product),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String searchQuery, int userId) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'No products match "$searchQuery"'
                  : 'No Products in Inventory',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try searching with different keywords or clear filters.'
                  : 'Start by adding your first product to track stock and movements.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
              },
              icon: const Icon(Icons.add_box_rounded),
              label: const Text('Add Product Now'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
