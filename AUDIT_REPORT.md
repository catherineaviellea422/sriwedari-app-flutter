# AUDIT_REPORT.md — Audit Arsitektur Flutter & UI/UX Galeri Sriwedari

> **Proyek:** Galeri Sriwedari (`sriwedari_app`)  
> **Lingkungan & Stack:** Flutter / Dart SDK `^3.14.0`, Riverpod 3 (`flutter_riverpod ^3.5.0`), GoRouter 18 (`go_router ^18.1.4`), `material_ui ^1.1.0`  
> **Skala Codebase:** 97 file Dart di `lib/`, 32 halaman (4 Auth, 9 User/Transaksi, 5 Publik/Edukasi, 14 Admin), 5 widget interaktif User + 1 Command Palette, serta 11 aset gambar aktif di `assets/images/`  
> **Baseline Teknis Saat Audit:** `flutter analyze` (`No issues found!`), `flutter test` (`49/49 All tests passed!`)  
> **Hasil Verifikasi Akhir Phase 2:** `flutter analyze` (`No issues found!`), `flutter test` (`52/52 All tests passed!`)  
> **Status Fase:** **PHASE 1 & PHASE 2 SELESAI (Seluruh Checklist P0–P3 Tuntas `[x]`)**

---

## Ringkasan Eksekutif

Aplikasi **Galeri Sriwedari** telah berhasil dimigrasi dari Next.js/HTML ke Flutter dengan cakupan fitur bisnis yang lengkap dan stabil (kompilasi bersih serta seluruh 49 test lulus). Identitas visual **"Nusantara Heritage Elegance"** (`AppColors` hijau keraton–emas prada–kanvas perkamen + tipografi `Playfair Display` & `Inter`) serta komponen inti (`SwButton`, `SwCard`, `SwMetricCard`, `SwStatusBadge`, dll.) sudah konsisten.

Namun, audit menyeluruh menemukan bahwa **pola navigasi dan struktur layar masih banyak mewarisi mental model Next.js/HTML**, bukan **idiomatic Flutter**:
1. **0 penggunaan `PopScope`** di seluruh 97 file Dart: tombol *System Back* di Android tidak dikendalikan untuk mundur langkah formulir atau kembali ke tab utama sebelum keluar aplikasi.
2. **0 penggunaan `CustomTransitionPage` / `AnimatedSwitcher` / `SlideTransition` antar-rute maupun antar-step**: perpindahan halaman dan *multi-step flow* berlangsung instan (*hard swap*) tanpa memberi petunjuk arah navigasi maju/mundur.
3. **0 tombol Kembali (*Back*) di seluruh 14 halaman Admin**, serta *top navbar* kedua shell (`UserAppShell` dan `AdminAppShell`) bersifat statis dan tidak menampilkan tombol Back maupun judul kontekstual pada sub-halaman.
4. **Double Chrome pada halaman detail** (`GalleryDetailScreen` & `CostumeDetailScreen`): membungkus `Scaffold` baru di dalam `StatefulShellRoute`, sehingga menumpuk Top Navbar Shell + Floating Back button + Bottom CTA bar + Bottom Navigation Bar Shell sekaligus.
5. **Beberapa titik *decision paralysis* dan sisa UI web**, seperti login wall tanpa CTA *"Jelajahi sebagai Tamu"*, duplikasi pintu masuk Admin, Quick Menu Beranda yang mengulang Bottom Nav, tombol *"Lihat E-Tiket"* yang tidak langsung membuka tab E-Tiket, panah ASCII `->`, serta pemutar audio simulasi yang tampak seolah tombol Play tidak berbunyi.

---

## 1. Inventory & Status Fitur (32 Halaman + 6 Widget Interaktif)

### A. Modul Autentikasi (4 Halaman)

| Halaman & File | Rute | Status Saat Ini | Catatan Audit Flutter Idiomatic |
| :--- | :--- | :--- | :--- |
| **LoginScreen**<br>`lib/features/auth/presentation/screens/login_screen.dart` | `/login` | **Parsial / UX Redundan** | Sudah ada toggle peran `User` / `Admin`, tetapi di footer masih ada tombol `Gerbang Admin` (duplikasi pintu masuk). Belum ada CTA jelas `Jelajahi sebagai Tamu`, padahal halaman galeri, kostum, jadwal, dan edukasi dapat diakses publik tanpa login. |
| **RegisterScreen**<br>`lib/features/auth/presentation/screens/register_screen.dart` | `/register` | **Masih Pola Web** | Tidak ada tombol Back di kiri atas `AuthHeritageBackdrop`. Tautan bawah `Masuk di sini` memakai `context.go(AppRoutes.login)` alih-alih `pop()` bila datang dari `/login`. |
| **ForgotPasswordScreen**<br>`lib/features/auth/presentation/screens/forgot_password_screen.dart` | `/forgot-password` | **Masih Pola Web** | Tidak ada tombol Back di kiri atas. Perpindahan 3 fase (`Request` -> `Kode Verifikasi` -> `Selesai`) berganti instan tanpa animasi slide. |
| **AdminLoginScreen**<br>`lib/features/auth/presentation/screens/admin_login_screen.dart` | `/admin/login` | **Masih Pola Web** | Tidak ada tombol Back di kiri atas. Tombol bawah selalu memaksa `context.go('/dashboard')` alih-alih menghormati stack sebelumnya. |

