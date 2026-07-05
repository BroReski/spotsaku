/// Detail screen for a single spot.
///
/// Shows a hero image, the spot's name, category & status labels, rating
/// (editable when visited), review text, edit/delete actions, and a
/// floating "Buka Rute di Google Maps" button.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/spot.dart';
import '../../utils/maps_service.dart';
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
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
