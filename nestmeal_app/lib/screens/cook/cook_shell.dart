import 'package:flutter/material.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/screens/cook/cook_dashboard_screen.dart';
import 'package:nestmeal_app/screens/cook/add_meal_screen.dart';
import 'package:nestmeal_app/screens/cook/cook_orders_screen.dart';
import 'package:nestmeal_app/screens/cook/cook_profile_edit_screen.dart';

class CookShell extends StatefulWidget {
  const CookShell({super.key});

  @override
  State<CookShell> createState() => _CookShellState();
}

class _CookShellState extends State<CookShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CookDashboardScreen(),
    AddMealScreen(),
    CookOrdersScreen(),
    CookProfileEditScreen(),
  ];

  void _switchTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CookShellTabNotifier(
      switchTab: _switchTab,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppTheme.primaryOrange,
          unselectedItemColor: AppTheme.greyText,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Add Meal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
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
