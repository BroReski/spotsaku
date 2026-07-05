/// Add / Edit Spot form screen.
///
/// Lets the user capture/select a photo, grab GPS coordinates or paste a
/// Maps URL, enter a name, choose a category, toggle visited status, and
/// (when visited) give a rating. Saves via [SpotProvider].
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/spot.dart';
import '../../utils/constants.dart';
import '../../utils/location_service.dart';
import '../../utils/media_service.dart';
import '../providers/spot_provider.dart';
import '../widgets/star_rating.dart';

class AddEditScreen extends StatefulWidget {
  const AddEditScreen({super.key, this.spot});

  /// When non-null, the form is in "edit" mode and pre-fills the fields.
  final Spot? spot;

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _mapsUrlController = TextEditingController();

  String? _photoPath;
  double? _latitude;
  double? _longitude;
  String _category = AppCategories.predefined.first;
  bool _isVisited = false;
  int? _rating;
  bool _isSaving = false;
  bool _isFetchingLocation = false;

  bool get _isEditing => widget.spot != null;

  @override
  void initState() {
    super.initState();
    if (widget.spot != null) {
      final s = widget.spot!;
      _nameController.text = s.name;
      _notesController.text = s.notes ?? '';
      _mapsUrlController.text = s.mapsUrl ?? '';
      _photoPath = s.photoPath;
      _latitude = s.latitude;
      _longitude = s.longitude;
      _category = s.category;
      _isVisited = s.isVisited;
      _rating = s.rating;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _mapsUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Spot' : 'Tambah Spot Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Photo picker ---
            _PhotoPicker(
              photoPath: _photoPath,
              onTap: _showPhotoSourceSheet,
            ),
            const SizedBox(height: 16),
            // --- Name ---
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Tempat',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            // --- Category dropdown ---
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              items: AppCategories.predefined
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            // --- Location section ---
            Text('Lokasi', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _isFetchingLocation ? null : _getCurrentLocation,
              icon: _isFetchingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Dapatkan Lokasi Saat Ini'),
            ),
            if (_latitude != null && _longitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Koordinat: ${_latitude!.toStringAsFixed(6)}, '
                  '${_longitude!.toStringAsFixed(6)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mapsUrlController,
              decoration: const InputDecoration(
                labelText: 'Tempel Tautan Maps (opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
                hintText: 'https://maps.app.goo.gl/...',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            // --- Notes / review ---
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan / Review',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // --- Visited toggle ---
            SwitchListTile(
              title: const Text('Sudah Dikunjungi'),
              subtitle: Text(
                _isVisited
                    ? 'Spot ini telah dikunjungi'
                    : 'Masih dalam wishlist',
                style: theme.textTheme.bodySmall,
              ),
              value: _isVisited,
              onChanged: (v) => setState(() {
                _isVisited = v;
                if (!v) _rating = null;
              }),
            ),
            // --- Rating (only when visited) ---
            if (_isVisited) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Rating: '),
                  StarRating(
                    rating: _rating,
                    onRatingChanged: (v) => setState(() => _rating = v),
                  ),
                  if (_rating != null)
                    TextButton(
                      onPressed: () => setState(() => _rating = null),
                      child: const Text('Hapus'),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            // --- Save button ---
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Spot'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _showPhotoSourceSheet() async {
    final provider = context.read<SpotProvider>();
    final source = await showModalBottomSheet<ImageSourceChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Buka Kamera'),
              onTap: () => Navigator.pop(context, ImageSourceChoice.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSourceChoice.gallery),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Foto'),
                onTap: () => Navigator.pop(context, ImageSourceChoice.remove),
              ),
          ],
        ),
      ),
    );

    String? path;
    switch (source) {
      case ImageSourceChoice.camera:
        path = await MediaService.instance.takePhoto();
        break;
      case ImageSourceChoice.gallery:
        path = await MediaService.instance.pickFromGallery();
        break;
      case ImageSourceChoice.remove:
        setState(() => _photoPath = null);
        return;
      case null:
        return;
    }
    if (path != null) {
      final persisted = await provider.persistPhoto(path);
      if (!mounted) return;
      setState(() => _photoPath = persisted ?? path);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final result = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;
      if (result is LocationSuccess) {
        setState(() {
          _latitude = result.latitude;
          _longitude = result.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi berhasil didapatkan!')),
        );
      } else {
        final msg = (result as dynamic).message as String;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final provider = context.read<SpotProvider>();
      final spot = Spot(
        id: widget.spot?.id,
        name: _nameController.text.trim(),
        category: _category,
        latitude: _latitude,
        longitude: _longitude,
        mapsUrl: _mapsUrlController.text.trim().isEmpty
            ? null
            : _mapsUrlController.text.trim(),
        photoPath: _photoPath,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        rating: _rating,
        isVisited: _isVisited,
        createdAt: widget.spot?.createdAt ?? '',
        updatedAt: '',
      );

      if (_isEditing) {
        await provider.updateSpot(spot);
      } else {
        await provider.addSpot(spot);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Spot diperbarui' : 'Spot disimpan')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

enum ImageSourceChoice { camera, gallery, remove }

/// Image picker tile widget.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photoPath, required this.onTap});

  final String? photoPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          image: hasPhoto
              ? DecorationImage(
                  image: FileImage(File(photoPath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasPhoto
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 40, color: theme.colorScheme.outline),
                  const SizedBox(height: 8),
                  Text('Tambah Foto',
                      style: TextStyle(color: theme.colorScheme.outline)),
                ],
              ),
      ),
    );
  }
}