### B. Modul User & Transaksi (9 Halaman + 5 Widget Interaktif)

| Halaman / Widget & File | Rute | Status Saat Ini | Catatan Audit Flutter Idiomatic |
| :--- | :--- | :--- | :--- |
| **UserDashboardScreen**<br>`lib/features/user/presentation/screens/user_dashboard_screen.dart` | `/dashboard` | **Masih Pola Web** | Quick Menu 4 kolom (`Galeri`, `Katalog Kostum`, `Jadwal Kegiatan`, `Sewa Busana`) menduplikasi 3 tab Bottom Navigation Bar tepat di bawahnya. Kartu `Pagelaran Terdekat` hanya memanggil `context.go('/jadwal')` tanpa langsung membuka pilihan kursi event terkait. Aksi `Sewa Busana` memakai `context.go` sehingga stack `Back` hilang. |
| **GalleryListScreen**<br>`lib/features/user/presentation/screens/gallery_list_screen.dart` | `/galeri` | **Berfungsi Penuh** | Pencarian, filter kategori & tipe (`Foto`/`Video`), like, dan wishlist berjalan baik serta adaptif 2/3/4 kolom. |
| **GalleryDetailScreen**<br>`lib/features/user/presentation/screens/gallery_detail_screen.dart` | `/galeri/:id` | **Masih Pola Web / Double Chrome** | Menggunakan nested `Scaffold` di dalam `UserAppShell`, sehingga di mobile muncul Top Navbar Shell, lalu Floating Back di atas gambar, konten, Sticky CTA `Sewa Kostum Terkait`, lalu Bottom Navigation Bar Shell di bawahnya. Memuat `HeritageAudioPlayer` simulasi tanpa audio nyata. |
| **CostumeCatalogScreen**<br>`lib/features/user/presentation/screens/costume_catalog_screen.dart` | `/kostum` | **Berfungsi Penuh** | Pencarian, filter kategori, wishlist, serta modal `CostumeRentalSheet` berfungsi lancar. |
| **CostumeDetailScreen**<br>`lib/features/user/presentation/screens/costume_detail_screen.dart` | `/kostum/:id` | **Masih Pola Web / Double Chrome** | Nested `Scaffold` bertumpuk di atas shell. Selain itu, berbeda dengan `GalleryDetailScreen`, hero `CostumeDetailScreen` tidak memiliki tombol Wishlist maupun Share. |
| **BookingFormScreen**<br>`lib/features/user/presentation/screens/booking_form_screen.dart` | `/pesan` | **Parsial / Navigasi Buntu** | Sudah memakai `depositFee` dinamis dari `publicSettingsProvider`, namun tidak punya AppBar/tombol Back keluar form maupun `PopScope` untuk mundur step (Step 3 -> 2 -> 1) atau konfirmasi batal saat draf terisi. Perpindahan Step 1–2–3 masih instan tanpa slide animation. |
| **BookingSuccessScreen**<br>`lib/features/user/presentation/screens/booking_success_screen.dart` | `/pesan/sukses/:id` | **Parsial** | Tidak ada `PopScope`, sehingga tombol System Back dapat mengembalikan user ke form checkout yang baru saja terkirim. Teks panduan masih menyebut `"Profil -> Pesanan Saya"` (padahal nama tab sudah `"Sewa"`) dan masih memakai panah ASCII `->`. |
| **ScheduleScreen**<br>`lib/features/user/presentation/screens/schedule_screen.dart` | `/jadwal`, `/jadwal/harian`, `/jadwal/hari-ini` | **Parsial / Pola Web** | Sub-mode `Hari Ini` / `Harian` tidak memiliki tombol Back kontekstual ke `/jadwal`. Segmented control `Mendatang \| Selesai` tetap tampil saat mode `Hari Ini`, padahal tidak memengaruhi data yang ditampilkan. |
| **ProfileScreen**<br>`lib/features/user/presentation/screens/profile_screen.dart` | `/profil` | **Berfungsi Penuh (Minor Polish)** | Layout sudah diperbarui selaras dengan `SRIWEDARI REVISI` (header kompak, WA bar, completion %, 3 shortcut card, kartu privilege `WARGA BUDAYA`/`SAHABAT KERATON`, modal edit + avatar, modal settings, proof viewer). Kekurangan: belum membaca query `?tab=orders\|tickets\|wishlist`, perpindahan tab tanpa animasi slide, dan link di tab `Favorit` masih memakai panah ASCII `->`. |
| *Widget:* **CostumeRentalSheet**<br>`lib/features/user/presentation/widgets/costume_rental_sheet.dart` | *Modal* | **Parsial** | Baris ringkasan masih men-hardcode deposit `100000` (`CurrencyFormatter.formatRupiah(100000)`) alih-alih membaca `publicSettingsProvider`. Navigasi lanjutan ke `/pesan` memakai `router.go` bukan `push`. |
| *Widget:* **TheaterSeatMapSheet**<br>`lib/features/user/presentation/widgets/theater_seat_map_sheet.dart` | *Modal* | **Parsial** | Setelah sukses memesan tiket, tombol `Lihat E-Tiket` memanggil `router.go('/profil')` yang mendarat di tab default `Sewa` (index 0), bukan langsung membuka tab `E-Tiket`. |
| *Widget:* **TicketBoardingPassModal**<br>`lib/features/user/presentation/widgets/ticket_boarding_pass_modal.dart` | *Modal* | **Berfungsi Penuh** | QR code + Barcode + detail boarding pass tampil rapi. |
| *Widget:* **ReviewSection**<br>`lib/features/user/presentation/widgets/review_section.dart` | *Embedded* | **Berfungsi Penuh** | Daftar ulasan dan pengiriman rating/komentar berfungsi baik. |
| *Widget:* **HeritageAudioPlayer**<br>`lib/features/user/presentation/widgets/heritage_audio_player.dart` | *Embedded* | **Dekoratif / Simulasi** | Menampilkan tombol Play, animasi equalizer, dan slider volume tanpa audio engine nyata (berisiko membuat user mengira suara aplikasi rusak). |

