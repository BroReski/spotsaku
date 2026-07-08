/// Detail screen for a single spot.
///
/// Shows a hero image, the spot's name, category & status labels, rating
/// (editable when visited), review text, edit/delete actions, and a
/// floating "Buka Rute di Google Maps" button.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/spot.dart';
import '../../utils/maps_service.dart';
import '../providers/settings_provider.dart';
import '../providers/spot_provider.dart';
import '../widgets/star_rating.dart';
import 'add_edit_screen.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.spotId});

  final int spotId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Spot? _spot;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpot();
  }

  Future<void> _loadSpot() async {
    try {
      final spot = await context.read<SpotProvider>().getSpotById(widget.spotId);
      if (mounted) {
        setState(() {
          _spot = spot;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat spot: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final spot = _spot;
    if (spot == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Spot tidak ditemukan.')),
      );
    }

    final hasPhoto = spot.photoPath != null && spot.photoPath!.isNotEmpty;
    final mapsUrl = spot.toMapsDirectionsUrl();
    final canOpenMaps = mapsUrl != null && mapsUrl.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- Hero image app bar ---
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: hasPhoto
                  ? Image.file(
                      File(spot.photoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imagePlaceholder(theme),
                    )
                  : _imagePlaceholder(theme),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context, false),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Edit',
                onPressed: () => _navigateToEdit(spot),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Hapus',
                onPressed: () => _confirmDelete(spot),
              ),
            ],
          ),
          // --- Body ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // --- Labels ---
                  Wrap(
                    spacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.label_outline,
                        label: spot.category,
                      ),
                      _InfoChip(
                        icon: spot.isVisited
                            ? Icons.check_circle
                            : Icons.bookmark_outline,
                        label: spot.isVisited ? 'Dikunjungi' : 'Wishlist',
                        color: spot.isVisited
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                      if (spot.latitude != null)
                        _InfoChip(
                          icon: Icons.location_on_outlined,
                          label:
                              '${spot.latitude!.toStringAsFixed(4)}, ${spot.longitude!.toStringAsFixed(4)}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // --- Rating ---
                  if (spot.isVisited) ...[
                    Text('Rating', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    StarRating(
                      rating: spot.rating,
                      starSize: 36,
                      onRatingChanged: (v) => _setRating(spot, v),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // --- Reminder ---
                  if (!spot.isVisited) ...[
                    Text('Pengingat', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (spot.reminderAt != null)
                      _ReminderCard(
                        reminderAt: spot.reminderAt!,
                        onClear: () => _clearReminder(spot),
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: () => _showReminderPicker(spot),
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Set Pengingat'),
                      ),
                    const SizedBox(height: 20),
                  ],
                  // --- Review / notes ---
                  Text('Catatan / Review', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    spot.notes?.isNotEmpty == true
                        ? spot.notes!
                        : 'Belum ada catatan untuk spot ini.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: spot.notes?.isNotEmpty == true
                          ? null
                          : theme.colorScheme.outline,
                    ),
                  ),
                  if (spot.mapsUrl != null &&
                      spot.mapsUrl!.isNotEmpty &&
                      spot.latitude == null) ...[
                    const SizedBox(height: 12),
                    Text('Tautan Maps: ${spot.mapsUrl}',
                        style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 80), // space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: canOpenMaps ? () => _openMaps(spot) : null,
        icon: const Icon(Icons.map_outlined),
        label: const Text('Buka Rute di Google Maps'),
      ),
    );
  }

  Widget _imagePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_outlined,
          size: 64, color: theme.colorScheme.outline),
    );
  }

  Future<void> _navigateToEdit(Spot spot) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditScreen(spot: spot)),
    );
    if (result == true && mounted) {
      _loadSpot();
    }
  }

  Future<void> _confirmDelete(Spot spot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Spot?'),
        content: Text('Yakin ingin menghapus "${spot.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<SpotProvider>().deleteSpot(spot.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _setRating(Spot spot, int rating) async {
    await context.read<SpotProvider>().setRating(spot, rating);
    _loadSpot();
  }

  /// Shows a bottom sheet with quick reminder presets and a custom
  /// date/time picker.
  Future<void> _showReminderPicker(Spot spot) async {
    final settings = context.read<SettingsProvider>();
    if (!settings.notificationsEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Aktifkan notifikasi di Pengaturan terlebih dahulu.'),
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    final choices = <_ReminderPreset>[
      _ReminderPreset('1 Hari', now.add(const Duration(days: 1))),
      _ReminderPreset('3 Hari', now.add(const Duration(days: 3))),
      _ReminderPreset('1 Minggu', now.add(const Duration(days: 7))),
    ];

    if (!mounted) return;
    final picked = await showModalBottomSheet<_ReminderChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Set Pengingat'),
              dense: true,
            ),
            const Divider(),
            ...choices.map(
              (c) => ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(c.label),
                trailing: Text(
                  '${c.time.day}/${c.time.month}/${c.time.year} '
                  '${c.time.hour.toString().padLeft(2, '0')}:'
                  '${c.time.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () => Navigator.pop(context, _ReminderChoice.preset(c)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Pilih Tanggal & Waktu'),
              onTap: () => Navigator.pop(context, const _ReminderChoice.custom()),
            ),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;

    late DateTime selected;
    if (picked.isCustom) {
      final date = await showDatePicker(
        context: context,
        initialDate: now.add(const Duration(days: 1)),
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
      );
      if (date == null || !mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );
      if (time == null || !mounted) return;
      selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    } else {
      selected = picked.time;
    }

    if (mounted) {
      await context.read<SpotProvider>().setReminder(spot, selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pengingat dijadwalkan: '
              '${selected.day}/${selected.month}/${selected.year} '
              '${selected.hour.toString().padLeft(2, '0')}:'
              '${selected.minute.toString().padLeft(2, '0')}',
            ),
          ),
        );
        _loadSpot();
      }
    }
  }

  Future<void> _clearReminder(Spot spot) async {
    await context.read<SpotProvider>().setReminder(spot, null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengingat dibatalkan.')),
      );
      _loadSpot();
    }
  }

  Future<void> _openMaps(Spot spot) async {
    final url = spot.toMapsDirectionsUrl();
    if (url == null) return;
    bool success;
    if (spot.latitude != null && spot.longitude != null) {
      success = await MapsService.instance
          .openDirections(spot.latitude!, spot.longitude!);
    } else {
      success = await MapsService.instance.openUrl(url);
    }
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 16, color: color ?? theme.colorScheme.outline),
      label: Text(label, style: TextStyle(color: color)),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Quick-pick reminder preset shown in the bottom sheet.
class _ReminderPreset {
  final String label;
  final DateTime time;
  const _ReminderPreset(this.label, this.time);
}

/// Result of the reminder picker bottom sheet.
class _ReminderChoice {
  final _ReminderPreset? preset;
  final bool isCustom;

  const _ReminderChoice.preset(this.preset) : isCustom = false;
  const _ReminderChoice.custom()
      : preset = null,
        isCustom = true;

  DateTime get time => preset!.time;
}

/// Card showing the active reminder with a clear button.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminderAt,
    required this.onClear,
  });

  final String reminderAt;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dt = DateTime.tryParse(reminderAt);
    final formatted = dt != null
        ? '${dt.day}/${dt.month}/${dt.year} '
            '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}'
        : reminderAt;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.notifications_active, color: AppColors.warning),
        title: Text('Pengingat aktif', style: theme.textTheme.bodyMedium),
        subtitle: Text(formatted, style: theme.textTheme.titleSmall),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Batalkan pengingat',
          onPressed: onClear,
        ),
      ),
    );
  }
}
