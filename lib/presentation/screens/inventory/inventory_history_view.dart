import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/inventory_transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';

/// Tab view for Inventory Movement History & Audit Trails.
class InventoryHistoryView extends StatefulWidget {
  const InventoryHistoryView({super.key});

  @override
  State<InventoryHistoryView> createState() => _InventoryHistoryViewState();
}

class _InventoryHistoryViewState extends State<InventoryHistoryView> {
  final List<String> _txTypes = [
    'ALL',
    'STOCK_IN',
    'SALE',
    'ADJUSTMENT',
    'RETURN',
    'DAMAGE',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final invProvider = Provider.of<InventoryProvider>(context);
    final userId = authProvider.currentUser?.id ?? 1;
    final transactions = invProvider.transactions;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => invProvider.loadData(userId),
      child: Column(
        children: [
          // 1. Transaction Type Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: _txTypes.map((type) {
                final isSelected = invProvider.selectedTransactionType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(type == 'ALL' ? 'All Movements' : type.replaceAll('_', ' ')),
                    selected: isSelected,
                    selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.secondary,
                    onSelected: (_) {
                      invProvider.setTransactionTypeFilter(type, userId);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // 2. Transaction Count Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Movement Audit Log',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${transactions.length} entries',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // 3. Transactions List or Empty State
          Expanded(
            child: invProvider.isLoading && transactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return _buildTransactionCard(context, tx, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, InventoryTransactionModel tx, bool isDark) {
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

    final formattedQty = tx.quantity.abs().toStringAsFixed(
      tx.quantity.truncateToDouble() == tx.quantity ? 0 : 2,
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Pill
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tx.productName ?? 'Product #${tx.productId}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$sign$formattedQty ${tx.productUnit ?? ""}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Transaction Type & Cost
                  Row(
                    children: [
                      Text(
                        tx.transactionType.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                      if (tx.unitCostCents != null) ...[
                        Text(
                          ' • Unit Cost: ₱${(tx.unitCostCents! / 100.0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Reason / Reference Note
                  if (tx.note != null || tx.referenceId != null) ...[
                    Text(
                      tx.note ?? tx.referenceId!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Timestamp
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(tx.createdAt),
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 40,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Movements Recorded',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Every stock change (Restock, Sale, Audit Adjustment) will appear here in the audit log.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
