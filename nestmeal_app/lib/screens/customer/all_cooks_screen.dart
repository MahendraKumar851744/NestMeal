import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/meal_model.dart';
import '../../providers/cook_provider.dart';
import 'cook_profile_screen.dart';

class AllCooksScreen extends StatefulWidget {
  const AllCooksScreen({super.key});

  @override
  State<AllCooksScreen> createState() => _AllCooksScreenState();
}

class _AllCooksScreenState extends State<AllCooksScreen> {
  final _searchController = TextEditingController();
  String _sortBy = '-avg_rating';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCooks());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCooks() async {
    try {
      await context.read<CookProvider>().fetchCooks(
            search: _searchController.text.trim().isNotEmpty
                ? _searchController.text.trim()
                : null,
            ordering: _sortBy,
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cookProvider = context.watch<CookProvider>();

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
        title: Text(
          'Local Cooks',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cooks by name or city...',
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.greyText),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.greyText),
                        onPressed: () {
                          _searchController.clear();
                          _loadCooks();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.lightGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.lightGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.primaryOrange),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _loadCooks(),
            ),
          ),

          // Sort chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _SortChip(
                  label: 'Top Rated',
                  isSelected: _sortBy == '-avg_rating',
                  onTap: () {
                    setState(() => _sortBy = '-avg_rating');
                    _loadCooks();
                  },
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Most Reviewed',
                  isSelected: _sortBy == '-total_reviews',
                  onTap: () {
                    setState(() => _sortBy = '-total_reviews');
                    _loadCooks();
                  },
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Newest',
                  isSelected: _sortBy == '-created_at',
                  onTap: () {
                    setState(() => _sortBy = '-created_at');
                    _loadCooks();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Cook list
          Expanded(
            child: cookProvider.isLoading && cookProvider.cooks.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryOrange),
                  )
                : cookProvider.cooks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_outlined,
                              size: 64,
                              color:
                                  AppTheme.greyText.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No cooks found',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.greyText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.primaryOrange,
                        onRefresh: _loadCooks,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: cookProvider.cooks.length,
                          itemBuilder: (context, index) {
                            return _CookListCard(
                              cook: cookProvider.cooks[index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Sort Chip ──────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? AppTheme.primaryOrange : AppTheme.lightGrey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.greyText,
          ),
        ),
      ),
    );
  }
}

// ─── Cook List Card ─────────────────────────────────────────────────────────

class _CookListCard extends StatelessWidget {
  final CookCard cook;

  const _CookListCard({required this.cook});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CookProfileScreen(cookId: cook.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor:
                  AppTheme.primaryOrange.withValues(alpha: 0.12),
              backgroundImage: cook.profileImageUrl != null
                  ? CachedNetworkImageProvider(cook.profileImageUrl!)
                  : null,
              child: cook.profileImageUrl == null
                  ? Text(
                      cook.displayName.isNotEmpty
                          ? cook.displayName[0].toUpperCase()
                          : 'C',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryOrange,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cook.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (cook.kitchenCity.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.greyText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${cook.kitchenCity}${cook.kitchenState.isNotEmpty ? ', ${cook.kitchenState}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: AppTheme.primaryOrange),
                      const SizedBox(width: 3),
                      Text(
                        cook.avgRating > 0
                            ? cook.avgRating.toStringAsFixed(1)
                            : 'New',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.rate_review_outlined,
                          size: 14, color: AppTheme.greyText),
                      const SizedBox(width: 3),
                      Text(
                        '${cook.totalReviews} reviews',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                        ),
                      ),
                      if (cook.deliveryEnabled) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Delivery',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(Icons.chevron_right, color: AppTheme.lightGrey),
          ],
        ),
      ),
    );
  }
}
