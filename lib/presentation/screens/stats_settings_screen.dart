/// Statistics & Settings screen.
///
/// Visualises visit status counts, shows the average rating, and exposes
/// settings for reminder notifications and CSV/JSON data export.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/spot_provider.dart';

class StatsSettingsScreen extends StatefulWidget {
  const StatsSettingsScreen({super.key});

  @override
  State<StatsSettingsScreen> createState() => _StatsSettingsScreenState();
}

class _StatsSettingsScreenState extends State<StatsSettingsScreen> {
  int? _total;
  int? _visited;
  int? _wishlist;
  double? _avgRating;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final provider = context.read<SpotProvider>();
    final total = await provider.totalCount;
    final visited = await provider.visitedCount;
    final wishlist = await provider.wishlistCount;
    final avg = await provider.averageRating;
    if (mounted) {
      setState(() {
        _total = total;
        _visited = visited;
        _wishlist = wishlist;
        _avgRating = avg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik & Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Stats section ---
          Text('Statistik Kunjungan',
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_total == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Spot',
                    value: _total.toString(),
                    icon: Icons.place,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Dikunjungi',
                    value: _visited.toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Wishlist',
                    value: _wishlist.toString(),
                    icon: Icons.bookmark_outline,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.star_outline,
                    color: theme.colorScheme.primary),
                title: const Text('Rata-rata Rating'),
                trailing: Text(
                  _avgRating! == 0 ? 'Belum ada' : _avgRating!.toStringAsFixed(1),
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
            // Progress bar
            const SizedBox(height: 8),
            if (_total! > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _visited! / _total!,
                  minHeight: 12,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${((_visited! / _total!) * 100).round()}% spot telah dikunjungi',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
          const SizedBox(height: 32),
          // --- Settings section ---
          Text('Pengaturan',
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Notifikasi Pengingat'),
            subtitle: const Text(
                'Aktifkan reminder untuk spot wishlist'),
            value: settings.notificationsEnabled,
            onChanged: (_) => settings.toggleNotifications(),
          ),
          const Divider(),
          // --- Export ---
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Ekspor Data (CSV)'),
            subtitle: const Text('Cadangkan data ke berkas CSV'),
            trailing: settings.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: settings.isLoading ? null : () => _exportCsv(settings),
          ),
          ListTile(
            leading: const Icon(Icons.data_object_outlined),
            title: const Text('Ekspor Data (JSON)'),
            subtitle: const Text('Cadangkan data ke berkas JSON'),
            trailing: settings.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: settings.isLoading ? null : () => _exportJson(settings),
          ),
          if (settings.lastExportPath != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Berkas terakhir: ${settings.lastExportPath}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline),
              ),
            ),
          const SizedBox(height: 24),
          // --- About ---
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang SpotSaku'),
            subtitle: const Text('Aplikasi Jurnal & Wishlist Tempat\n'
                'Kelompok 1 — Mobile Computing 2025/2026'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(SettingsProvider settings) async {
    try {
      final path = await settings.exportCsv();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV diekspor: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ekspor: $e')),
        );
      }
    }
  }

  Future<void> _exportJson(SettingsProvider settings) async {
    try {
      final path = await settings.exportJson();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JSON diekspor: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ekspor: $e')),
        );
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
