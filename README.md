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
- [x] Kategori & Status Wishlist (custom categories + toggle Wishlist/Visited)
- [x] Pencarian & Penyaringan (search + filter by category & status)

## Fitur Tambahan (Additional Features)
- [x] Eksternal Routing — Buka rute langsung di Google Maps via Intent
- [x] Notifikasi Pengingat — reminder untuk mengunjungi wishlist
- [x] Sistem Penilaian — rating bintang & review untuk spot visited
- [x] Ekspor & Pencadangan Data — backup CSV/JSON secara offline
- [x] Dark Mode — toggle tema gelap/terang

## Core Mobile Computing Technologies
1. **Sensor Hardware**: GPS (`geolocator`) & Kamera/Galeri (`image_picker`)
2. **Local Database & State Management**: SQLite/Hive + Provider (offline-first)
3. **Inter-Process Communication**: `url_launcher` (Google Maps intent) + `flutter_local_notifications` (OS notification scheduling)

## Killer Use Case: Spontaneous Discovery
Pengguna sedang berjalan-jalan, melihat pemandangan sunset yang bagus,
ingin menyimpan lokasi untuk dikunjungi lagi, namun tidak ada internet
dan tidak tahu nama jalan.
**Aksi**: Buka SpotSaku → tap "+" → foto langsung (camera) → tap
"Dapatkan Lokasi Saat Ini" (GPS) → beri nama → simpan.
**Waktu**: <20 detik, 100% offline.
**Nanti**: tap "Buka di Maps" untuk dipandu kembali ke titik tersebut.

## Tech Stack
- **Framework**: Flutter & Dart
- **Database**: sqflite / Hive
- **State Management**: Provider
- **Key Packages**: geolocator, image_picker, url_launcher, sqflite/hive,
  path_provider, flutter_local_notifications, csv, shared_preferences, intl

## Struktur Proyek (Direktori)
lib/
├── main.dart
├── data/
│   ├── models/          # Data models (Spot model)
│   ├── database/        # Database helper & schema
│   └── repositories/    # Data access layer (CRUD, export)
├── domain/
│   ├── entities/
│   └── usecases/
├── presentation/
│   ├── screens/         # Home, AddEditForm, Detail, StatsSettings
│   ├── widgets/         # Reusable UI components (cards, chips, rating stars)
│   └── providers/       # State management (spot, theme, settings)
└── utils/               # Constants, theme, helpers, export utils

## Instalasi & Setup
### Prasyarat
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 2.17.0)
- Android Studio / VS Code
- Android SDK (untuk build Android)
- iOS SDK & Xcode (untuk build iOS, macOS only)

### Langkah Instalasi
- [ ] Clone repository
- [ ] Jalankan `flutter pub get` untuk menginstal dependencies
- [ ] Konfigurasi permission Android:
  - INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION
  - CAMERA, READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE
  - SCHEDULE_EXACT_ALARM, POST_NOTIFICATIONS (untuk notifikasi)
- [ ] Konfigurasi permission iOS:
  - NSLocationWhenInUseUsageDescription
  - NSCameraUsageDescription, NSPhotoLibraryUsageDescription
- [ ] Jalankan `flutter run` pada device/emulator

## Alur Layar (Screen Flow)
1. **Home / Dashboard** → Daftar spot + search + filter + dark mode toggle
2. **Add/Edit Spot Screen** → Form input (kamera, GPS, kategori, status)
3. **Detail Spot Screen** → Detail + rating + buka rute Google Maps
4. **Statistik & Pengaturan** → Visualisasi status + pengaturan notifikasi & backup

## Database Schema (Spot Table)
| Field         | Type    | Description                              |
|---------------|---------|------------------------------------------|
| id            | INTEGER | Primary key (auto increment)             |
| name          | TEXT    | Nama spot/tempat                         |
| category      | TEXT    | Kategori (custom labels)                 |
| latitude      | REAL    | Koordinat lintang GPS                    |
| longitude     | REAL    | Koordinat bujur GPS                      |
| mapsUrl       | TEXT    | URL Google Maps (opsional manual)        |
| photoPath     | TEXT    | Path file foto lokal                     |
| notes         | TEXT    | Catatan/review tambahan                  |
| rating        | INTEGER | Rating bintang (1-5, nullable)           |
| isVisited     | INTEGER | Status (0=Wishlist, 1=Visited)           |
| createdAt     | TEXT    | Timestamp pembuatan                      |
| updatedAt     | TEXT    | Timestamp pembaruan terakhir             |

## Panduan Pengembang (Developer Guide)

Bagian ini menjelaskan standar penulisan kode, penataan gaya (styling), format berkas, serta petunjuk umum untuk pengembangan dan pemeliharaan aplikasi SpotSaku.

