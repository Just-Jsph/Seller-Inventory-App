import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/money.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/kpi_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _customRange;
  String _selectedFilter = 'Today';

  final List<String> _filters = [
    'Today',
    'Yesterday',
    'This Week',
    'Last Week',
    'This Month',
    'Last Month',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    final provider = Provider.of<ReportsProvider>(context, listen: false);
    provider.loadReport(_selectedFilter, customRange: _customRange);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _customRange ?? initial,
    );
    if (result != null) {
      setState(() {
        _customRange = result;
        _selectedFilter = 'Custom';
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportsProvider = Provider.of<ReportsProvider>(context);
    final summary = reportsProvider.summary;
    final isLoading = reportsProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadReport,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter selector
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedFilter,
                    items: _filters
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedFilter = value;
                        if (value != 'Custom') _customRange = null;
                      });
                      if (value == 'Custom') {
                        _pickCustomRange();
                      } else {
                        _loadReport();
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  if (_selectedFilter == 'Custom' && _customRange != null)
                    Text(
                      '${_customRange!.start.toLocal().toString().split(' ')[0]} – ${_customRange!.end.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KPI cards
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.4,
                          children: [
                            KpiCard(
                              title: 'Total Sales',
                              value: Money.format(summary.totalSalesCents),
                              subtitle: '${summary.salesCount} transaction(s)',
                              icon: Icons.point_of_sale_rounded,
                              color: AppColors.primary,
                              onTap: null,
                            ),
                            KpiCard(
                              title: 'Total Cost',
                              value: Money.format(summary.cogsCents),
                              subtitle: 'Cost of goods sold',
                              icon: Icons.production_quantity_limits_rounded,
                              color: AppColors.error,
                              onTap: null,
                            ),
                            KpiCard(
                              title: 'Gross Profit',
                              value: Money.format(summary.grossProfitCents),
                              subtitle: summary.grossProfitCents >= 0 ? 'Positive' : 'Negative',
                              icon: Icons.trending_up_rounded,
                              color: summary.grossProfitCents >= 0 ? AppColors.success : AppColors.error,
                              onTap: null,
                            ),
                            KpiCard(
                              title: 'Expenses',
                              value: Money.format(summary.expenseCents),
                              subtitle: 'Operating expenses',
                              icon: Icons.receipt_long_rounded,
                              color: Colors.orangeAccent,
                              onTap: null,
                            ),
                            KpiCard(
                              title: 'Net Profit',
                              value: Money.format(summary.netProfitCents),
                              subtitle: summary.netProfitCents >= 0 ? 'Profit' : 'Loss',
                              icon: Icons.account_balance_wallet_rounded,
                              color: summary.netProfitCents >= 0 ? AppColors.success : AppColors.error,
                              onTap: null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Sales by Product
                        Text('Sales by Product', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...reportsProvider.salesByProduct.map((item) => ListTile(
                              title: Text(item['product_name'] ?? ''),
                              trailing: Text(Money.format(item['total_sales_cents'] ?? 0)),
                            )),
                        const SizedBox(height: 24),
                        // Sales by Payment Method
                        Text('Sales by Payment Method', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...reportsProvider.salesByPaymentMethod.map((item) => ListTile(
                              title: Text(item['payment_method'] ?? ''),
                              subtitle: Text('${item['transaction_count'] ?? 0} txn'),
                              trailing: Text(Money.format(item['total_sales_cents'] ?? 0)),
                            )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
