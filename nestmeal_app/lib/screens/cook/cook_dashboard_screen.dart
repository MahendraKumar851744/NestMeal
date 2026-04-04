import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/providers/auth_provider.dart';
import 'package:nestmeal_app/providers/order_provider.dart';
import 'package:nestmeal_app/providers/slot_provider.dart';
import 'package:nestmeal_app/screens/cook/cook_reviews_screen.dart';
import 'package:nestmeal_app/screens/cook/cook_stories_screen.dart';
import 'package:nestmeal_app/screens/cook/slot_management_screen.dart';

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
    final cookId = authProvider.currentUser?.cookProfile?.id;
    final orderProvider = context.read<OrderProvider>();
    final slotProvider = context.read<SlotProvider>();
    try {
      await Future.wait([
        orderProvider.fetchCookStats(),
        if (cookId != null) slotProvider.fetchCookOwnPickupSlots(cookId),
      ]);
    } catch (_) {}
  }

  void _switchToTab(int index) {
    CookShellTabNotifier.of(context)?.switchTab(index);
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildEarningsCard(),
                const SizedBox(height: 16),
                _buildOrderStatsRow(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildUpcomingSlotsCard(),
                const SizedBox(height: 20),
                _buildReviewsSummary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
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
                    fontSize: 12,
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
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (cook != null) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 15, color: Colors.white),
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
                const SizedBox(height: 4),
                Text(
                  cook.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Earnings Card ─────────────────────────────────────────────────────────

  Widget _buildEarningsCard() {
    final stats = context.watch<OrderProvider>().cookStats;

    final todayRevenue =
        double.tryParse(stats?['today_revenue']?.toString() ?? '0') ?? 0.0;
    final totalRevenue =
        double.tryParse(stats?['total_revenue']?.toString() ?? '0') ?? 0.0;
    final todayOrders = stats?['today_orders'] ?? 0;
    final completedOrders = stats?['completed_orders'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up,
                    color: AppTheme.successGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Earnings',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _EarningsCell(
                  label: "Today's Earnings",
                  value: '\$${todayRevenue.toStringAsFixed(2)}',
                  sub: '$todayOrders orders today',
                  color: AppTheme.primaryOrange,
                ),
              ),
              Container(
                width: 1,
                height: 56,
                color: AppTheme.lightGrey,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _EarningsCell(
                  label: 'Total Earnings',
                  value: '\$${totalRevenue.toStringAsFixed(2)}',
                  sub: '$completedOrders completed',
                  color: AppTheme.successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Order Stats Row ───────────────────────────────────────────────────────

  Widget _buildOrderStatsRow() {
    final stats = context.watch<OrderProvider>().cookStats;
    final pending = stats?['pending_orders'] ?? 0;
    final total = stats?['total_orders'] ?? 0;
    final completed = stats?['completed_orders'] ?? 0;
    final cancelled = stats?['cancelled_orders'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _switchToTab(2),
            child: _StatCard(
              icon: Icons.pending_actions,
              iconColor: Colors.amber.shade700,
              label: 'Pending',
              value: '$pending',
              tappable: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _switchToTab(2),
            child: _StatCard(
              icon: Icons.receipt_long_outlined,
              iconColor: AppTheme.primaryOrange,
              label: 'Total',
              value: '$total',
              tappable: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline,
            iconColor: AppTheme.successGreen,
            label: 'Completed',
            value: '$completed',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.cancel_outlined,
            iconColor: AppTheme.errorRed,
            label: 'Cancelled',
            value: '$cancelled',
          ),
        ),
      ],
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.event_available_outlined,
                label: 'Manage Slots',
                subtitle: 'Pickup & delivery',
                color: Colors.teal,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SlotManagementScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.camera_alt_outlined,
                label: 'Stories',
                subtitle: 'Manage & post',
                color: Colors.purple,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CookStoriesScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.restaurant_menu_outlined,
                label: 'My Meals',
                subtitle: 'Add or edit meals',
                color: AppTheme.primaryOrange,
                onTap: () => _switchToTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                subtitle: 'View & manage',
                color: Colors.blue.shade600,
                onTap: () => _switchToTab(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Upcoming Slots ────────────────────────────────────────────────────────

  Widget _buildUpcomingSlotsCard() {
    final slots = context.watch<SlotProvider>().pickupSlots;
    final upcoming = slots
        .where((s) => s.status == 'open' || s.status == 'full')
        .take(3)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_available,
                        color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Upcoming Slots',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SlotManagementScreen()),
                ),
                child: const Text('Manage',
                    style: TextStyle(color: AppTheme.primaryOrange)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppTheme.greyText),
                  const SizedBox(width: 8),
                  Text(
                    'No open slots. Add slots so customers can order.',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.greyText),
                  ),
                ],
              ),
            )
          else
            ...upcoming.map((slot) {
              String formattedDate;
              try {
                formattedDate = DateFormat('EEE, MMM d')
                    .format(DateTime.parse(slot.date));
              } catch (_) {
                formattedDate = slot.date;
              }
              final start = slot.startTime.length >= 5
                  ? slot.startTime.substring(0, 5)
                  : slot.startTime;
              final end = slot.endTime.length >= 5
                  ? slot.endTime.substring(0, 5)
                  : slot.endTime;
              final isFull = slot.status == 'full';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.warmCream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.store_outlined,
                        size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$formattedDate  •  $start – $end',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${slot.bookedOrders}/${slot.maxOrders}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isFull
                            ? AppTheme.errorRed
                            : AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Reviews Summary ───────────────────────────────────────────────────────

  Widget _buildReviewsSummary() {
    final cook =
        context.watch<AuthProvider>().currentUser?.cookProfile;
    if (cook == null) return const SizedBox.shrink();

    final rating = cook.avgRating;
    final reviewCount = cook.totalReviews;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CookReviewsScreen()),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Reviews',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reviewCount > 0
                      ? '$reviewCount review${reviewCount == 1 ? '' : 's'}'
                      : 'No reviews yet',
                  style:
                      TextStyle(fontSize: 13, color: AppTheme.greyText),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating.floor()
                        ? Icons.star_rounded
                        : (i < rating && rating - i >= 0.5)
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios,
              size: 14, color: AppTheme.greyText),
        ],
      ),
    ),
    );
  }

}

// ── Supporting widgets ────────────────────────────────────────────────────

class _EarningsCell extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _EarningsCell({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: AppTheme.greyText)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(sub,
            style: TextStyle(fontSize: 11, color: AppTheme.greyText)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool tappable;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.tappable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: tappable
            ? Border.all(
                color: AppTheme.primaryOrange.withValues(alpha: 0.2))
            : null,
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppTheme.greyText),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (tappable) ...[
            const SizedBox(height: 4),
            Icon(Icons.arrow_forward_ios,
                size: 10, color: AppTheme.primaryOrange),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.greyText),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 12, color: AppTheme.greyText),
          ],
        ),
      ),
    );
  }
}

// ── InheritedWidget for tab switching ────────────────────────────────────────

class CookShellTabNotifier extends InheritedWidget {
  final void Function(int) switchTab;

  const CookShellTabNotifier({
    super.key,
    required this.switchTab,
    required super.child,
  });

  static CookShellTabNotifier? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CookShellTabNotifier>();
  }

  @override
  bool updateShouldNotify(CookShellTabNotifier oldWidget) => false;
}