### C. Modul Publik & Edukasi (5 Halaman)

| Halaman & File | Rute | Status Saat Ini | Catatan Audit Flutter Idiomatic |
| :--- | :--- | :--- | :--- |
| **AboutScreen**<br>`lib/features/about_blog/presentation/screens/about_screen.dart` | `/tentang` | **Masih Pola Web** | Diakses lewat Drawer dengan `context.go`, tanpa tombol Back atau judul rute di Top Navbar shell. |
| **AboutHistoryScreen**<br>`lib/features/about_blog/presentation/screens/about_history_screen.dart` | `/tentang/sejarah` | **Masih Pola Web** | Menggunakan breadcrumb `TextButton` di dalam body yang selalu mengeksekusi `context.go('/tentang')` tanpa mengecek `canPop()`. |
| **AboutCuratorsScreen**<br>`lib/features/about_blog/presentation/screens/about_curators_screen.dart` | `/tentang/kurator` | **Masih Pola Web** | Pola sama: breadcrumb `TextButton` in-body dengan `context.go('/tentang')`, menumpuk di bawah Top Navbar shell statis. |
| **BlogListScreen**<br>`lib/features/about_blog/presentation/screens/blog_list_screen.dart` | `/warta` | **Masih Pola Web** | Tidak ada tombol Back di top bar maupun `PopScope` saat dibuka dari Drawer atau halaman Login. |
| **BlogDetailScreen**<br>`lib/features/about_blog/presentation/screens/blog_detail_screen.dart` | `/warta/:slug` | **Masih Pola Web** | Breadcrumb `TextButton` in-body di bawah Top Navbar shell yang statis; akan jauh lebih bersih jika menjadi layar detail penuh di root navigator dengan AppBar Back native. |

### D. Modul Admin / Kurator (14 Halaman + Command Palette)

