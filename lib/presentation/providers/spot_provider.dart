/// Central state for the spot list: owns the loaded spots, the active
/// search/filter state, and exposes CRUD operations that the UI triggers.
library;

import 'package:flutter/foundation.dart';

import '../../data/models/spot.dart';
import '../../data/repositories/spot_repository.dart';
import '../../utils/notification_service.dart';

class SpotProvider extends ChangeNotifier {
  SpotProvider({SpotRepository? repository})
      : _repo = repository ?? SpotRepository();

  final SpotRepository _repo;

  // --- State ---------------------------------------------------------------

  List<Spot> _spots = const [];
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool? _statusFilter; // null = no status filter
  bool _isLoading = false;
  String? _error;

  /// Whether only wishlist spots should be shown.
  bool? get statusFilter => _statusFilter;

  /// Currently active category chip (defaults to "Semua" = all).
  String get selectedCategory => _selectedCategory;

  /// Current search text.
  String get searchQuery => _searchQuery;

  /// The filtered list currently displayed on the Home screen.
  List<Spot> get spots => _spots;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Lifecycle ------------------------------------------------------------

  /// Loads spots from the database and applies the current filters.
  /// Called on app start and after every mutation.
  Future<void> loadSpots() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _spots = await _repo.filter(
        searchQuery: _searchQuery,
        category: _selectedCategory,
        isVisited: _statusFilter,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Single-spot access ---------------------------------------------------

  /// Returns a single spot by id (used by the Detail screen).
  Future<Spot> getSpotById(int id) => _repo.getById(id);

  /// Persists a photo into the app directory (used by the Add/Edit form).
  Future<String?> persistPhoto(String? sourcePath) =>
      _repo.persistPhoto(sourcePath);

  // --- Mutations ------------------------------------------------------------

  /// Inserts a new spot and refreshes the list.
  Future<void> addSpot(Spot spot) async {
    await _repo.insert(spot);
    await loadSpots();
  }

  /// Updates an existing spot and refreshes the list.
  Future<void> updateSpot(Spot spot) async {
    await _repo.update(spot);
    await loadSpots();
  }

  /// Deletes a spot by id and refreshes the list.
  Future<void> deleteSpot(int id) async {
    await _repo.delete(id);
    await loadSpots();
  }

  /// Toggles the visited status of a spot and persists it.
  Future<void> toggleVisited(Spot spot) async {
    await _repo.update(spot.copyWith(isVisited: !spot.isVisited));
    await loadSpots();
  }

  /// Updates the rating of a spot (1-5). Only allowed for visited spots.
  Future<void> setRating(Spot spot, int rating) async {
    if (!spot.isVisited) return;
    final clamped = rating.clamp(1, 5);
    await _repo.update(spot.copyWith(rating: clamped));
    await loadSpots();
  }

  /// Sets or clears a reminder for a spot.
  ///
  /// When [reminderAt] is non-null, schedules a local notification via
  /// [NotificationService] and persists the timestamp. When `null`, any
  /// existing reminder is cancelled and the field is cleared.
  Future<void> setReminder(Spot spot, DateTime? reminderAt) async {
    final id = spot.id;
    if (id == null) return;

    if (reminderAt != null) {
      await NotificationService.instance.scheduleReminder(
        id: id,
        spotName: spot.name,
        scheduledTime: reminderAt,
      );
      await _repo.update(
        spot.copyWith(reminderAt: reminderAt.toIso8601String()),
      );
    } else {
      await NotificationService.instance.cancelReminder(id);
      await _repo.update(spot.copyWith(reminderAt: null));
    }
    await loadSpots();
  }

  // --- Filters --------------------------------------------------------------

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadSpots();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    loadSpots();
  }

  /// Cycles the status filter: `null` -> `false` (wishlist) -> `true`
  /// (visited) -> `null` (all).
  void cycleStatusFilter() {
    if (_statusFilter == null) {
      _statusFilter = false;
    } else if (_statusFilter == false) {
      _statusFilter = true;
    } else {
      _statusFilter = null;
    }
    loadSpots();
  }

  /// Sets the status filter directly. `null` shows all spots, `false`
  /// shows only wishlist, `true` shows only visited.
  void setStatusFilter(bool? status) {
    _statusFilter = status;
    loadSpots();
  }

  // --- Statistics -----------------------------------------------------------

  Future<int> get totalCount => _repo.countAll();
  Future<int> get visitedCount => _repo.countVisited();
  Future<int> get wishlistCount => _repo.countWishlist();
  Future<double> get averageRating => _repo.averageRating();
}
