import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'sales/sales_screen.dart';
import 'inventory/inventory_screen.dart';
import 'debts/debts_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import 'login_screen.dart';

/// Main navigation container implementing Material 3 NavigationBar and NavigationDrawer.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Sub-tab selectors to pass into nested tab screens
  int _salesInitialTab = 0;
  int _inventoryInitialTab = 0;
  int _debtsInitialTab = 0;
  int _reportsInitialTab = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 5);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final invProvider = Provider.of<InventoryProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      if (userId != null) {
        invProvider.loadData(userId);
      }
    });
  }

  void _navigateToTab(int tabIndex, {int subTabIndex = 0}) {
    setState(() {
      _currentIndex = tabIndex.clamp(0, 5);
      if (tabIndex == 1) _salesInitialTab = subTabIndex;
      if (tabIndex == 2) _inventoryInitialTab = subTabIndex;
      if (tabIndex == 3) _debtsInitialTab = subTabIndex;
      if (tabIndex == 4) _reportsInitialTab = subTabIndex;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out? Your business data will remain safely stored on this device.',
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
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // List of active root screens
    final screens = <Widget>[
      DashboardScreen(
        onNavigateToTab: (index, {int subTabIndex = 0}) {
          _navigateToTab(index, subTabIndex: subTabIndex);
        },
      ),
      SalesScreen(
        key: ValueKey('sales_$_salesInitialTab'),
        initialTabIndex: _salesInitialTab,
      ),
      InventoryScreen(
        key: ValueKey('inventory_$_inventoryInitialTab'),
        initialTabIndex: _inventoryInitialTab,
      ),
      DebtsScreen(
        key: ValueKey('debts_$_debtsInitialTab'),
        initialTabIndex: _debtsInitialTab,
      ),
      ReportsScreen(
        key: ValueKey('reports_$_reportsInitialTab'),
        initialTabIndex: _reportsInitialTab,
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildNavigationDrawer(context, user, isDark),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex > 4 ? 4 : _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        elevation: 3,
        indicatorColor: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale_rounded, color: AppColors.primary),
            label: 'Sales',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primary),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
            label: 'Debts',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: AppColors.primary),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context, dynamic user, bool isDark) {
    return NavigationDrawer(
      selectedIndex: _currentIndex,
      onDestinationSelected: (int index) {
        Navigator.of(context).pop(); // Close drawer
        if (index < 6) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      children: [
        // Drawer Header with User Profile
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                child: Text(
                  user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Seller',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user != null ? '@${user.username}' : AppConstants.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(indent: 16, endIndent: 16),

        // Navigation Destinations (All 6 Main Sections)
        const NavigationDrawerDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: Text('Dashboard'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale_rounded),
          label: Text('Sales'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded),
          label: Text('Inventory'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: Text('Debts'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics_rounded),
          label: Text('Reports'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: Text('Settings'),
        ),

        const Divider(indent: 16, endIndent: 16),

        // Quick Logout Option in Drawer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              _handleLogout(context);
            },
          ),
        ),
      ],
    );
  }
}