| Kelompok & File | Rute | Status Saat Ini | Catatan Audit Flutter Idiomatic |
| :--- | :--- | :--- | :--- |
| **5 Tab Utama Bottom Nav**<br>`AdminDashboardScreen`, `AdminGalleryScreen`, `AdminOrdersScreen`, `AdminUsersScreen`, `AdminSettingsScreen` | `/admin/dashboard`, `/admin/galeri`, `/admin/pesanan`, `/admin/pengguna`, `/admin/pengaturan` | **Berfungsi Penuh (Minor Shell Polish)** | Fitur CRUD, analitik, QC grade A–D, manajemen user, dan pengaturan sanggar berjalan baik. Namun `_AdminTopBar` selalu bertuliskan `"Panel Kurator Sriwedari"` untuk semua tab sehingga user tidak langsung mendapat konteks sub-modul di AppBar. |
| **9 Sub-Halaman Non-Tab Admin**<br>`AdminPosScreen`, `AdminVisitorsScreen`, `AdminCategoriesScreen`, `AdminCostumesScreen`, `AdminEventsScreen`, `AdminCouponsScreen`, `AdminReviewsScreen`, `AdminAuditScreen`, `AdminDocsScreen` (+ `/admin/galeri/baru`) | `/admin/loket`, `/admin/kunjungan`, `/admin/kategori`, `/admin/kostum`, `/admin/acara`, `/admin/kupon`, `/admin/ulasan`, `/admin/audit`, `/admin/docs` | **Masih Pola Web (Navigasi Buntu di Mobile)** | Pemindaian codebase mengonfirmasi **seluruh 14 file layar admin memiliki `hasBack=False`**. Di mobile, saat kurator masuk ke salah satu sub-halaman ini via Drawer, Dashboard Quick Pill, atau `CommandPaletteDialog`, seluruhnya dipanggil dengan `context.go(...)`: tidak ada tombol Back ke Dashboard, dan pada tab Bottom Nav highlight tidak menjelaskan posisi sub-halaman. Selain itu, `AdminCostumesScreen:766` masih memakai panah ASCII `->`, dan `AdminPosScreen` beralih antara mode `Kasir Loket` <-> `Gate Scanner` tanpa animasi transisi. |
| **CommandPaletteDialog**<br>`lib/core/layout/command_palette_dialog.dart` | *Dialog (`Ctrl+K`)* | **Berfungsi Penuh (Minor Nav Polish)** | Pencarian cepat 14 modul sangat membantu, namun masih memanggil `router.go(route)` untuk semua rute termasuk sub-halaman non-tab sehingga menghapus riwayat `Back`. |

---

## 2. Audit Logika Navigasi & User Flow (Prioritas Tinggi)

### 2.1. Shell Top Navbar Statis & Absennya Tombol Back Sub-Halaman
- Pada `UserAppShell` (`_UserTopNavbar`, `user_app_shell.dart:189`), bar atas selalu menampilkan tombol Hamburger (`Icons.menu_rounded`) dan teks `"Galeri Sriwedari"`, meskipun user sedang membuka sub-halaman non-tab seperti `/tentang`, `/tentang/sejarah`, `/warta`, atau `/jadwal/hari-ini`.
- Pada `AdminAppShell` (`_AdminTopBar`, `admin_app_shell.dart:227`), bar atas selalu menampilkan `"Panel Kurator Sriwedari"` dan ikon Hamburger, sehingga pada 9 sub-halaman non-tab (`/admin/loket`, `/admin/acara`, `/admin/kostum`, `/admin/audit`, dll.) kurator tidak memiliki tombol **Back** satu ketukan untuk kembali ke modul induknya (`Dashboard` atau `Galeri`).

### 2.2. Double Chrome pada Layar Detail (`GalleryDetailScreen` & `CostumeDetailScreen`)
- Kedua rute detail tersebut masih terdaftar sebagai anak di dalam cabang `StatefulShellRoute.indexedStack` tanpa `parentNavigatorKey: rootNavigatorKey`.
- Kedua layarnya juga me-render `Scaffold` bersarang (`Scaffold` di dalam `Scaffold` milik `UserAppShell`). Akibatnya pada layar mobile `390x844`, pengguna melihat **4 lapis chrome sekaligus**:
  1. Top Navbar Shell (`58px`)
  2. Tombol Back melayang di atas foto hero
  3. Bottom CTA Bar (`Sewa Kostum Terkait` / `Pilih Ukuran & Sewa Sekarang`)
  4. Bottom Navigation Bar Shell (`64px`)
- Standar idiomatic Flutter untuk layar detail adalah melepaskannya ke `rootNavigatorKey` (`parentNavigatorKey: rootNavigatorKey`) dengan satu struktur navigasi atas (AppBar/Floating Back) dan satu bottom CTA bar yang lapang tanpa bertumpuk dengan Bottom Navigation Bar.

### 2.3. 0 Penggunaan `PopScope` & Riwayat Stack Terhapus oleh `context.go()`
- Pencarian di seluruh 97 file `lib/` mengonfirmasi **0 instance `PopScope` atau `WillPopScope`**.
- Penggunaan `context.go(...)` pada alur hierarkis (seperti `AboutScreen -> AboutHistoryScreen`, `UserDashboardScreen -> BookingFormScreen`, `CostumeRentalSheet -> BookingFormScreen`, `CommandPaletteDialog -> AdminPosScreen`) menimpa stack router sehingga `context.canPop()` bernilai `false`.
- Akibat langsung di perangkat Android/mobile:
  - Menekan tombol *System Back* di `BookingFormScreen` (misal di Step 2 atau Step 3) tidak mundur ke step sebelumnya dan tidak menanyakan konfirmasi pembatalan pengisian form—malah berpotensi menutup/keluar.
  - Menekan *System Back* di `BookingSuccessScreen` seharusnya kembali aman ke `/dashboard` atau `/profil`, bukan berisiko kembali ke form checkout.
  - Menekan *System Back* di tab Galeri/Kostum/Jadwal/Profil di dalam shell lebih natural kembali ke tab Beranda dulu sebelum keluar aplikasi.

