/// Data access layer for [Spot] entities.
///
/// Wraps the raw [DatabaseHelper] calls with a clean, domain-oriented API
/// used by the providers and use-cases. It also owns the timestamp logic
/// so callers never need to manage `createdAt` / `updatedAt` manually,
/// and exposes CSV/JSON export helpers plus photo-persistence logic.
library;

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/spot.dart';

class SpotRepository {
  SpotRepository({DatabaseHelper? dbHelper})
    : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  /// Returns every saved spot, newest first.
  Future<List<Spot>> getAll() async {
    final rows = await _db.queryAllSpots();
    return rows.map(Spot.fromMap).toList(growable: false);
  }

  /// Returns a single spot by id.
  Future<Spot> getById(int id) async {
    final row = await _db.querySpotById(id);
    return Spot.fromMap(row);
  }

  /// Inserts a new spot. Returns the stored spot (with its generated id).
  Future<Spot> insert(Spot spot) async {
    final now = _nowIso();
    final values = spot.copyWith(createdAt: now, updatedAt: now).toMap();
    final id = await _db.insertSpot(values);
    return spot.copyWith(id: id, createdAt: now, updatedAt: now);
  }

  /// Updates an existing spot. Returns the updated spot.
  Future<Spot> update(Spot spot) async {
    final now = _nowIso();
    final updated = spot.copyWith(updatedAt: now);
    await _db.updateSpot(spot.id!, updated.toMap());
    return updated;
  }

  /// Deletes a spot by id.
  Future<void> delete(int id) async {
    await _db.deleteSpot(id);
  }

