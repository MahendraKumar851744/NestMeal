import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/providers/order_provider.dart';
import 'package:nestmeal_app/screens/shared/order_chat_screen.dart';
import 'package:nestmeal_app/widgets/status_badge.dart';

class CookOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const CookOrderDetailScreen({super.key, required this.orderId});

  @override
  State<CookOrderDetailScreen> createState() => _CookOrderDetailScreenState();
}

class _CookOrderDetailScreenState extends State<CookOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      await context.read<OrderProvider>().fetchOrderDetail(widget.orderId);
    } catch (_) {}
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await context
          .read<OrderProvider>()
          .updateOrderStatus(widget.orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order status updated'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _showPickupVerificationDialog() async {
    final codeController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verify Pickup Code'),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Customer Pickup Code',
            hintText: 'Enter the 4-digit code',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.greyText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, codeController.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      try {
        await context
            .read<OrderProvider>()
            .verifyPickup(widget.orderId, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pickup verified!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    if (orderProvider.isLoading && orderProvider.selectedOrder == null) {
      return Scaffold(
        backgroundColor: AppTheme.warmCream,
        appBar: AppBar(backgroundColor: AppTheme.warmCream, elevation: 0),
        body: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
      );
    }

    final order = orderProvider.selectedOrder;
    if (order == null || order.id != widget.orderId) {
      return Scaffold(
        backgroundColor: AppTheme.warmCream,
        appBar: AppBar(backgroundColor: AppTheme.warmCream, elevation: 0),
        body: const Center(child: Text('Order not found')),
      );
    }

    final isActive = ![
      'completed',
      'cancelled',
      'rejected',
    ].contains(order.status);

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
        title: Text(
          '#${order.orderNumber}',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined, color: AppTheme.primaryOrange),
            tooltip: 'Chat with customer',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderChatScreen(
                  orderId: order.id,
                  orderNumber: order.orderNumber,
                  isOrderClosed: ['completed', 'cancelled', 'rejected']
                      .contains(order.status),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusBadge(status: order.status),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderMeta(order),
            const SizedBox(height: 16),
            _buildCustomerAndFulfillment(order),
            const SizedBox(height: 16),
            _buildItemsList(order),
            if (order.specialInstructions != null &&
                order.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSpecialInstructions(order.specialInstructions!),
            ],
            const SizedBox(height: 16),
            _buildPriceBreakdown(order),
          ],
        ),
      ),
      bottomNavigationBar: isActive
          ? _buildActionBar(order.status, order.fulfillmentType)
          : null,
    );
  }

  // ── Order meta ────────────────────────────────────────────────────────────

  Widget _buildOrderMeta(order) {
    String timeStr;
    try {
      final dt = DateTime.parse(order.createdAt).toLocal();
      timeStr = DateFormat('EEE, MMM d · h:mm a').format(dt);
    } catch (_) {
      timeStr = order.createdAt;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_outlined,
                color: AppTheme.primaryOrange, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 13, color: AppTheme.greyText),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.greyText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Customer + Fulfillment ────────────────────────────────────────────────

  Widget _buildCustomerAndFulfillment(order) {
    final isPickup = order.fulfillmentType == 'pickup';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.person_outline,
            label: 'Customer',
            value: order.customerName,
          ),
          const Divider(height: 20),
          _infoRow(
            icon: isPickup
                ? Icons.store_outlined
                : Icons.delivery_dining_outlined,
            label: 'Fulfillment',
            value: isPickup ? 'Pickup' : 'Delivery',
            valueColor: isPickup
                ? AppTheme.primaryOrange
                : Colors.blue.shade700,
          ),
          if (!isPickup && order.deliveryStreet != null &&
              order.deliveryStreet!.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: [
                order.deliveryStreet,
                order.deliveryCity,
                order.deliveryState,
              ].where((s) => s != null && s.isNotEmpty).join(', '),
            ),
          ],
          if (isPickup && order.pickupCode != null) ...[
            const Divider(height: 20),
            _infoRow(
              icon: Icons.pin_outlined,
              label: 'Pickup Code',
              value: order.pickupCode!,
              valueColor: AppTheme.primaryOrange,
              bold: true,
            ),
          ],
          if (order.paymentStatus.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow(
              icon: Icons.payment_outlined,
              label: 'Payment',
              value: order.paymentStatus == 'paid' ? 'Paid' : 'Pending',
              valueColor: order.paymentStatus == 'paid'
                  ? AppTheme.successGreen
                  : AppTheme.errorRed,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.greyText),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppTheme.greyText),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? AppTheme.darkText,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  // ── Items List ────────────────────────────────────────────────────────────

  Widget _buildItemsList(order) {
    final items = order.items as List;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_outlined,
                  size: 18, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              Text(
                'Order Items',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} item${items.length == 1 ? '' : 's'}',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.greyText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            return Column(
              children: [
                if (i > 0) const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '×${item.quantity}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.mealTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '\$${item.unitPrice.toStringAsFixed(2)} each',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.greyText),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${item.lineTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Special Instructions ──────────────────────────────────────────────────

  Widget _buildSpecialInstructions(String instructions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sticky_note_2_outlined,
                  size: 18, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Text(
                'Special Instructions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            instructions,
            style: TextStyle(
                fontSize: 13, color: Colors.amber.shade900, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── Price Breakdown ───────────────────────────────────────────────────────

  Widget _buildPriceBreakdown(order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 18, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              Text(
                'Bill Summary',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _priceRow('Subtotal', order.subtotal),
          const SizedBox(height: 6),
          _priceRow('Service fee', order.serviceFee),
          const SizedBox(height: 6),
          _priceRow('Tax', order.taxAmount),
          if (order.deliveryFee > 0) ...[
            const SizedBox(height: 6),
            _priceRow('Delivery fee', order.deliveryFee),
          ],
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 6),
            _priceRow('Discount', -order.discountAmount,
                isDiscount: true),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '\$${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: AppTheme.greyText)),
        Text(
          isDiscount
              ? '-\$${amount.abs().toStringAsFixed(2)}'
              : '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppTheme.successGreen : AppTheme.darkText,
          ),
        ),
      ],
    );
  }

  // ── Action Bar ────────────────────────────────────────────────────────────

  Widget _buildActionBar(String status, String fulfillmentType) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _buildButtons(status, fulfillmentType),
    );
  }

  Widget _buildButtons(String status, String fulfillmentType) {
    switch (status) {
      case 'placed':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateStatus('preparing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Accept & Start Preparing',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _updateStatus('rejected'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Reject Order',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );

      case 'accepted':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateStatus('preparing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Start Preparing',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        );

      case 'preparing':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateStatus(
              fulfillmentType == 'delivery'
                  ? 'out_for_delivery'
                  : 'ready_for_pickup',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: fulfillmentType == 'delivery'
                  ? Colors.indigo
                  : AppTheme.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              fulfillmentType == 'delivery'
                  ? 'Mark Out for Delivery'
                  : 'Mark Ready for Pickup',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        );

      case 'ready_for_pickup':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showPickupVerificationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 20),
                SizedBox(width: 8),
                Text('Verify Pickup Code',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );

      case 'out_for_delivery':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateStatus('delivered'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Mark Delivered',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        );

      case 'delivered':
      case 'picked_up':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateStatus('completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Mark Completed',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
