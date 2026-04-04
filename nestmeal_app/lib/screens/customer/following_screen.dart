import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/meal_model.dart';
import '../../providers/cook_provider.dart';
import 'cook_profile_screen.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CookProvider>().fetchFollowing();
    });
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
          'Following',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
      ),
      body: cookProvider.isFollowingLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryOrange),
            )
          : cookProvider.followingCooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: AppTheme.greyText.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Not following anyone yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Follow cooks to see their meals\nand stories in your feed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primaryOrange,
                  onRefresh: () => cookProvider.fetchFollowing(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: cookProvider.followingCooks.length,
                    itemBuilder: (context, index) {
                      return _FollowingCookCard(
                        cook: cookProvider.followingCooks[index],
                      );
                    },
                  ),
                ),
    );
  }
}

class _FollowingCookCard extends StatelessWidget {
  final CookCard cook;

  const _FollowingCookCard({required this.cook});

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
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  AppTheme.primaryOrange.withValues(alpha: 0.12),
              child: Text(
                cook.displayName.isNotEmpty
                    ? cook.displayName[0].toUpperCase()
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
                  Text(
                    cook.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (cook.kitchenCity.isNotEmpty)
                    Text(
                      '${cook.kitchenCity}${cook.kitchenState.isNotEmpty ? ', ${cook.kitchenState}' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.greyText,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: AppTheme.primaryOrange),
                      const SizedBox(width: 2),
                      Text(
                        cook.avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.greyText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.people_outline,
                          size: 14, color: AppTheme.greyText),
                      const SizedBox(width: 2),
                      Text(
                        '${cook.followersCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                        ),
                      ),
                      if (cook.deliveryEnabled) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.delivery_dining,
                            size: 14, color: AppTheme.successGreen),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _UnfollowButton(cookId: cook.id),
          ],
        ),
      ),
    );
  }
}

class _UnfollowButton extends StatefulWidget {
  final String cookId;

  const _UnfollowButton({required this.cookId});

  @override
  State<_UnfollowButton> createState() => _UnfollowButtonState();
}

class _UnfollowButtonState extends State<_UnfollowButton> {
  bool _loading = false;
  bool _unfollowed = false;

  Future<void> _toggle() async {
    setState(() => _loading = true);
    try {
      await context.read<CookProvider>().toggleFollow(widget.cookId);
      if (mounted) setState(() => _unfollowed = !_unfollowed);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.primaryOrange,
        ),
      );
    }
    if (_unfollowed) {
      return ElevatedButton(
        onPressed: _toggle,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Follow',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }
    return OutlinedButton(
      onPressed: _toggle,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryOrange,
        side: const BorderSide(color: AppTheme.primaryOrange),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        'Unfollow',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
