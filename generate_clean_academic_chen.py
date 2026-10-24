import os
import math
import matplotlib.pyplot as plt
import matplotlib.patches as patches

WIDTH = 4200
HEIGHT = 3200

# Academic clean grayscale palette matching screenshot 25.png
BG_COLOR = "#FFFFFF"
ENTITY_BG = "#FFFFFF"
ENTITY_BORDER = "#1E293B"
ENTITY_TEXT = "#0F172A"

REL_BG = "#FFFFFF"
REL_BORDER = "#1E293B"
REL_TEXT = "#0F172A"

ATTR_BG = "#FFFFFF"
ATTR_BORDER = "#475569"
ATTR_TEXT = "#0F172A"
ATTR_PK_BG = "#F8FAFC"
ATTR_PK_BORDER = "#0F172A"

LINE_COLOR = "#475569"
CARD_BG = "#FFFFFF"
CARD_BORDER = "#64748B"
CARD_TEXT = "#0F172A"

# 11 Entities definition with coordinate positions (center x, center y)
# Symmetrically aligned across 4200 x 3200 canvas
entities = {
    # ROW 1 (Top Master Entities)
    "Shift": {
        "x": 520, "y": 480, "w": 220, "h": 76,
        "label": "Shift",
        "attrs": [
            ("id_shifts", True, -170, -90),
            ("nama_shift", False, -100, -150),
            ("jam_masuk", False, 30, -160),
            ("jam_pulang", False, 150, -130),
            ("toleransi_terlambat", False, 200, -50),
        ],
    },
    "Perusahaan": {
        "x": 1600, "y": 480, "w": 240, "h": 76,
        "label": "Perusahaan",
        "attrs": [
            ("id_companies", True, -260, -90),
            ("nama_perusahaan", False, -200, -155),
            ("industri", False, -100, -190),
            ("email", False, 0, -200),
            ("telepon", False, 100, -190),
            ("alamat", False, 200, -155),
            ("nama_direktur", False, 270, -90),
            ("latitude", False, -240, -25),
            ("longitude", False, 250, -25),
            ("radius_meter", False, 0, -135),
        ],
    },
    "Pengguna": {
        "x": 2680, "y": 480, "w": 220, "h": 76,
        "label": "Pengguna",
        "attrs": [
            ("id_users", True, -190, -80),
            ("nama", False, -150, -145),
            ("email", False, -40, -170),
            ("password", False, 70, -160),
            ("role", False, 170, -120),
            ("status_aktif", False, 195, -50),
        ],
    },
    "Notifikasi": {
        "x": 3650, "y": 480, "w": 220, "h": 76,
        "label": "Notifikasi",
        "attrs": [
            ("id_notifications", True, 175, -80),
            ("tipe_notif", False, 210, -20),
            ("judul", False, 210, 40),
            ("pesan", False, 190, 100),
            ("status_dibaca", False, 130, 150),
            ("waktu_baca", False, 30, 165),
        ],
    },

    # ROW 2 (Center Core Entity)
    "Pegawai": {
        "x": 2100, "y": 1150, "w": 250, "h": 82,
        "label": "Pegawai",
        "attrs": [
            ("id_employees", True, -260, -50),
            ("nik", False, -270, 30),
            ("nama_departemen", False, -220, 105),
            ("nama_jabatan", False, -110, 145),
            ("jenis_kelamin", False, 0, 150),
            ("tanggal_masuk", False, 110, 145),
            ("gaji_pokok", False, 220, 105),
            ("tunjangan_tetap", False, 270, 30),
            ("kuota_cuti", False, 260, -50),
        ],
    },

    # ROW 3 (Operational Transactions)
    "Presensi": {
        "x": 520, "y": 1880, "w": 230, "h": 76,
        "label": "Presensi",
        "attrs": [
            ("id_attendances", True, -220, -50),
            ("tanggal", False, -230, 20),
            ("jam_masuk", False, -200, 90),
            ("jam_pulang", False, -120, 140),
            ("foto_masuk", False, -20, 160),
            ("status", False, 90, 150),
            ("menit_terlambat", False, 190, 110),
            ("jarak_meter", False, 230, 40),
        ],
    },
    "Pengajuan_Cuti": {
        "x": 1550, "y": 1880, "w": 240, "h": 76,
        "label": "Pengajuan Cuti",
        "attrs": [
            ("id_leave_requests", True, -200, 65),
            ("tipe_cuti", False, -140, 130),
            ("cuti_berbayar", False, -50, 160),
            ("tanggal_mulai", False, 50, 160),
            ("tanggal_selesai", False, 140, 130),
            ("total_hari", False, 210, 70),
            ("alasan", False, 210, 5),
            ("status_approval", False, 175, -60),
        ],
    },
    "Pengajuan_Lembur": {
        "x": 2650, "y": 1880, "w": 250, "h": 76,
        "label": "Pengajuan Lembur",
        "attrs": [
            ("id_overtime_requests", True, -200, 60),
            ("tanggal", False, -150, 125),
            ("jam_mulai", False, -60, 160),
            ("jam_selesai", False, 40, 160),
            ("durasi_jam", False, 140, 135),
            ("alasan", False, 210, 75),
            ("status_approval", False, 210, 10),
        ],
    },
    "Slip_Gaji": {
        "x": 3650, "y": 1880, "w": 230, "h": 76,
        "label": "Slip Gaji",
        "attrs": [
            ("id_payroll_slips", True, 200, -40),
            ("nama_periode", False, 220, 25),
            ("tanggal_mulai", False, 190, 90),
            ("tanggal_selesai", False, 120, 145),
            ("gaji_pokok", False, 30, 165),
            ("gaji_bersih", False, -70, 165),
            ("berkas_pdf", False, -165, 135),
            ("status_bayar", False, -210, 75),
        ],
    },

    # ROW 4 (SPK SMART Evaluation Tier)
    "Periode_Penilaian": {
        "x": 1250, "y": 2600, "w": 270, "h": 76,
        "label": "Periode Penilaian",
        "attrs": [
            ("id_perf_periods", True, -210, 65),
            ("nama_periode", False, -140, 130),
            ("tanggal_mulai", False, -50, 160),
            ("tanggal_selesai", False, 50, 160),
            ("status_periode", False, 140, 130),
            ("konfigurasi_kriteria", False, 210, 65),
        ],
    },
    "Evaluasi_Kinerja": {
        "x": 2850, "y": 2600, "w": 270, "h": 76,
        "label": "Evaluasi Kinerja",
        "attrs": [
            ("id_perf_eval", True, -220, 60),
            ("skor_akhir_smart", False, -150, 125),
            ("peringkat", False, -60, 160),
            ("grade", False, 40, 160),
            ("rekomendasi", False, 140, 130),
            ("rincian_skor", False, 220, 65),
        ],
    },
}

