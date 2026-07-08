# SpotSaku

> Aplikasi Jurnal & Wishlist Tempat — Offline-First Flutter App

## Deskripsi

SpotSaku adalah aplikasi mobile pencatat lokasi personal yang memungkinkan
pengguna merekam penemuan lokasi secara spontan, mengelola wishlist, dan
menyimpan histori kunjungan dengan rapi. Dibangun dengan pendekatan
offline-first (100% berfungsi tanpa internet) dan mengintegrasikan tiga
teknologi inti Mobile Computing: akses sensor GPS, kamera, database lokal,
serta komunikasi antar-aplikasi via intent.

## Latar Belakang

Pengguna sering menemukan rekomendasi lokasi estetik di media sosial dan
menyimpannya via fitur "Save" bawaan platform. Namun, daftar tersebut
bercampur dengan konten lain dan bergantung pada koneksi internet. Lebih
jauh lagi, pengguna sering menemukan spot menarik secara kebetulan saat
bepergian tanpa mengetahui alamat pastinya. SpotSaku mengatasi masalah ini
dengan pencatatan koordinat GPS presisi secara instan dan manajemen
wishlist offline.

## Fitur Utama (Core Features)

- [x] CRUD Manajemen Spot (Tambah, Lihat, Edit, Hapus)
- [x] Live GPS Pinpointing (satu klik, simpan koordinat presisi)
- [x] Direct Camera Capture & Gallery (foto langsung dari kamera HP)
- [x] Kategori & Status Wishlist (custom categories + dropdown filter Wishlist/Visited)
- [x] Pencarian & Penyaringan (search + filter by category & status)
- [x] Notifikasi Pengingat — reminder terjadwal untuk mengunjungi wishlist
- [x] Sistem Penilaian — rating bintang & review untuk spot visited
- [x] Ekspor & Impor Data — backup/restore CSV & JSON secara offline
- [x] Dark Mode — toggle tema gelap/terang dengan persistensi preferensi

## Core Mobile Computing Technologies

1. **Sensor Hardware**: GPS (`geolocator`) & Kamera/Galeri (`image_picker`)
2. **Local Database & State Management**: SQLite (`sqflite`) + Provider (offline-first)
3. **Inter-Process Communication**: `url_launcher` (Google Maps intent) + `flutter_local_notifications` (OS notification scheduling)

## Killer Use Case: Spontaneous Discovery

Pengguna sedang berjalan-jalan, melihat pemandangan sunset yang bagus,
ingin menyimpan lokasi untuk dikunjungi lagi, namun tidak ada internet
dan tidak tahu nama jalan.
**Aksi**: Buka SpotSaku → tap "+" → foto langsung (camera) → tap
"Dapatkan Lokasi Saat Ini" (GPS) → beri nama → simpan.
**Waktu**: <20 detik, 100% offline.
**Nanti**: tap "Buka di Maps" untuk dipandu kembali ke titik tersebut.

---

## Kompatibilitas & Persyaratan (Mobile Phone)

### Android

| Aspek                           | Persyaratan                                                                                            |
| ------------------------------- | ------------------------------------------------------------------------------------------------------ |
| **Minimum Android version**     | Android 5.0 (API 21) — ditentukan oleh `flutter.minSdkVersion`                                         |
| **Target Android version**      | Android 15 (API 35) — ditentukan oleh `flutter.targetSdkVersion`                                       |
| **Compile SDK**                 | `flutter.compileSdkVersion` (default SDK Flutter)                                                      |
| **Kotlin**                      | 2.3.20                                                                                                 |
| **AGP (Android Gradle Plugin)** | 9.0.1                                                                                                  |
| **Java**                        | 17 (dengan core library desugaring)                                                                    |
| **GPS**                         | Wajib — perangkat harus memiliki GPS receiver                                                          |
| **Kamera**                      | Wajib — untuk foto langsung dari aplikasi                                                              |
| **Storage**                     | ~50 MB ruang kosong (APK + foto + database)                                                            |
| **Internet**                    | Tidak wajib — aplikasi 100% offline-first. Internet hanya dibutuhkan untuk membuka rute di Google Maps |

### iOS

| Aspek                   | Persyaratan                        |
| ----------------------- | ---------------------------------- |
| **Minimum iOS version** | iOS 12.0 (default Flutter)         |
| **Xcode**               | 16+                                |
| **GPS**                 | Wajib                              |
| **Kamera**              | Wajib                              |
| **Internet**            | Tidak wajib — sama seperti Android |

