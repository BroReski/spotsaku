/// Low-level SQLite access for SpotSaku.
///
/// Exposes a singleton [DatabaseHelper] that lazily opens the local
/// database, creates/migrates the [spots] table, and provides raw CRUD
/// operations. The repository layer ([SpotRepository]) wraps these calls
/// with domain-friendly signatures.
library;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../utils/constants.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  /// Opens (and lazily creates) the database.
  ///
  /// The database file lives in the app's documents directory so it
  /// persists across launches and survives app restarts.
  Future<Database> database() async {
    if (_db != null) return _db!;
    final docsDir = await getApplicationDocumentsDirectory();
    final path = p.join(docsDir.path, AppDatabase.dbName);
    _db = await openDatabase(
      path,
      version: AppDatabase.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  /// Creates the schema on first install.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppDatabase.tableSpots} (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        category    TEXT    NOT NULL DEFAULT '',
        latitude    REAL,
        longitude   REAL,
        mapsUrl     TEXT,
        photoPath   TEXT,
        notes       TEXT,
        rating      INTEGER,
        isVisited   INTEGER NOT NULL DEFAULT 0,
        reminderAt  TEXT,
        createdAt   TEXT    NOT NULL,
        updatedAt   TEXT    NOT NULL
      )
    ''');
  }

  /// Handles future schema migrations.
  ///
  /// v1 → v2: adds the `reminderAt` column for scheduled notification
  /// reminders.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${AppDatabase.tableSpots} ADD COLUMN reminderAt TEXT',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CRUD helpers (raw). Domain logic lives in SpotRepository.
  // ---------------------------------------------------------------------------

  /// Inserts a spot and returns the generated row id.
  Future<int> insertSpot(Map<String, Object?> values) async {
    final db = await database();
    return db.insert(AppDatabase.tableSpots, values);
  }

  /// Returns all spots ordered by most-recently-updated first.
  Future<List<Map<String, Object?>>> queryAllSpots() async {
    final db = await database();
    return db.query(
      AppDatabase.tableSpots,
      orderBy: 'updatedAt DESC',
    );
  }

  /// Returns a single spot by id.
  ///
  /// Throws a [StateError] (wrapped as an [Exception]) when no row matches
  /// [id], so callers can present a friendly "spot tidak ditemukan" message
  /// instead of crashing on `rows.first`.
  Future<Map<String, Object?>> querySpotById(int id) async {
    final db = await database();
    final rows = await db.query(
      AppDatabase.tableSpots,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('Spot tidak ditemukan');
    }
    return rows.first;
  }

  /// Updates a spot by id. Returns the number of affected rows.
  Future<int> updateSpot(int id, Map<String, Object?> values) async {
    final db = await database();
    return db.update(
      AppDatabase.tableSpots,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a spot by id. Returns the number of affected rows.
  Future<int> deleteSpot(int id) async {
    final db = await database();
    return db.delete(
      AppDatabase.tableSpots,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns the count of visited spots (isVisited = 1).
  Future<int> countVisited() async {
    final db = await database();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) FROM ${AppDatabase.tableSpots} WHERE isVisited = 1',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Returns the count of wishlist spots (isVisited = 0).
  Future<int> countWishlist() async {
    final db = await database();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) FROM ${AppDatabase.tableSpots} WHERE isVisited = 0',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Returns the total number of saved spots.
  Future<int> countAll() async {
    final db = await database();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) FROM ${AppDatabase.tableSpots}',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Closes the database. Mainly useful for tests.
  Future<void> close() async {
    final db = _db;
    if (db != null && db.isOpen) {
      await db.close();
      _db = null;
    }
  }
}
