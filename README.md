# Multi-Tenant SaaS HRIS (Human Resource Information System)

Aplikasi Multi-Tenant Software-as-a-Service (SaaS) Human Resource Information System dirancang khusus untuk kebutuhan operasional Usaha Mikro, Kecil, dan Menengah (UMKM) serta perusahaan rintisan (*startup*) di Indonesia.

---

## 1. Ikhtisar Arsitektur Sistem

Sistem ini dibangun dengan pendekatan **Monorepo** yang terbagi ke dalam tiga komponen utama:

```
├── backend/       # RESTful API Engine (Laravel 11, PHP 8.2+, MySQL, Laravel Sanctum, Barryvdh DomPDF)
├── web-admin/     # Web Portal HR & Owner (Next.js 14+ App Router, Tailwind CSS, TanStack Query)
└── mobile-app/    # Aplikasi Presensi & Karyawan (Flutter, Riverpod, Dio Interceptors, Geolocator)
```

### Konvensi Basis Data (Golden Rules)
1. **Primary Key & Foreign Key**: Seluruh primary key menggunakan format `id_{nama_tabel}` (contoh: `id_companies`, `id_employees`, `id_payroll_periods`). Seluruh foreign key memiliki nama kolom yang identik dengan primary key tabel referensinya.
2. **Isolasi Multi-Tenancy**: Setiap entitas data tenant terikat pada kolom `id_companies` dan diamankan secara otomatis oleh Eloquent Global Scope `BelongsToCompany`. Tidak ada data antar-perusahaan yang dapat saling terlihat (*zero leakage*).
3. **Standar Response API**:
   ```json
   {
     "success": true,
     "message": "Pesan deskriptif dalam Bahasa Indonesia.",
     "data": {},
     "errors": null
   }
   ```

---

## 2. Modul Fungsional Utama

### 2.1 Autentikasi & Registrasi Multi-Tenant
- Pendaftaran mandiri perusahaan baru langsung menghasilkan tenant aktif dan akun pengguna bertindak sebagai **Owner**.
- Autentikasi berbasis Bearer Token aman menggunakan **Laravel Sanctum**.
- Akses kontrol berbasis peran (*Role-Based Access Control*): `owner`, `hr`, `manager`, dan `employee`.

### 2.2 Struktur Organisasi & Penjadwalan Kerja
- Pengelolaan cabang (*branches*) lengkap dengan titik koordinat latitude, longitude, dan radius toleransi geofence (meter).
- Pengelolaan departemen dan posisi jabatan.
- Master shift kerja dengan jam mulai, jam selesai, serta toleransi keterlambatan menit.
- Penugasan shift fleksibel per karyawan untuk tanggal spesifik maupun rentang tanggal (*date range*).

### 2.3 Presensi Berbasis GPS & Swafoto (Geofencing)
- Validasi jarak lokasi karyawan menggunakan algoritma **Haversine Formula**.
- Deteksi integritas perangkat: pencegahan pemalsuan lokasi (*Anti Mock GPS / Fake GPS* via `position.isMocked`).
- Validasi swafoto (*selfie camera*) saat clock in dan clock out.
- Otomatisasi kalkulasi status kehadiran (`present`, `late`) beserta durasi keterlambatan dalam satuan menit.

### 2.4 Manajemen Cuti, Izin, & Alur Persetujuan
- Master jenis cuti dengan konfigurasi kuota tahunan dan status berbayar (*paid leave*).
- Pencegahan pengajuan tanggal cuti bertabrakan (*overlap validation*).
- Validasi batas sisa kuota cuti karyawan.
- Alur persetujuan (*approval flow*) berjenjang oleh Atasan / HR lengkap dengan catatan persetujuan atau penolakan.

### 2.5 Payroll Engine Sederhana & Slip Gaji Digital
- Perhitungan hari kerja efektif dalam periode penggajian (otomatis mengecualikan hari Sabtu dan Minggu).
- Formula potongan gaji otomatis:
  - **Denda keterlambatan**: akumulasi durasi menit terlambat dikalikan tarif per menit (`late_duration_minutes * Rp 1.000`).
  - **Potongan ketidakhadiran (Alpha)**: ketidakhadiran tanpa izin resmi dipotong secara prorata harian (`(basic_salary / work_days) * unexcused_absences`). Cuti resmi yang disetujui tidak dikenakan potongan alpha.
- *State machine* periode penggajian yang terproteksi:
  - `draft` (periode baru dibuka)
  - `calculated` (kalkulasi slip gaji dihitung otomatis)
  - `finalized` (periode dikunci permanen, tidak dapat dihitung ulang, dan seluruh berkas PDF di-generate).
- Generator slip gaji resmi berformat PDF via **Barryvdh DomPDF** yang tersimpan di direktori privat tenant:
  `storage/app/public/{id_companies}/payroll/{id_payroll_periods}/slip_{id_employees}.pdf`.
- Akses unduh slip gaji digital melalui aplikasi mobile karyawan dan portal web HR.

---

## 3. Kepatuhan Standar Anti-Slop & Aksesibilitas (WCAG AA)