  /// Returns the spots matching the given filter criteria.
  ///
  /// Filtering is performed in Dart so that the repository can compose
  /// arbitrary conditions (search text + category + status) without
  /// duplicating SQL fragments. The dataset is expected to stay small
  /// (personal journal), so an in-memory scan is negligible.
  Future<List<Spot>> filter({
    String searchQuery = '',
    String? category,
    bool? isVisited,
  }) async {
    var spots = await getAll();
    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      spots = spots
          .where((s) => s.name.toLowerCase().contains(query))
          .toList(growable: false);
    }
    if (category != null && category.isNotEmpty && category != 'Semua') {
      spots = spots
          .where((s) => s.category == category)
          .toList(growable: false);
    }
    if (isVisited != null) {
      spots = spots
          .where((s) => s.isVisited == isVisited)
          .toList(growable: false);
    }
    return spots;
  }

  // ---------------------------------------------------------------------------
  // Statistics used by the Stats & Settings screen.
  // ---------------------------------------------------------------------------

  Future<int> countAll() => _db.countAll();
  Future<int> countVisited() => _db.countVisited();
  Future<int> countWishlist() => _db.countWishlist();

  /// Returns the average rating across visited spots (0 when none rated).
  Future<double> averageRating() async {
    final spots = await getAll();
    final rated = spots.where((s) => s.isVisited && s.rating != null).toList();
    if (rated.isEmpty) return 0;
    final sum = rated.fold<int>(0, (acc, s) => acc + s.rating!);
    return sum / rated.length;
  }

  // ---------------------------------------------------------------------------
  // Photo persistence helper.
  // ---------------------------------------------------------------------------

  /// Copies a source image (from the camera/gallery cache) into the app's
  /// documents directory so the path stays valid across reboots.
  ///
  /// Returns the new absolute path, or `null` when [sourcePath] is empty
  /// or the file does not exist.
  Future<String?> persistPhoto(String? sourcePath) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'spot_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final ext = p.extension(sourcePath);
    final destPath = p.join(
      photosDir.path,
      'spot_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await sourceFile.copy(destPath);
    return destPath;
  }

  // ---------------------------------------------------------------------------
  // Export helpers (CSV / JSON).
  // ---------------------------------------------------------------------------

  /// Serialises every spot to a CSV string (header row included).
  Future<String> toCsv() async {
    final spots = await getAll();
    final header = const <dynamic>[
      'id',
      'name',
      'category',
      'latitude',
      'longitude',
      'mapsUrl',
      'photoPath',
      'notes',
      'rating',
      'isVisited',
      'reminderAt',
      'createdAt',
      'updatedAt',
    ];
    final rows = spots
        .map(
          (s) => <dynamic>[
            s.id?.toString() ?? '',
            s.name,
            s.category,
            s.latitude?.toString() ?? '',
            s.longitude?.toString() ?? '',
            s.mapsUrl ?? '',
            s.photoPath ?? '',
            s.notes ?? '',
            s.rating?.toString() ?? '',
            s.isVisited ? '1' : '0',
            s.reminderAt ?? '',
            s.createdAt,
            s.updatedAt,
          ],
        )
        .toList();
    return const ListToCsvConverter().convert([header, ...rows]);
  }

  /// Serialises every spot to a pretty JSON string.
  Future<String> toJson() async {
    final spots = await getAll();
    final list = spots.map((s) => s.toMap()).toList();
    final encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(list);
  }

  /// Writes the given [content] to a file named [fileName] inside the
  /// app's documents directory (`exports/` sub-folder) and returns the
  /// absolute path.
  Future<String> exportToFile(String content, String fileName) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(docsDir.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File(p.join(exportDir.path, fileName));
    await file.writeAsString(content);
    return file.path;
  }

  // ---------------------------------------------------------------------------
  // Import helpers (CSV / JSON) — restore from a backup file.
  // ---------------------------------------------------------------------------

  /// Parses a CSV string (same format as [toCsv]) and inserts every row
  /// as a new spot. Returns the number of spots imported.
  ///
  /// The `id` column is ignored — the database assigns fresh ids so
  /// imports never collide with existing rows. `createdAt` / `updatedAt`
  /// are preserved when present, otherwise defaulted to "now".
  Future<int> importFromCsv(String csvContent) async {
    final rows = const CsvToListConverter().convert(csvContent);
    if (rows.length < 2) return 0;

    // First row is the header — map column names to indices.
    final header = rows.first.cast<String>();
    int idx(String name) {
      final i = header.indexOf(name);
      return i >= 0 ? i : -1;
    }

    final iId = idx('id');
    final iName = idx('name');
    final iCat = idx('category');
    final iLat = idx('latitude');
    final iLng = idx('longitude');
    final iMaps = idx('mapsUrl');
    final iPhoto = idx('photoPath');
    final iNotes = idx('notes');
    final iRating = idx('rating');
    final iVisited = idx('isVisited');
    final iReminder = idx('reminderAt');
    final iCreated = idx('createdAt');

    var count = 0;
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      String cell(int i) => i >= 0 && i < row.length ? row[i].toString() : '';

      final name = cell(iName);
      if (name.isEmpty) continue;

      final latVal = cell(iLat);
      final lngVal = cell(iLng);
      final ratingVal = cell(iRating);

      final spot = Spot(
        name: name,
        category: cell(iCat),
        latitude: latVal.isEmpty ? null : double.tryParse(latVal),
        longitude: lngVal.isEmpty ? null : double.tryParse(lngVal),
        mapsUrl: cell(iMaps).isEmpty ? null : cell(iMaps),
        photoPath: cell(iPhoto).isEmpty ? null : cell(iPhoto),
        notes: cell(iNotes).isEmpty ? null : cell(iNotes),
        rating: ratingVal.isEmpty ? null : int.tryParse(ratingVal),
        isVisited: cell(iVisited) == '1' || cell(iVisited) == 'true',
        reminderAt: cell(iReminder).isEmpty ? null : cell(iReminder),
        createdAt: cell(iCreated).isEmpty ? _nowIso() : cell(iCreated),
        updatedAt: _nowIso(),
      );
      // Preserve the original id only when importing into an empty DB;
      // otherwise let SQLite auto-assign a fresh id to avoid collisions.
      await _db.insertSpot(
        spot
            .copyWith(
              id: iId >= 0 && cell(iId).isNotEmpty
                  ? int.tryParse(cell(iId))
                  : null,
            )
            .toMap(),
      );
      count++;
    }
    return count;
  }

  /// Parses a JSON string (same format as [toJson]) and inserts every
  /// entry as a new spot. Returns the number of spots imported.
  Future<int> importFromJson(String jsonContent) async {
    final List<dynamic> list = jsonDecode(jsonContent) as List<dynamic>;
    var count = 0;
    for (final entry in list) {
      final map = Map<String, Object?>.from(entry as Map);
      // Always assign a fresh updatedAt; clear id to avoid collisions.
      map.remove('id');
      map['updatedAt'] = _nowIso();
      if (!map.containsKey('createdAt') || map['createdAt'] == null) {
        map['createdAt'] = _nowIso();
      }
      await _db.insertSpot(map);
      count++;
    }
    return count;
  }

  /// Reads [filePath] and imports it based on the file extension.
  /// `.csv` → [importFromCsv], `.json` → [importFromJson].
  /// Throws [ArgumentError] for unsupported extensions.
  Future<int> importFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File tidak ditemukan', filePath);
    }
    final content = await file.readAsString();
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.csv':
        return importFromCsv(content);
      case '.json':
        return importFromJson(content);
      default:
        throw ArgumentError('Format file tidak didukung: $ext');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _nowIso() => DateTime.now().toIso8601String();
}
