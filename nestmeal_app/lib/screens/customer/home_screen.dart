import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/meal_model.dart';
import '../../models/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../models/story_model.dart';
import '../../providers/story_provider.dart';
import '../../providers/cook_provider.dart';
import 'meal_detail_screen.dart';
import 'search_screen.dart';
import 'story_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadData();
    }
  }

  String _getTodayDayCode() {
    const dayCodes = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return dayCodes[DateTime.now().weekday - 1];
  }

  Future<void> _loadData() async {
    final mealProvider = context.read<MealProvider>();
    final storyProvider = context.read<StoryProvider>();
    final cookProvider = context.read<CookProvider>();
    final today = _getTodayDayCode();
    try {
      await Future.wait([
        mealProvider.fetchMeals(availableDays: today),
        mealProvider.fetchFeaturedMeals(),
        storyProvider.fetchStoryFeed(),
        cookProvider.fetchFollowing(),
      ]);
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getMealTimeQuestion() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "What's for breakfast?";
    if (hour < 17) return "What's for lunch?";
    return "What's for dinner?";
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final mealProvider = context.watch<MealProvider>();
    final storyProvider = context.watch<StoryProvider>();
    // firstName used in greeting if needed


    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App bar area
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting + Avatar row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()} \u{1F37D}',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getMealTimeQuestion(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.greyText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.15),
                            child: Text(
                              (authProvider.currentUser?.fullName ?? 'U')[0].toUpperCase(),
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Search bar
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SearchScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.lightGrey),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: AppTheme.greyText),
                              SizedBox(width: 12),
                              Text(
                                'Search meals, cooks, cuisines...',
                                style: TextStyle(
                                  color: AppTheme.greyText,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Category chips
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _CategoryChip(
                              label: 'Vegetarian',
                              icon: Icons.eco_outlined,
                              onTap: () => _navigateToSearch('vegetarian'),
                            ),
                            _CategoryChip(
                              label: 'Non-Veg',
                              icon: Icons.restaurant_outlined,
                              onTap: () => _navigateToSearch('non_vegetarian'),
                            ),
                            _CategoryChip(
                              label: 'Breakfast',
                              icon: Icons.free_breakfast_outlined,
                              onTap: () => _navigateToSearchByType('breakfast'),
                            ),
                            _CategoryChip(
                              label: 'Dinner',
                              icon: Icons.dinner_dining_outlined,
                              onTap: () => _navigateToSearchByType('dinner'),
                            ),
                            _CategoryChip(
                              label: 'Nearby',
                              icon: Icons.near_me_outlined,
                              onTap: () => _navigateToSearch(null),
                            ),
                            _CategoryChip(
                              label: 'Top Rated',
                              icon: Icons.star_outline,
                              onTap: () => _navigateToSearchTopRated(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Stories bar
            if (storyProvider.storyFeed.isNotEmpty)
              SliverToBoxAdapter(
                child: _StoryBar(storyGroups: storyProvider.storyFeed),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Today's Fresh Meals
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: "Today's Fresh Meals Near You",
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (mealProvider.isLoading && mealProvider.meals.isEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 280,
                  child: _buildShimmerList(),
                ),
              )
            else if (mealProvider.meals.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No meals available right now',
                      style: TextStyle(color: AppTheme.greyText),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _MealCard(meal: mealProvider.meals[index]);
                    },
                    childCount: mealProvider.meals.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Trending Section
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Trending',
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
              ),
            ),
            if (mealProvider.isLoading && mealProvider.meals.isEmpty)
              SliverToBoxAdapter(child: _buildTrendingShimmer())
            else if (mealProvider.meals.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No trending meals yet',
                      style: TextStyle(color: AppTheme.greyText),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final meal = mealProvider.meals[index];
                    return _TrendingMealRow(meal: meal);
                  },
                  childCount: mealProvider.meals.length.clamp(0, 5),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _navigateToSearch(String? category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialCategory: category),
      ),
    );
  }

  void _navigateToSearchByType(String mealType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialMealType: mealType),
      ),
    );
  }

  void _navigateToSearchTopRated() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchScreen(initialSort: '-avg_rating'),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 200,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendingShimmer() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Story Bar ──────────────────────────────────────────────────────────────

class _StoryBar extends StatelessWidget {
  final List<CookStoryGroup> storyGroups;

