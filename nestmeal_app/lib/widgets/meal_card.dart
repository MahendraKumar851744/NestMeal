import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:nestmeal_app/config/theme.dart';

class MealCard extends StatelessWidget {
  final String id;
  final String title;
  final String? imageUrl;
  final String cookName;
  final double price;
  final double? effectivePrice;
  final double rating;
  final List<String> fulfillmentModes;
  final bool isAvailable;
  final double? width;
  final int? slotsRemaining;
  final String? shortDescription;
  final String? mealType;

  const MealCard({
    super.key,
    required this.id,
    required this.title,
    this.imageUrl,
    required this.cookName,
    required this.price,
    this.effectivePrice,
    required this.rating,
    this.fulfillmentModes = const [],
    this.isAvailable = true,
    this.width,
    this.slotsRemaining,
    this.shortDescription,
    this.mealType,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        effectivePrice != null && effectivePrice! < price;
    final displayPrice = effectivePrice ?? price;

    return GestureDetector(
      onTap: () {
        // Navigate to MealDetailScreen with meal id
        // Navigator.of(context).push(MaterialPageRoute(
        //   builder: (_) => MealDetailScreen(mealId: id),
        // ));
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 140,
                            color: AppTheme.lightGrey,
                            child: const Center(
                              child: Icon(Icons.restaurant, size: 32),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 140,
                            color: AppTheme.lightGrey,
                            child: const Center(
                              child: Icon(Icons.restaurant, size: 32),
                            ),
                          ),
                        )
                      : Container(
                          height: 140,
                          width: double.infinity,
                          color: AppTheme.lightGrey,
                          child: Icon(
                            Icons.restaurant,
                            size: 40,
                            color: AppTheme.greyText,
                          ),
                        ),
                ),

                // Fulfillment badges
                if (fulfillmentModes.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Row(
                      children: fulfillmentModes.map((mode) {
                        final isPickup = mode == 'pickup';
                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPickup
                                ? AppTheme.primaryOrange
                                : AppTheme.successGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPickup ? 'Pickup' : 'Delivery',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Slots remaining badge
                if (slotsRemaining != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$slotsRemaining',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Unavailable overlay
                if (!isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Unavailable',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with veg/non-veg
                  Row(
                    children: [
                      if (mealType != null) ...[
                        _VegDot(mealType: mealType!),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Cook name
                  Text(
                    cookName,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.greyText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Short description
                  if (shortDescription != null && shortDescription!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      shortDescription!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.greyText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Rating, distance, price row
                  Row(
                    children: [
                      // Rating
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 2),
                      Text(
                        rating > 0 ? rating.toStringAsFixed(1) : 'New',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Distance placeholder
                      Icon(Icons.location_on,
                          size: 14, color: AppTheme.greyText),
                      const SizedBox(width: 2),
                      Text(
                        '-- km',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                        ),
                      ),

                      const Spacer(),

                      // Price
                      if (hasDiscount) ...[
                        Text(
                          'A\$${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        'A\$${displayPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VegDot extends StatelessWidget {
  final String mealType;
  const _VegDot({required this.mealType});

  @override
  Widget build(BuildContext context) {
    final isVeg = mealType == 'veg';
    final isEgg = mealType == 'egg';
    final color = isVeg
        ? Colors.green.shade600
        : isEgg
            ? Colors.amber.shade700
            : Colors.red.shade600;

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