# Relationships: (Ent1, Ent2, label, card1, card2, rx, ry)
relationships = [
    # Top tier relationships
    ("Perusahaan", "Shift", "menetapkan", "1", "N", 1060, 480),
    ("Perusahaan", "Pengguna", "memiliki", "1", "N", 2140, 480),
    ("Pengguna", "Notifikasi", "menerima", "1", "N", 3165, 480),
    ("Perusahaan", "Pegawai", "mempekerjakan", "1", "N", 1850, 815),
    ("Shift", "Pegawai", "jadwal_kerja", "1", "N", 1310, 815),
    ("Pengguna", "Pegawai", "akun_profil", "1", "1", 2390, 815),

    # Mid operational transactions from Pegawai
    ("Pegawai", "Presensi", "mencatat", "1", "N", 1310, 1515),
    ("Pegawai", "Pengajuan_Cuti", "mengajukan", "1", "N", 1825, 1515),
    ("Pegawai", "Pengajuan_Lembur", "mengajukan", "1", "N", 2375, 1515),
    ("Pegawai", "Slip_Gaji", "menerima", "1", "N", 2875, 1515),

    # Bottom SPK SMART Tier
    ("Periode_Penilaian", "Evaluasi_Kinerja", "menaungi", "1", "N", 2050, 2600),
    ("Pegawai", "Evaluasi_Kinerja", "dievaluasi", "1", "N", 2475, 2240),
]

# Build High-Precision Clean Academic SVG
svg = []
svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {WIDTH} {HEIGHT}" width="{WIDTH}" height="{HEIGHT}" style="background-color: {BG_COLOR}; font-family: \'Segoe UI\', -apple-system, BlinkMacSystemFont, Arial, sans-serif;">')

