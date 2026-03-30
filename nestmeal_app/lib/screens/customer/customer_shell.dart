import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;

  // Navigator keys for each tab so back button works within tabs
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<Widget> _screens = const [
    HomeScreen(),
    OrdersScreen(),
    _PlansPlaceholder(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final orderUpdates = context.watch<OrderProvider>().unreadUpdates;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Try to pop the current tab's navigator first
        final currentNav = _navigatorKeys[_currentIndex].currentState;
        if (currentNav != null && currentNav.canPop()) {
          currentNav.pop();
        } else if (_currentIndex != 0) {
          // Go back to home tab
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(_screens.length, (index) {
            return Navigator(
              key: _navigatorKeys[index],
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (_) => _screens[index],
                );
              },
            );
          }),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 1) {
              // Clear order notification badge when tapping Orders tab
              context.read<OrderProvider>().clearUnreadUpdates();
            }
            if (index == _currentIndex) {
              _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
            } else {
              setState(() => _currentIndex = index);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryOrange,
          unselectedItemColor: AppTheme.greyText,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 8,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: orderUpdates > 0,
                backgroundColor: AppTheme.primaryOrange,
                child: const Icon(Icons.receipt_long_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: orderUpdates > 0,
                backgroundColor: AppTheme.primaryOrange,
                child: const Icon(Icons.receipt_long),
              ),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Plans',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text(
                  cartCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                backgroundColor: AppTheme.primaryOrange,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text(
                  cartCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                backgroundColor: AppTheme.primaryOrange,
                child: const Icon(Icons.shopping_cart),
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlansPlaceholder extends StatelessWidget {
  const _PlansPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        title: const Text('Meal Plans'),
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 80,
              color: AppTheme.greyText.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Meal Plans Coming Soon',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to weekly meal plans\nfrom your favourite cooks.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.greyText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
