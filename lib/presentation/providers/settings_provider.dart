/// User settings: notification toggles + export actions. Persisted via
/// `shared_preferences`.
library;

import 'package:flutter/foundation.dart';

import '../../data/repositories/spot_repository.dart';
import '../../utils/constants.dart';
import '../../utils/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SpotRepository? repository})
      : _repo = repository ?? SpotRepository();

  final SpotRepository _repo;

  bool _notificationsEnabled = true;
  bool _isLoading = false;
  String? _lastExportPath;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoading => _isLoading;
  String? get lastExportPath => _lastExportPath;

  /// Loads saved settings on app start.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(AppPrefs.notificationsEnabled) ?? true;
    notifyListeners();
  }

  /// Toggles the reminder-notification feature and persists the choice.
  ///
  /// When toggled off, all scheduled reminders are cancelled so the user
  /// is not surprised by notifications after disabling the feature.
  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPrefs.notificationsEnabled, _notificationsEnabled);
    if (!_notificationsEnabled) {
      await NotificationService.instance.cancelAllReminders();
    }
  }

  /// Exports all spots as CSV. Returns the absolute file path.
  Future<String> exportCsv() async {
    _isLoading = true;
    notifyListeners();
    try {
      final csv = await _repo.toCsv();
      final stamp = _fileStamp();
      final path = await _repo.exportToFile(csv, 'spotsaku_backup_$stamp.csv');
      _lastExportPath = path;
      return path;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Exports all spots as JSON. Returns the absolute file path.
  Future<String> exportJson() async {
    _isLoading = true;
    notifyListeners();
    try {
      final json = await _repo.toJson();
      final stamp = _fileStamp();
      final path = await _repo.exportToFile(json, 'spotsaku_backup_$stamp.json');
      _lastExportPath = path;
      return path;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Imports spots from a backup file (.csv or .json). Returns the number
  /// of spots imported. The caller is responsible for refreshing the
  /// SpotProvider list afterwards.
  Future<int> importData(String filePath) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _repo.importFromFile(filePath);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static String _fileStamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}';
  }
}