# Draw relationship lines and cardinalities
svg.append('<g id="relationship-lines">')
for ent1, ent2, label, c1, c2, rx, ry in relationships:
    e1 = entities[ent1]
    e2 = entities[ent2]
    # Line 1: Ent1 -> Rel
    svg.append(f'<line x1="{e1["x"]}" y1="{e1["y"]}" x2="{rx}" y2="{ry}" stroke="{LINE_COLOR}" stroke-width="2.0" />')
    # Line 2: Rel -> Ent2
    svg.append(f'<line x1="{rx}" y1="{ry}" x2="{e2["x"]}" y2="{e2["y"]}" stroke="{LINE_COLOR}" stroke-width="2.0" />')

    # Cardinality badge 1 (near ent1)
    bx1 = e1["x"] * 0.45 + rx * 0.55
    by1 = e1["y"] * 0.45 + ry * 0.55 - 12
    svg.append(f'<rect x="{bx1-14}" y="{by1-12}" width="28" height="24" rx="4" fill="{CARD_BG}" stroke="{CARD_BORDER}" stroke-width="1.2" />')
    svg.append(f'<text x="{bx1}" y="{by1+5}" font-size="13" font-weight="bold" fill="{CARD_TEXT}" text-anchor="middle">{c1}</text>')

    # Cardinality badge 2 (near ent2)
    bx2 = rx * 0.45 + e2["x"] * 0.55
    by2 = ry * 0.45 + e2["y"] * 0.55 - 12
    svg.append(f'<rect x="{bx2-14}" y="{by2-12}" width="28" height="24" rx="4" fill="{CARD_BG}" stroke="{CARD_BORDER}" stroke-width="1.2" />')
    svg.append(f'<text x="{bx2}" y="{by2+5}" font-size="13" font-weight="bold" fill="{CARD_TEXT}" text-anchor="middle">{c2}</text>')

svg.append('</g>')

# Draw attribute lines and ovals
svg.append('<g id="attributes">')
for ent_name, edata in entities.items():
    ex, ey = edata["x"], edata["y"]
    attrs = edata["attrs"]

    for aname, is_pk, dx, dy in attrs:
        ax = ex + dx
        ay = ey + dy

        # Clean line from entity to attribute
        svg.append(f'<line x1="{ex}" y1="{ey}" x2="{ax}" y2="{ay}" stroke="{LINE_COLOR}" stroke-width="1.4" />')

        # Ellipse pill
        bg_col = ATTR_PK_BG if is_pk else ATTR_BG
        border_col = ATTR_PK_BORDER if is_pk else ATTR_BORDER
        stroke_w = "1.8" if is_pk else "1.2"
        rx_val = 78
        ry_val = 26

        svg.append(f'<g transform="translate({ax},{ay})">')
        svg.append(f'<ellipse cx="0" cy="0" rx="{rx_val}" ry="{ry_val}" fill="{bg_col}" stroke="{border_col}" stroke-width="{stroke_w}" />')

        # Text inside ellipse
        if is_pk:
            svg.append(f'<text x="0" y="5" font-size="11.5" font-weight="bold" fill="{ATTR_TEXT}" text-anchor="middle" text-decoration="underline">{aname}</text>')
        else:
            svg.append(f'<text x="0" y="4.5" font-size="11" font-weight="500" fill="{ATTR_TEXT}" text-anchor="middle">{aname}</text>')

        svg.append('</g>')

svg.append('</g>')

# Draw Relationships (Rhombus / Diamond)
svg.append('<g id="relationships">')
for ent1, ent2, label, c1, c2, rx, ry in relationships:
    rw = 170
    rh = 70
    pts = f"{rx},{ry - rh/2} {rx + rw/2},{ry} {rx},{ry + rh/2} {rx - rw/2},{ry}"
    svg.append(f'<g transform="translate(0,0)">')
    svg.append(f'<polygon points="{pts}" fill="{REL_BG}" stroke="{REL_BORDER}" stroke-width="2.0" />')
    svg.append(f'<text x="{rx}" y="{ry + 5}" font-size="12.5" font-weight="bold" fill="{REL_TEXT}" text-anchor="middle">{label}</text>')
    svg.append('</g>')
svg.append('</g>')