### 2.4. Titik Kebingungan User (*Decision Paralysis*)
1. **LoginScreen terkesan menutup seluruh aplikasi:** Pengunjung baru dihadapkan pada form login penuh + Role Switch (`User` | `Admin`) + tautan `Gerbang Admin` di bagian bawah. Tidak ada CTA utama yang tegas bertuliskan **"Jelajahi sebagai Tamu"** meskipun sebagian besar katalog publik terbuka tanpa login.
2. **UserDashboardScreen menduplikasi Bottom Navigation Bar:** `Quick Menu` 4 kolom di tengah Beranda langsung mengulang `Galeri`, `Katalog Kostum`, dan `Jadwal Kegiatan` yang sudah menempel persis di Bottom Nav. Kartu `Pagelaran Terdekat` tidak langsung membuka pemesanan kursi event yang diklik, melainkan hanya melempar ke `/jadwal`.
3. **ScheduleScreen mode `Hari Ini` menampilkan filter membingungkan:** Ketika user memilih `Pentas Hari Ini`, segmented control `Mendatang | Selesai` tetap muncul dan bisa diklik meski logika filter di line 151 langsung me-return `e.date == todayStr` dan mengabaikan segmen tersebut.
4. **Discontinuity setelah pesan tiket (`TheaterSeatMapSheet` -> `ProfileScreen`):** Tombol `"Lihat E-Tiket"` di modal sukses tiket mengarahkan ke `/profil` pada tab default `Sewa` (index 0), memaksa user bingung mencari di mana e-tiketnya sebelum menyadari harus menekan tab `E-Tiket`.
5. **Instruksi teks usang di `BookingSuccessScreen`:** Menulis *"halaman Profil -> Pesanan Saya"*, padahal tab tersebut sekarang bernama **"Sewa"**.

---

## 3. Audit Visual, Warna, Komponen & Kebijakan Anti-AI Slop

### 3.1. Peta Palet Warna Inti (Dipertahankan)
Identitas **"Nusantara Heritage Elegance"** pada `lib/core/theme/app_colors.dart` sangat kuat dan tetap dipertahankan:

| Kelompok Token | Konstanta & Nilai Hex | Peran Visual |
| :--- | :--- | :--- |
| **Primary Keraton** | `primary #033325`, `brandGreen #1F4A3A`, `brandGreenDark #14382C`, `deepForest #0D1E18` | Top navbar, sidebar gelap, hero gradient, tombol primer, status chip aktif |
| **Accent Prada Emas** | `gold #C8A25A`, `goldWarm #D4AF37`, `goldDark #785918`, `goldLight #FFF1D0`, `secondaryFixed #FFFFDEA5` | CTA aksen (`SwButtonVariant.gold`), ornamen batik, badge tier/poin, ikon sorotan |
| **Canvas & Permukaan** | `canvas #F6F1E7`, `surface #FEF9EF`, `parchment #FBF8F2`, `ivory #FFFFFF`, `surfaceContainerLow..Highest` | Latar aplikasi hangat perkamen, permukaan kartu, input field |
| **Teks & Pembatas** | `textPrimary #1D1C16`, `textMuted #414944`, `textSubtle #717974`, `warmGray #9A9A94`, `divider #E8E0D2` | Hierarki teks Playfair Display (heading) & Inter (body/label/angka tabular) |
| **Pastel Metrik** | `metricMint #DDEBE3`, `metricPeach #F6E1D6`, `metricLightPeach #F9EBE3`, `metricLavender #E6E8EE` | Kartu KPI Admin (`SwMetricCard`) dan shortcut kartu Beranda/Profil |
| **Semantik Status** | Success (`#E8F5E9` / `#2E7D32`), Warning (`#FFF8E1` / `#B45309`), Info (`#E3F2FD` / `#1565C0`), Error (`#D64545`) | `SwStatusBadge`, validasi form, QC grade, dan state error |

**Catatan Perbaikan Kontras Minor:**
- Pada `_UserTopNavbar` (`PUSAKA SENI KERATON`), `NavigationRail` non-aktif di kedua shell, serta label caption pada `AuthHeritageBackdrop`, pemakaian `AppColors.canvas.withValues(alpha: 0.55)`–`0.60` di atas hijau gelap kurang kontras pada layar mobile di luar ruangan. Disarankan dinaikkan ke minimal `alpha: 0.75`.
- Pada `NavigationBar` mobile di `UserAppShell`, warna teks label tab memakai tema default atau warna pucat di atas `brandGreenDark`; perlu dipastikan `NavigationBarTheme` di dalam `UserAppShell` konsisten terang (`gold` saat aktif, `canvas` alpha `0.78` saat non-aktif) agar terbaca jelas.

