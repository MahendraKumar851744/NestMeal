import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/meal_model.dart';
import '../../models/helpers.dart';
import '../../providers/meal_provider.dart';
import '../../providers/cart_provider.dart';
import 'cook_profile_screen.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealId;

  const MealDetailScreen({super.key, required this.mealId});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealProvider>().fetchMealDetail(widget.mealId);
    });
  }

  void _addToCart(MealDetail meal) {
    final cart = context.read<CartProvider>();
    final imageUrl =
        meal.images.isNotEmpty ? meal.images.first.imageUrl : null;

    final added = cart.addItem(
      meal.id,
      meal.title,
      imageUrl,
      meal.effectivePrice,
      meal.cookId,
      meal.cookDisplayName,
    );

    if (!added) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace cart items?'),
          content: Text(
            'Your cart has items from ${cart.cookDisplayName}. '
            'Adding this meal will clear your current cart.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                cart.clearCart();
                cart.addItem(
                  meal.id,
                  meal.title,
                  imageUrl,
                  meal.effectivePrice,
                  meal.cookId,
                  meal.cookDisplayName,
                );
                Navigator.pop(ctx);
                _showAddedSnackbar();
              },
              child: const Text('Replace'),
            ),
          ],
        ),
      );
    } else {
      _showAddedSnackbar();
    }
  }

  void _showAddedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart'),
        backgroundColor: AppTheme.successGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatLabel(String tag) {
    return tag
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealProvider>();
    final meal = mealProvider.selectedMeal;

    if (mealProvider.isLoading && meal == null) {
      return Scaffold(
        backgroundColor: AppTheme.warmCream,
        appBar: AppBar(backgroundColor: AppTheme.warmCream, elevation: 0),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryOrange),
        ),
      );
    }

    if (meal == null) {
      return Scaffold(
        backgroundColor: AppTheme.warmCream,
        appBar: AppBar(backgroundColor: AppTheme.warmCream, elevation: 0),
        body: const Center(child: Text('Meal not found')),
      );
    }

    final imageUrl =
        meal.images.isNotEmpty ? meal.images.first.imageUrl : null;
    final cs = currencySymbol(meal.currency);

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppTheme.warmCream,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppTheme.lightGrey,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppTheme.lightGrey,
                                child: const Icon(Icons.restaurant,
                                    size: 60, color: AppTheme.greyText),
                              ),
                            )
                          : Container(
                              color: AppTheme.lightGrey,
                              child: const Icon(Icons.restaurant,
                                  size: 60, color: AppTheme.greyText),
                            ),
                      // Gradient overlay for readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Badges on image
                      Positioned(
                        bottom: 12,
                        left: 16,
                        child: Row(
                          children: [
                            // Veg/Non-veg indicator
                            _MealTypeBadge(mealType: meal.mealType),
                            if (meal.fulfillmentModes.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              ...meal.fulfillmentModes.map((mode) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: mode == 'pickup'
                                        ? AppTheme.primaryOrange
                                        : AppTheme.successGreen,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    mode == 'pickup' ? 'Pickup' : 'Delivery',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )),
                            ],
                          ],
                        ),
                      ),
                      // Discount badge
                      if (meal.discountPercentage > 0)
                        Positioned(
                          top: 80,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${meal.discountPercentage.toStringAsFixed(0)}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Title + Price ────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.title,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                if (meal.shortDescription.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    meal.shortDescription,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.greyText,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (meal.discountPercentage > 0)
                                Text(
                                  '$cs${meal.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.greyText,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                '$cs${meal.effectivePrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ─── Quick Info Strip ─────────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _InfoItem(
                              icon: Icons.star,
                              iconColor: AppTheme.primaryOrange,
                              label: meal.avgRating > 0
                                  ? meal.avgRating.toStringAsFixed(1)
                                  : 'New',
                              sublabel: '${meal.totalOrders} orders',
                            ),
                            _divider(),
                            _InfoItem(
                              icon: Icons.timer_outlined,
                              iconColor: AppTheme.greyText,
                              label: '${meal.preparationTimeMins} min',
                              sublabel: 'Prep time',
                            ),
                            _divider(),
                            _InfoItem(
                              icon: Icons.local_fire_department_outlined,
                              iconColor: AppTheme.greyText,
                              label: meal.caloriesApprox != null
                                  ? '${meal.caloriesApprox} cal'
                                  : '--',
                              sublabel: 'Calories',
                            ),
                            if (meal.servingSize.isNotEmpty) ...[
                              _divider(),
                              _InfoItem(
                                icon: Icons.restaurant_outlined,
                                iconColor: AppTheme.greyText,
                                label: meal.servingSize,
                                sublabel: 'Serving',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ─── Meal Details Chips ───────────────────────
                      _buildChipRow(meal),
                      const SizedBox(height: 20),

                      // ─── About This Dish ──────────────────────────
                      if (meal.description.isNotEmpty ||
                          meal.shortDescription.isNotEmpty) ...[
                        _sectionTitle('About This Dish'),
                        const SizedBox(height: 8),
                        Text(
                          meal.description.isNotEmpty
                              ? meal.description
                              : meal.shortDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppTheme.greyText,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ─── Available Days ───────────────────────────
                      if (meal.availableDays.isNotEmpty) ...[
                        _sectionTitle('Available On'),
                        const SizedBox(height: 10),
                        _buildAvailableDays(meal.availableDays),
                        const SizedBox(height: 20),
                      ],

                      // ─── Dietary Tags ─────────────────────────────
                      if (meal.dietaryTags.isNotEmpty) ...[
                        _sectionTitle('Dietary Info'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: meal.dietaryTags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: AppTheme.primaryOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatLabel(tag),
                                    style: const TextStyle(
                                      color: AppTheme.primaryOrange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ─── Tags ─────────────────────────────────────
                      if (meal.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: meal.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.lightGrey,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '#${tag.replaceAll('_', ' ')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.greyText,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ─── Allergen Warning ─────────────────────────
                      if (meal.allergenInfo.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.errorRed.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppTheme.errorRed,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Allergen Warning',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.errorRed,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: meal.allergenInfo.map((allergen) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRed
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      _formatLabel(allergen),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.errorRed
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ─── Your Cook ────────────────────────────────
                      _sectionTitle('Your Cook'),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CookProfileScreen(
                                cookId: meal.cookId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.primaryOrange
                                    .withValues(alpha: 0.15),
                                child: Text(
                                  meal.cookCard.displayName.isNotEmpty
                                      ? meal.cookCard.displayName[0]
                                          .toUpperCase()
                                      : 'C',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            meal.cookCard.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (meal.cookCard.status == 'approved')
                                          const Padding(
                                            padding: EdgeInsets.only(left: 6),
                                            child: Icon(
                                              Icons.verified,
                                              size: 18,
                                              color: AppTheme.primaryOrange,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            size: 14,
                                            color: AppTheme.primaryOrange),
                                        const SizedBox(width: 2),
                                        Text(
                                          meal.cookCard.avgRating
                                              .toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${meal.cookCard.totalReviews} reviews)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.greyText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (meal.cookCard.kitchenCity.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined,
                                              size: 13, color: AppTheme.greyText),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${meal.cookCard.kitchenCity}, ${meal.cookCard.kitchenState}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.greyText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppTheme.greyText,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom padding for sticky button
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky bottom button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: meal.isAvailable ? () => _addToCart(meal) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.lightGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    meal.isAvailable
                        ? 'Add to Cart  \u00B7  $cs${meal.effectivePrice.toStringAsFixed(2)}'
                        : 'Currently Unavailable',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper Widgets ─────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.darkText,
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: AppTheme.lightGrey,
    );
  }

  Widget _buildChipRow(MealDetail meal) {
    final chips = <Widget>[];

    // Cuisine type
    if (meal.cuisineType.isNotEmpty) {
      chips.add(_DetailChip(
        icon: Icons.public,
        label: _formatLabel(meal.cuisineType),
      ));
    }

    // Category
    if (meal.category.isNotEmpty) {
      chips.add(_DetailChip(
        icon: Icons.category_outlined,
        label: _formatLabel(meal.category),
      ));
    }

    // Spice level
    if (meal.spiceLevel.isNotEmpty) {
      chips.add(_DetailChip(
        icon: Icons.whatshot_outlined,
        label: _formatLabel(meal.spiceLevel),
        color: meal.spiceLevel == 'extra_spicy' || meal.spiceLevel == 'spicy'
            ? Colors.red.shade400
            : null,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildAvailableDays(List<String> days) {
    const allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final activeDays = days.map((d) => d.toLowerCase()).toSet();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final isActive = activeDays.contains(allDays[i]);
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryOrange.withValues(alpha: 0.15)
                : AppTheme.lightGrey.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppTheme.primaryOrange : AppTheme.greyText,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;

  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.greyText,
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _DetailChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.greyText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTypeBadge extends StatelessWidget {
  final String mealType;

  const _MealTypeBadge({required this.mealType});

  @override
  Widget build(BuildContext context) {
    final isVeg = mealType == 'veg';
    final isEgg = mealType == 'egg';
    final color = isVeg
        ? Colors.green.shade600
        : isEgg
            ? Colors.amber.shade700
            : Colors.red.shade600;
    final label = isVeg
        ? 'Veg'
        : isEgg
            ? 'Egg'
            : 'Non-Veg';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