# Draw Entities (Clean White Box with Dark Border)
svg.append('<g id="entities">')
for ent_name, edata in entities.items():
    ex, ey, ew, eh, elabel = edata["x"], edata["y"], edata["w"], edata["h"], edata["label"]
    x0 = ex - ew/2
    y0 = ey - eh/2

    svg.append(f'<g transform="translate(0,0)">')
    svg.append(f'<rect x="{x0}" y="{y0}" width="{ew}" height="{eh}" rx="4" fill="{ENTITY_BG}" stroke="{ENTITY_BORDER}" stroke-width="2.2" />')
    svg.append(f'<text x="{ex}" y="{ey + 6}" font-size="16" font-weight="bold" fill="{ENTITY_TEXT}" text-anchor="middle" letter-spacing="0.3">{elabel}</text>')
    svg.append('</g>')
svg.append('</g>')

# Add Clean Academic Legend at bottom center
leg_x = 2100
leg_y = 3050
svg.append(f'''
<g id="legend" transform="translate({leg_x - 380}, {leg_y - 40})">
  <rect x="0" y="0" width="760" height="70" rx="4" fill="#FFFFFF" stroke="#64748B" stroke-width="1.4" />
  <text x="380" y="20" font-size="11" font-weight="bold" fill="#0F172A" text-anchor="middle" letter-spacing="0.5">LEGENDA SIMBOL NOTASI PETER CHEN (STANDAR AKADEMIK)</text>

  <!-- Entity sample -->
  <rect x="30" y="32" width="80" height="26" rx="2" fill="#FFFFFF" stroke="#1E293B" stroke-width="1.8" />
  <text x="70" y="49" font-size="10.5" font-weight="bold" fill="#0F172A" text-anchor="middle">Entitas</text>
  <text x="120" y="49" font-size="10.5" fill="#334155">= Entitas (Tabel)</text>

  <!-- Rel sample -->
  <polygon points="280,32 315,45 280,58 245,45" fill="#FFFFFF" stroke="#1E293B" stroke-width="1.6" />
  <text x="280" y="49" font-size="9.5" font-weight="bold" fill="#0F172A" text-anchor="middle">relasi</text>
  <text x="325" y="49" font-size="10.5" fill="#334155">= Relasi</text>

  <!-- Attr sample -->
  <ellipse cx="440" cy="45" rx="38" ry="14" fill="#FFFFFF" stroke="#475569" stroke-width="1.2" />
  <text x="440" y="48" font-size="9.5" fill="#0F172A" text-anchor="middle">atribut</text>
  <text x="488" y="49" font-size="10.5" fill="#334155">= Atribut</text>

  <!-- PK sample -->
  <ellipse cx="605" cy="45" rx="42" ry="14" fill="#F8FAFC" stroke="#0F172A" stroke-width="1.6" />
  <text x="605" y="48" font-size="9.5" font-weight="bold" fill="#0F172A" text-anchor="middle" text-decoration="underline">id_key (PK)</text>
  <text x="656" y="49" font-size="10.5" fill="#334155">= Primary Key</text>
</g>
''')

svg.append('</svg>')

svg_content = "\n".join(svg)

# Write to root directory
base_dir = r"C:\Perkuliahan\Semester 7\Project SMT 7\SAAS HRIS"
svg_path = os.path.join(base_dir, "ERD_Chen_Notation_Academic.svg")
with open(svg_path, "w", encoding="utf-8") as f:
    f.write(svg_content)

# Also update the primary ERD_Chen_Notation_11_Tables.svg
primary_svg_path = os.path.join(base_dir, "ERD_Chen_Notation_11_Tables.svg")
with open(primary_svg_path, "w", encoding="utf-8") as f:
    f.write(svg_content)