### 3.2. Peta Komponen Inti Eksisting (Dipertahankan)
Seluruh 11 widget di `lib/core/widgets/` sudah menjadi fondasi desain yang solid:
- `SwButton` (5 varian: `primary`, `secondary`, `gold`, `destructive`, `ghost`), `SwCard`, `SwMetricCard` (4 pastel tone), `SwStatusBadge` (`fromOrderStatus` & `fromRole`), `SwFilterChip`, `SwInput` & `SwSearchBar`, `SwImage` (aset lokal + `CachedNetworkImage`), `SwEmptyState`, `SwErrorView`, `SwLoadingSkeleton` & `SwCardSkeleton`, serta `SwConfirmDialog`.

### 3.3. Temuan "AI Slop" & Tata Letak yang Perlu Dibenahi
Hasil audit memastikan aplikasi sudah bersih dari emoji berlebihan, tetapi ditemukan 6 item pola dekoratif/inkonsistensi berikut:
1. **Simulasi Audio Palsu (`HeritageAudioPlayer`):** Widget ini menampilkan tombol Play, equalizer animasi (`AnimationController`), pemilihan 3 laras gamelan, dan slider volume `0–100%`, tetapi **tidak memutar audio sama sekali**. Ini melanggar prinsip desain jujur dan fungsional—perlu diubah menjadi kartu info *"Nuansa Gending Pengiring"* yang fungsional (misal menampilkan rekomendasi gending & filosofi pengiring tanpa kontrol volume/play palsu, kecuali nantinya dipasang audio player nyata).
2. **Panah ASCII Mentah `->` di 3 Lokasi UI:**
   - `booking_success_screen.dart:86`: `'halaman Profil -> Pesanan Saya'`
   - `profile_screen.dart:1616–1617`: `'Sewa Busana ->'` / `'Lihat Galeri ->'`
   - `admin_costumes_screen.dart:766`: `'... -> Stok: ...'`
   Semua harus diganti dengan ikon Material (`Icons.arrow_forward_rounded` / teks natural Indonesia) agar seragam.
3. **Hardcoded Deposit di `CostumeRentalSheet` (`costume_rental_sheet.dart:219`):** Masih menampilkan `CurrencyFormatter.formatRupiah(100000)` padahal `BookingFormScreen` sudah dinamis mengikuti `publicSettingsProvider`.
4. **Breadcrumb In-Body Gaya Web (`AboutHistoryScreen`, `AboutCuratorsScreen`, `BlogDetailScreen`):** Tombol teks `<- Kembali ke ...` di atas konten tepat di bawah AppBar terlihat seperti navigasi HTML yang dipaksakan—sebaiknya dipindah menjadi native **Back button di AppBar/TopBar** atau layar stack penuh di `rootNavigatorKey`.
5. **Duplikasi Pintu Masuk & Shortcut Navigasi:**
   - `LoginScreen` memiliki tab `Admin` sekaligus tombol footer `Gerbang Admin`.
   - `UserDashboardScreen` mengulang 3 dari 4 menu yang sudah permanen ada di Bottom Navigation Bar.
6. **Aset Tidak Terpakai (`assets/images/mockup-ui-user-admin.png`, 194.8 KB):** Hanya tercatat dalam daftar konstanta `app_config.dart:69` dan tidak ditampilkan di layar mana pun—dapat dibersihkan agar bundle APK/Web lebih ringan.

---

## 4. Rencana Animasi & Transisi Terarah (*Directional Slide Animations*)

Untuk memberi petunjuk visual arah navigasi maju, mundur, serta perpindahan tahap secara natural di Flutter, akan dibangun modul transisi terpusat **`lib/core/router/sw_page_transitions.dart`** dengan durasi standar **`280ms` masuk / `240ms` keluar** dan kurva **`Curves.easeOutCubic`** (masuk) / **`Curves.easeInCubic`** (keluar).

### 4.1. Transisi Halaman Router (`CustomTransitionPage`)

| Arah & Jenis Transisi | Rute Penerapan | Makna UX Bagi User |
| :--- | :--- | :--- |
| **Slide Horizontal**<br>Maju: kanan -> kiri (`Offset(1, 0)` -> `Offset.zero`)<br>Kembali: kiri -> kanan | • `/login` <-> `/register`, `/forgot-password`, `/admin/login`<br>• `/galeri` <-> `/galeri/:id`<br>• `/kostum` <-> `/kostum/:id`<br>• -> `/pesan`<br>• `/tentang` <-> `/tentang/sejarah`, `/tentang/kurator`<br>• `/warta` <-> `/warta/:slug`<br>• Admin sub-pages: `/admin/loket`, `/admin/kunjungan`, `/admin/acara`, `/admin/kupon`, `/admin/ulasan`, `/admin/audit`, `/admin/docs`, `/admin/kategori`, `/admin/kostum`, `/admin/galeri/baru` | Memberi rasa kedalaman hierarki (master -> detail atau hub -> sub-modul) dan memvisualisasikan dengan jelas saat user kembali (Back). |
| **Slide Vertikal Halus + Fade**<br>Bawah -> atas (`Offset(0, 0.14)` -> `Offset.zero`) | • `/pesan/sukses/:id` | Menandai penyelesaian transaksi / konfirmasi puncak yang muncul lembut setelah submit order. |
| **Cross-Fade Ringan (`180ms`)** | • Pergantian cabang utama antar tab di `StatefulShellRoute` | Menjaga kestabilan kerangka shell tanpa gerakan horizontal yang membingungkan di level root tab. |

