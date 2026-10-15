import os
import sys
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.pdfgen import canvas
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    KeepTogether,
    HRFlowable,
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT, TA_JUSTIFY


class NumberedCanvas(canvas.Canvas):
    """
    Dua lintasan canvas untuk menghitung total halaman secara dinamis
    serta menggambar running header dan footer dengan rapi.
    """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()

        # Running Header (muncul mulai halaman ke-2)
        if self._pageNumber > 1:
            self.setFont("Helvetica-Bold", 7.5)
            self.setFillColor(colors.HexColor("#0B2545"))
            self.drawString(36, 810, "DOKUMEN SPESIFIKASI FITUR DAN BASIS DATA SISTEM HRIS & SPK SMART")

            self.setFont("Helvetica", 7.5)
            self.setFillColor(colors.HexColor("#64748B"))
            self.drawRightString(559, 810, "PT. Steel Pipe Industry of Indonesia")

            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.6)
            self.line(36, 804, 559, 804)

        # Running Footer (seluruh halaman)
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.6)
        self.line(36, 40, 559, 40)

        self.setFont("Helvetica", 7.5)
        self.setFillColor(colors.HexColor("#64748B"))
        self.drawString(36, 28, "Dokumen Teknis Kepegawaian - Hak Cipta Terpelihara (Internal Organisasi)")

        page_str = f"Halaman {self._pageNumber} dari {page_count}"
        self.drawRightString(559, 28, page_str)

        self.restoreState()


