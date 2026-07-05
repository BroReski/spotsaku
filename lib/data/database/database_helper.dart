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
        createdAt   TEXT    NOT NULL,
        updatedAt   TEXT    NOT NULL
      )
    ''');
  }

  /// Handles future schema migrations.
  ///
  /// The current schema is the final v1 design (including `rating` and
  /// `updatedAt`), so no migration steps are needed yet. New columns can
  /// be added here with `ALTER TABLE` when the version is bumped.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Intentionally empty: v1 is the initial release. Add ALTER TABLE
    // statements here as the schema evolves (e.g. for v2).
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
  Future<Map<String, Object?>> querySpotById(int id) async {
    final db = await database();
    final rows = await db.query(
      AppDatabase.tableSpots,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
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
