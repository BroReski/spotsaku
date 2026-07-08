import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),

        alignment: Alignment.center,

        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),

        decoration: BoxDecoration(
          color: selected ? AppColors.primary : theme.cardColor,

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: selected ? AppColors.primary : theme.dividerColor,
          ),

          // boxShadow: [
          //   BoxShadow(
          //     color: AppColors.shadow.withOpacity(
          //         theme.brightness == Brightness.dark ? 1.0 : 0.3),
          //     blurRadius: 8,
          //     offset: const Offset(0, 4),
          //   ),
          // ],
        ),

        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
