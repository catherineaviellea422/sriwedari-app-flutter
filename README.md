# Galeri Sriwedari (Flutter App)

Aplikasi mobile & web resmi **Galeri Sriwedari Surakarta** untuk pelestarian arsip seni tari Nusantara, penyewaan busana adat keraton multi-item dengan sistem deposit QC, pemesanan tiket kursi teater Wayang Orang, serta portal operasional Kurator/Admin.

---

## Fitur Utama

### Portal Pengunjung (User)
- **Beranda & Galeri Budaya:** Arsip foto/video seni tari dengan pencarian, filter kategori, wishlist/favorit, audio rekomendasi gending gamelan, serta ulasan budaya.
- **Katalog & Sewa Busana Multi-Item:** Pemesanan kostum bertahap (Data Diri -> Pilih Kostum & Durasi -> Kupon Promo & Metode Pembayaran) lengkap dengan validasi input ketat dan pemilih tanggal `calendarOnly`.
- **Jadwal & Peta Kursi Teater:** Reservasi tiket pertunjukan Wayang Orang 3 zona (VIP, Reguler, Balkon) dengan pencegahan *double-booking* & E-Tiket QR Boarding Pass.
- **Edukasi & Warta Budaya:** Kronik sejarah Taman Sriwedari (1899), profil Dewan Kurator, dan artikel warta budaya.
- **Profil & Riwayat Transaksi:** Unggah bukti transfer, pantau status inspeksi QC pengembalian deposit, e-tiket, dan daftar favorit.

### Portal Kurator (Admin)
- **Dashboard Analitik:** Ringkasan KPI omzet, dana escrow deposit, grafik kunjungan 7 hari (`fl_chart`), koleksi terpopuler, dan log aktivitas.
- **Manajemen Operasional:** CRUD Galeri, Kategori, Kostum + Ledger Mutasi Stok, Jadwal & Tarif Zona, Antrean Pesanan & Mesin Inspeksi QC Retur (Grade A–D), Kupon Diskon, Moderasi Ulasan, Kelola Akun, Kasir Loket Walk-In (POS + Gate Check-In), Audit Trail (Ekspor CSV), & Pengaturan Sistem.

---

## Struktur Proyek

```text
lib/
├── core/
│   ├── config/        # AppConfig (dev/staging/prod), AssetResolver
│   ├── layout/        # UserAppShell & AdminAppShell responsif
│   ├── motion/        # SwScrollBehavior, ScaleOnTap, FadeSlideEntrance, SwContentSwitcher
│   ├── network/       # ApiClient (Dio) dengan isolasi token User vs Admin
│   ├── router/        # GoRouter + Role Guard & transisi slide terarah
│   ├── storage/       # UserLocalStorage & AdminLocalStorage terpisah
│   ├── theme/         # Palet warna Nusantara Heritage Elegance, tipografi, spacing
│   ├── utils/         # SwValidators, SwInputFormatters, CurrencyFormatter, DateFormatter
│   └── widgets/       # Core design system (SwButton, SwCard, SwInput, SwImage, dll.)
└── features/
    ├── auth/          # Login User/Admin, Register, Lupa Kata Sandi
    ├── user/          # Dashboard, Galeri, Kostum, Jadwal, Booking, Profil
    ├── about_blog/    # Tentang Sriwedari, Sejarah, Kurator, Warta Budaya
    └── admin/         # Seluruh modul operasional Kurator/Admin
```

---

## Prasyarat & Menjalankan Lokal

Pastikan backend **`sriwedari-backend`** sudah berjalan di `http://localhost:5000`:

```powershell
# Terminal 1 — Backend Express + TypeScript
cd ..\sriwedari-backend
npm install
npm run dev
```

Kemudian jalankan aplikasi Flutter di **Terminal 2**:

```powershell
cd sriwedari_app_flutter
flutter pub get

# Web (Chrome) — disarankan memakai web-server agar extension Chrome pribadi tetap aktif
flutter run -d web-server --web-port=8080

# Atau langsung di Chrome / Edge / Android Emulator:
flutter run -d chrome
flutter run
```

Untuk perangkat HP fisik dalam jaringan Wi-Fi yang sama, arahkan `API_BASE_URL` ke IP lokal laptop:

```powershell
flutter run --dart-define=API_BASE_URL=http://<IP_LOKAL_LAPTOP>:5000
```

Untuk build rilis produksi (tombol demo otomatis disembunyikan):

```powershell
flutter build web --release --dart-define=APP_FLAVOR=prod --dart-define=API_BASE_URL=https://api-domain-anda.com
```

---

## Akun Demo (Mode `dev`)
- **Pengunjung (User):** `oliv@example.com` / `rahasia123`
- **Kurator (Admin):** `admin@galerisriwedari.id` / `rahasia123`

---

## Pengujian & Kualitas Kode

```powershell
flutter analyze
flutter test
```

Dokumentasi audit & optimasi teknis tersimpan di [AUDIT_REPORT.md](AUDIT_REPORT.md) dan [MOTION_PLAN.md](MOTION_PLAN.md).
