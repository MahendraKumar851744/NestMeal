import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/screens/customer/cook_profile_screen.dart';

class CookAvatar extends StatelessWidget {
  final String id;
  final String name;
  final String? imageUrl;
  final double rating;

  const CookAvatar({
    super.key,
    required this.id,
    required this.name,
    this.imageUrl,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CookProfileScreen(cookId: id),
        ));
      },
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.lightGrey,
              backgroundImage:
                  imageUrl != null && imageUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(imageUrl!)
                      : null,
              child: imageUrl == null || imageUrl!.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryOrange,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 6),

            // Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),

            // Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 12, color: Colors.amber[700]),
                const SizedBox(width: 2),
                Text(
                  rating > 0 ? rating.toStringAsFixed(1) : 'New',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.greyText,
                    fontWeight: FontWeight.w500,
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