  const _StoryBar({required this.storyGroups});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Stories',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: storyGroups.length,
            itemBuilder: (context, index) {
              final group = storyGroups[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryViewerScreen(
                        storyGroups: storyGroups,
                        initialGroupIndex: index,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryOrange,
                              Colors.deepOrange.shade700,
                              Colors.orange.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.warmCream,
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                AppTheme.primaryOrange.withValues(alpha: 0.12),
                            child: Text(
                              group.cookDisplayName.isNotEmpty
                                  ? group.cookDisplayName[0].toUpperCase()
                                  : 'C',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 72,
                        child: Text(
                          group.cookDisplayName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'See all',
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Chip ──────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: AppTheme.primaryOrange),
        label: Text(label),
        labelStyle: const TextStyle(
          color: AppTheme.primaryOrange,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppTheme.primaryOrange, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onPressed: onTap,
      ),
    );
  }
}

// ─── Meal Card ──────────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final MealModel meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        meal.images.isNotEmpty ? meal.images.first.imageUrl : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MealDetailScreen(mealId: meal.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 140,
                            color: AppTheme.lightGrey.withValues(alpha: 0.5),
                            child: const Center(
                              child: Icon(
                                Icons.restaurant,
                                color: AppTheme.greyText,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 140,
                            color: AppTheme.lightGrey.withValues(alpha: 0.5),
                            child: const Center(
                              child: Icon(
                                Icons.restaurant,
                                color: AppTheme.greyText,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 140,
                          color: AppTheme.lightGrey.withValues(alpha: 0.5),
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 40,
                              color: AppTheme.greyText,
                            ),
                          ),
                        ),
                ),
                // Fulfillment badges
                Positioned(
                  top: 8,
                  left: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (meal.fulfillmentModes.contains('pickup'))
                            _Badge(
                              label: 'Pickup',
                              color: AppTheme.primaryOrange,
                            ),
                          if (meal.fulfillmentModes.contains('delivery'))
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _Badge(
                                label: 'Delivery',
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                        ],
                      ),
                      if (_isNewMeal(meal.createdAt))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: AppTheme.primaryOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Discount badge
                if (meal.discountPercentage > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _Badge(
                      label: '${meal.discountPercentage.toStringAsFixed(0)}% OFF',
                      color: AppTheme.successGreen,
                    ),
                  ),
              ],
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'by ${meal.cookDisplayName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyText,
                            ),
                          ),
                        ),
                        if (meal.category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              meal.category[0].toUpperCase() +
                                  meal.category.substring(1),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppTheme.primaryOrange,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          meal.avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (meal.discountPercentage > 0) ...[
                          Text(
                            '${currencySymbol(meal.currency)}${meal.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.greyText,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '${currencySymbol(meal.currency)}${meal.effectivePrice.toStringAsFixed(2)}',
                          style: const TextStyle(
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
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

bool _isNewMeal(String createdAt) {
  if (createdAt.isEmpty) return false;
  try {
    final created = DateTime.parse(createdAt);
    return DateTime.now().difference(created).inDays <= 7;
  } catch (_) {
    return false;
  }
}

// ─── Badge ──────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Trending Meal Row ──────────────────────────────────────────────────────

class _TrendingMealRow extends StatelessWidget {
  final MealModel meal;

  const _TrendingMealRow({required this.meal});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        meal.images.isNotEmpty ? meal.images.first.imageUrl : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MealDetailScreen(mealId: meal.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
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
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 70,
                        width: 70,
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 70,
                        width: 70,
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                        child: const Icon(Icons.restaurant,
                            color: AppTheme.greyText),
                      ),
                    )
                  : Container(
                      height: 70,
                      width: 70,
                      color: AppTheme.lightGrey.withValues(alpha: 0.5),
                      child: const Icon(Icons.restaurant,
                          color: AppTheme.greyText),
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
                      Flexible(
                        child: Text(
                          meal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_isNewMeal(meal.createdAt)) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppTheme.primaryOrange, width: 1),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: AppTheme.primaryOrange,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'by ${meal.cookDisplayName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ),
                      if (meal.category.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            meal.category[0].toUpperCase() +
                                meal.category.substring(1),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: AppTheme.primaryOrange),
                      const SizedBox(width: 2),
                      Text(
                        meal.avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${meal.totalOrders} orders',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (meal.discountPercentage > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${meal.discountPercentage.toStringAsFixed(0)}% OFF',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currencySymbol(meal.currency)}${meal.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.greyText,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
                Text(
                  '${currencySymbol(meal.currency)}${meal.effectivePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