### 1. Pola Arsitektur (Architecture Pattern)
SpotSaku menggunakan arsitektur berlapis (layered architecture) yang terbagi menjadi:
- **Data Layer**:
  - **Models** ([spot.dart](file:///D:/Cakrawala/SMT%204/Mobile%20Computing/spotsaku/lib/data/models/spot.dart)): Struktur representasi data (immutable) dengan method pembantu `fromMap`, `toMap`, dan `copyWith`.
  - **Database** ([database_helper.dart](file:///D:/Cakrawala/SMT%204/Mobile%20Computing/spotsaku/lib/data/database/database_helper.dart)): Singleton untuk akses langsung `sqflite` (SQLite), migrasi, dan eksekusi SQL mentah.
  - **Repositories** ([spot_repository.dart](file:///D:/Cakrawala/SMT%204/Mobile%20Computing/spotsaku/lib/data/repositories/spot_repository.dart)): Abstraksi data access, menyimpan logika waktu pembaruan (`updatedAt`), penyalinan gambar, ekspor file (CSV/JSON), dan pencarian/penyaringan tingkat data.
- **Presentation Layer**:
  - **Providers** ([providers/](file:///D:/Cakrawala/SMT%204/Mobile%20Computing/spotsaku/lib/presentation/providers/)): Mengelola status (state) aplikasi menggunakan `ChangeNotifier` (`SpotProvider`, `ThemeProvider`, `SettingsProvider`).
  - **Screens** ([screens/](file:///D:/Cakrawala/SMT%204/Mobile%20Computing/spotsaku/lib/presentation/screens/)): Widget halaman utama aplikasi (Home, Detail, Form Add/Edit, dan Stats/Settings).
  - **Widgets** ([widgets/](file:///D:/Cakrawala/SMT%204/Mobile%20Computing/spotsaku/lib/presentation/widgets/)): Komponen UI modular dan reusable (`SpotCard`, `CategoryChip`, `StarRating`).
- **Utils Layer** ([utils/](file:///D:/Cakrawala/SMT%204/Mobile%20Computing/spotsaku/lib/utils/)): Layanan perangkat keras seperti `Geolocator`, `ImagePicker`, `url_launcher`, dan `NotificationService`.

### 2. Format & Standardisasi Kode (Formatting & Coding Standards)
Semua developer wajib mengikuti pedoman berikut untuk menjaga konsistensi repositori:
- **Linter & Analyzer**: Proyek dikonfigurasi menggunakan `package:flutter_lints/flutter.yaml`. Jangan abaikan peringatan (warning) linter kecuali dengan komentar penjelas `// ignore: <lint_rule>`.
- **Format Otomatis**: Jalankan perintah pemformatan resmi Dart sebelum melakukan komit kode:
  ```bash
  flutter format lib/
  ```
- **Trailing Commas**: Selalu gunakan koma penutup (trailing commas) pada argument list yang panjang atau berumpun agar auto-formatter dapat merapikan baris kode secara vertikal.
- **Dokumentasi Kode**: Gunakan komentar triple-slash `///` untuk kelas, metode, atau atribut publik, serta sertakan deklarasi `library;` pada awal berkas pustaka baru.

### 3. Penataan Gaya & Tema (Styling & Theming Guide)
SpotSaku menerapkan panduan desain yang konsisten dengan tema adaptif:
- **Material 3**: Proyek menggunakan spesifikasi Material 3 (`useMaterial3: true`).
- **Sistem Warna Dinamis**: Warna diatur secara dinamis menggunakan `ColorScheme.fromSeed` dengan seed warna biru utama `Color(0xFF1E88E5)`.
- **Penggunaan Token Warna**: Hindari menggunakan warna konstan/hardcoded langsung pada widget (seperti `Colors.blue` atau `Colors.white`). Selalu ambil warna dari skema tema aktif, contoh:
  ```dart
  final theme = Theme.of(context);
  final backgroundColor = theme.colorScheme.surface;
  final outlineColor = theme.colorScheme.outline;
  ```
- **Adaptasi Tema (Dark Mode)**: Gunakan `ThemeProvider` untuk menyelaraskan tampilan. Pastikan widget kustom mendukung transisi warna yang kontras saat berganti dari Light Mode ke Dark Mode.

### 4. Manajemen Media & Perangkat Keras (Media & Hardware Management)
- **Persistensi Gambar**: Gambar yang diambil dari kamera (`image_picker`) berada di direktori cache sementara OS. Pustaka `SpotRepository.persistPhoto` bertanggung jawab menyalin berkas tersebut ke direktori permanen aplikasi (`/spot_photos`) agar jalur berkas (`photoPath`) tetap valid selamanya.
- **Lokasi & Google Maps**: Perekaman koordinat menggunakan `geolocator`. Untuk navigasi, gunakan `url_launcher` dengan intent universal `https://www.google.com/maps/dir/?api=1&destination=lat,lng` agar perangkat mengarah ke aplikasi peta native atau browser.

### 5. Panduan Pengembangan Berkelanjutan (Workflow Pengeditan & Fitur Baru)
Jika Anda perlu menambahkan properti baru pada entitas `Spot` (misal: menambahkan koordinat ketinggian `altitude` atau `tag` tambahan):
1. **Perbarui Database**: Ubah versi skema di `AppDatabase.dbVersion` di `constants.dart` dan buat skrip migrasi `ALTER TABLE` pada fungsi `_onUpgrade` di [database_helper.dart](file:///D:/Cakrawala/SMT%204/Mobile Computing/spotsaku/lib/data/database/database_helper.dart).
2. **Perbarui Model**: Tambahkan parameter tersebut ke konstruktor `Spot`, method `fromMap`, `toMap`, dan `copyWith` di [spot.dart](file:///D:/Cakrawala/SMT%204/Mobile Computing/spotsaku/lib/data/models/spot.dart).
3. **Perbarui Ekspor Data**: Tambahkan kolom baru ke data header dan baris pada fungsi `toCsv()` di [spot_repository.dart](file:///D:/Cakrawala/SMT%204/Mobile Computing/spotsaku/lib/data/repositories/spot_repository.dart).
4. **Perbarui Antarmuka (UI)**: Sesuaikan halaman tambah/edit form, detail screen, atau card untuk mengakomodasi data baru tersebut.

## Tim Pengembang (Kelompok 1)
- Muhammad Reski
- Nanda Fadila
- Akhtar Muzaqie Abraar

## Lisensi
[Proprietary / Academic Project — Mobile Computing 2025/2026]