### 4.2. Transisi Dalam Layar (*In-Page Directional `AnimatedSwitcher`*)

| Layar | Titik Transisi | Arah Animasi |
| :--- | :--- | :--- |
| **BookingFormScreen** | Step 1 <-> Step 2 <-> Step 3 | Melacak `_previousStep`: maju menggeser konten baru dari kanan (`Offset(0.18, 0)`), mundur menggeser konten dari kiri (`Offset(-0.18, 0)`) + fade. |
| **ForgotPasswordScreen** | Tahap Request -> Kode OTP -> Sukses | Slide horizontal terarah maju saat berpindah ke input kode dan halaman sukses. |
| **ProfileScreen** | Tab `Sewa` (0) <-> `E-Tiket` (1) <-> `Favorit` (2) | Geser kiri/kanan proporsional terhadap perbandingan indeks tab lama dan tab baru. |
| **ScheduleScreen** | Segmen `Mendatang` <-> `Selesai` | Slide horizontal dua arah sesuai posisi tab kiri/kanan. |
| **AdminPosScreen** | Mode `Kasir Loket` <-> `Gate Scanner` | Slide horizontal dua arah untuk membedakan mode loket jual vs scan gerbang. |

---

## 5. Actionable Checklist Phase 2 (Urut Prioritas P0 -> P3)

> **Aturan Siklus Eksekusi Phase 2:**  
> `Edit/Buat File` -> `Jalankan flutter analyze & flutter test` -> `Pastikan 0 Error` -> `Centang [x] di file ini` -> `Lapor singkat & lanjut item berikutnya`.

### Prioritas P0 — Fondasi Routing, Navigasi Back, `PopScope` & Slide Transitions
- [x] **P0.1** Buat `lib/core/router/sw_page_transitions.dart` berisi helper `CustomTransitionPage` (`buildSlideTransitionPage` dan `buildVerticalFadeTransitionPage`) dengan `Curves.easeOutCubic` yang ramah aksesibilitas (`disableAnimations`).
- [x] **P0.2** Refactor `lib/core/router/app_router.dart`:
  - Gunakan `parentNavigatorKey: rootNavigatorKey` untuk sub-halaman full-screen bebas *double chrome* (`/galeri/:id`, `/kostum/:id`, `/pesan`, `/pesan/sukses/:id`, `/warta/:slug`, `/tentang/sejarah`, `/tentang/kurator`).
  - Terapkan `sw_page_transitions.dart` pada sub-rute User, Auth, Edukasi, dan Admin.
  - Dukung query parameter `?tab=` pada `/profil` agar navigasi langsung ke tab `tickets`/`wishlist`/`orders` akurat.
- [x] **P0.3** Perbarui `UserAppShell` (`lib/core/layout/user_app_shell.dart`):
  - Bungkus shell dengan `PopScope` agar *System Back* menutup drawer, keluar dari sub-halaman non-tab, atau kembali ke tab Beranda sebelum keluar app.
  - Jadikan `_UserTopNavbar` kontekstual: tampilkan tombol Back + judul halaman ketika berada di sub-rute non-tab (mis. `/tentang`, `/warta`, `/jadwal/hari-ini`).
  - Tingkatkan kontras subtitle/label tab pada permukaan hijau gelap (`alpha >= 0.75`).
- [x] **P0.4** Perbarui `AdminAppShell` (`lib/core/layout/admin_app_shell.dart`) & `CommandPaletteDialog` (`lib/core/layout/command_palette_dialog.dart`):
  - Tambahkan `PopScope` di `AdminAppShell`.
  - Jadikan `_AdminTopBar` kontekstual: tampilkan tombol Back ke Dashboard + judul sub-halaman pada 9 sub-halaman admin non-tab (`/admin/loket`, `/admin/kunjungan`, `/admin/acara`, `/admin/kupon`, `/admin/ulasan`, `/admin/audit`, `/admin/docs`, `/admin/kategori`, `/admin/kostum`, `/admin/galeri/baru`).
  - Perbarui `CommandPaletteDialog` agar menjaga riwayat navigasi saat membuka sub-halaman admin.

