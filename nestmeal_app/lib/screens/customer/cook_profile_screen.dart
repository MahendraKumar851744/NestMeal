import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/meal_model.dart';
import '../../models/helpers.dart';
import '../../models/review_model.dart';
import '../../models/story_model.dart';
import '../../providers/meal_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/cook_provider.dart';
import '../../providers/story_provider.dart';
import 'meal_detail_screen.dart';
import 'story_viewer_screen.dart';

class CookProfileScreen extends StatefulWidget {
  final String cookId;

  const CookProfileScreen({super.key, required this.cookId});

  @override
  State<CookProfileScreen> createState() => _CookProfileScreenState();
}

class _CookProfileScreenState extends State<CookProfileScreen> {
  bool _isLoading = true;
  bool _isFollowLoading = false;
  CookCard? _cook;
  List<MealModel> _cookMeals = [];
  List<ReviewModel> _reviews = [];
  List<StoryModel> _stories = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCookData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCookData() async {
    setState(() => _isLoading = true);
    try {
      final cookProvider = context.read<CookProvider>();
      final mealProvider = context.read<MealProvider>();
      final reviewProvider = context.read<ReviewProvider>();
      final storyProvider = context.read<StoryProvider>();

      // Fetch cook profile directly from the public endpoint
      try {
        await cookProvider.fetchCookDetail(widget.cookId);
        _cook = cookProvider.selectedCook;
      } catch (_) {
        // Fallback: extract cook info from first meal detail
      }

      // Fetch meals by this cook
      await mealProvider.fetchMeals(cook: widget.cookId);
      _cookMeals = List.from(mealProvider.meals);

      // If we couldn't get cook from public endpoint, try from meal detail
      if (_cook == null && _cookMeals.isNotEmpty) {
        await mealProvider.fetchMealDetail(_cookMeals.first.id);
        final detail = mealProvider.selectedMeal;
        if (detail != null) {
          _cook = detail.cookCard;
        }
      }

      // Fetch reviews
      try {
        await reviewProvider.fetchReviews(cookId: widget.cookId);
        _reviews = List.from(reviewProvider.reviews);
      } catch (_) {}

      // Fetch stories for this cook
      try {
        await storyProvider.fetchCookStories(widget.cookId);
        _stories = List.from(storyProvider.cookStories);
      } catch (_) {}

      // Always sync following state so the follow button is accurate
      try {
        await cookProvider.fetchFollowing();
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cook profile: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isFollowLoading = true);
    try {
      final cookProvider = context.read<CookProvider>();
      await cookProvider.toggleFollow(widget.cookId);
      _cook = cookProvider.selectedCook;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  void _openStoryViewer() {
    if (_stories.isEmpty) return;
    final group = CookStoryGroup(
      cookId: widget.cookId,
      cookDisplayName: _cook?.displayName ?? 'Cook',
      stories: _stories,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          storyGroups: [group],
          initialGroupIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.warmCream,
        appBar: AppBar(backgroundColor: AppTheme.warmCream, elevation: 0),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryOrange),
        ),
      );
    }

    final cook = _cook;
    final cookName = cook?.displayName ??
        (_cookMeals.isNotEmpty ? _cookMeals.first.cookDisplayName : 'Cook');
    final cookProvider = context.watch<CookProvider>();
    final isFollowed = cookProvider.isFollowing(widget.cookId) || (_cook?.isFollowed ?? false);
    final hasStories = _stories.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.warmCream,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              cookName,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Avatar with story ring
                  Center(
                    child: GestureDetector(
                      onTap: hasStories ? _openStoryViewer : null,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: hasStories
                            ? BoxDecoration(
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
                              )
                            : null,
                        child: Container(
                          padding: hasStories ? const EdgeInsets.all(2) : null,
                          decoration: hasStories
                              ? const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.warmCream,
                                )
                              : null,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                AppTheme.primaryOrange.withValues(alpha: 0.15),
                            backgroundImage: _cook?.profileImageUrl != null
                                ? CachedNetworkImageProvider(_cook!.profileImageUrl!)
                                : null,
                            child: _cook?.profileImageUrl == null
                                ? Text(
                                    cookName.isNotEmpty
                                        ? cookName[0].toUpperCase()
                                        : 'C',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Center(
                    child: Text(
                      cookName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Location
                  if (cook != null && cook.kitchenCity.isNotEmpty)
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: AppTheme.greyText),
                          const SizedBox(width: 4),
                          Text(
                            '${cook.kitchenCity}${cook.kitchenState.isNotEmpty ? ', ${cook.kitchenState}' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Follow & Order buttons
                  Row(
                    children: [
                      Expanded(
                        child: _isFollowLoading
                            ? Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primaryOrange),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: _toggleFollow,
                                icon: Icon(
                                  isFollowed
                                      ? Icons.person_remove_outlined
                                      : Icons.person_add_outlined,
                                  size: 18,
                                ),
                                label: Text(isFollowed ? 'Following' : 'Follow'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFollowed
                                      ? AppTheme.primaryOrange
                                      : Colors.white,
                                  foregroundColor: isFollowed
                                      ? Colors.white
                                      : AppTheme.primaryOrange,
                                  elevation: 0,
                                  side: const BorderSide(color: AppTheme.primaryOrange),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          icon: const Icon(Icons.restaurant_menu, size: 18),
                          label: const Text('Order'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          value: cook?.avgRating.toStringAsFixed(1) ?? '0.0',
                          label: 'Rating',
                          icon: Icons.star,
                          iconColor: AppTheme.primaryOrange,
                        ),
                        Container(width: 1, height: 40, color: AppTheme.lightGrey),
                        _StatItem(
                          value: '${cook?.followersCount ?? 0}',
                          label: 'Followers',
                          icon: Icons.people_outline,
                          iconColor: AppTheme.greyText,
                        ),
                        Container(width: 1, height: 40, color: AppTheme.lightGrey),
                        _StatItem(
                          value: '${_cookMeals.length}',
                          label: 'Meals',
                          icon: Icons.restaurant_menu_outlined,
                          iconColor: AppTheme.greyText,
                        ),
                        if (cook != null && cook.deliveryEnabled) ...[
                          Container(width: 1, height: 40, color: AppTheme.lightGrey),
                          _StatItem(
                            value: '${cook.deliveryRadiusKm.toStringAsFixed(0)} km',
                            label: 'Delivery',
                            icon: Icons.delivery_dining,
                            iconColor: AppTheme.successGreen,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── About section ──────────────────────────────────────
                  if (cook != null && cook.bio.isNotEmpty) ...[
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cook.bio,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.greyText,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Reviews section ────────────────────────────────────
                  if (_reviews.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reviews (${_reviews.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkText,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: AppTheme.primaryOrange),
                            const SizedBox(width: 4),
                            Text(
                              cook?.avgRating.toStringAsFixed(1) ?? '0.0',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._reviews.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ReviewCard(review: r),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // ── Meals section ──────────────────────────────────────
                  Row(
                    children: [
                      const Text(
                        'Meals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_cookMeals.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Meals list
          _cookMeals.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No meals listed yet',
                        style: TextStyle(color: AppTheme.greyText),
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _CookMealCard(meal: _cookMeals[index]),
                    childCount: _cookMeals.length,
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ─── Stat Item ──────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.greyText,
          ),
        ),
      ],
    );
  }
}

// ─── Cook Meal Card ─────────────────────────────────────────────────────────

class _CookMealCard extends StatelessWidget {
  final MealModel meal;

  const _CookMealCard({required this.meal});

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
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 100,
                        width: 100,
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 100,
                        width: 100,
                        color: AppTheme.lightGrey.withValues(alpha: 0.5),
                        child: const Icon(Icons.restaurant,
                            color: AppTheme.greyText),
                      ),
                    )
                  : Container(
                      height: 100,
                      width: 100,
                      color: AppTheme.lightGrey.withValues(alpha: 0.5),
                      child: const Icon(Icons.restaurant,
                          color: AppTheme.greyText),
                    ),
            ),
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
                      ),
                    ),
                    const SizedBox(height: 8),
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
                        if (meal.fulfillmentModes.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ...meal.fulfillmentModes.map((mode) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    mode == 'pickup' ? 'Pickup' : 'Delivery',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  ),
                                ),
                              )),
                        ],
                        const Spacer(),
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
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Review Card ────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.lightGrey,
                child: Text(
                  review.customerName.isNotEmpty
                      ? review.customerName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      review.mealTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                size: 16,
                color: AppTheme.primaryOrange,
              );
            }),
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppTheme.greyText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
