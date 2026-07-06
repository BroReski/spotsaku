import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onTheme;
  final VoidCallback onStatistic;
  final bool isDark;

  const HomeHeader({
    super.key,
    required this.onTheme,
    required this.onStatistic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Selamat Datang",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Akhtar Abraar",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "Temukan tempat favoritmu",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),

        _HeaderButton(
          icon: isDark
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          onTap: onTheme,
        ),

        const SizedBox(width: 10),

        _HeaderButton(
          icon: Icons.bar_chart_rounded,
          onTap: onStatistic,
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: theme.brightness == Brightness.dark
          ? Colors.black54
          : Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}