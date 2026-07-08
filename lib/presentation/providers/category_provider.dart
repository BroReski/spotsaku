/// State management for spot categories.
///
/// Maintains the predefined list plus any user-added custom labels,
/// persisted across launches via `shared_preferences`. The merged list
/// is exposed for the Home screen chips and the Add/Edit dropdown.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/constants.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider();

  static const _prefsKey = 'customCategories';

  final List<String> _custom = [];

  /// All categories available for selection: predefined first, then custom.
  List<String> get all => [...AppCategories.predefined, ..._custom];

  /// The chip list for the Home screen ("Semua" + all categories).
  List<String> get chips => [AppCategories.all, ...all];

  /// Loads persisted custom categories on app start.
  Future<void> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_prefsKey) ?? const [];
    _custom
      ..clear()
      ..addAll(encoded);
    notifyListeners();
  }

  /// Adds a new custom category. Returns `false` (without adding) when the
  /// label is empty or already exists (case-insensitive).
  Future<bool> addCategory(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return false;

    final exists = all.any((c) => c.toLowerCase() == trimmed.toLowerCase());
    if (exists) return false;

    _custom.add(trimmed);
    await _persist();
    notifyListeners();
    return true;
  }

  /// Removes a custom category by label. Predefined labels cannot be removed.
  /// Returns `true` when a custom label was actually removed.
  Future<bool> removeCategory(String label) async {
    final removed = _custom.remove(label);
    if (removed) {
      await _persist();
      notifyListeners();
    }
    return removed;
  }

  /// Whether [label] is a user-defined (custom) category.
  bool isCustom(String label) => _custom.contains(label);

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _custom);
  }
}
