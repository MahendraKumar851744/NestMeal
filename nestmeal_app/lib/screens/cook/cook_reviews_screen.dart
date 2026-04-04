import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/models/review_model.dart';
import 'package:nestmeal_app/providers/auth_provider.dart';
import 'package:nestmeal_app/providers/review_provider.dart';

class CookReviewsScreen extends StatefulWidget {
  const CookReviewsScreen({super.key});

  @override
  State<CookReviewsScreen> createState() => _CookReviewsScreenState();
}

class _CookReviewsScreenState extends State<CookReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final cookId = context
        .read<AuthProvider>()
        .currentUser
        ?.cookProfile
        ?.id
        ?.toString();
    if (cookId == null) return;
    try {
      await context.read<ReviewProvider>().fetchReviews(cookId: cookId);
    } catch (_) {}
  }

  Future<void> _showReplyDialog(ReviewModel review) async {
    final controller =
        TextEditingController(text: review.cookReply ?? '');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          review.cookReply != null ? 'Edit Reply' : 'Reply to Review',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLength: 300,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Write your reply...',
              hintStyle:
                  const TextStyle(color: AppTheme.greyText, fontSize: 14),
              filled: true,
              fillColor: AppTheme.warmCream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Reply cannot be empty' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.greyText)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Post Reply',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context
          .read<ReviewProvider>()
          .replyToReview(review.id, controller.text.trim());
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply posted.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post reply: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
        title: Text(
          'Customer Reviews',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.reviews.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryOrange),
            );
          }

          if (provider.reviews.isEmpty) {
            return _buildEmptyState();
          }

          // Summary bar
          final avg = provider.reviews.isEmpty
              ? 0.0
              : provider.reviews
                      .map((r) => r.rating)
                      .reduce((a, b) => a + b) /
                  provider.reviews.length;

          final repliedCount =
              provider.reviews.where((r) => r.cookReply != null).length;
          final pendingCount =
              provider.reviews.length - repliedCount;

          return RefreshIndicator(
            onRefresh: _load,
            color: AppTheme.primaryOrange,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _buildSummaryCard(
                    avg, provider.reviews.length, pendingCount),
                const SizedBox(height: 16),
                ...provider.reviews.map((r) => _ReviewCard(
                      review: r,
                      onReply: () => _showReplyDialog(r),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(double avg, int total, int pending) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Avg rating big display
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avg.floor()
                        ? Icons.star_rounded
                        : (i < avg && avg - i >= 0.5)
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$total ${total == 1 ? 'review' : 'reviews'}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.greyText),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Container(width: 1, height: 64, color: AppTheme.lightGrey),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow(
                  Icons.check_circle_outline,
                  AppTheme.successGreen,
                  '${total - pending} replied',
                ),
                const SizedBox(height: 8),
                _summaryRow(
                  Icons.pending_outlined,
                  Colors.amber.shade700,
                  pending > 0
                      ? '$pending awaiting reply'
                      : 'All replied',
                  highlight: pending > 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, Color color, String label,
      {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                highlight ? FontWeight.w700 : FontWeight.normal,
            color: highlight ? color : AppTheme.darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline_rounded,
              size: 72,
              color: AppTheme.greyText.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Customer reviews will appear here after\ncompleted orders.',
            style: TextStyle(fontSize: 14, color: AppTheme.greyText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Review Card ──────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onReply;

  const _ReviewCard({required this.review, required this.onReply});

  @override
  Widget build(BuildContext context) {
    String dateStr;
    try {
      dateStr = DateFormat('MMM d, yyyy')
          .format(DateTime.parse(review.createdAt).toLocal());
    } catch (_) {
      dateStr = review.createdAt;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      AppTheme.primaryOrange.withValues(alpha: 0.15),
                  child: Text(
                    review.customerName.isNotEmpty
                        ? review.customerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
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
                        review.customerName.isNotEmpty
                            ? review.customerName
                            : 'Customer',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.greyText),
                      ),
                    ],
                  ),
                ),
                // Star rating
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            // Meal title
            if (review.mealTitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.lunch_dining_outlined,
                      size: 13, color: AppTheme.greyText),
                  const SizedBox(width: 4),
                  Text(
                    review.mealTitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.greyText),
                  ),
                ],
              ),
            ],
            // Comment
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                review.comment,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.darkText, height: 1.4),
              ),
            ],
            // Delivery rating
            if (review.deliveryRating != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.delivery_dining_outlined,
                      size: 13, color: AppTheme.greyText),
                  const SizedBox(width: 4),
                  Text(
                    'Delivery: ${review.deliveryRating}/5',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.greyText),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.lightGrey),
            const SizedBox(height: 10),
            // Cook reply section
            if (review.cookReply != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply,
                            size: 14, color: AppTheme.primaryOrange),
                        const SizedBox(width: 6),
                        const Text(
                          'Your reply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                        const Spacer(),
                        if (review.cookRepliedAt != null)
                          Text(
                            _formatReplyDate(review.cookRepliedAt!),
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.greyText),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.cookReply!,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.darkText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onReply,
                  icon: const Icon(Icons.edit_outlined,
                      size: 14, color: AppTheme.greyText),
                  label: const Text(
                    'Edit Reply',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.greyText),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.reply_outlined,
                      size: 14, color: AppTheme.greyText),
                  const SizedBox(width: 6),
                  const Text(
                    'No reply yet',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.greyText),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: onReply,
                    icon: const Icon(Icons.reply,
                        size: 14, color: Colors.white),
                    label: const Text(
                      'Reply',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatReplyDate(String dateStr) {
    try {
      return DateFormat('MMM d, yyyy')
          .format(DateTime.parse(dateStr).toLocal());
    } catch (_) {
      return '';
    }
  }
}
