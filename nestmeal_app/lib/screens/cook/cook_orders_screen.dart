import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/models/order_model.dart';
import 'package:nestmeal_app/providers/order_provider.dart';
import 'package:nestmeal_app/widgets/status_badge.dart';
import 'cook_order_detail_screen.dart';

class CookOrdersScreen extends StatefulWidget {
  const CookOrdersScreen({super.key});

  @override
  State<CookOrdersScreen> createState() => _CookOrdersScreenState();
}

class _CookOrdersScreenState extends State<CookOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _activeStatuses = [
    'placed',
    'accepted',
    'preparing',
    'ready_for_pickup',
    'picked_up',
    'out_for_delivery',
    'delivered',
  ];
  static const _historyStatuses = ['completed', 'cancelled', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      await context.read<OrderProvider>().fetchOrders();
    } catch (_) {}
  }

  List<OrderListItem> _filtered(
      List<OrderListItem> orders, List<String> statuses) {
    return orders.where((o) => statuses.contains(o.status)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
        title: Text(
          'Orders',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor: AppTheme.greyText,
          indicatorColor: AppTheme.primaryOrange,
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.orders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryOrange),
            );
          }

          final active = _filtered(provider.orders, _activeStatuses);
          final history = _filtered(provider.orders, _historyStatuses);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(active, provider, isActive: true),
              _buildList(history, provider, isActive: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
      List<OrderListItem> orders, OrderProvider provider,
      {required bool isActive}) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        color: AppTheme.primaryOrange,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive
                        ? Icons.receipt_long_outlined
                        : Icons.history,
                    size: 64,
                    color: AppTheme.greyText.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isActive ? 'No active orders' : 'No order history',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.greyText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isActive
                        ? 'New orders will appear here'
                        : 'Completed and cancelled orders will appear here',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.greyText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppTheme.primaryOrange,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _OrderCard(
          order: orders[i],
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    CookOrderDetailScreen(orderId: orders[i].id),
              ),
            );
            _loadOrders();
          },
        ),
      ),
    );
  }
}

// ─── Order Card ──────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderListItem order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPickup = order.fulfillmentType == 'pickup';
    final isNew = order.status == 'placed';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isNew
              ? Border.all(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.5),
                  width: 1.5)
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Order number + new badge
                if (isNew)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Text(
                  '#${order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Fulfillment type
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isPickup
                          ? AppTheme.primaryOrange.withValues(alpha: 0.5)
                          : Colors.blue.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPickup
                            ? Icons.store_outlined
                            : Icons.delivery_dining_outlined,
                        size: 13,
                        color: isPickup
                            ? AppTheme.primaryOrange
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPickup ? 'Pickup' : 'Delivery',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPickup
                              ? AppTheme.primaryOrange
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Time
                Icon(Icons.access_time,
                    size: 13, color: AppTheme.greyText),
                const SizedBox(width: 4),
                _TimeAgo(createdAt: order.createdAt),
                const Spacer(),
                // Amount
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
            // Acceptance countdown for placed orders
            if (order.status == 'placed') ...[
              const SizedBox(height: 8),
              const _NewOrderPrompt(),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Smart time display ───────────────────────────────────────────────────────

class _TimeAgo extends StatefulWidget {
  final String createdAt;
  const _TimeAgo({required this.createdAt});

  @override
  State<_TimeAgo> createState() => _TimeAgoState();
}

class _TimeAgoState extends State<_TimeAgo> {
  late DateTime _createdAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    try {
      _createdAt = DateTime.parse(widget.createdAt).toLocal();
    } catch (_) {
      _createdAt = DateTime.now();
    }
    // Refresh every minute while within the "X mins ago" window
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format() {
    final diff = DateTime.now().difference(_createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(_createdAt);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(),
      style: TextStyle(fontSize: 12, color: AppTheme.greyText),
    );
  }
}

// ─── Prompt shown on new "placed" orders ─────────────────────────────────────

class _NewOrderPrompt extends StatelessWidget {
  const _NewOrderPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_outlined,
              size: 14, color: AppTheme.primaryOrange),
          const SizedBox(width: 6),
          Text(
            'Tap to accept or reject',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}