# HTML Viewer for Academic Version
html_content = f'''<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ERD Notasi Peter Chen (Format Skripsi &amp; Akademik) — 11 Tabel SAAS HRIS</title>
  <script src="https://cdn.jsdelivr.net/npm/svg-pan-zoom@3.6.1/dist/svg-pan-zoom.min.js"></script>
  <style>
    * {{
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }}
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: #F8FAFC;
      color: #0F172A;
      display: flex;
      flex-direction: column;
      height: 100vh;
      overflow: hidden;
    }}
    header {{
      background: #FFFFFF;
      color: #0F172A;
      padding: 12px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 1px solid #E2E8F0;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
      z-index: 10;
    }}
    .title-box h1 {{
      font-size: 16px;
      font-weight: 700;
      letter-spacing: 0.3px;
      display: flex;
      align-items: center;
      gap: 10px;
    }}
    .badge {{
      font-size: 11px;
      background: #F1F5F9;
      color: #334155;
      border: 1px solid #CBD5E1;
      padding: 2px 8px;
      border-radius: 4px;
      font-weight: 600;
    }}
    .subtitle {{
      font-size: 12px;
      color: #64748B;
      margin-top: 2px;
    }}
    .toolbar {{
      display: flex;
      gap: 8px;
      align-items: center;
    }}
    .btn {{
      background: #FFFFFF;
      color: #0F172A;
      border: 1px solid #CBD5E1;
      padding: 6px 12px;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 600;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      text-decoration: none;
      transition: all 0.15s ease-in-out;
    }}
    .btn:hover {{
      background: #F1F5F9;
      border-color: #94A3B8;
    }}
    .btn-primary {{
      background: #0F172A;
      color: #FFFFFF;
      border-color: #0F172A;
    }}
    .btn-primary:hover {{
      background: #1E293B;
    }}
    #viewer-container {{
      flex: 1;
      width: 100%;
      height: 100%;
      background: #FFFFFF;
      position: relative;
      overflow: hidden;
      cursor: grab;
    }}
    #viewer-container:active {{
      cursor: grabbing;
    }}
    #erd-svg {{
      width: 100%;
      height: 100%;
    }}
    .floating-tips {{
      position: absolute;
      bottom: 16px;
      left: 16px;
      background: rgba(255, 255, 255, 0.95);
      border: 1px solid #CBD5E1;
      color: #334155;
      padding: 8px 14px;
      border-radius: 6px;
      font-size: 11px;
      display: flex;
      align-items: center;
      gap: 6px;
      box-shadow: 0 2px 6px rgba(0,0,0,0.06);
      pointer-events: none;
    }}
  </style>
</head>
<body>
  <header>
    <div class="title-box">
      <h1>
        <span>ERD Notasi Peter Chen (11 Tabel Skripsi)</span>
        <span class="badge">Model Hitam Putih / Grayscale Bersih</span>
      </h1>
      <div class="subtitle">Format Buku &amp; Laporan Skripsi: Kotak Bersih, Belah Ketupat Relasi, dan Oval Atribut</div>
    </div>
    <div class="toolbar">
      <button class="btn" onclick="panZoom.zoomIn()">🔍 Zoom In</button>
      <button class="btn" onclick="panZoom.zoomOut()">🔍 Zoom Out</button>
      <button class="btn" onclick="panZoom.reset()">↺ Reset</button>
      <a href="ERD_Chen_Notation_Academic.png" download="ERD_Chen_Notation_Academic.png" class="btn btn-primary">📥 Unduh PNG</a>
      <a href="ERD_Chen_Notation_Academic.svg" download="ERD_Chen_Notation_Academic.svg" class="btn">📥 Unduh SVG</a>
    </div>
  </header>

  <div id="viewer-container">
    <div id="svg-wrapper" style="width: 100%; height: 100%;">
      {svg_content}
    </div>
    <div class="floating-tips">
      💡 <span>Gunakan <strong>Scroll Mouse</strong> untuk Zoom dan <strong>Drag Klik-Kiri</strong> untuk Menggeser Diagram.</span>
    </div>
  </div>

  <script>
    let panZoom;
    window.addEventListener('DOMContentLoaded', () => {{
      const svgElement = document.querySelector('#svg-wrapper svg');
      svgElement.id = 'erd-svg';
      panZoom = svgPanZoom('#erd-svg', {{
        zoomEnabled: true,
        controlIconsEnabled: false,
        fit: true,
        center: true,
        minZoom: 0.2,
        maxZoom: 10,
        zoomScaleSensitivity: 0.2
      }});
    }});
  </script>
</body>
</html>
'''

viewer_path = os.path.join(base_dir, "ERD_Chen_Notation_Academic_Viewer.html")
with open(viewer_path, "w", encoding="utf-8") as f:
    f.write(html_content)

# Also update the primary ERD_Chen_Notation_Viewer.html
primary_viewer_path = os.path.join(base_dir, "ERD_Chen_Notation_Viewer.html")
with open(primary_viewer_path, "w", encoding="utf-8") as f:
    f.write(html_content)

print("Academic Chen ERD SVG and HTML Viewer generated successfully!")
