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
  final RouteObserver<ModalRoute<void>>? routeObserver;

  const HomeScreen({super.key, this.routeObserver});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadData();
    }
    // Subscribe to the home tab's RouteObserver so we get didPopNext callbacks
    final observer = widget.routeObserver;
    final route = ModalRoute.of(context);
    if (observer != null && route != null) {
      observer.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    widget.routeObserver?.unsubscribe(this);
    super.dispose();
  }

  /// Called when a route above this one is popped off — i.e. user navigated
  /// back to home. Re-fetch so the time-filtered meal list is restored.
  @override
  void didPopNext() {
    _loadData();
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
    final timeCategory = _getTimeCategory();
    try {
      await Future.wait([
        mealProvider.fetchMeals(availableDays: today, category: timeCategory),
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

  String _getTimeCategory() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'breakfast';
    if (hour < 17) return 'lunch';
    return 'dinner';
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting + Avatar row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()} \u{1F37D}',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "What's your nextmeal?",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.greyText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppTheme.primaryOrange,
                                size: 26,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${(authProvider.currentUser?.customerProfile?.walletBalance ?? 0.0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Stories strip (IG/WA style, above search bar)
                    if (storyProvider.storyFeed.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _StoryBar(storyGroups: storyProvider.storyFeed),
                    ],

                    const SizedBox(height: 0),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
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
                    ),
                  ],
                ),
              ),
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
                  height: 200,
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
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: mealProvider.meals.length,
                    itemBuilder: (context, index) {
                      final cardWidth =
                          (MediaQuery.of(context).size.width - 44) / 2;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < mealProvider.meals.length - 1 ? 12 : 0,
                        ),
                        child: SizedBox(
                          width: cardWidth,
                          child: _MealCard(meal: mealProvider.meals[index]),
                        ),
                      );
                    },
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


  Widget _buildShimmerList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 200,
          margin: const EdgeInsets.only(right: 12),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 115,
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 13,
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 11,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 13,
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
    return SizedBox(
      height: 115,
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
                          color: group.hasUnviewed
                              ? AppTheme.primaryOrange    // orange — unviewed
                              : Colors.grey.shade400,     // gray   — all viewed
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
                            backgroundImage: group.cookProfileImageUrl != null
                                ? CachedNetworkImageProvider(group.cookProfileImageUrl!)
                                : null,
                            child: group.cookProfileImageUrl == null
                                ? Text(
                                    group.cookDisplayName.isNotEmpty
                                        ? group.cookDisplayName[0].toUpperCase()
                                        : 'C',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  )
                                : null,
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
        clipBehavior: Clip.hardEdge,
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
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 115,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 115,
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                        child: const Center(
                          child: Icon(Icons.restaurant, color: AppTheme.greyText),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 115,
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                        child: const Center(
                          child: Icon(Icons.restaurant, color: AppTheme.greyText),
                        ),
                      ),
                    )
                  : Container(
                      height: 115,
                      color: AppTheme.lightGrey.withValues(alpha: 0.5),
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 40, color: AppTheme.greyText),
                      ),
                    ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          meal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'by ${meal.cookDisplayName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.greyText,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 13, color: AppTheme.primaryOrange),
                        const SizedBox(width: 2),
                        Text(
                          meal.avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${currencySymbol(meal.currency)}${meal.effectivePrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryOrange,
                            height: 1.2,
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
