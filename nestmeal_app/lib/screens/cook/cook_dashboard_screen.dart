import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/providers/auth_provider.dart';
import 'package:nestmeal_app/providers/meal_provider.dart';
import 'package:nestmeal_app/providers/order_provider.dart';
import 'package:nestmeal_app/screens/cook/edit_meal_screen.dart';

class CookDashboardScreen extends StatefulWidget {
  const CookDashboardScreen({super.key});

  @override
  State<CookDashboardScreen> createState() => _CookDashboardScreenState();
}

class _CookDashboardScreenState extends State<CookDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final mealProvider = context.read<MealProvider>();
    final orderProvider = context.read<OrderProvider>();

    final cookId = authProvider.currentUser?.cookProfile?.id;

    try {
      await Future.wait([
        orderProvider.fetchCookStats(),
        if (cookId != null) mealProvider.fetchMeals(cook: cookId),
      ]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryOrange,
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(),
                const SizedBox(height: 20),
                _buildStatsRow(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildMenuHeader(),
                const SizedBox(height: 12),
                _buildMealsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final cook = user?.cookProfile;

    final displayName = cook?.displayName ?? user?.fullName ?? 'Chef';
    final initials = displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .take(2)
        .join();

    final location = [cook?.kitchenCity, cook?.kitchenState]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFFB923C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
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
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (cook != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    cook.avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final orderProvider = context.watch<OrderProvider>();
    final stats = orderProvider.cookStats;

    final todayRevenue = stats?['today_revenue'] ?? stats?['total_earnings'] ?? 0;
    final activeOrders = stats?['active_orders'] ?? 0;
    final totalOrders = stats?['total_orders'] ?? 0;
    final pendingOrders = stats?['pending_orders'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.attach_money,
            iconColor: AppTheme.successGreen,
            label: "Today's Revenue",
            value: 'A\$$todayRevenue',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.pending_actions,
            iconColor: Colors.amber.shade700,
            label: 'Pending',
            value: '$pendingOrders',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.assignment_outlined,
            iconColor: AppTheme.primaryOrange,
            label: 'Active',
            value: '$activeOrders',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline,
            iconColor: AppTheme.successGreen,
            label: 'Total',
            value: '$totalOrders',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_circle_outline,
            label: 'Add Meal',
            color: AppTheme.primaryOrange,
            onTap: () => _switchToTab(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.receipt_long_outlined,
            label: 'View Orders',
            color: Colors.blue.shade600,
            onTap: () => _switchToTab(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.person_outline,
            label: 'My Profile',
            color: Colors.purple.shade600,
            onTap: () => _switchToTab(3),
          ),
        ),
      ],
    );
  }

  void _switchToTab(int index) {
    CookShellTabNotifier.of(context)?.switchTab(index);
  }

  Widget _buildMenuHeader() {
    final mealProvider = context.watch<MealProvider>();
    final mealCount = mealProvider.meals.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'My Meals ($mealCount)',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        TextButton.icon(
          onPressed: () => _switchToTab(1),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add New'),
        ),
      ],
    );
  }

  Widget _buildMealsList() {
    final mealProvider = context.watch<MealProvider>();

    if (mealProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (mealProvider.meals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: AppTheme.greyText),
            const SizedBox(height: 12),
            Text(
              'No meals yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.greyText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your first meal to get started',
              style: TextStyle(fontSize: 13, color: AppTheme.greyText),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _switchToTab(1),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Meal'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mealProvider.meals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final meal = mealProvider.meals[index];
        final imageUrl =
            meal.images.isNotEmpty ? meal.images.first.imageUrl : null;

        return InkWell(
          onTap: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => EditMealScreen(meal: meal),
              ),
            );
            if (result == true) _loadData();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 64,
                            height: 64,
                            color: AppTheme.lightGrey,
                            child: const Icon(Icons.restaurant, size: 24),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: AppTheme.lightGrey,
                            child: const Icon(Icons.restaurant, size: 24),
                          ),
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.lightGrey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.restaurant,
                            size: 24,
                            color: AppTheme.greyText,
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              meal.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: meal.isAvailable
                                  ? AppTheme.successGreen.withValues(alpha: 0.1)
                                  : AppTheme.errorRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              meal.isAvailable ? 'Active' : 'Hidden',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: meal.isAvailable
                                    ? AppTheme.successGreen
                                    : AppTheme.errorRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatLabel(meal.category),
                            style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            meal.mealType == 'veg'
                                ? Icons.eco
                                : meal.mealType == 'egg'
                                    ? Icons.egg
                                    : Icons.lunch_dining,
                            size: 14,
                            color: meal.mealType == 'veg'
                                ? AppTheme.successGreen
                                : meal.mealType == 'egg'
                                    ? Colors.amber
                                    : AppTheme.errorRed,
                          ),
                          const Spacer(),
                          Icon(Icons.edit_outlined, size: 14, color: AppTheme.greyText),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(fontSize: 11, color: AppTheme.greyText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Price
                Text(
                  'A\$${meal.effectivePrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatLabel(String tag) {
    return tag
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}

// InheritedWidget to allow dashboard to switch tabs in CookShell
class CookShellTabNotifier extends InheritedWidget {
  final void Function(int) switchTab;

  const CookShellTabNotifier({
    super.key,
    required this.switchTab,
    required super.child,
  });

  static CookShellTabNotifier? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CookShellTabNotifier>();
  }

  @override
  bool updateShouldNotify(CookShellTabNotifier oldWidget) => false;
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.greyText,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