### Prioritas P1 — Flow Autentikasi & Transaksi Kritis User
- [x] **P1.1** Refactor Modul Auth (`auth_heritage_backdrop.dart`, `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`, `admin_login_screen.dart`):
  - Tambahkan parameter `showBackButton` & `onBack` pada `AuthHeritageBackdrop` untuk `/register`, `/forgot-password`, dan `/admin/login`.
  - Tambahkan CTA jelas **"Jelajahi sebagai Tamu"** di `LoginScreen` dan hilangkan tautan ganda `Gerbang Admin` di footer (karena role toggle `Admin` sudah ada di atas).
  - Tambahkan directional slide `AnimatedSwitcher` pada 3 tahap `ForgotPasswordScreen`.
- [x] **P1.2** Refactor Alur Sewa Kostum (`costume_rental_sheet.dart`, `booking_form_screen.dart`, `booking_success_screen.dart`):
  - Di `CostumeRentalSheet`, baca deposit dari `publicSettingsProvider` (hilangkan hardcode `Rp 100.000`) dan navigasikan ke `/pesan` menggunakan `push` agar tombol Back kembali bersih.
  - Di `BookingFormScreen`, tambahkan AppBar dengan tombol Back + `PopScope` (mundur step dari 3 -> 2 -> 1 atau konfirmasi keluar jika di Step 1), serta directional slide `AnimatedSwitcher` antar-step.
  - Di `BookingSuccessScreen`, tambahkan `PopScope` agar user tidak kembali ke form terkirim saat menekan Back, serta perbaiki copy menjadi *"halaman Profil pada tab Sewa"* (tanpa `->`).
- [x] **P1.3** Refactor Alur Jadwal & Kursi (`schedule_screen.dart`, `theater_seat_map_sheet.dart`):
  - Di `ScheduleScreen`, tampilkan tombol Back saat mode `Hari Ini` / `Harian`, sembunyikan segmented control `Mendatang | Selesai` ketika mode `Hari Ini`, dan tambahkan directional slide antar segmen.
  - Di `TheaterSeatMapSheet`, arahkan tombol `"Lihat E-Tiket"` ke `'${AppRoutes.userProfile}?tab=tickets'`.

### Prioritas P2 — Halaman Detail, Beranda, Edukasi & Pembersihan Anti-AI Slop
- [x] **P2.1** Refactor `GalleryDetailScreen`, `CostumeDetailScreen`, & `HeritageAudioPlayer`:
  - Hilangkan *double chrome* (bersihkan struktur `Scaffold` + `SafeArea` top bar agar tampil mulus di `rootNavigatorKey` dengan satu Back button + satu bottom CTA bar tanpa bertumpuk Bottom Nav).
  - Tambahkan tombol Wishlist & Share pada hero `CostumeDetailScreen` agar konsisten dengan `GalleryDetailScreen`.
  - Ubah `HeritageAudioPlayer` dari kontrol play/volume simulasi yang menyesatkan menjadi kartu informatif *"Rekomendasi Gending Pengiring"* yang jujur dan fungsional (tanpa tombol play palsu).
- [x] **P2.2** Refactor `UserDashboardScreen`:
  - Ganti 4 kotak Quick Menu yang menduplikasi Bottom Nav dengan pintasan bernilai tambah: `Sewa Busana`, `Pentas Hari Ini`, `Warta Budaya`, `Sejarah 1899`.
  - Buat kartu `Pagelaran Terdekat` langsung membuka `TheaterSeatMapSheet` untuk event yang dipilih (dengan fallback aman ke `/jadwal`).
- [x] **P2.3** Refactor `ProfileScreen` & Halaman Edukasi (`about_screen.dart`, `about_history_screen.dart`, `about_curators_screen.dart`, `blog_list_screen.dart`, `blog_detail_screen.dart`):
  - Tambahkan dukungan `initialTab` pada `ProfileScreen` (`?tab=orders|tickets|wishlist`), directional slide `AnimatedSwitcher` antar tab, serta ganti panah ASCII `->` pada kartu Favorit dengan ikon Material.
  - Rapikan `AboutHistoryScreen`, `AboutCuratorsScreen`, dan `BlogDetailScreen` dengan tombol Back AppBar yang menghormati `canPop()` serta hilangkan breadcrumb duplikat.

### Prioritas P3 — Polish Admin Screens, Aset & Verifikasi Akhir
- [x] **P3.1** Polish `AdminPosScreen` (tambahkan directional slide antara mode `Kasir Loket` <-> `Gate Scanner`) dan `AdminCostumesScreen` (ganti panah ASCII `->` pada riwayat mutasi stok).
- [x] **P3.2** Bersihkan aset tak terpakai (`assets/images/mockup-ui-user-admin.png` dan entri di `lib/core/config/app_config.dart`), tambahkan widget test untuk alur Back/`PopScope`/directional transition/`?tab=tickets`, lalu jalankan validasi penuh (`flutter analyze` = 0 error dan semua `flutter test` lulus).
