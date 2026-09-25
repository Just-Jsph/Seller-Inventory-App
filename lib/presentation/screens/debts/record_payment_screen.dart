import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/debt_payment_model.dart';
import '../../../data/repositories/debt_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/inventory_provider.dart';

/// Screen for recording a customer debt repayment/collection.
class RecordPaymentScreen extends StatefulWidget {
  final DebtModel? preselectedDebt;

  const RecordPaymentScreen({super.key, this.preselectedDebt});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DebtRepository _debtRepository = DebtRepository();

  List<DebtModel> _activeDebts = [];
  DebtModel? _selectedDebt;
  bool _isLoadingDebts = true;

  late TextEditingController _amountController;
  late TextEditingController _noteController;

  String _paymentMethod = 'CASH';
  DateTime _paymentDate = DateTime.now();

  final List<String> _paymentMethods = [
    'CASH',
    'E-WALLET',
    'BANK',
    'CARD',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _loadActiveDebts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveDebts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      setState(() => _isLoadingDebts = false);
      return;
    }

    try {
      final allDebts = await _debtRepository.getAll(userId);
      final active = allDebts.where((d) => d.status != 'PAID').toList();

      setState(() {
        _activeDebts = active;
        _isLoadingDebts = false;

        if (widget.preselectedDebt != null) {
          try {
            _selectedDebt = _activeDebts.firstWhere((d) => d.id == widget.preselectedDebt!.id);
          } catch (_) {
            _selectedDebt = widget.preselectedDebt;
          }
        } else if (_activeDebts.isNotEmpty) {
          _selectedDebt = _activeDebts.first;
        }

        if (_selectedDebt != null) {
          _amountController.text = (_selectedDebt!.remainingAmount).toStringAsFixed(2);
        }
      });
    } catch (e) {
      setState(() => _isLoadingDebts = false);
    }
  }

  void _onDebtChanged(DebtModel? debt) {
    if (debt != null) {
      setState(() {
        _selectedDebt = debt;
        _amountController.text = debt.remainingAmount.toStringAsFixed(2);
      });
    }
  }

  void _setQuickAmount(double value) {
    if (_selectedDebt == null) return;
    final maxVal = _selectedDebt!.remainingAmount;
    final target = value > maxVal ? maxVal : value;
    setState(() {
      _amountController.text = target.toStringAsFixed(2);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  Future<void> _handleSavePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDebt == null || _selectedDebt!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an active debtor account.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    final amountDouble = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final amountCents = Money.fromDouble(amountDouble);

    if (amountCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment amount must be greater than zero.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final payment = DebtPaymentModel(
      debtId: _selectedDebt!.id!,
      userId: userId,
      amountCents: amountCents,
      paymentMethod: _paymentMethod,
      paymentDate: _paymentDate,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    try {
      await _debtRepository.recordPayment(payment);

      if (!mounted) return;

      // Refresh Dashboard and Inventory state
      final dashProvider = Provider.of<DashboardProvider>(context, listen: false);
      final invProvider = Provider.of<InventoryProvider>(context, listen: false);
      await dashProvider.loadDashboardData(userId);
      await invProvider.loadData(userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment of ₱${amountDouble.toStringAsFixed(2)} recorded for ${_selectedDebt!.customerName}.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to record payment: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final amountVal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final remainingAfter = _selectedDebt != null
        ? (_selectedDebt!.remainingAmount - amountVal).clamp(0.0, double.infinity)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Payment / Collection'),
      ),
      body: SafeArea(
        child: _isLoadingDebts
            ? const Center(child: CircularProgressIndicator())
            : _activeDebts.isEmpty && widget.preselectedDebt == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 64,
                            color: AppColors.success.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Outstanding Debts',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All customer accounts are fully settled. No open receivables to collect.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back to Dashboard'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        // Customer / Debt Selector
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
                                    Icon(Icons.person_pin_rounded, color: AppColors.warning, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Debtor Account',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                DropdownButtonFormField<DebtModel>(
                                  initialValue: _selectedDebt,
                                  decoration: InputDecoration(
                                    labelText: 'Select Debtor Customer *',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    prefixIcon: const Icon(Icons.people_alt_outlined),
                                  ),
                                  isExpanded: true,
                                  items: _activeDebts.map((d) {
                                    return DropdownMenuItem<DebtModel>(
                                      value: d,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              d.customerName,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            'Balance: ${d.formattedRemaining}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _onDebtChanged,
                                  validator: (val) => val == null ? 'Select customer debt' : null,
                                ),

                                if (_selectedDebt != null) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.warning.withValues(alpha: 0.15)
                                          : AppColors.warning.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.warning.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Debt',
                                              style: TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            Text(
                                              Money.format(_selectedDebt!.totalAmountCents),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Paid So Far',
                                              style: TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            Text(
                                              Money.format(_selectedDebt!.paidAmountCents),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'Unpaid Balance',
                                              style: TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            Text(
                                              _selectedDebt!.formattedRemaining,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.error,
                                              ),
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

                        // Payment Details Card
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
                                    Icon(Icons.payments_rounded, color: AppColors.primary, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Payment Amount & Method',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),

                                // Amount Field
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    labelText: 'Payment Amount (₱) *',
                                    hintText: '0.00',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.success),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Enter payment amount';
                                    final n = double.tryParse(val.trim());
                                    if (n == null || n <= 0) return 'Must be > 0';
                                    if (_selectedDebt != null && n > _selectedDebt!.remainingAmount + 0.01) {
                                      return 'Cannot exceed remaining debt';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),

                                // Quick Amount Chips
                                if (_selectedDebt != null)
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        ActionChip(
                                          label: const Text('Full Balance'),
                                          avatar: const Icon(Icons.check_circle_rounded, size: 16),
                                          onPressed: () => _setQuickAmount(_selectedDebt!.remainingAmount),
                                        ),
                                        const SizedBox(width: 8),
                                        ActionChip(
                                          label: const Text('₱500'),
                                          onPressed: () => _setQuickAmount(500),
                                        ),
                                        const SizedBox(width: 8),
                                        ActionChip(
                                          label: const Text('₱1,000'),
                                          onPressed: () => _setQuickAmount(1000),
                                        ),
                                        const SizedBox(width: 8),
                                        ActionChip(
                                          label: const Text('₱2,000'),
                                          onPressed: () => _setQuickAmount(2000),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 14),

                                // Remaining Balance Forecast
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'New Balance After Payment:',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        '₱${remainingAfter.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: remainingAfter == 0
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Payment Method Selector
                                DropdownButtonFormField<String>(
                                  initialValue: _paymentMethod,
                                  decoration: InputDecoration(
                                    labelText: 'Payment Method *',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                                  ),
                                  items: _paymentMethods.map((m) {
                                    return DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _paymentMethod = val;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Date Picker
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
                                              'Date: ${DateFormat('MMMM dd, yyyy').format(_paymentDate)}',
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

                                // Notes
                                TextFormField(
                                  controller: _noteController,
                                  decoration: InputDecoration(
                                    labelText: 'Payment Note / Receipt # (Optional)',
                                    hintText: 'e.g., GCash Ref #1029384',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    prefixIcon: const Icon(Icons.note_alt_outlined),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Record Button
                        FilledButton.icon(
                          onPressed: _handleSavePayment,
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text(
                            'Save Debt Payment',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
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
