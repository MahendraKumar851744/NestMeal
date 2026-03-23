import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetail());
  }

  Future<void> _fetchDetail() async {
    try {
      await context.read<OrderProvider>().fetchOrderDetail(widget.orderId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order Details',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedOrder == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF97316)),
            );
          }

          if (provider.error != null && provider.selectedOrder == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load order details',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _fetchDetail,
                    child: const Text('Retry',
                        style: TextStyle(color: Color(0xFFF97316))),
                  ),
                ],
              ),
            );
          }

          final order = provider.selectedOrder;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return _buildContent(order);
        },
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number + status
          _buildHeader(order),
          const SizedBox(height: 24),

          // Status timeline
          _buildSectionTitle('Order Progress'),
          const SizedBox(height: 12),
          _buildStatusTimeline(order),
          const SizedBox(height: 24),

          // Pickup code
          if (order.status == 'ready_for_pickup' &&
              order.fulfillmentType == 'pickup')
            _buildPickupCode(order),

          // Order items
          _buildSectionTitle('Order Items'),
          const SizedBox(height: 12),
          _buildItemsList(order),
          const SizedBox(height: 24),

          // Price breakdown
          _buildSectionTitle('Price Breakdown'),
          const SizedBox(height: 12),
          _buildPriceBreakdown(order),
          const SizedBox(height: 24),

          // Cook info
          _buildSectionTitle('Cook'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.person, order.cookDisplayName),
          const SizedBox(height: 16),

          // Special instructions
          if (order.specialInstructions != null &&
              order.specialInstructions!.isNotEmpty) ...[
            _buildSectionTitle('Special Instructions'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.notes, order.specialInstructions!),
            const SizedBox(height: 16),
          ],

          // Delivery address
          if (order.fulfillmentType == 'delivery' &&
              order.deliveryStreet != null) ...[
            _buildSectionTitle('Delivery Address'),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on_outlined,
              [
                order.deliveryStreet,
                order.deliveryCity,
                order.deliveryState,
                order.deliveryZip,
              ].where((s) => s != null && s.isNotEmpty).join(', '),
            ),
            const SizedBox(height: 16),
          ],

          // Bottom actions
          _buildBottomActions(order),
        ],
      ),
    );
  }

  // ───────── Header ─────────

  Widget _buildHeader(OrderModel order) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            StatusBadge(status: order.status),
          ],
        ),
      ),
    );
  }

  // ───────── Status Timeline ─────────

  List<String> _stepsForOrder(OrderModel order) {
    if (order.fulfillmentType == 'delivery') {
      return [
        'placed',
        'accepted',
        'preparing',
        'ready_for_pickup',
        'out_for_delivery',
        'delivered',
        'completed',
      ];
    }
    return [
      'placed',
      'accepted',
      'preparing',
      'ready_for_pickup',
      'picked_up',
      'completed',
    ];
  }

  Widget _buildStatusTimeline(OrderModel order) {
    final steps = _stepsForOrder(order);
    final currentIndex = steps.indexOf(order.status);
    final isCancelledOrRejected =
        order.status == 'cancelled' || order.status == 'rejected';

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: [
            if (isCancelledOrRejected)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      order.status == 'cancelled'
                          ? 'Order Cancelled'
                          : 'Order Rejected',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ...List.generate(steps.length, (i) {
              final isCompleted = currentIndex >= 0 && i < currentIndex;
              final isCurrent = i == currentIndex;
              final isLast = i == steps.length - 1;

              Color circleColor;
              if (isCancelledOrRejected) {
                circleColor = Colors.grey.shade300;
              } else if (isCompleted) {
                circleColor = Colors.green;
              } else if (isCurrent) {
                circleColor = const Color(0xFFF97316);
              } else {
                circleColor = Colors.grey.shade300;
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: circleColor,
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : isCurrent
                                ? const Icon(Icons.circle,
                                    size: 10, color: Colors.white)
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _stepLabel(steps[i]),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: (isCompleted || isCurrent) &&
                                    !isCancelledOrRejected
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Center(
                            child: Container(
                              width: 2,
                              height: 28,
                              color: isCompleted && !isCancelledOrRejected
                                  ? Colors.green
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _stepLabel(String step) {
    return step
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  // ───────── Pickup Code ─────────

  Widget _buildPickupCode(OrderModel order) {
    // The pickup code is typically the last 6 chars of the order number
    final code = order.orderNumber.length >= 6
        ? order.orderNumber.substring(order.orderNumber.length - 6)
        : order.orderNumber;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFF97316), width: 2),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              const Icon(Icons.qr_code_2,
                  size: 36, color: Color(0xFFF97316)),
              const SizedBox(height: 12),
              Text(
                'Pickup Code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                code,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF97316),
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Show this code to your cook',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────── Order Items ─────────

  Widget _buildItemsList(OrderModel order) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
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
                        const SizedBox(height: 2),
                        Text(
                          '${item.quantity} x A\$${item.unitPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'A\$${item.lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ───────── Price Breakdown ─────────

  Widget _buildPriceBreakdown(OrderModel order) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _priceRow('Item Total', order.subtotal),
            _priceRow('Platform Fee', order.serviceFee),
            if (order.fulfillmentType == 'delivery')
              _priceRow('Delivery Fee', order.deliveryFee),
            if (order.discountAmount > 0)
              _priceRow('Discount', -order.discountAmount, isDiscount: true),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'A\$${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF97316),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            isDiscount
                ? '-A\$${amount.abs().toStringAsFixed(2)}'
                : 'A\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDiscount ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ───────── Info row helper ─────────

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // ───────── Section title ─────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  // ───────── Bottom Actions ─────────

  Widget _buildBottomActions(OrderModel order) {
    final canCancel =
        order.status == 'placed' || order.status == 'accepted';
    final canReview = order.status == 'completed';

    if (!canCancel && !canReview) return const SizedBox.shrink();

    return Column(
      children: [
        if (canCancel)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelDialog(order),
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text('Cancel Order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (canReview)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showReviewSheet(order),
              icon: const Icon(Icons.star_outline, color: Colors.white),
              label: const Text('Leave a Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
      ],
    );
  }

  // ───────── Cancel Dialog ─────────

  void _showCancelDialog(OrderModel order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancel Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for cancellation:'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('Back', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await context
                      .read<OrderProvider>()
                      .cancelOrder(order.id, reason);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order cancelled')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to cancel: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Confirm Cancel'),
            ),
          ],
        );
      },
    );
  }

  // ───────── Review Bottom Sheet ─────────

  void _showReviewSheet(OrderModel order) {
    double rating = 0;
    double deliveryRating = 0;
    final commentController = TextEditingController();
    final isDelivery = order.fulfillmentType == 'delivery';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'How was your meal?',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    RatingBar.builder(
                      initialRating: rating,
                      minRating: 1,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemSize: 40,
                      unratedColor: Colors.grey[300],
                      itemBuilder: (_, __) => const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF97316),
                      ),
                      onRatingUpdate: (val) {
                        setSheetState(() => rating = val);
                      },
                    ),
                    if (isDelivery) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Delivery experience',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      RatingBar.builder(
                        initialRating: deliveryRating,
                        minRating: 1,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemSize: 32,
                        unratedColor: Colors.grey[300],
                        itemBuilder: (_, __) => const Icon(
                          Icons.star_rounded,
                          color: Colors.blue,
                        ),
                        onRatingUpdate: (val) {
                          setSheetState(() => deliveryRating = val);
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Share your experience (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: rating < 1
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                try {
                                  final comment =
                                      commentController.text.trim();
                                  await context
                                      .read<ReviewProvider>()
                                      .createReview(
                                        order.id,
                                        rating.toInt(),
                                        deliveryRating:
                                            isDelivery && deliveryRating >= 1
                                                ? deliveryRating.toInt()
                                                : null,
                                        comment: comment.isNotEmpty
                                            ? comment
                                            : null,
                                      );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Review submitted. Thanks!'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to submit review: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Submit Review',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ───────── Helpers ─────────

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy  h:mm a').format(date.toLocal());
    } catch (_) {
      return dateStr;
    }
  }
}
