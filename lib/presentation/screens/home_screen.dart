/// Home / Dashboard screen.
///
/// Displays the list of saved spots with search, category chips,
/// dark-mode toggle, and FAB.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/spot.dart';

import '../providers/category_provider.dart';
import '../providers/spot_provider.dart';
import '../providers/theme_provider.dart';

import '../widgets/category_chip.dart';
import '../widgets/home_header.dart';
import '../widgets/spot_card.dart';
import '../widgets/search_box.dart';

import 'add_edit_screen.dart';
import 'detail_screen.dart';
import 'stats_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotProvider>().loadSpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final spotProvider = context.watch<SpotProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah Spot"),
        onPressed: () => _navigateToAdd(context),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              /// HEADER
              HomeHeader(
                isDark: themeProvider.isDarkMode,
                onTheme: () {
                  themeProvider.toggleTheme();
                },
                onStatistic: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const StatsSettingsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              /// SEARCH
              SearchBox(
  onChanged: (value) {
    spotProvider.setSearchQuery(value);
  },
),

              const SizedBox(height: 20),

              /// CATEGORY
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryProvider.chips.length,

                  separatorBuilder: (_, _) =>
                      const SizedBox(width: 10),

                  itemBuilder: (context, index) {
                    final category = categoryProvider.chips[index];

                    return SizedBox(
                      width: 105,

                      child: CategoryChip(
                        label: category,
                        selected:
                            spotProvider.selectedCategory ==
                                category,
                        onTap: () {
                          spotProvider.setCategory(category);
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              /// STATUS FILTER (Semua / Wishlist / Dikunjungi)
              _StatusFilterBar(
                value: spotProvider.statusFilter,
                onChanged: spotProvider.setStatusFilter,
              ),

              const SizedBox(height: 20),

              /// LIST
              Expanded(
                child: spotProvider.isLoading &&
                        spotProvider.spots.isEmpty
                    ? const Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    : spotProvider.error != null
                        ? _ErrorState(
                            message:
                                spotProvider.error!,
                            onRetry: () {
                              spotProvider
                                  .loadSpots();
                            },
                          )
                        : spotProvider.spots.isEmpty
                            ? _EmptyState(
                                onAdd: () =>
                                    _navigateToAdd(context),
                                isFiltered:
                                    spotProvider.searchQuery
                                            .isNotEmpty ||
                                    spotProvider.selectedCategory !=
                                        "Semua" ||
                                    spotProvider.statusFilter !=
                                        null,
                              )
                            : RefreshIndicator(
                                color: AppColors.primary,
                                onRefresh: () =>
                                    spotProvider.loadSpots(),
                                child: ListView.builder(
                                  itemCount:
                                      spotProvider.spots.length,
                                  itemBuilder: (context, index) {
                                    final spot =
                                        spotProvider.spots[index];

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(
                                              bottom: 14),
                                      child: SpotCard(
                                        spot: spot,
                                        onTap: () =>
                                            _navigateToDetail(
                                          context,
                                          spot,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAdd(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditScreen(),
      ),
    );

    if (result == true && context.mounted) {
      context.read<SpotProvider>().loadSpots();
    }
  }

  Future<void> _navigateToDetail(
      BuildContext context,
      Spot spot,
      ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          spotId: spot.id!,
        ),
      ),
    );

    if (result == true && context.mounted) {
      context.read<SpotProvider>().loadSpots();
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onAdd,
    this.isFiltered = false,
  });

  final VoidCallback onAdd;
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [

          Icon(
            isFiltered
                ? Icons.search_off
                : Icons.location_on_outlined,
            size: 80,
            color: AppColors.primary,
          ),

          const SizedBox(height: 20),

          Text(
            isFiltered
                ? "Tidak ada hasil"
                : "Belum ada Spot Favorit",
            style: theme.textTheme.titleLarge,
          ),

          const SizedBox(height: 10),

          Text(
            isFiltered
                ? "Coba ubah kata kunci pencarian."
                : "Tambahkan lokasi pertama kamu.",
            textAlign: TextAlign.center,
          ),

          if (!isFiltered) ...[
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text(
                "Tambah Spot",
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [

          const Icon(
            Icons.error_outline,
            size: 70,
            color: AppColors.danger,
          ),

          const SizedBox(height: 20),

          const Text(
            "Terjadi Kesalahan",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding:
                const EdgeInsets.symmetric(
                    horizontal: 30),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 25),

          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Lagi"),
          ),
        ],
      ),
    );
  }
}

/// Dropdown filter for the spot list by visit status.
///
/// Only the currently selected filter is shown as the button label.
/// `null` = Semua, `false` = Wishlist, `true` = Dikunjungi.
class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.value,
    required this.onChanged,
  });

  /// Current filter value: `null` (all), `false` (wishlist), `true` (visited).
  final bool? value;

  /// Callback invoked when the user picks an option.
  final ValueChanged<bool?> onChanged;

  String get _label => switch (value) {
        null => 'Semua',
        false => 'Wishlist',
        true => 'Dikunjungi',
      };

  IconData get _icon => switch (value) {
        null => Icons.list,
        false => Icons.bookmark_outline,
        true => Icons.check_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.5 : 0.1,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool?>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 22),
          style: theme.textTheme.bodyLarge,
          // Shows only the selected filter as the button label.
          selectedItemBuilder: (context) {
            return [
              _selectedItem(context, Icons.list, 'Semua'),
              _selectedItem(context, Icons.bookmark_outline, 'Wishlist'),
              _selectedItem(
                  context, Icons.check_circle_outline, 'Dikunjungi'),
            ];
          },
          items: const [
            DropdownMenuItem(
              value: null,
              child: _FilterOption(
                icon: Icons.list,
                label: 'Semua',
              ),
            ),
            DropdownMenuItem(
              value: false,
              child: _FilterOption(
                icon: Icons.bookmark_outline,
                label: 'Wishlist',
              ),
            ),
            DropdownMenuItem(
              value: true,
              child: _FilterOption(
                icon: Icons.check_circle_outline,
                label: 'Dikunjungi',
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _selectedItem(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// A single option row inside the dropdown menu.
class _FilterOption extends StatelessWidget {
  const _FilterOption({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}