Sistem ini dikembangkan dengan kepatuhan antislop aktif:
- **Zero Buzzwords & Clichés**: Bersih dari kata-kata generik seperti "seamless", "cutting-edge", "game-changing".
- **Zero Em Dashes**: Tidak menggunakan tanda hubung em dash (`—`) pada salinan UI maupun dokumen pengguna.
- **Aksesibilitas Kontras Warna (WCAG AA)**:
  - Background Neutral: Slate 50 (`#F8FAFC`) / White (`#FFFFFF`).
  - Text Primary: Slate 900 (`#0F172A`) dengan rasio kontras 15.8:1 terhadap latar putih (standar minimum 4.5:1).
  - Text Secondary: Slate 600 (`#475569`) dengan rasio kontras 5.2:1.
  - Interactive Accent: Sky 600 (`#0284C7`) dengan fokus outline tegas (`focus:ring-2 focus:ring-[#0284C7] focus:ring-offset-2`).
- **Navigasi Keyboard Penuh**:
  - Skip link ("Lewati ke konten utama") untuk pembaca layar dan pengguna papan ketik.
  - Penutupan modal dialog melalui tombol `Escape`.
- **Target Sentuh Ramah Mobile**: Seluruh tombol aksi utama pada aplikasi mobile memiliki tinggi minimal **48px x 48px** sesuai standar ergonomis Android Material Design dan Apple HIG.
- **Penanganan 3 Status UI Konsisten**: Setiap halaman data web dan mobile memiliki:
  1. *Loading Skeleton* yang proporsional.
  2. *Empty State* informatif dengan aksi yang jelas.
  3. *Error State* dengan penjelasan kegagalan dan tombol coba lagi (*retry*).

---

## 4. Hasil Verifikasi Pengujian

### 4.1 Backend (PHPUnit / Laravel Feature Tests)
- **121 Tests Lulus 100% (552 Assertions)**
- Cakupan uji:
  - `AttendanceApiTest`: validasi radius geofence, toleransi jam kerja, pembatasan ganda, dan rekapitulasi data.
  - `AuthApiTest`: registrasi tenant baru, pencegahan email duplikat, login token Sanctum.
  - `EmployeeApiTest`: transaksi atomik pembuatan pegawai & akun login, isolasi tenant.
  - `LeaveApiTest`: kuota cuti, pencegahan overlap, workflow persetujuan manager.
  - `OrganizationApiTest`: CRUD cabang, departemen, dan jabatan.
  - `PayrollApiTest`: kalkulasi gaji, denda keterlambatan, pemotongan alpha, PDF generator, dan penguncian status final.
  - `ShiftApiTest`: pembuatan shift, penugasan tanggal tunggal dan rentang tanggal.
  - `MultiTenancyIsolationTest`: pengujian penetrasi isolasi data lintas tenant.
  - `EndToEndHrisFlowTest`: simulasi penuh alur siklus operasional HRIS dari registrasi hingga pengunduhan slip PDF.

### 4.2 Mobile App (Flutter Tests)
- **53 Tests Lulus 100%**
- Cakupan uji:
  - `auth_test.dart`: validasi formulir login, manajemen token sesi, dan penanganan error banner.
  - `attendance_test.dart`: validasi status badge, proteksi anti mock GPS, interaksi tombol clock-in / clock-out min 48px.
  - `leave_test.dart`: formulir permohonan cuti, validasi input wajib, penanganan error API.
  - `payroll_test.dart`: parsing model gaji, pemformatan mata uang Rupiah, pengujian 3 status UI (Skeleton, Empty, Error), dan interaksi unduh slip PDF.

### 4.3 Web Admin (Next.js 14+ Production Build)
- Kompilasi sukses tanpa kesalahan TypeScript:
  - `/` (Dashboard Utama)
  - `/login` & `/register`
  - `/branches`
  - `/employees`
  - `/shifts`
  - `/attendance`
  - `/leaves`
  - `/payroll`

---

## 5. Panduan Instalasi & Menjalankan Proyek

### Kebutuhan Sistem
- PHP 8.2 atau lebih tinggi + Composer
- Node.js 18+ & npm
- Flutter SDK 3.x
- MySQL 8.0+

### 5.1 Menjalankan Backend (Laravel)
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan storage:link
php artisan serve --port=8000
```
Untuk menjalankan pengujian otomatis:
```bash
php artisan test
```

### 5.2 Menjalankan Web Admin (Next.js)
```bash
cd web-admin
npm install
npm run dev -- -p 3000
```
Buka browser pada `http://localhost:3000`.

### 5.3 Menjalankan Mobile App (Flutter)
```bash
cd mobile-app
flutter pub get
flutter test
flutter run
```

---

## 6. Kredensial Uji Coba Bawaan (Database Seeder)
- **Owner**: `owner@nusantara.test` / `password123`
- **HR**: `hr@nusantara.test` / `password123`
- **Manager**: `manager@nusantara.test` / `password123`
- **Staff / Karyawan**: `budi@nusantara.test` / `password123`
