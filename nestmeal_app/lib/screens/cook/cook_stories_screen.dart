import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/models/story_model.dart';
import 'package:nestmeal_app/providers/story_provider.dart';
import 'package:nestmeal_app/screens/cook/story_upload_screen.dart';

class CookStoriesScreen extends StatefulWidget {
  const CookStoriesScreen({super.key});

  @override
  State<CookStoriesScreen> createState() => _CookStoriesScreenState();
}

class _CookStoriesScreenState extends State<CookStoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      await context.read<StoryProvider>().fetchMyStories();
    } catch (_) {}
  }

  Future<void> _confirmDelete(StoryModel story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Story?'),
        content: const Text(
            'This story will be permanently deleted and no longer visible to customers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.greyText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<StoryProvider>().deleteStory(story.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story deleted.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
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
          'My Stories',
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
                  MaterialPageRoute(
                      builder: (_) => const StoryUploadScreen()),
                );
                _load();
              },
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                'New Story',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<StoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.myStories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryOrange),
            );
          }

          if (provider.myStories.isEmpty) {
            return _buildEmptyState();
          }

          final active =
              provider.myStories.where((s) => !s.isExpired).toList();
          final expired =
              provider.myStories.where((s) => s.isExpired).toList();

          return RefreshIndicator(
            onRefresh: _load,
            color: AppTheme.primaryOrange,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (active.isNotEmpty) ...[
                  _sectionHeader('Active', active.length,
                      color: AppTheme.successGreen),
                  const SizedBox(height: 10),
                  ...active.map((s) => _StoryCard(
                        story: s,
                        onDelete: () => _confirmDelete(s),
                      )),
                ],
                if (expired.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _sectionHeader('Expired', expired.length,
                      color: AppTheme.greyText),
                  const SizedBox(height: 10),
                  ...expired.map((s) => _StoryCard(
                        story: s,
                        onDelete: () => _confirmDelete(s),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, int count, {required Color color}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color),
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
          Icon(Icons.camera_alt_outlined,
              size: 72,
              color: AppTheme.greyText.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No stories yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share what\'s cooking — stories last 24 hours',
            style: TextStyle(fontSize: 14, color: AppTheme.greyText),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const StoryUploadScreen()),
              );
              _load();
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Post a Story',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Story Card ───────────────────────────────────────────────────────────────

class _StoryCard extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onDelete;

  const _StoryCard({required this.story, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final expired = story.isExpired;

    String postedAt;
    String expiresLabel;
    try {
      final created = DateTime.parse(story.createdAt).toLocal();
      final expires = DateTime.parse(story.expiresAt).toLocal();
      postedAt = DateFormat('MMM d, h:mm a').format(created);
      if (expired) {
        expiresLabel = 'Expired ${DateFormat('MMM d, h:mm a').format(expires)}';
      } else {
        final remaining = expires.difference(DateTime.now());
        if (remaining.inHours >= 1) {
          expiresLabel = 'Expires in ${remaining.inHours}h';
        } else {
          expiresLabel = 'Expires in ${remaining.inMinutes}m';
        }
      }
    } catch (_) {
      postedAt = story.createdAt;
      expiresLabel = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            child: ColorFiltered(
              colorFilter: expired
                  ? const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ])
                  : const ColorFilter.mode(
                      Colors.transparent, BlendMode.color),
              child: CachedNetworkImage(
                imageUrl: story.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 90,
                  height: 90,
                  color: AppTheme.lightGrey,
                  child: const Icon(Icons.image_outlined,
                      color: AppTheme.greyText),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 90,
                  height: 90,
                  color: AppTheme.lightGrey,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppTheme.greyText),
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: expired
                              ? AppTheme.greyText.withValues(alpha: 0.1)
                              : AppTheme.successGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          expired ? 'Expired' : 'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: expired
                                ? AppTheme.greyText
                                : AppTheme.successGreen,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // View count
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: 14, color: AppTheme.greyText),
                          const SizedBox(width: 4),
                          Text(
                            '${story.viewCount}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkText,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            story.viewCount == 1 ? 'view' : 'views',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.greyText),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (story.caption.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      story.caption,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.darkText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: AppTheme.greyText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$postedAt  •  $expiresLabel',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.greyText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Delete button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              color: AppTheme.errorRed,
              tooltip: 'Delete story',
            ),
          ),
        ],
      ),
    );
  }
}