### Permissions yang Dibutuhkan

#### Android (`AndroidManifest.xml`)

| Permission               | Kebutuhan                           |
| ------------------------ | ----------------------------------- |
| `ACCESS_FINE_LOCATION`   | GPS presisi untuk koordinat spot    |
| `ACCESS_COARSE_LOCATION` | Lokasi approximasi sebagai fallback |
| `CAMERA`                 | Foto langsung dari kamera           |
| `READ_EXTERNAL_STORAGE`  | Akses galeri (Android < 13)         |
| `WRITE_EXTERNAL_STORAGE` | Penyimpanan foto (Android < 10)     |
| `POST_NOTIFICATIONS`     | Notifikasi pengingat (Android 13+)  |
| `SCHEDULE_EXACT_ALARM`   | Jadwal notifikasi presisi           |
| `USE_EXACT_ALARM`        | Fallback alarm mode                 |
| `INTERNET`               | Buka URL Google Maps (fallback)     |

#### iOS (`Info.plist`)

| Key                                   | Deskripsi                                                                              |
| ------------------------------------- | -------------------------------------------------------------------------------------- |
| `NSLocationWhenInUseUsageDescription` | "SpotSaku memerlukan akses lokasi untuk merekam koordinat GPS spot yang Anda temukan." |
| `NSCameraUsageDescription`            | "SpotSaku memerlukan akses kamera untuk memotret lokasi yang Anda temukan."            |
| `NSPhotoLibraryUsageDescription`      | "SpotSaku memerlukan akses galeri untuk memilih foto representatif lokasi."            |

---

## Tech Stack

### Framework & Language

| Komponen          | Teknologi                                                            |
| ----------------- | -------------------------------------------------------------------- |
| **Framework**     | Flutter (Dart SDK ^3.12.0)                                           |
| **Design System** | Material 3 dengan `ColorScheme.fromSeed`                             |
| **Font**          | Poppins via `google_fonts`                                           |
| **Primary Color** | Hijau `#017F3C` (single source of truth di `AppColors` + `AppTheme`) |

### Dependencies (pubspec.yaml)

| Package                       | Version | Kebutuhan                                                                                  |
| ----------------------------- | ------- | ------------------------------------------------------------------------------------------ |
| `provider`                    | ^6.1.2  | State management (`SpotProvider`, `ThemeProvider`, `SettingsProvider`, `CategoryProvider`) |
| `sqflite`                     | ^2.4.1  | Local database (SQLite, offline-first)                                                     |
| `path`                        | ^1.9.0  | Path manipulation untuk file system                                                        |
| `path_provider`               | ^2.1.5  | Akses app documents directory                                                              |
| `geolocator`                  | ^13.0.2 | GPS sensor access                                                                          |
| `image_picker`                | ^1.1.2  | Camera capture & gallery picker                                                            |
| `url_launcher`                | ^6.3.1  | Buka Google Maps via intent (IPC)                                                          |
| `flutter_local_notifications` | ^18.0.1 | Scheduled notification reminders                                                           |
| `timezone`                    | ^0.9.4  | Timezone support untuk notifikasi                                                          |
| `csv`                         | ^6.0.0  | CSV export & import                                                                        |
| `file_selector`               | 1.1.0   | File picker untuk import backup (Flutter team package)                                     |
| `shared_preferences`          | ^2.3.3  | Persist dark mode, notification settings, custom categories                                |
| `intl`                        | ^0.20.1 | Date/time formatting                                                                       |
| `google_fonts`                | ^6.3.1  | Poppins font                                                                               |
| `cupertino_icons`             | ^1.0.8  | iOS-style icons                                                                            |

### Dev Dependencies

| Package         | Version | Kebutuhan                    |
| --------------- | ------- | ---------------------------- |
| `flutter_test`  | SDK     | Widget & unit testing        |
| `flutter_lints` | ^6.0.0  | Static analysis & lint rules |

---

## Struktur Proyek (Direktori)

