# MOTION_PLAN.md — Peta Optimasi Smooth Scrolling & Layer Motion Galeri Sriwedari

> **Peran:** Senior Flutter Motion Engineer & UI Performance Specialist  
> **Lingkungan:** Galeri Sriwedari (`sriwedari_app`) — Android, iOS, & Web (Safari iOS/Desktop)  
> **Referensi UI Selesai (Protected):** Seluruh checklist **P0–P3** pada [AUDIT_REPORT.md](file:///C:/Users/WINDOWS/Documents/sriwedari_app_flutter/AUDIT_REPORT.md) berstatus `[x]` dan **TIDAK AKAN DIUBAH** struktur layout, palet warna, tombol navigasi/back, routing logic, maupun logika databasenya.  
> **Status Tahap:** **Tahap 1–3 Selesai & Terverifikasi (`flutter analyze`: 0 isu, `flutter test`: 57/57 lulus)**

---

## 1. Hasil Pemindaian Kondisi Scroll & Motion Saat Ini

Pemindaian seluruh **97 file Dart** di `lib/` menunjukkan:
1. **`0` custom `ScrollBehavior`**: Pada Web/Desktop belum ada dukungan mouse *click-and-drag* yang mulus maupun penyelarasan fisika scroll adaptif lintas platform (`iOS`/`Android`/`Web`).
2. **`0` `CustomScrollView` / `SliverGrid` / `SliverAppBar`**:
   - Halaman beranda & katalog utama (`UserDashboardScreen`, `GalleryListScreen`, `CostumeCatalogScreen`) saat ini masih memakai `SingleChildScrollView` + `GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())`. Pola `shrinkWrap: true` memaksa Flutter menghitung dan merender seluruh item di luar layar sekaligus sehingga rawan *frame drop* saat katalog bertambah.
   - Halaman detail hero (`GalleryDetailScreen`, `CostumeDetailScreen`) masih memakai `SingleChildScrollView` statis tanpa `SliverAppBar` maupun *subtle parallax*.
3. **`0` `RepaintBoundary` & `0` `cacheExtent`**: Kartu bergambar pada daftar galeri, kostum, jadwal, profil, dan antrean admin belum diisolasi dengan `RepaintBoundary` saat scroll cepat.
4. **`SwImage` & Loading Transition**:
   - `Image.asset` di `SwImage` belum memakai `frameBuilder` fade-in halus saat decoding frame pertama.
   - `SwLoadingSkeleton` menjalankan `AnimationController.repeat()` tanpa menonaktifkan ticker ketika aksesibilitas `MediaQuery.disableAnimationsOf(context)` aktif.
   - Transisi state *loading skeleton -> data asli* di sebagian besar layar masih langsung terganti (*snap*) tanpa cross-fade halus.
5. **Motion Layer (`Hero`, Micro-interaction, Entrance, `AnimatedSize`)**:
   - Belum ada `Hero` transition antar kartu galeri/kostum ke halaman detail. *(Catatan penting arsitektur: karena `UserDashboardScreen`, `GalleryListScreen`, dan `CostumeCatalogScreen` hidup bersamaan di dalam `IndexedStack` milik `StatefulShellRoute`, setiap sumber **wajib** membawa prefix `heroTag` unik—misal `dash-gal-<id>` vs `list-gal-<id>`—agar tidak pernah memicu error `Hero tag collision` saat navigasi cepat).*
   - Belum ada feedback taktil skala (`ScaleOnTap` 0.97) maupun efek *hover* halus khusus Desktop/Web pada kartu & chip interaktif.

---

## 2. Prinsip Desain Motion & Batasan Ketat (*Strict Guardrails*)

- **Timing Bersih (Anti-Motion Slop):**
  - *Micro-interaction* (`ScaleOnTap`, hover border/shadow, chip/toggle): **`140ms – 180ms`**.
  - *Reveal / Content Switcher / Expand* (`FadeSlideEntrance`, `SwContentSwitcher`, `AnimatedSize`): **`220ms – 300ms`**.
  - Kurva: `Curves.easeOutCubic`, `Curves.easeOutQuart`, `Curves.fastOutSlowIn` (bebas `linear` & bebas pantulan berlebihan).
- **Ramah Aksesibilitas & Bebas Bocor Ticker:** Seluruh komponen di `lib/core/motion/` memeriksa `MediaQuery.disableAnimationsOf(context)` dan hanya menganimasikan kemunculan awal sekali jalan (`once-only reveal`) tanpa mengulang animasi saat scroll bolak-balik.
- **Zero UI/Nav Regression Gate:** Setiap langkah di Tahap 2 & Tahap 3 wajib ditutup dengan `flutter analyze` (`0` isu) + `flutter test` (`100%` lulus) sebelum mencentang `[x]`.

---

## 3. Rencana Pelaksanaan Bertahap

### Tahap 2 — Fondasi Reusable Motion Kit (`lib/core/motion/`) & Core Scroll/Image Layer
- [x] **M1.1** Bangun `lib/core/motion/`:
  - `sw_scroll_behavior.dart`: `SwScrollBehavior` global (mendukung `touch`, `mouse`, `trackpad`, `stylus`, serta fisika scroll halus lintas iOS/Android/Web).
  - `sw_interactive_card.dart`: `ScaleOnTap` (`140ms`, `scale: 0.97` saat ditekan) & `SwHoverLift` (elevasi/border lembut saat hover di Desktop/Web).
  - `sw_fade_slide_entrance.dart`: `FadeSlideEntrance` (`fade` + geser vertikal `14px`, jeda staggered `45ms` maksimal cap ringan, hanya berjalan sekali saat mount).
  - `sw_content_reveal.dart`: `SwContentSwitcher` (transisi halus loading skeleton -> konten asli `240ms Curves.easeOutCubic`) dan `SwAnimatedExpand` (`AnimatedSize` untuk ekspansi panel).
  - `smooth_page_transition.dart`: wrapper `SmoothPageTransition` (kurva parallax sekunder & dukungan swipe-back natural).
  - `motion.dart`: barrel export untuk seluruh kit motion.
- [x] **M1.2** Integrasikan Global Scroll, Image Smoothness, & Core Interactive Widgets:
  - Pasang `scrollBehavior: const SwScrollBehavior()` pada `MaterialApp.router` di `lib/app.dart`.
  - Tingkatkan `SwImage` (`lib/core/widgets/sw_image.dart`) dengan fade-in frame `220ms` mulus (aman untuk aset yang sudah cached sinkron maupun jaringan) + dukungan `disableAnimations`.
  - Perbarui `SwLoadingSkeleton` (`lib/core/widgets/sw_loading_skeleton.dart`) agar otomatis berhenti menganimasikan controller saat `disableAnimationsOf(context)` aktif.
  - Pasang `ScaleOnTap` & hover feedback halus di `SwButton`, `SwCard` (ketika `onTap != null`), dan `SwFilterChip` (`AnimatedContainer` `180ms` + tap scale) tanpa mengubah warna, ukuran, maupun padding.

### Tahap 3 — Penerapan Per Halaman (1 Halaman = 1 Siklus Analyze & Test)
- [x] **M2.1 — `UserDashboardScreen`** (`lib/features/user/presentation/screens/user_dashboard_screen.dart`):
  - Ubah struktur scroll menjadi **`CustomScrollView` + `SliverPadding` + `SliverGrid` (`cacheExtent: 600`)** (menggantikan `SingleChildScrollView` + `shrinkWrap` grid).
  - Bungkus kartu `Galeri Terbaru` & `Pagelaran Terdekat` dengan `RepaintBoundary` + `FadeSlideEntrance` staggered.
  - Pasang `Hero` ber-tag unik (`dash-gal-<id>`) dan kirim query `?heroTag=...` ke detail; gunakan `SwContentSwitcher` untuk transisi loading -> data.
- [x] **M2.2 — `GalleryListScreen`** (`lib/features/user/presentation/screens/gallery_list_screen.dart`):
  - Konversi ke **`CustomScrollView` + `SliverGrid` (`cacheExtent: 650`)** dengan `RepaintBoundary` per item + `FadeSlideEntrance`.
  - Pasang `Hero` ber-tag unik (`list-gal-<id>`) dan `SwContentSwitcher` saat loading/filter berubah.
- [x] **M2.3 — `GalleryDetailScreen`** (`lib/features/user/presentation/screens/gallery_detail_screen.dart`):
  - Ubah body menjadi **`CustomScrollView` + `SliverAppBar`** (pinned top bar bertransisi halus saat di-scroll + **subtle parallax** pada foto hero via `FlexibleSpaceBar` tanpa mengubah posisi tombol Back/Favorit/Bagikan).
  - Hubungkan `Hero` dinamis membaca parameter opsional `?heroTag=` (dengan fallback aman `detail-gal-<id>`) dan perhalus tombol Like dengan `AnimatedSwitcher` + `ScaleOnTap`.
- [x] **M2.4 — `CostumeCatalogScreen`** (`lib/features/user/presentation/screens/costume_catalog_screen.dart`):
  - Konversi ke **`CustomScrollView` + `SliverGrid` (`cacheExtent: 650`)**, bungkus item dengan `RepaintBoundary` + `FadeSlideEntrance`, tambahkan `Hero` tag unik (`list-cos-<id>`), serta `SwContentSwitcher` pada hasil filter/loading.
- [x] **M2.5 — `CostumeDetailScreen`** (`lib/features/user/presentation/screens/costume_detail_screen.dart`):
  - Konversi ke **`CustomScrollView` + `SliverAppBar`** (**subtle parallax** hero + pinned bar saat di-scroll), hubungkan `Hero` dinamis `?heroTag=`, dan perhalus tombol Favorit/Bagikan.
- [x] **M2.6 — Alur Transaksi & Profil (`ScheduleScreen`, `BookingFormScreen`, `BookingSuccessScreen`, `ProfileScreen`)**:
  - `ScheduleScreen`: **`CustomScrollView` + `SliverList`** (`cacheExtent: 550`), `RepaintBoundary` + `FadeSlideEntrance` + `SwContentSwitcher` loading -> list.
  - `BookingFormScreen`: gunakan `AnimatedSize` (`SwAnimatedExpand`) untuk kemunculan pesan kupon/rincian diskon & `ScaleOnTap` pada pilihan metode pembayaran.
  - `BookingSuccessScreen`: pasang `FadeSlideEntrance` lembut pada kartu konfirmasi.
  - `ProfileScreen`: pasang `RepaintBoundary` + `SwContentSwitcher` loading -> riwayat, serta `Hero` unik (`prof-gal-<id>` / `prof-cos-<id>`) pada item tab Favorit.
- [x] **M2.7 — Halaman Edukasi & Auth (`HeritageAudioPlayer`, `BlogListScreen`, `BlogDetailScreen`, `AboutScreen`, `AboutHistoryScreen`, `AboutCuratorsScreen`, `AuthHeritageBackdrop`)**:
  - `HeritageAudioPlayer`: bungkus ekspansi pilihan gending dengan `SwAnimatedExpand` (`AnimatedSize` 220ms).
  - `BlogListScreen` & `BlogDetailScreen`: `CustomScrollView` + `SliverList` + `RepaintBoundary` + `FadeSlideEntrance` + `Hero` unik (`blog-<slug>`).
  - `About*` & `AuthHeritageBackdrop`: pasang `FadeSlideEntrance` halus saat kemunculan kartu/form.
- [x] **M2.8 — Modul Admin + Test Khusus Motion/Scroll + Verifikasi Menyeluruh**:
  - Pasang `RepaintBoundary` pada KPI/grafik `fl_chart` & daftar item di modul Admin utama (`AdminDashboardScreen`, `AdminGalleryScreen`, `AdminCostumesScreen`, `AdminOrdersScreen`, `AdminEventsScreen`, `AdminVisitorsScreen`, `AdminCouponsScreen`, `AdminReviewsScreen`, `AdminUsersScreen`, `AdminAuditScreen`), serta `SwContentSwitcher` pada state loading -> konten dan `CustomScrollView`/`SliverList` pada daftar panjang.
  - Tambahkan suite widget test khusus (`test/core/motion_and_scroll_test.dart`) yang memverifikasi `SwScrollBehavior`, `ScaleOnTap`, `FadeSlideEntrance` (termasuk mode `disableAnimations: true`), dan navigasi `Hero` berurutan tanpa tag collision.
  - Verifikasi final: `flutter analyze` = `0` isu & seluruh `flutter test` lulus `100%`.
