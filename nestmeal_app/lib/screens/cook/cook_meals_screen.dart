import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/models/helpers.dart';
import 'package:nestmeal_app/providers/auth_provider.dart';
import 'package:nestmeal_app/providers/meal_provider.dart';
import 'package:nestmeal_app/screens/cook/add_meal_screen.dart';
import 'package:nestmeal_app/screens/cook/edit_meal_screen.dart';

class CookMealsScreen extends StatefulWidget {
  const CookMealsScreen({super.key});

  @override
  State<CookMealsScreen> createState() => _CookMealsScreenState();
}

class _CookMealsScreenState extends State<CookMealsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMeals());
  }

  Future<void> _loadMeals() async {
    final cookId = context.read<AuthProvider>().currentUser?.cookProfile?.id;
    if (cookId == null) return;
    try {
      await context.read<MealProvider>().fetchMeals(cook: cookId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealProvider>();

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
        title: Text(
          'My Meals',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddMealScreen()),
                );
                _loadMeals();
              },
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                'Add New',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMeals,
        color: AppTheme.primaryOrange,
        child: mealProvider.isLoading && mealProvider.meals.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryOrange,
                ),
              )
            : mealProvider.meals.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: mealProvider.meals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildMealCard(mealProvider.meals[index]),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu, size: 72, color: AppTheme.greyText.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No meals yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first meal to start receiving orders',
            style: TextStyle(fontSize: 14, color: AppTheme.greyText),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddMealScreen()),
              );
              _loadMeals();
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Meal',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(meal) {
    final imageUrl = meal.images.isNotEmpty ? meal.images.first.imageUrl : null;

    return InkWell(
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => EditMealScreen(meal: meal)),
        );
        if (result == true) _loadMeals();
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _imagePlaceholder(),
                      errorWidget: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            const SizedBox(width: 12),
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
                      const SizedBox(width: 6),
                      _statusBadge(meal.isAvailable, meal.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        meal.mealType == 'veg'
                            ? Icons.eco
                            : meal.mealType == 'egg'
                                ? Icons.egg
                                : Icons.lunch_dining,
                        size: 13,
                        color: meal.mealType == 'veg'
                            ? AppTheme.successGreen
                            : meal.mealType == 'egg'
                                ? Colors.amber
                                : AppTheme.errorRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatLabel(meal.category),
                        style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                      ),
                      const Spacer(),
                      ...meal.fulfillmentModes.map((m) => Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: m == 'pickup'
                                    ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                                    : Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                m == 'pickup' ? 'Pickup' : 'Delivery',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: m == 'pickup'
                                      ? AppTheme.primaryOrange
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (meal.discountPercentage > 0) ...[
                        Text(
                          '${currencySymbol(meal.currency)}${meal.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '${currencySymbol(meal.currency)}${meal.effectivePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_outlined, size: 15, color: AppTheme.greyText),
                      const SizedBox(width: 3),
                      Text(
                        'Edit',
                        style: TextStyle(fontSize: 12, color: AppTheme.greyText),
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

  Widget _imagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.restaurant, size: 28, color: AppTheme.greyText),
    );
  }

  Widget _statusBadge(bool isAvailable, String status) {
    final Color color;
    final String label;
    if (status == 'draft') {
      color = AppTheme.greyText;
      label = 'Draft';
    } else if (!isAvailable) {
      color = AppTheme.errorRed;
      label = 'Unavailable';
    } else {
      color = AppTheme.successGreen;
      label = 'Active';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
}
