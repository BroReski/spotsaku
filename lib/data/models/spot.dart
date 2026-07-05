/// Data model representing a saved location ("spot") in SpotSaku.
///
/// Each field maps to a column in the local SQLite database (see
/// [DatabaseHelper]). The model is immutable; mutations produce a new
/// instance via [copyWith].
library;

/// A single saved location entry.
class Spot {
  /// Primary key. `null` until the row has been inserted into the database.
  final int? id;

  /// User-given name of the place (e.g. "Sunset Point Pananjakan").
  final String name;

  /// Category label. May be one of [AppCategories.predefined] or a custom
  /// label supplied by the user.
  final String category;

  /// GPS latitude captured via `geolocator`. `null` when the user only
  /// provided a manual [mapsUrl].
  final double? latitude;

  /// GPS longitude captured via `geolocator`. `null` when the user only
  /// provided a manual [mapsUrl].
  final double? longitude;

  /// Optional manually pasted Google Maps URL. Used as a fallback when
  /// GPS coordinates are unavailable.
  final String? mapsUrl;

  /// Local file path of the representative photo. The image is copied into
  /// the app's documents directory by the repository so the path remains
  /// valid across reboots.
  final String? photoPath;

  /// Free-form notes / review written by the user.
  final String? notes;

  /// Star rating from 1 to 5. `null` when the spot is still a wishlist
  /// item (not yet visited) or has not been rated.
  final int? rating;

  /// Visit status. `false` (0) = Wishlist, `true` (1) = Sudah Dikunjungi.
  final bool isVisited;

  /// ISO-8601 timestamp of when the spot was first created.
  final String createdAt;

  /// ISO-8601 timestamp of the most recent update.
  final String updatedAt;

  const Spot({
    this.id,
    required this.name,
    required this.category,
    this.latitude,
    this.longitude,
    this.mapsUrl,
    this.photoPath,
    this.notes,
    this.rating,
    required this.isVisited,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [Spot] from a row returned by `sqflite`.
  factory Spot.fromMap(Map<String, Object?> map) {
    return Spot(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      mapsUrl: map['mapsUrl'] as String?,
      photoPath: map['photoPath'] as String?,
      notes: map['notes'] as String?,
      rating: map['rating'] as int?,
      isVisited: (map['isVisited'] as int?) == 1,
      createdAt: map['createdAt'] as String? ?? '',
      updatedAt: map['updatedAt'] as String? ?? '',
    );
  }

  /// Serialises the spot into a row suitable for `sqflite` insert/update.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'mapsUrl': mapsUrl,
      'photoPath': photoPath,
      'notes': notes,
      'rating': rating,
      'isVisited': isVisited ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Returns a copy of this spot with the given fields replaced.
  Spot copyWith({
    int? id,
    String? name,
    String? category,
    double? latitude,
    double? longitude,
    String? mapsUrl,
    String? photoPath,
    String? notes,
    int? rating,
    bool? isVisited,
    String? createdAt,
    String? updatedAt,
  }) {
    return Spot(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      isVisited: isVisited ?? this.isVisited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Builds a Google Maps directions URL for this spot.
  ///
  /// Prefers stored GPS coordinates; falls back to a manually pasted
  /// [mapsUrl] when coordinates are absent. Returns `null` when neither
  /// is available.
  String? toMapsDirectionsUrl() {
    if (latitude != null && longitude != null) {
      // Universal URL — opens the native app if installed, otherwise the
      // browser. Uses the user's current location as origin (omitted) so
      // Maps will use the device location automatically.
      return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    }
    return mapsUrl;
  }
}
