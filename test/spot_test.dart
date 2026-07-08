// Unit tests for the [Spot] model and SpotRepository filter logic.
//
// These cover the serialisation round-trip (toMap/fromMap), the
// clearable `reminderAt` field in copyWith, and the in-memory filter
// used by the Home screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:spotsaku/data/models/spot.dart';

void main() {
  group('Spot model', () {
    test('toMap/fromMap round-trip preserves all fields', () {
      final spot = Spot(
        id: 1,
        name: 'Sunset Point',
        category: 'Pemandangan',
        latitude: -7.9666,
        longitude: 112.6326,
        mapsUrl: 'https://maps.app.goo.gl/test',
        photoPath: '/photos/spot_1.jpg',
        notes: 'Tempat terbaik untuk sunset',
        rating: 5,
        isVisited: true,
        reminderAt: '2026-07-10T09:00:00.000',
        createdAt: '2026-07-07T10:00:00.000',
        updatedAt: '2026-07-07T10:00:00.000',
      );

      final map = spot.toMap();
      final restored = Spot.fromMap(map);

      expect(restored.id, 1);
      expect(restored.name, 'Sunset Point');
      expect(restored.category, 'Pemandangan');
      expect(restored.latitude, -7.9666);
      expect(restored.longitude, 112.6326);
      expect(restored.mapsUrl, 'https://maps.app.goo.gl/test');
      expect(restored.photoPath, '/photos/spot_1.jpg');
      expect(restored.notes, 'Tempat terbaik untuk sunset');
      expect(restored.rating, 5);
      expect(restored.isVisited, isTrue);
      expect(restored.reminderAt, '2026-07-10T09:00:00.000');
      expect(restored.createdAt, '2026-07-07T10:00:00.000');
      expect(restored.updatedAt, '2026-07-07T10:00:00.000');
    });

    test('copyWith keeps unspecified fields unchanged', () {
      final spot = Spot(
        id: 1,
        name: 'Cafe Kopi',
        category: 'Kuliner',
        isVisited: false,
        reminderAt: '2026-07-10T09:00:00.000',
        createdAt: '2026-07-07T10:00:00.000',
        updatedAt: '2026-07-07T10:00:00.000',
      );

      final updated = spot.copyWith(name: 'Cafe Kopi Senja');

      expect(updated.id, 1);
      expect(updated.name, 'Cafe Kopi Senja');
      expect(updated.category, 'Kuliner');
      expect(updated.isVisited, isFalse);
      expect(updated.reminderAt, '2026-07-10T09:00:00.000');
    });

    test('copyWith can explicitly clear reminderAt', () {
      final spot = Spot(
        id: 1,
        name: 'Pantai Kuta',
        category: 'Pantai',
        isVisited: false,
        reminderAt: '2026-07-10T09:00:00.000',
        createdAt: '2026-07-07T10:00:00.000',
        updatedAt: '2026-07-07T10:00:00.000',
      );

      // Passing null explicitly should clear the reminder.
      final cleared = spot.copyWith(reminderAt: null);

      expect(cleared.reminderAt, isNull);
      // Other fields must be untouched.
      expect(cleared.name, 'Pantai Kuta');
      expect(cleared.id, 1);
    });

    test('toMapsDirectionsUrl prefers GPS coordinates', () {
      final withGps = Spot(
        id: 1,
        name: 'Gunung Bromo',
        category: 'Pemandangan',
        latitude: -7.9425,
        longitude: 112.9530,
        mapsUrl: 'https://maps.app.goo.gl/fallback',
        isVisited: false,
        createdAt: '',
        updatedAt: '',
      );
      final url = withGps.toMapsDirectionsUrl();
      expect(url, contains('-7.9425'));
      expect(url, contains('112.953'));
      expect(url, contains('dir/?api=1'));
    });

    test('toMapsDirectionsUrl falls back to mapsUrl when no GPS', () {
      final noGps = Spot(
        id: 2,
        name: 'Spot Manual',
        category: 'Lainnya',
        mapsUrl: 'https://maps.app.goo.gl/manual',
        isVisited: false,
        createdAt: '',
        updatedAt: '',
      );
      expect(noGps.toMapsDirectionsUrl(), 'https://maps.app.goo.gl/manual');
    });

    test('toMapsDirectionsUrl returns null when no location data', () {
      final empty = Spot(
        id: 3,
        name: 'Tanpa Lokasi',
        category: 'Lainnya',
        isVisited: false,
        createdAt: '',
        updatedAt: '',
      );
      expect(empty.toMapsDirectionsUrl(), isNull);
    });
  });

  group('in-memory filter logic', () {
    // Re-implements the same predicate SpotRepository.filter() uses, so we
    // can test the logic without a real SQLite database.
    final sample = <Spot>[
      Spot(
        id: 1,
        name: 'Pantai Kuta',
        category: 'Pantai',
        isVisited: true,
        rating: 5,
        createdAt: '',
        updatedAt: '',
      ),
      Spot(
        id: 2,
        name: 'Cafe Senja',
        category: 'Kuliner',
        isVisited: false,
        createdAt: '',
        updatedAt: '',
      ),
      Spot(
        id: 3,
        name: 'Gunung Bromo',
        category: 'Pemandangan',
        isVisited: true,
        rating: 4,
        createdAt: '',
        updatedAt: '',
      ),
    ];

    List<Spot> applyFilter({
      String searchQuery = '',
      String category = 'Semua',
      bool? isVisited,
    }) {
      var spots = sample.toList();
      final query = searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        spots = spots
            .where((s) => s.name.toLowerCase().contains(query))
            .toList();
      }
      if (category != 'Semua') {
        spots = spots.where((s) => s.category == category).toList();
      }
      if (isVisited != null) {
        spots = spots.where((s) => s.isVisited == isVisited).toList();
      }
      return spots;
    }

    test('no filters returns all spots', () {
      expect(applyFilter().length, 3);
    });

    test('search by name (case-insensitive)', () {
      final result = applyFilter(searchQuery: 'senja');
      expect(result.length, 1);
      expect(result.first.name, 'Cafe Senja');
    });

    test('filter by category', () {
      final result = applyFilter(category: 'Pantai');
      expect(result.length, 1);
      expect(result.first.name, 'Pantai Kuta');
    });

    test('filter by visited status', () {
      final visited = applyFilter(isVisited: true);
      expect(visited.length, 2);
      final wishlist = applyFilter(isVisited: false);
      expect(wishlist.length, 1);
      expect(wishlist.first.name, 'Cafe Senja');
    });

    test('combined search + status filter', () {
      final result = applyFilter(searchQuery: 'bromo', isVisited: true);
      expect(result.length, 1);
      expect(result.first.name, 'Gunung Bromo');
    });
  });
}
