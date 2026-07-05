/// A tappable star-rating widget (1-5 stars).
///
/// Used on the Detail screen for visited spots and on Home cards in a
/// read-only (non-interactive) variant.
library;

import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    this.rating,
    this.maxRating = 5,
    this.onRatingChanged,
    this.starSize = 24,
    this.readOnly = false,
  });

  /// Current rating value (1-5). `null` means "not rated".
  final int? rating;

  /// Maximum number of stars (default 5).
  final int maxRating;

  /// Callback when a star is tapped. If `null` or [readOnly] is true the
  /// widget is non-interactive.
  final ValueChanged<int>? onRatingChanged;

  /// Size of each star icon.
  final double starSize;

  /// When true, taps are ignored even if [onRatingChanged] is provided.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final emptyColor = theme.colorScheme.outlineVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starValue = index + 1;
        final isFilled = rating != null && starValue <= rating!;
        final interactive = !readOnly && onRatingChanged != null;
        return GestureDetector(
          onTap: interactive ? () => onRatingChanged!(starValue) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: starSize,
              color: isFilled ? color : emptyColor,
            ),
          ),
        );
      }),
    );
  }
}
