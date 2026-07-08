/// A card displaying a single spot in the Home list.
///
/// Shows: thumbnail photo (or placeholder), name, category label,
/// rating stars (if visited & rated), and a status badge.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/spot.dart';
import 'star_rating.dart';

class SpotCard extends StatelessWidget {
  const SpotCard({
    super.key,
    required this.spot,
    required this.onTap,
  });

  final Spot spot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = spot.photoPath != null && spot.photoPath!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Thumbnail ---
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: hasPhoto
                      ? Image.file(
                          File(spot.photoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder(theme),
                        )
                      : _placeholder(theme),
                ),
              ),
              const SizedBox(width: 12),
              // --- Text content ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      spot.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.label_outline, size: 14,
                            color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            spot.category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (spot.isVisited && spot.rating != null) ...[
                      const SizedBox(height: 4),
                      StarRating(
                        rating: spot.rating,
                        starSize: 16,
                        readOnly: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // --- Reminder + Status badges ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (spot.reminderAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.notifications_active,
                        size: 16,
                        color: AppColors.warning,
                      ),
                    ),
                  _StatusBadge(isVisited: spot.isVisited),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.photo_camera_outlined,
        size: 28,
        color: theme.colorScheme.outline,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isVisited});

  final bool isVisited;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isVisited ? AppColors.success : AppColors.textSecondary;
    final bg = isVisited
        ? AppColors.success.withValues(alpha: 0.1)
        : AppColors.textSecondary.withValues(alpha: 0.1);
    final label = isVisited ? 'Dikunjungi' : 'Wishlist';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