def build_pdf(filename="Dokumentasi_Fitur_dan_Database_HRIS_SPK_SMART.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=46,
        bottomMargin=48,
    )

    # Lebar area cetak = 595.27 - 72 = 523.27 pt
    content_width = 523.27

    # Palette Warna
    c_primary = colors.HexColor("#0B2545")     # Deep Navy
    c_secondary = colors.HexColor("#1E3A8A")   # Blue Slate
    c_accent = colors.HexColor("#047857")      # Forest Emerald
    c_dark = colors.HexColor("#1E293B")        # Slate 800
    c_muted = colors.HexColor("#475569")       # Slate 600
    c_border = colors.HexColor("#CBD5E1")      # Slate 300
    c_bg_light = colors.HexColor("#F8FAFC")    # Slate 50
    c_badge_bg = colors.HexColor("#E0F2FE")    # Light Sky
    c_badge_text = colors.HexColor("#0369A1")

    # Typography Styles
    base_styles = getSampleStyleSheet()

    doc_title = ParagraphStyle(
        "DocTitle",
        fontName="Helvetica-Bold",
        fontSize=18,
        leading=22,
        textColor=c_primary,
        alignment=TA_LEFT,
        spaceAfter=4,
    )

    doc_subtitle = ParagraphStyle(
        "DocSubtitle",
        fontName="Helvetica",
        fontSize=9.5,
        leading=13.5,
        textColor=c_muted,
        alignment=TA_LEFT,
        spaceAfter=8,
    )

    meta_text = ParagraphStyle(
        "MetaText",
        fontName="Helvetica",
        fontSize=7.5,
        leading=10.5,
        textColor=c_muted,
    )

    meta_bold = ParagraphStyle(
        "MetaBold",
        fontName="Helvetica-Bold",
        fontSize=7.5,
        leading=10.5,
        textColor=c_primary,
    )

    sec_title = ParagraphStyle(
        "SecTitle",
        fontName="Helvetica-Bold",
        fontSize=11.5,
        leading=15,
        textColor=c_primary,
        spaceBefore=14,
        spaceAfter=6,
        keepWithNext=True,
    )

    sub_sec_title = ParagraphStyle(
        "SubSecTitle",
        fontName="Helvetica-Bold",
        fontSize=9.5,
        leading=13,
        textColor=c_secondary,
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True,
    )

    body_text = ParagraphStyle(
        "BodyText",
        fontName="Helvetica",
        fontSize=8,
        leading=11.5,
        textColor=c_dark,
        alignment=TA_JUSTIFY,
        spaceAfter=5,
    )

    body_bold = ParagraphStyle(
        "BodyBold",
        fontName="Helvetica-Bold",
        fontSize=8,
        leading=11.5,
        textColor=c_dark,
    )

    bullet_text = ParagraphStyle(
        "BulletText",
        fontName="Helvetica",
        fontSize=8,
        leading=11.5,
        textColor=c_dark,
        leftIndent=12,
        firstLineIndent=-8,
        spaceAfter=3,
    )

    th_text = ParagraphStyle(
        "TableHeader",
        fontName="Helvetica-Bold",
        fontSize=7.5,
        leading=9.5,
        textColor=colors.white,
        alignment=TA_LEFT,
    )

    th_center = ParagraphStyle(
        "TableHeaderCenter",
        fontName="Helvetica-Bold",
        fontSize=7.5,
        leading=9.5,
        textColor=colors.white,
        alignment=TA_CENTER,
    )

    td_text = ParagraphStyle(
        "TableCell",
        fontName="Helvetica",
        fontSize=7.5,
        leading=9.5,
        textColor=c_dark,
        alignment=TA_LEFT,
    )

    td_center = ParagraphStyle(
        "TableCellCenter",
        fontName="Helvetica",
        fontSize=7.5,
        leading=9.5,
        textColor=c_dark,
        alignment=TA_CENTER,
    )

    td_bold = ParagraphStyle(
        "TableCellBold",
        fontName="Helvetica-Bold",
        fontSize=7.5,
        leading=9.5,
        textColor=c_dark,
        alignment=TA_LEFT,
    )

    td_code = ParagraphStyle(
        "TableCellCode",
        fontName="Courier-Bold",
        fontSize=7,
        leading=9,
        textColor=c_secondary,
        alignment=TA_LEFT,
    )

    td_muted = ParagraphStyle(
        "TableCellMuted",
        fontName="Helvetica",
        fontSize=7,
        leading=9,
        textColor=c_muted,
        alignment=TA_LEFT,
    )

    story = []

    # =========================================================================
    # HEADER DOKUMEN & KOTAK IDENTITAS SISTEM
    # =========================================================================
    story.append(Paragraph("SPESIFIKASI FITUR DAN BASIS DATA SISTEM HRIS & SPK SMART", doc_title))
    story.append(
        Paragraph(
            "Ringkasan Arsitektur Fungsional dan Skema Struktur Tabel Database Terkonsolidasi",
            doc_subtitle,
        )
    )

    # Meta Info Card
    meta_data = [
        [
            Paragraph("<b>Instansi:</b> PT. Steel Pipe Industry of Indonesia (SPINDO)", meta_text),
            Paragraph("<b>Status Sistem:</b> Single-Tenant Enterprise", meta_text),
            Paragraph("<b>Tanggal Terbit:</b> 15 Oktober 2026", meta_text),
        ],
        [
            Paragraph("<b>Backend:</b> Laravel 11 (PHP 8.2+), Sanctum REST API", meta_text),
            Paragraph("<b>Frontend Web:</b> Next.js 14+ App Router, Tailwind CSS", meta_text),
            Paragraph("<b>Aplikasi Mobile:</b> Flutter SDK (Android & iOS)", meta_text),
        ],
    ]
    meta_table = Table(meta_data, colWidths=[180, 175, 168.27])
    meta_table.setStyle(
        TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), c_bg_light),
            ("BOX", (0, 0), (-1, -1), 0.8, c_border),
            ("INNERGRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#E2E8F0")),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ("LEFTPADDING", (0, 0), (-1, -1), 7),
            ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ])
    )
    story.append(meta_table)
    story.append(Spacer(1, 10))

    # =========================================================================
    # BAGIAN 1: ARSITEKTUR & PRINSIP DESAIN
    # =========================================================================
    story.append(Paragraph("1. Arsitektur dan Standar Sistem", sec_title))
    story.append(
        Paragraph(
            "Sistem Informasi Manajemen Sumber Daya Manusia (HRIS) dan Sistem Pendukung Keputusan (SPK) SMART ini "
            "dibangun untuk memenuhi kebutuhan operasional internal perusahaan secara terpusat. "
            "Aplikasi menggabungkan tiga pilar teknologi utama: backend Laravel 11 dengan token Bearer Sanctum, "
            "antarmuka web admin Next.js 14 dengan sistem rendering modern, serta aplikasi mobile Flutter untuk presensi mandiri karyawan di lapangan.",
            body_text,
        )
    )
    story.append(
        Paragraph(
            "Standar perancangan basis data mematuhi konvensi berikut:",
            body_text,
        )
    )
    story.append(
        Paragraph(
            "- <b>Konvensi Penamaan Primary Key & Foreign Key:</b> Seluruh Primary Key wajib menggunakan pola <code>id_{nama_tabel}</code> "
            "(misal: <code>id_companies</code>, <code>id_users</code>, <code>id_employees</code>). Kolom Foreign Key yang merujuk tabel tersebut "
            "memiliki nama yang sama persis untuk menjaga konsistensi relasi antar-entitas.",
            bullet_text,
        )
    )
    story.append(
        Paragraph(
            "- <b>Integritas Referensial Ketat:</b> Seluruh foreign key dilengkapi batasan <code>ON DELETE CASCADE</code> atau "
            "<code>ON DELETE SET NULL</code> pada level database guna mencegah adanya data yatim (orphan records).",
            bullet_text,
        )
    )
    story.append(
        Paragraph(
            "- <b>Format Respon REST API Baku:</b> Semua antarmuka komunikasi data merespon format standar "
            "<code>{'success': bool, 'message': string, 'data': any, 'errors': any}</code>.",
            bullet_text,
        )
    )
    story.append(Spacer(1, 8))

    # =========================================================================
    # BAGIAN 2: RANGKUMAN FITUR APLIKASI
    # =========================================================================
    story.append(Paragraph("2. Rangkuman Fitur Aplikasi", sec_title))
    story.append(
        Paragraph(
            "Sistem mencakup modul operasional kepegawaian menyeluruh yang terbagi ke dalam 9 kelompok fungsional utama:",
            body_text,
        )
    )

    features = [
        (
            "2.1 Manajemen Akses dan Autentikasi Pengguna (RBAC)",
            "Mengelola akun login dan wewenang pengguna dengan arsitektur Role-Based Access Control bertingkat. "
            "Peran sistem mencakup Super Admin, Owner, HRD, Manager, dan Employee. Sistem juga mendukung penambahan peran kustom "
            "melalui matriks konfigurasi izin dinamis berbasis JSON yang tersimpan pada entitas perusahaan. "
            "Pengguna nonaktif dicegah masuk, dan sesi token Sanctum diamankan secara ketat.",
        ),
        (
            "2.2 Profil Perusahaan dan Pengelolaan Data Karyawan",
            "Menampung master data instansi tunggal (nama perusahaan, sektor industri, alamat, kontak kantor, nama direktur utama, "
            "dan manajer HRD untuk pengesahan dokumen resmi). Modul karyawan mengelola profil staf secara komprehensif, meliputi NIK, "
            "nama lengkap, nomor telepon, tanggal lahir, tanggal bergabung, status kerja (tetap, kontrak, probation, magang), unit divisi, "
            "jabatan posisi, nomor rekening bank pencairan gaji, dan kuota cuti tahunan.",
        ),
        (
            "2.3 Presensi Digital dengan Geofencing GPS dan Swafoto",
            "Memvalidasi absensi masuk (clock in) dan pulang (clock out) karyawan secara real-time via aplikasi mobile dan portal web. "
            "Sistem menghitung jarak posisi perangkat terhadap titik koordinat kantor dengan rumus Haversine. Absensi hanya disetujui jika berada "
            "dalam radius toleransi (default 100 meter). Dilengkapi swafoto bukti kehadiran, pencatatan waktu otomatis, toleransi keterlambatan 15 menit, "
            "serta kalkulasi otomatis durasi terlambat dan pulang lebih awal.",
        ),
        (
            "2.4 Pengajuan dan Verifikasi Izin / Cuti Karyawan",
            "Memfasilitasi pengajuan cuti tahunan, cuti khusus, maupun izin sakit oleh karyawan dengan unggahan bukti pendukung. "
            "Sistem memvalidasi sisa kuota cuti tahunan, mencegah pengajuan tanggal yang tumpang tindih (overlapping), "
            "dan menyediakan alur verifikasi dua arah (persetujuan atau penolakan dengan catatan resmi) oleh atasan atau tim HRD.",
        ),
        (
            "2.5 Pengajuan dan Persetujuan Lembur (Overtime Tracking)",
            "Karyawan dapat mencatat rencana kerja lembur mencakup tanggal, jam mulai, jam selesai, durasi jam kerja, dan alasan penugasan. "
            "Permohonan diverifikasi oleh manajer divisi sebelum masuk ke proses perhitungan upah lembur pada periode penggajian berjalan.",
        ),
        (
            "2.6 Otomasi Penggajian dan Penerbitan Slip Gaji Digital",
            "Menghitung gaji bersih karyawan secara otomatis berdasarkan komponen gaji pokok, tunjangan tetap, akumulasi upah lembur yang disetujui, "
            "serta pemotongan denda menit keterlambatan dan ketidakhadiran tanpa keterangan (alpha). Tim HRD dapat meninjau rincian slip, "
            "menerbitkan penggajian periode berjalan, dan mencetak slip gaji berformat PDF lengkap dengan tanda tangan digital pejabat perusahaan.",
        ),
        (
            "2.7 Penilaian Kinerja Karyawan Metode SPK SMART",
            "Mengimplementasikan Simple Multi-Attribute Rating Technique (SMART) untuk evaluasi kinerja objektif berkala. "
            "Kriteria penilaian mencakup parameter Benefit (contoh: disiplin kehadiran, kualitas hasil kerja, inisiatif) dan Cost (contoh: frekuensi komplain). "
            "Sistem melakukan normalisasi bobot kriteria, kalkulasi nilai utilitas, pembobotan skor akhir (0 hingga 100), perankingan staf otomatis, "
            "serta rekomendasi tindak lanjut manajerial (promosi, bonus insentif, atau program pembinaan).",
        ),
        (
            "2.8 Pusat Notifikasi Terpadu (In-App Notification Center)",
            "Menyampaikan pemberitahuan otomatis kepada pengguna terkait aktivitas operasional penting: pengajuan izin baru, keputusan approval cuti "
            "atau lembur, publikasi slip gaji bulanan, serta pengumuman evaluasi kinerja. Mendukung penandaan status baca dan tautan navigasi langsung.",
        ),
        (
            "2.9 Navigasi Aman dan Kolom Pencarian Global (Role-Gated)",
            "Menyediakan navigasi cepat melalui pintasan keyboard (Command/Ctrl + K) yang disaring berdasarkan peran akun aktif. "
            "Karyawan biasa hanya dapat mencari aksi mandiri (ajukan cuti, lembur, presensi, lihat slip gaji) dan diblokir dari pencarian data rahasia seluruh staf. "
            "Rute administratif pada web admin diproteksi komponen RoleGuard untuk menolak akses langsung melalui address bar browser.",
        ),
    ]

    for title, desc in features:
        story.append(Paragraph(title, sub_sec_title))
        story.append(Paragraph(desc, body_text))

    story.append(Spacer(1, 10))

    # =========================================================================
    # BAGIAN 3: MATRIKS HAK AKSES PENGGUNA (RBAC MATRIX)
    # =========================================================================
    rbac_elements = []
    rbac_elements.append(Paragraph("3. Matriks Hak Akses Pengguna (RBAC Matrix)", sec_title))
    rbac_elements.append(
        Paragraph(
            "Tabel berikut menguraikan pembagian wewenang operasional pada setiap modul sistem berdasarkan peran akun pengguna:",
            body_text,
        )
    )

    rbac_rows = [
        [
            Paragraph("Modul / Fitur Sistem", th_text),
            Paragraph("Pimpinan / Owner", th_center),
            Paragraph("HR (Human Resources)", th_center),
            Paragraph("Manager / Atasan", th_center),
            Paragraph("Karyawan (Employee)", th_center),
        ],
        [
            Paragraph("Profil Perusahaan", td_bold),
            Paragraph("Lihat & Edit", td_center),
            Paragraph("Lihat Saja", td_center),
            Paragraph("Tidak Ada Akses", td_center),
            Paragraph("Tidak Ada Akses", td_center),
        ],
        [
            Paragraph("Cabang, Divisi, Jabatan", td_bold),
            Paragraph("Lihat Saja", td_center),
            Paragraph("Penuh (CRUD)", td_center),
            Paragraph("Lihat Saja", td_center),
            Paragraph("Tidak Ada Akses", td_center),
        ],
        [
            Paragraph("Master Data Karyawan", td_bold),
            Paragraph("Lihat Saja", td_center),
            Paragraph("Penuh (CRUD)", td_center),
            Paragraph("Lihat Tim Sendiri", td_center),
            Paragraph("Lihat Profil Sendiri", td_center),
        ],
        [
            Paragraph("Pengaturan Shift & Roster", td_bold),
            Paragraph("Lihat Saja", td_center),
            Paragraph("Penuh (CRUD)", td_center),
            Paragraph("Atur Jadwal Tim", td_center),
            Paragraph("Lihat Jadwal Sendiri", td_center),
        ],
        [
            Paragraph("Presensi Kehadiran", td_bold),
            Paragraph("Lihat Rekap", td_center),
            Paragraph("Kelola & Monitoring", td_center),
            Paragraph("Monitoring Tim", td_center),
            Paragraph("Clock In/Out & Riwayat", td_center),
        ],
        [
            Paragraph("Pengajuan & Saldo Cuti", td_bold),
            Paragraph("Lihat Laporan", td_center),
            Paragraph("Approval & Kelola", td_center),
            Paragraph("Approval Tim", td_center),
            Paragraph("Ajukan & Cek Kuota", td_center),
        ],
        [
            Paragraph("Pengajuan Lembur", td_bold),
            Paragraph("Lihat Laporan", td_center),
            Paragraph("Approval & Rekap", td_center),
            Paragraph("Approval Tim", td_center),
            Paragraph("Ajukan Lembur Mandiri", td_center),
        ],
        [
            Paragraph("Proses Gaji (Payroll)", td_bold),
            Paragraph("Approval & Cetak", td_center),
            Paragraph("Generate & Finalisasi", td_center),
            Paragraph("Tidak Ada Akses", td_center),
            Paragraph("Unduh Slip Gaji Sendiri", td_center),
        ],
        [
            Paragraph("Penilaian Kinerja SMART", td_bold),
            Paragraph("Lihat Hasil & PDF", td_center),
            Paragraph("Kelola Kriteria & Hitung", td_center),
            Paragraph("Input Nilai Bawahan", td_center),
            Paragraph("Lihat Skor Pribadi", td_center),
        ],
        [
            Paragraph("Manajemen Role Akun", td_bold),
            Paragraph("Penuh (Ubah Role)", td_center),
            Paragraph("Aktif/Nonaktif Akun", td_center),
            Paragraph("Tidak Ada Akses", td_center),
            Paragraph("Tidak Ada Akses", td_center),
        ],
    ]

    rbac_table = Table(rbac_rows, colWidths=[127.27, 96, 106, 96, 98])
    rbac_table.setStyle(
        TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), c_primary),
            ("BOX", (0, 0), (-1, -1), 0.6, c_border),
            ("INNERGRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#E2E8F0")),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, c_bg_light]),
            ("TOPPADDING", (0, 0), (-1, -1), 4),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ("LEFTPADDING", (0, 0), (-1, -1), 5),
            ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ])
    )
    rbac_elements.append(rbac_table)
    rbac_elements.append(Spacer(1, 6))
    rbac_elements.append(
        Paragraph(
            "<b>Catatan Wewenang Khusus Super Admin:</b> Akun dengan peran Super Admin memiliki hak akses penuh setingkat root atau administrator teknis atas seluruh modul di atas, termasuk pemeliharaan database dan audit keamanan sistem.",
            td_muted,
        )
    )
    rbac_elements.append(Spacer(1, 12))
    story.append(KeepTogether(rbac_elements))

    # =========================================================================
    # BAGIAN 4: RANGKUMAN SELURUH TABEL DATABASE
    # =========================================================================
    story.append(Paragraph("4. Skema dan Spesifikasi Tabel Basis Data", sec_title))
    story.append(
        Paragraph(
            "Skema database telah dikonsolidasi menjadi 11 tabel operasional bisnis terstruktur "
            "ditambah tabel pendukung teknis framework Laravel. Setiap tabel didesain dengan tipe data terindeks untuk menjaga kecepatan kueri "
            "dan keutuhan data relasional.",
            body_text,
        )
    )

    # Definisi 11 Tabel Operasional
    tables_definition = [
        {
            "name": "companies",
            "desc": "Menyimpan data identitas resmi entitas perusahaan, titik koordinat kantor untuk geofencing presensi, dan konfigurasi peran dinamis.",
            "pk": "id_companies (BIGINT UNSIGNED)",
            "fk": "-",
            "cols": [
                ("id_companies", "BIGINT UNSIGNED", "Primary Key identitas unik entitas perusahaan"),
                ("name", "VARCHAR(150)", "Nama resmi perusahaan (PT. Steel Pipe Industry of Indonesia)"),
                ("industry", "VARCHAR(150)", "Bidang atau sektor usaha (opsional)"),
                ("email", "VARCHAR(150)", "Alamat surel resmi korespondensi perusahaan"),
                ("website", "VARCHAR(150)", "Alamat situs web resmi perusahaan (opsional)"),
                ("phone", "VARCHAR(30)", "Nomor kontak telepon kantor pusat (opsional)"),
                ("address", "TEXT", "Alamat lengkap kantor operasional pusat (opsional)"),
                ("director_name", "VARCHAR(150)", "Nama pimpinan penandatangan dokumen dan laporan SPK"),
                ("hr_manager_name", "VARCHAR(150)", "Nama manajer HRD penandatangan slip gaji resmi"),
                ("logo_url", "VARCHAR(255)", "Tautan berkas logo perusahaan (opsional)"),
                ("latitude", "DECIMAL(10,8)", "Garis lintang titik pusat kantor untuk acuan geofencing"),
                ("longitude", "DECIMAL(11,8)", "Garis bujur titik pusat kantor untuk acuan geofencing"),
                ("radius_meters", "INT UNSIGNED", "Radius toleransi batas presensi dalam satuan meter (default: 100)"),
                ("role_configurations", "JSON", "Matriks konfigurasi hak akses dan peran kustom (opsional)"),
                ("created_at / updated_at", "TIMESTAMP", "Waktu pembuatan dan pembaruan rekaman data"),
            ],
        },
        {
            "name": "users",
            "desc": "Menyimpan kredensial otentikasi login pengguna sistem, peran akun (RBAC), dan status keaktifan akses.",
            "pk": "id_users (BIGINT UNSIGNED)",
            "fk": "id_companies -> companies(id_companies) [CASCADE]",
            "cols": [
                ("id_users", "BIGINT UNSIGNED", "Primary Key akun pengguna"),
                ("id_companies", "BIGINT UNSIGNED", "Foreign Key yang merujuk ke tabel companies (opsional)"),
                ("name", "VARCHAR(150)", "Nama lengkap pengguna akun"),
                ("email", "VARCHAR(150)", "Alamat surel unik untuk autentikasi login"),
                ("password", "VARCHAR(255)", "Hash kata sandi akun (terenkripsi algoritma Bcrypt)"),
                ("role", "VARCHAR(50)", "Hak akses pengguna: superadmin, owner, hr, manager, employee"),
                ("is_active", "TINYINT(1)", "Status keaktifan akun (1 = aktif, 0 = dinonaktifkan)"),
                ("remember_token", "VARCHAR(100)", "Token sesi pengingat login (opsional)"),
                ("created_at / updated_at", "TIMESTAMP", "Waktu pembuatan dan pembaruan data pengguna"),
            ],
        },
        {
            "name": "shifts",
            "desc": "Master data jadwal kerja operasional harian, jam masuk, jam pulang, dan batas toleransi keterlambatan.",
            "pk": "id_shifts (BIGINT UNSIGNED)",
            "fk": "id_companies -> companies(id_companies) [CASCADE]",
            "cols": [
                ("id_shifts", "BIGINT UNSIGNED", "Primary Key jadwal shift kerja"),
                ("id_companies", "BIGINT UNSIGNED", "Foreign Key entitas perusahaan pemilik shift"),
                ("name", "VARCHAR(100)", "Nama jadwal shift (contoh: Shift Pagi Reguler, Shift Siang)"),
                ("start_time", "TIME", "Jam mulai kerja resmi (format HH:mm:ss)"),
                ("end_time", "TIME", "Jam berakhir kerja resmi (format HH:mm:ss)"),
                ("late_tolerance_minutes", "INT UNSIGNED", "Batas toleransi keterlambatan dalam menit (default: 15)"),
                ("created_at / updated_at", "TIMESTAMP", "Waktu pencatatan jadwal kerja"),
            ],
        },
        {
            "name": "employees",
            "desc": "Menampung profil terperinci kepegawaian, penempatan divisi, jabatan, kompensasi gaji, kuota cuti, dan rekening bank.",
            "pk": "id_employees (BIGINT UNSIGNED)",
            "fk": "id_companies -> companies; id_users -> users [CASCADE]; id_shifts -> shifts [SET NULL]",
            "cols": [
                ("id_employees", "BIGINT UNSIGNED", "Primary Key data kepegawaian"),
                ("id_companies", "BIGINT UNSIGNED", "Foreign Key entitas perusahaan"),
                ("id_users", "BIGINT UNSIGNED", "Foreign Key relasi one-to-one ke akun login users"),
                ("department_name", "VARCHAR(100)", "Unit divisi penempatan kerja karyawan (opsional)"),
                ("job_position_name", "VARCHAR(100)", "Posisi atau nama jabatan kerja karyawan (opsional)"),
                ("id_shifts", "BIGINT UNSIGNED", "Foreign Key shift default yang ditugaskan (opsional)"),
                ("nik", "VARCHAR(50)", "Nomor Induk Karyawan resmi instansi"),
                ("phone", "VARCHAR(30)", "Nomor kontak telepon pribadi karyawan (opsional)"),
                ("gender", "ENUM('male','female')", "Jenis kelamin karyawan"),
                ("birth_date", "DATE", "Tanggal lahir karyawan (opsional)"),
                ("hire_date", "DATE", "Tanggal resmi mulai bekerja di perusahaan"),
                ("employment_status", "ENUM", "Status: permanent, contract, probation, intern"),
                ("basic_salary", "DECIMAL(14,2)", "Nominal gaji pokok bulanan (default: 0.00)"),
                ("allowance_fixed", "DECIMAL(14,2)", "Nominal tunjangan tetap bulanan (default: 0.00)"),
                ("annual_leave_quota", "INT UNSIGNED", "Kuota jatah cuti tahunan karyawan (default: 12 hari)"),
                ("bank_name", "VARCHAR(50)", "Nama bank penyalur penggajian (opsional)"),
                ("bank_account_number", "VARCHAR(50)", "Nomor rekening bank karyawan (opsional)"),
                ("bank_account_holder", "VARCHAR(100)", "Nama pemilik buku rekening bank (opsional)"),
                ("created_at / updated_at", "TIMESTAMP", "Waktu pembuatan dan pembaruan data karyawan"),
            ],
        },
        {
            "name": "attendances",
            "desc": "Mencatat transaksi kehadiran harian karyawan, koordinat GPS masuk dan pulang, foto swafoto, jarak, serta durasi deviasi waktu.",
            "pk": "id_attendances (BIGINT UNSIGNED)",
            "fk": "id_companies -> companies; id_employees -> employees [CASCADE]",
            "cols": [
                ("id_attendances", "BIGINT UNSIGNED", "Primary Key rekaman presensi"),
                ("id_companies", "BIGINT UNSIGNED", "Foreign Key perusahaan"),
                ("id_employees", "BIGINT UNSIGNED", "Foreign Key karyawan yang melakukan presensi"),
                ("date", "DATE", "Tanggal pelaksanaan kehadiran kerja"),
                ("clock_in_time", "TIME", "Waktu absensi masuk tercatat (opsional)"),
                ("clock_in_latitude / longitude", "DECIMAL", "Koordinat GPS perangkat saat melakukan presensi masuk"),
                ("clock_in_photo_path", "VARCHAR(255)", "Lokasi penyimpanan berkas foto swafoto bukti masuk"),
                ("clock_in_distance_meters", "INT UNSIGNED", "Jarak posisi perangkat terhadap koordinat kantor (meter)"),
                ("clock_out_time", "TIME", "Waktu absensi pulang tercatat (opsional)"),
                ("clock_out_latitude / longitude", "DECIMAL", "Koordinat GPS perangkat saat melakukan presensi pulang"),
                ("clock_out_photo_path", "VARCHAR(255)", "Lokasi berkas foto swafoto bukti presensi pulang"),
                ("clock_out_distance_meters", "INT UNSIGNED", "Jarak posisi perangkat terhadap kantor saat presensi pulang"),
                ("status", "ENUM", "Status: on_time, late, early_leave, absent, leave, holiday"),
                ("late_duration_minutes", "INT UNSIGNED", "Total menit keterlambatan melewati batas toleransi shift"),
                ("early_leave_minutes", "INT UNSIGNED", "Total menit pulang lebih cepat dari jam kepulangan shift"),
                ("notes", "TEXT", "Keterangan atau catatan tambahan terkait kehadiran (opsional)"),
                ("created_at / updated_at", "TIMESTAMP", "Waktu pembuatan dan pembaruan presensi"),
            ],
        },
        {
            "name": "leave_requests",
            "desc": "Mencatat permohonan izin atau cuti karyawan, jenis perizinan, rentang tanggal, bukti dokumen, dan status verifikasi.",
            "pk": "id_leave_requests (BIGINT UNSIGNED)",
            "fk": "id_companies -> companies; id_employees -> employees; approved_by -> users [SET NULL]",
            "cols": [
                ("id_leave_requests", "BIGINT UNSIGNED", "Primary Key pengajuan cuti"),
                ("id_companies", "BIGINT UNSIGNED", "Foreign Key perusahaan"),
                ("id_employees", "BIGINT UNSIGNED", "Foreign Key karyawan pemohon cuti"),
                ("leave_type", "VARCHAR(50)", "Kategori izin (Cuti Tahunan, Izin Sakit, Cuti Menikah, dll)"),
                ("is_paid", "TINYINT(1)", "Status cuti dibayar (1 = dibayar penuh, 0 = un-paid leave)"),
                ("start_date", "DATE", "Tanggal awal masa permohonan cuti"),
                ("end_date", "DATE", "Tanggal akhir masa permohonan cuti"),
                ("total_days", "INT UNSIGNED", "Jumlah hari kerja efektif yang diajukan"),
                ("reason", "TEXT", "Deskripsi alasan pengajuan izin atau cuti"),
                ("attachment_url", "VARCHAR(255)", "Tautan berkas dokumen bukti surat dokter/pendukung (opsional)"),
                ("status", "ENUM", "Status persetujuan: pending, approved, rejected"),
                ("approved_by", "BIGINT UNSIGNED", "Foreign Key akun pimpinan/HRD yang menyetujui (opsional)"),
                ("rejected_reason", "TEXT", "Catatan alasan penolakan jika permohonan ditolak (opsional)"),
                ("created_at / updated_at", "TIMESTAMP", "Waktu pengajuan dan perubahan status perizinan"),
            ],
        },
        {
            "name": "overtime_requests",
            "desc": "Mencatat permohonan jam kerja lembur karyawan, waktu pelaksanaan, durasi jam lembur, dan verifikasi atasan.",
            "pk": "id_overtime_requests (BIGINT UNSIGNED)",
            "fk": "id_companies -> companies; id_employees -> employees; approved_by -> users [SET NULL]",
            "cols": [
                ("id_overtime_requests", "BIGINT UNSIGNED", "Primary Key pengajuan lembur"),
                ("id_companies", "BIGINT UNSIGNED", "Foreign Key perusahaan"),
                ("id_employees", "BIGINT UNSIGNED", "Foreign Key karyawan yang mengajukan lembur"),
                ("date", "DATE", "Tanggal pelaksanaan tugas lembur"),
                ("start_time", "TIME", "Jam mulai kerja lembur"),
                ("end_time", "TIME", "Jam berakhir kerja lembur"),
                ("duration_hours", "DECIMAL(5,2)", "Kalkulasi total durasi jam lembur"),
                ("reason", "TEXT", "Uraian tugas atau pekerjaan lembur yang dikerjakan"),
                ("status", "ENUM", "Status verifikasi lembur: pending, approved, rejected"),
                ("approved_by", "BIGINT UNSIGNED", "Foreign Key akun atasan yang menyetujui (opsional)"),
                ("rejected_reason", "TEXT", "Catatan alasan penolakan permohonan lembur (opsional)"),
                ("created_at / updated_at", "TIMESTAMP", "Waktu pencatatan dan verifikasi lembur"),
            ],
        },
        {
            "name": "payroll_slips",
            "desc": "Menyimpan slip gaji karyawan per periode, kalkulasi pendapatan, akumulasi potongan presensi, gaji bersih, dan arsip PDF.",
            "pk": "id_payroll_slips (BIGINT UNSIGNED)",
            "fk": "id_companies -> companies; id_employees -> employees [CASCADE]",
            "cols": [
                ("id_payroll_slips", "BIGINT UNSIGNED", "Primary Key rekaman slip gaji"),
                ("id_companies", "BIGINT UNSIGNED", "Foreign Key perusahaan"),
                ("id_employees", "BIGINT UNSIGNED", "Foreign Key karyawan penerima gaji"),
                ("period_name", "VARCHAR(100)", "Nama periode penggajian (contoh: Periode Oktober 2026)"),
                ("start_date", "DATE", "Tanggal awal siklus perhitungan absensi"),
                ("end_date", "DATE", "Tanggal akhir siklus perhitungan absensi"),
                ("payment_date", "DATE", "Tanggal pencairan atau pembayaran upah (opsional)"),
                ("basic_salary", "DECIMAL(14,2)", "Nominal gaji pokok karyawan pada periode terkait"),
                ("allowance_fixed", "DECIMAL(14,2)", "Nominal tunjangan tetap yang disertakan"),
                ("overtime_pay", "DECIMAL(14,2)", "Nominal total kompensasi upah lembur yang disetujui"),
                ("deduction_late", "DECIMAL(14,2)", "Nominal potongan akibat keterlambatan presensi"),
                ("deduction_absence", "DECIMAL(14,2)", "Nominal potongan akibat ketidakhadiran tanpa izin (alpha)"),
                ("deduction_other", "DECIMAL(14,2)", "Nominal potongan lain-lain seperti kasbon atau iuran"),
                ("net_salary", "DECIMAL(14,2)", "Total nominal gaji bersih yang diterima (Take Home Pay)"),
                ("status", "VARCHAR(20)", "Status slip gaji: draft, published, paid"),
                ("pdf_path", "VARCHAR(255)", "Tautan berkas dokumen slip gaji PDF yang diterbitkan (opsional)"),
                ("created_at / updated_at", "TIMESTAMP", "Waktu kalkulasi dan pembaruan slip gaji"),
            ],
        },
        {
            "name": "performance_periods",
            "desc": "Menyimpan gelombang evaluasi kinerja berkala (SPK SMART), jadwal penilaian, dan konfigurasi matriks kriteria penilaian.",
            "pk": "id_performance_periods (BIGINT UNSIGNED)",
            "fk": "-",
            "cols": [
                ("id_performance_periods", "BIGINT UNSIGNED", "Primary Key gelombang periode penilaian kinerja"),
                ("name", "VARCHAR(100)", "Nama siklus evaluasi (contoh: Penilaian Kinerja Triwulan III 2026)"),
                ("start_date", "DATE", "Tanggal awal rentang kinerja yang dievaluasi"),
                ("end_date", "DATE", "Tanggal akhir rentang kinerja yang dievaluasi"),
                ("status", "ENUM", "Tahapan evaluasi: draft, active, calculated, finalized"),
                ("criteria_config", "JSON", "Konfigurasi kriteria SMART (kode, nama, bobot, tipe benefit/cost, rentang Cmin-Cmax)"),
                ("created_at / updated_at", "TIMESTAMP", "Waktu inisialisasi dan pembaruan gelombang evaluasi"),
            ],
        },
        {
            "name": "performance_evaluations",
            "desc": "Menyimpan hasil perhitungan SPK SMART per individu karyawan, rincian skor tiap kriteria, peringkat, dan rekomendasi manajemen.",
            "pk": "id_performance_evaluations (BIGINT UNSIGNED)",
            "fk": "id_performance_periods -> performance_periods; id_employees -> employees; evaluated_by -> users [SET NULL]",
            "cols": [
                ("id_performance_evaluations", "BIGINT UNSIGNED", "Primary Key data hasil evaluasi kinerja karyawan"),
                ("id_performance_periods", "BIGINT UNSIGNED", "Foreign Key siklus periode penilaian terkait"),
                ("id_employees", "BIGINT UNSIGNED", "Foreign Key karyawan yang dinilai performanya"),
                ("final_score", "DECIMAL(6,2)", "Skor akhir preferensi metode SMART skala 0 hingga 100"),
                ("rank", "INT UNSIGNED", "Peringkat prestasi karyawan dalam gelombang penilaian terkait"),
                ("grade", "VARCHAR(50)", "Kategori predikat performa (Sangat Baik, Baik, Cukup, Kurang)"),
                ("recommendation", "VARCHAR(255)", "Rekomendasi manajerial (Promosi Jabatan, Bonus, Pembinaan)"),
                ("notes", "TEXT", "Catatan kualitatif dari atasan penilai (opsional)"),
                ("scores_breakdown", "JSON", "Rincian nilai mentah, nilai utilitas, dan bobot tiap kriteria"),
                ("evaluated_by", "BIGINT UNSIGNED", "Foreign Key akun atasan/manajer yang melakukan penilaian"),
                ("created_at / updated_at", "TIMESTAMP", "Waktu kalkulasi dan pengesahan hasil evaluasi"),
            ],
        },
        {
            "name": "notifications",
            "desc": "Menyimpan pemberitahuan aktivitas operasional pengguna, penanda keterbacaan pesan, dan payload navigasi langsung.",
            "pk": "id_notifications (BIGINT UNSIGNED)",
            "fk": "id_companies -> companies; id_users -> users [CASCADE]",
            "cols": [
                ("id_notifications", "BIGINT UNSIGNED", "Primary Key pesan pemberitahuan"),
                ("id_companies", "BIGINT UNSIGNED", "Foreign Key perusahaan"),
                ("id_users", "BIGINT UNSIGNED", "Foreign Key pengguna akun penerima pemberitahuan"),
                ("type", "VARCHAR(50)", "Kategori: system, leave, overtime, payroll, attendance, performance"),
                ("title", "VARCHAR(150)", "Judul ringkas pemberitahuan"),
                ("message", "TEXT", "Uraian isi pesan informasi aktivitas"),
                ("data", "JSON", "Metadata payload untuk tautan URL atau rujukan ID dokumen (opsional)"),
                ("is_read", "TINYINT(1)", "Status keterbacaan pesan (0 = belum dibaca, 1 = sudah dibaca)"),
                ("read_at", "TIMESTAMP", "Waktu pengguna menandai atau membuka pesan pemberitahuan"),
                ("created_at / updated_at", "TIMESTAMP", "Waktu pengiriman pemberitahuan"),
            ],
        },
    ]

    for tbl_idx, tbl in enumerate(tables_definition, 1):
        tbl_elements = []
        tbl_elements.append(
            Paragraph(
                f"4.{tbl_idx} Tabel: <code>{tbl['name']}</code>",
                sub_sec_title,
            )
        )
        tbl_elements.append(
            Paragraph(
                f"<b>Deskripsi:</b> {tbl['desc']}<br/>"
                f"<b>Primary Key:</b> <code>{tbl['pk']}</code> | <b>Foreign Key:</b> <code>{tbl['fk']}</code>",
                body_text,
            )
        )

        # Table Kolom
        table_rows = [
            [
                Paragraph("Nama Kolom", th_text),
                Paragraph("Tipe Data", th_text),
                Paragraph("Keterangan Fungsional & Batasan Validasi", th_text),
            ]
        ]
        for col_name, col_type, col_desc in tbl["cols"]:
            table_rows.append([
                Paragraph(col_name, td_code),
                Paragraph(col_type, td_muted),
                Paragraph(col_desc, td_text),
            ])

        col_table = Table(table_rows, colWidths=[130, 95, 298.27])
        col_table.setStyle(
            TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), c_primary),
                ("BOX", (0, 0), (-1, -1), 0.6, c_border),
                ("INNERGRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#E2E8F0")),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, c_bg_light]),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
            ])
        )
        tbl_elements.append(col_table)
        tbl_elements.append(Spacer(1, 8))

        story.append(KeepTogether(tbl_elements))

    # =========================================================================
    # TABEL SISTEM & FRAMEWORK LARAVEL
    # =========================================================================
    sys_elements = []
    sys_elements.append(Paragraph("4.12 Tabel Infrastruktur & Pendukung Framework Laravel", sub_sec_title))
    sys_elements.append(
        Paragraph(
            "Selain 11 tabel operasional di atas, basis data dilengkapi 9 tabel sistem yang dikelola otomatis oleh framework Laravel "
            "untuk keandalan transaksi, sesi, token keamanan, dan background processing:",
            body_text,
        )
    )

    sys_tables = [
        ("personal_access_tokens", "Manajemen token autentikasi REST API Sanctum (Bearer Token) untuk web dan aplikasi mobile."),
        ("sessions", "Penyimpanan state sesi pengguna aktif berbasis database driver."),
        ("password_reset_tokens", "Menyimpan token verifikasi permintaan atur ulang kata sandi akun pengguna."),
        ("jobs", "Antrean pemrosesan tugas latar belakang (background queue) untuk kalkulasi penggajian dan ekspor berkas."),
        ("job_batches", "Pengelolaan batch job pemrosesan antrean data massal secara asinkron."),
        ("failed_jobs", "Pencatatan kegagalan eksekusi tugas antrean guna audit kegagalan dan penanganan retry."),
        ("cache", "Penyimpanan data komputasi sementara berkecepatan tinggi untuk efisiensi beban kueri database."),
        ("cache_locks", "Mekanisme penguncian transaksi konkurensi (atomic locks) guna mencegah race condition pada presensi."),
        ("migrations", "Pencatatan riwayat eksekusi dan versi skema migrasi tabel database."),
    ]

    sys_rows = [
        [
            Paragraph("Nama Tabel Sistem", th_text),
            Paragraph("Fungsi Infrastruktur dan Penanganan Data", th_text),
        ]
    ]
    for st_name, st_desc in sys_tables:
        sys_rows.append([
            Paragraph(st_name, td_code),
            Paragraph(st_desc, td_text),
        ])

    sys_table_widget = Table(sys_rows, colWidths=[150, 373.27])
    sys_table_widget.setStyle(
        TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), c_secondary),
            ("BOX", (0, 0), (-1, -1), 0.6, c_border),
            ("INNERGRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#E2E8F0")),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, c_bg_light]),
            ("TOPPADDING", (0, 0), (-1, -1), 3),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ("LEFTPADDING", (0, 0), (-1, -1), 5),
            ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ])
    )
    sys_elements.append(sys_table_widget)
    sys_elements.append(Spacer(1, 10))
    story.append(KeepTogether(sys_elements))

    # =========================================================================
    # BAGIAN 5: MATRIKS RELASI ANTAR-TABEL (RELATIONAL SCHEMA MATRIX)
    # =========================================================================
    matrix_elements = []
    matrix_elements.append(Paragraph("5. Matriks Relasi Antar-Tabel Basis Data", sec_title))
    matrix_elements.append(
        Paragraph(
            "Tabel di bawah menyajikan peta keterhubungan antar-entitas (Foreign Key Constraint), kardinalitas relasi, "
            "dan perilaku penghapusan berjenjang (Cascading Behavior) untuk menjaga konsistensi transaksi data:",
            body_text,
        )
    )

    relations = [
        ("companies", "users", "id_companies", "1 : N (One to Many)", "ON DELETE CASCADE"),
        ("companies", "shifts", "id_companies", "1 : N (One to Many)", "ON DELETE CASCADE"),
        ("companies", "employees", "id_companies", "1 : N (One to Many)", "ON DELETE CASCADE"),
        ("users", "employees", "id_users", "1 : 1 (One to One)", "ON DELETE CASCADE"),
        ("shifts", "employees", "id_shifts", "1 : N (One to Many)", "ON DELETE SET NULL"),
        ("employees", "attendances", "id_employees", "1 : N (One to Many)", "ON DELETE CASCADE"),
        ("employees", "leave_requests", "id_employees", "1 : N (One to Many)", "ON DELETE CASCADE"),
        ("users", "leave_requests", "approved_by", "1 : N (One to Many)", "ON DELETE SET NULL"),
        ("employees", "overtime_requests", "id_employees", "1 : N (One to Many)", "ON DELETE CASCADE"),
        ("users", "overtime_requests", "approved_by", "1 : N (One to Many)", "ON DELETE SET NULL"),
        ("employees", "payroll_slips", "id_employees", "1 : N (One to Many)", "ON DELETE CASCADE"),
        ("performance_periods", "performance_evaluations", "id_performance_periods", "1 : N (One to Many)", "ON DELETE CASCADE"),
        ("employees", "performance_evaluations", "id_employees", "1 : N (One to Many)", "ON DELETE CASCADE"),
        ("users", "performance_evaluations", "evaluated_by", "1 : N (One to Many)", "ON DELETE SET NULL"),
        ("users", "notifications", "id_users", "1 : N (One to Many)", "ON DELETE CASCADE"),
        ("companies", "notifications", "id_companies", "1 : N (One to Many)", "ON DELETE CASCADE"),
    ]

    rel_rows = [
        [
            Paragraph("Tabel Induk (Parent)", th_text),
            Paragraph("Tabel Anak (Child)", th_text),
            Paragraph("Kunci Relasi (FK)", th_text),
            Paragraph("Kardinalitas", th_text),
            Paragraph("Aksi Referensial (Delete)", th_text),
        ]
    ]
    for p_tbl, c_tbl, fk_col, card, on_del in relations:
        rel_rows.append([
            Paragraph(p_tbl, td_code),
            Paragraph(c_tbl, td_code),
            Paragraph(fk_col, td_muted),
            Paragraph(card, td_text),
            Paragraph(on_del, td_muted),
        ])

    rel_table = Table(rel_rows, colWidths=[95, 115, 100, 105, 108.27])
    rel_table.setStyle(
        TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), c_primary),
            ("BOX", (0, 0), (-1, -1), 0.6, c_border),
            ("INNERGRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#E2E8F0")),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, c_bg_light]),
            ("TOPPADDING", (0, 0), (-1, -1), 3),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ("LEFTPADDING", (0, 0), (-1, -1), 4),
            ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ])
    )
    matrix_elements.append(rel_table)
    matrix_elements.append(Spacer(1, 14))

    # Kesimpulan & Tanda Pengesahan
    matrix_elements.append(
        Paragraph(
            "<b>Ringkasan Penutup Teknis:</b> Arsitektur basis data dan modul aplikasi di atas telah teruji "
            "melalui rangkaian Feature Test (150 tests passed, 724 assertions) serta diverifikasi pada antarmuka web admin "
            "dan aplikasi mobile. Struktur tabel yang ringkas dan terindeks menjamin kestabilan pemrosesan data kepegawaian jangka panjang.",
            body_text,
        )
    )

    story.append(KeepTogether(matrix_elements))

    # Build PDF
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF berhasil dibuat: {filename}")


if __name__ == "__main__":
    output_filename = "Dokumentasi_Fitur_dan_Database_HRIS_SPK_SMART.pdf"
    if len(sys.argv) > 1:
        output_filename = sys.argv[1]
    build_pdf(output_filename)
