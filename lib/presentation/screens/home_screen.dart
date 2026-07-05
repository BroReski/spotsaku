/// Home / Dashboard screen.
///
/// Displays the list of saved spots with search, category chips, a
/// dark-mode toggle, and a FAB to add a new spot. Tapping a card opens
/// the Detail screen.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/spot.dart';
import '../../utils/constants.dart';
import '../providers/spot_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/spot_card.dart';
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
    // Load spots after the first frame so providers are available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotProvider>().loadSpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final spotProvider = context.watch<SpotProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SpotSaku'),
        actions: [
          // Dark mode toggle
          IconButton(
            icon: Icon(
              context.read<ThemeProvider>().isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Ganti tema',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          // Stats & settings
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Statistik & Pengaturan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsSettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Search bar ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari spot...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => spotProvider.setSearchQuery(value),
            ),
          ),
          // --- Category chips ---
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: AppCategories.chips.map((cat) {
                return CategoryChip(
                  label: cat,
                  selected: spotProvider.selectedCategory == cat,
                  onTap: () => spotProvider.setCategory(cat),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          // --- Spot list ---
          Expanded(
            child: spotProvider.isLoading && spotProvider.spots.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : spotProvider.error != null
                    ? _ErrorState(
                        message: spotProvider.error!,
                        onRetry: () => spotProvider.loadSpots(),
                      )
                    : spotProvider.spots.isEmpty
                        ? _EmptyState(
                            onAdd: () => _navigateToAdd(context),
                            isFiltered: spotProvider.searchQuery.isNotEmpty ||
                                spotProvider.selectedCategory != 'Semua',
                          )
                        : RefreshIndicator(
                        onRefresh: () => spotProvider.loadSpots(),
                        child: ListView.builder(
                          itemCount: spotProvider.spots.length,
                          itemBuilder: (context, index) {
                            final spot = spotProvider.spots[index];
                            return SpotCard(
                              spot: spot,
                              onTap: () => _navigateToDetail(context, spot),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Spot'),
      ),
    );
  }

  Future<void> _navigateToAdd(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditScreen()),
    );
    // Reload if a spot was saved.
    if (result == true && context.mounted) {
      context.read<SpotProvider>().loadSpots();
    }
  }

  Future<void> _navigateToDetail(BuildContext context, Spot spot) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(spotId: spot.id!),
      ),
    );
    if (result == true && context.mounted) {
      context.read<SpotProvider>().loadSpots();
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd, this.isFiltered = false});

  final VoidCallback onAdd;

  /// When `true`, the empty list is the result of an active search or filter
  /// rather than the database genuinely having no spots.
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered ? Icons.search_off : Icons.place_outlined,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'Tidak ada spot yang cocok'
                  : 'Belum ada spot tersimpan',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Coba ubah kata kunci pencarian atau filter kategori.'
                  : 'Temukan lokasi menarik dan simpan di sini secara offline.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Spot Pertama'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 72,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi kesalahan',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
