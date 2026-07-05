/// Application-wide constants: category definitions and storage keys.
library;

/// Predefined category labels shown as filter chips on the Home screen.
///
/// Users may also add custom category labels when creating a spot; those
/// are stored verbatim in the database and merged into the chip list at
/// runtime.
class AppCategories {
  AppCategories._();

  /// Label representing "no filter" on the Home screen.
  static const String all = 'Semua';

  /// Default categories offered in the Add/Edit form dropdown.
  static const List<String> predefined = [
    'Restoran',
    'Kafe',
    'Wisata',
    'Alam',
    'Lainnya',
  ];

  /// Returns the list of chips shown on the Home screen, with [all] first.
  static List<String> get chips => [all, ...predefined];
}

/// Keys used with `shared_preferences` for persisting user settings.
class AppPrefs {
  AppPrefs._();

  static const String isDarkMode = 'isDarkMode';
  static const String notificationsEnabled = 'notificationsEnabled';
}

/// Database constants.
class AppDatabase {
  AppDatabase._();

  static const String dbName = 'spotsaku.db';
  static const int dbVersion = 1;
  static const String tableSpots = 'spots';
}
