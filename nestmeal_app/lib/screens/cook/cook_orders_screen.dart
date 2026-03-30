import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/providers/order_provider.dart';
import 'package:nestmeal_app/widgets/status_badge.dart';

class CookOrdersScreen extends StatefulWidget {
  const CookOrdersScreen({super.key});

  @override
  State<CookOrdersScreen> createState() => _CookOrdersScreenState();
}

class _CookOrdersScreenState extends State<CookOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future<void> _loadOrders() async {
    try {
      await context.read<OrderProvider>().fetchOrders();
    } catch (_) {}
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await context.read<OrderProvider>().updateOrderStatus(orderId, newStatus);
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _showPickupVerificationDialog(String orderId) async {
    final codeController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Pickup'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Pickup Code',
            hintText: 'Enter the customer\'s pickup code',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, codeController.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await context.read<OrderProvider>().verifyPickup(orderId, result);
        await _loadOrders();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pickup verified successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        title: Text(
          'Order Management',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: _loadOrders,
        child: orderProvider.isLoading && orderProvider.orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : orderProvider.orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64, color: AppTheme.greyText),
                        const SizedBox(height: 16),
                        Text(
                          'No orders yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orderProvider.orders.length,
                    itemBuilder: (context, index) {
                      final order = orderProvider.orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final status = order.status;
    final isActiveOrder = [
      'placed',
      'accepted',
      'preparing',
      'ready_for_pickup',
      'picked_up',
      'out_for_delivery',
      'delivered',
    ].contains(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.orderNumber}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 8),

          // Order details
          Row(
            children: [
              Icon(Icons.restaurant, size: 16, color: AppTheme.greyText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.cookDisplayName,
                  style: TextStyle(fontSize: 13, color: AppTheme.greyText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'A\$${order.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                order.fulfillmentType == 'pickup'
                    ? Icons.store_outlined
                    : Icons.delivery_dining,
                size: 16,
                color: AppTheme.greyText,
              ),
              const SizedBox(width: 6),
              Text(
                order.fulfillmentType == 'pickup' ? 'Pickup' : 'Delivery',
                style: TextStyle(fontSize: 13, color: AppTheme.greyText),
              ),
            ],
          ),

          // Acceptance deadline countdown for placed orders
          if (status == 'placed' && order.acceptanceDeadline != null) ...[
            const SizedBox(height: 8),
            _AcceptanceCountdown(deadline: order.acceptanceDeadline!),
          ],

          // Action buttons for active orders
          if (isActiveOrder) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildActionButtons(order.id, status, order.fulfillmentType),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      String orderId, String status, String fulfillmentType) {
    switch (status) {
      case 'placed':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateStatus(orderId, 'preparing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Accept & Start Preparing'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _updateStatus(orderId, 'rejected'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Reject'),
              ),
            ),
          ],
        );

      case 'accepted':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateStatus(orderId, 'preparing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Mark Preparing'),
          ),
        );

      case 'preparing':
        if (fulfillmentType == 'delivery') {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateStatus(orderId, 'out_for_delivery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Out for Delivery'),
            ),
          );
        } else {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateStatus(orderId, 'ready_for_pickup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Mark Ready for Pickup'),
            ),
          );
        }

      case 'ready_for_pickup':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showPickupVerificationDialog(orderId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Verify Pickup'),
          ),
        );

      case 'out_for_delivery':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateStatus(orderId, 'delivered'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Mark Delivered'),
          ),
        );

      case 'picked_up':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateStatus(orderId, 'completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Mark Completed'),
          ),
        );

      case 'delivered':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateStatus(orderId, 'completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Mark Completed'),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _AcceptanceCountdown extends StatefulWidget {
  final String deadline;
  const _AcceptanceCountdown({required this.deadline});

  @override
  State<_AcceptanceCountdown> createState() => _AcceptanceCountdownState();
}

class _AcceptanceCountdownState extends State<_AcceptanceCountdown> {
  late DateTime _deadline;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _deadline = DateTime.parse(widget.deadline).toLocal();
    _remaining = _deadline.difference(DateTime.now());
    _tick();
  }

  void _tick() {
    if (!mounted) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _remaining = _deadline.difference(DateTime.now());
      });
      if (_remaining.inSeconds > 0) _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining.inSeconds <= 0;
    final mins = _remaining.inMinutes;
    final secs = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isExpired
            ? AppTheme.errorRed.withValues(alpha: 0.1)
            : AppTheme.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: isExpired ? AppTheme.errorRed : AppTheme.primaryOrange,
          ),
          const SizedBox(width: 6),
          Text(
            isExpired
                ? 'Acceptance window expired'
                : 'Accept within ${mins}m ${secs.toString().padLeft(2, '0')}s',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isExpired ? AppTheme.errorRed : AppTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}