lib/ (24 file Dart)
├── main.dart # Entry point, MultiProvider, bootstrap
├── core/
│ └── constants/
│ └── app_colors.dart # Design tokens (primary, success, warning, danger, shadow, border)
├── data/
│ ├── models/
│ │ └── spot.dart # Spot model (immutable, fromMap/toMap/copyWith, clearable reminderAt)
│ ├── database/
│ │ └── database_helper.dart # SQLite singleton, schema v2, CRUD helpers
│ └── repositories/
│ └── spot_repository.dart # Data access layer, filter, export/import CSV/JSON, photo persistence
├── presentation/
│ ├── providers/
│ │ ├── spot_provider.dart # Spot list state, CRUD, filters, setReminder
│ │ ├── theme_provider.dart # Dark/light mode (persisted)
│ │ ├── settings_provider.dart # Notification toggle, export/import
│ │ └── category_provider.dart # Custom categories (persisted)
│ ├── screens/
│ │ ├── home_screen.dart # Dashboard: search, category chips, status dropdown, spot list
│ │ ├── add_edit_screen.dart # Form: camera, GPS, category dropdown, custom category dialog
│ │ ├── detail_screen.dart # Detail: photo, rating, reminder picker, maps route
│ │ └── stats_settings_screen.dart # Stats, notification toggle, export/import, about
│ └── widgets/
│ ├── spot_card.dart # Spot list card with status badge & reminder indicator
│ ├── category_chip.dart # Animated filter chip
│ ├── home_header.dart # Greeting header with theme toggle & stats button
│ ├── search_box.dart # Elevated search input
│ └── star_rating.dart # Interactive star rating widget
├── utils/
│ ├── constants.dart # AppCategories, AppPrefs, AppDatabase
│ ├── theme.dart # AppTheme.light() & AppTheme.dark() with Poppins
│ ├── location_service.dart # GPS permission & coordinate capture
│ ├── media_service.dart # Camera & gallery image picker
│ ├── maps_service.dart # URL launcher to Google Maps
│ └── notification_service.dart # Schedule/cancel local notifications
└── (test/)
├── widget_test.dart # Smoke test (greeting render)
└── spot_test.dart # Unit tests (model round-trip, copyWith sentinel, filter logic)

---

## Instalasi & Setup

### Prasyarat

- Flutter SDK (>= 3.12.0, Dart ^3.12.0)
- Android Studio / VS Code dengan Flutter plugin
- Android SDK (untuk build Android)
- Xcode 16+ (untuk build iOS, macOS only)

### Langkah Instalasi

1. Clone repository
2. Jalankan `flutter pub get` untuk menginstal dependencies
3. Jalankan `flutter analyze` untuk verifikasi kode
4. Jalankan `flutter run` pada device/emulator

### Build APK (Release)

```bash
flutter build apk --release

### Build iOS (Release)
flutter build ios --release

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────


## Alur Layar (Screen Flow)
1. Home / Dashboard → Daftar spot + search + filter kategori + dropdown status (Semua/Wishlist/Dikunjungi) + dark mode toggle
2. Add/Edit Spot Screen → Form input (kamera, GPS, kategori dropdown + tambah kategori custom, status)
3. Detail Spot Screen → Foto + rating bintang + set pengingat (1 hari / 3 hari / 1 minggu / custom) + buka rute Google Maps
4. Statistik & Pengaturan → Stats kunjungan + toggle notifikasi + ekspor/impor data + about

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────


## Database Schema (Spot Table — v2)

┌────────────┬─────────┬──────────────────────────────────────────────────┐
│ Field      │ Type    │ Description                                      │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ id         │ INTEGER │ Primary key (auto increment)                     │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ name       │ TEXT    │ Nama spot/tempat                                 │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ category   │ TEXT    │ Kategori (predefined atau custom)                │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ latitude   │ REAL    │ Koordinat lintang GPS                            │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ longitude  │ REAL    │ Koordinat bujur GPS                              │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ mapsUrl    │ TEXT    │ URL Google Maps (opsional manual)                │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ photoPath  │ TEXT    │ Path file foto lokal (persisten di spot_photos/) │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ notes      │ TEXT    │ Catatan/review tambahan                          │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ rating     │ INTEGER │ Rating bintang (1-5, nullable)                   │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ isVisited  │ INTEGER │ Status (0=Wishlist, 1=Visited)                   │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ reminderAt │ TEXT    │ ISO-8601 timestamp pengingat (nullable, v2)      │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ createdAt  │ TEXT    │ Timestamp pembuatan                              │
├────────────┼─────────┼──────────────────────────────────────────────────┤
│ updatedAt  │ TEXT    │ Timestamp pembaruan terakhir                     │
└────────────┴─────────┴──────────────────────────────────────────────────┘

Migration v1 → v2: ALTER TABLE spots ADD COLUMN reminderAt TEXT

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────


## Panduan Pengembang (Developer Guide)

### 1. Pola Arsitektur (Architecture Pattern)
SpotSaku menggunakan arsitektur berlapis (layered architecture):

• Data Layer:
    ◦ Models (data/models/spot.dart): Struktur data immutable dengan fromMap, toMap, dan copyWith (dengan sentinel pattern untuk reminderAt yang
      bisa di-clear).
    ◦ Database (data/database/database_helper.dart): Singleton untuk akses sqflite (SQLite), migrasi schema, dan eksekusi SQL.
    ◦ Repositories (data/repositories/spot_repository.dart): Abstraksi data access, logika timestamp, photo persistence, export/import CSV/JSON,
      dan filtering.
• Presentation Layer:
    ◦ Providers (presentation/providers/): State management dengan ChangeNotifier — SpotProvider, ThemeProvider, SettingsProvider,
      CategoryProvider.
    ◦ Screens (presentation/screens/): Widget halaman utama — Home, Detail, Add/Edit, Stats/Settings.
    ◦ Widgets (presentation/widgets/): Komponen UI reusable — SpotCard, CategoryChip, StarRating, HomeHeader, SearchBox.
• Core Layer (core/constants/app_colors.dart): Design tokens terpusat (warna, shadow, border).
• Utils Layer (utils/): Services untuk Geolocator, ImagePicker, url_launcher, NotificationService, theme, dan constants.

### 2. Format & Standardisasi Kode
• Linter: package:flutter_lints/flutter.yaml aktif via analysis_options.yaml.
• Format: Jalankan dart format lib/ sebelum commit.
• Trailing Commas: Gunakan koma penutup pada argument list panjang.
• Dokumentasi: Gunakan /// untuk kelas/metode publik, library; di awal file.

### 3. Penataan Gaya & Tema (Styling & Theming)
• Material 3: useMaterial3: true di light & dark theme.
• Primary Color: Hijau #017F3C — single source of truth di AppColors.primary (core/constants/app_colors.dart:8) dan AppTheme.primary
  (utils/theme.dart:16).
• Font: Poppins via GoogleFonts.poppinsTextTheme() di kedua tema.
• Design Tokens: Gunakan AppColors (primary, success, warning, danger, shadow, border). Hindari Colors.* hardcoded langsung di widget.
• Dark Mode: ThemeProvider + AppTheme.dark() lengkap dengan scaffold, card, input, chip, FAB, dan button theme.

### 4. Manajemen Media & Perangkat Keras
• Persistensi Gambar: SpotRepository.persistPhoto menyalin foto dari cache ke direktori permanen app (spot_photos/).
• Lokasi & Google Maps: geolocator untuk koordinat, url_launcher untuk navigasi (https://www.google.com/maps/dir/?api=1&destination=lat,lng).
• Notifikasi: NotificationService menjadwalkan notifikasi via flutter_local_notifications dengan timezone support. ID notifikasi = spot database
  ID.

### 5. Panduan Pengembangan Berkelanjutan
Jika menambahkan properti baru pada Spot:
1. Database: Naikkan AppDatabase.dbVersion di constants.dart, tulis migrasi ALTER TABLE di _onUpgrade di database_helper.dart.
2. Model: Tambahkan field ke Spot constructor, fromMap, toMap, copyWith (gunakan sentinel pattern jika fieldnya clearable/nullable).
3. Repository: Tambahkan kolom ke toCsv() header dan rows, serta parser di importFromCsv().
4. UI: Sesuaikan form, detail screen, dan card untuk menampilkan data baru.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────


## Testing
flutter test

┌──────────────────────┬───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Test File            │ Coverage                                                                                                              │
├──────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ test/spot_test.dart  │ 11 unit tests — model round-trip, copyWith sentinel (clearable reminderAt), toMapsDirectionsUrl, in-memory filter     │
│                      │ logic                                                                                                                 │
├──────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ test/widget_test.dar │ Smoke test — greeting widget render                                                                                   │
│ t                    │                                                                                                                       │
└──────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────


## Tim Pengembang (Kelompok 1)
• Muhammad Reski
• Nanda Fadila
• Akhtar Muzaqie Abraar


## Lisensi
[Proprietary / Academic Project — Mobile Computing 2025/2026]
```
