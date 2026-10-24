import os
import math

WIDTH = 3800
HEIGHT = 2600

# Color palette matching screenshot 24.png
ENTITY_BG = "#4C84F3"        # Crisp royal blue
ENTITY_BORDER = "#2B6CB0"
ENTITY_TEXT = "#FFFFFF"

REL_BG = "#23272F"           # Charcoal dark
REL_BORDER = "#111827"
REL_TEXT = "#FFFFFF"

ATTR_BG = "#72E5A0"          # Fresh mint green
ATTR_BORDER = "#10B981"
ATTR_TEXT = "#064E3B"
ATTR_PK_BG = "#34D399"       # Deep mint for PK

LINE_COLOR = "#94A3B8"       # Smooth slate line
CARD_BG = "#F1F5F9"
CARD_BORDER = "#CBD5E1"
CARD_TEXT = "#1E293B"

# 11 Entities definition with coordinate positions (center x, center y)
# Carefully spaced across 3800 x 2600 canvas
entities = {
    "Shift": {
        "x": 600, "y": 380, "w": 220, "h": 76,
        "label": "Shift",
        "attrs": [
            ("id_shifts", True, -160, -90),
            ("name", False, -90, -145),
            ("start_time", False, 40, -155),
            ("end_time", False, 160, -125),
            ("late_tolerance", False, 200, -50),
        ],
    },
    "Company": {
        "x": 1900, "y": 380, "w": 240, "h": 76,
        "label": "Company",
        "attrs": [
            ("id_companies", True, -260, -100),
            ("name", False, -200, -165),
            ("industry", False, -100, -195),
            ("email", False, 0, -205),
            ("phone", False, 100, -195),
            ("address", False, 200, -165),
            ("director_name", False, 270, -100),
            ("latitude", False, -240, -35),
            ("longitude", False, 250, -35),
            ("radius_meters", False, 0, -145),
        ],
    },
    "User": {
        "x": 3200, "y": 380, "w": 220, "h": 76,
        "label": "User",
        "attrs": [
            ("id_users", True, -190, -80),
            ("name", False, -150, -145),
            ("email", False, -40, -170),
            ("password", False, 70, -160),
            ("role", False, 170, -120),
            ("is_active", False, 195, -50),
        ],
    },
    "Employee": {
        "x": 1900, "y": 950, "w": 250, "h": 80,
        "label": "Employee",
        "attrs": [
            ("id_employees", True, -240, -45),
            ("nik", False, -250, 40),
            ("dept_name", False, -200, 110),
            ("position_name", False, -100, 140),
            ("gender", False, 0, 145),
            ("hire_date", False, 100, 140),
            ("basic_salary", False, 200, 110),
            ("allowance_fixed", False, 250, 40),
            ("annual_leave_quota", False, 240, -45),
        ],
    },
    "Notification": {
        "x": 3350, "y": 950, "w": 220, "h": 76,
        "label": "Notification",
        "attrs": [
            ("id_notifications", True, 175, -80),
            ("type", False, 210, -20),
            ("title", False, 210, 40),
            ("message", False, 190, 100),
            ("is_read", False, 130, 150),
            ("read_at", False, 30, 165),
        ],
    },
    "Attendance": {
        "x": 480, "y": 1600, "w": 230, "h": 76,
        "label": "Attendance",
        "attrs": [
            ("id_attendances", True, -220, -50),
            ("date", False, -230, 20),
            ("clock_in_time", False, -200, 90),
            ("clock_out_time", False, -120, 140),
            ("in_photo_path", False, -20, 160),
            ("status", False, 90, 150),
            ("late_minutes", False, 190, 110),
            ("distance_meters", False, 230, 40),
        ],
    },
    "Leave_Request": {
        "x": 1400, "y": 1600, "w": 230, "h": 76,
        "label": "Leave Request",
        "attrs": [
            ("id_leave_requests", True, -200, 70),
            ("leave_type", False, -140, 135),
            ("is_paid", False, -50, 165),
            ("start_date", False, 50, 165),
            ("end_date", False, 140, 135),
            ("total_days", False, 210, 75),
            ("reason", False, 210, 5),
            ("status", False, 170, -65),
        ],
    },
    "Overtime_Request": {
        "x": 2380, "y": 1600, "w": 240, "h": 76,
        "label": "Overtime Request",
        "attrs": [
            ("id_overtime_requests", True, -200, 60),
            ("date", False, -150, 130),
            ("start_time", False, -60, 165),
            ("end_time", False, 40, 165),
            ("duration_hours", False, 140, 140),
            ("reason", False, 210, 80),
            ("status", False, 210, 10),
        ],
    },
    "Payroll_Slip": {
        "x": 3300, "y": 1600, "w": 230, "h": 76,
        "label": "Payroll Slip",
        "attrs": [
            ("id_payroll_slips", True, 200, -40),
            ("period_name", False, 220, 25),
            ("start_date", False, 190, 90),
            ("end_date", False, 120, 145),
            ("basic_salary", False, 30, 165),
            ("net_salary", False, -70, 165),
            ("pdf_path", False, -165, 135),
            ("status", False, -210, 75),
        ],
    },
    "Performance_Period": {
        "x": 980, "y": 2240, "w": 270, "h": 76,
        "label": "Performance Period",
        "attrs": [
            ("id_perf_periods", True, -210, 70),
            ("name", False, -140, 135),
            ("start_date", False, -50, 165),
            ("end_date", False, 50, 165),
            ("status", False, 140, 135),
            ("criteria_config", False, 210, 70),
        ],
    },
    "Performance_Evaluation": {
        "x": 2600, "y": 2240, "w": 280, "h": 76,
        "label": "Performance Evaluation",
        "attrs": [
            ("id_perf_eval", True, -220, 65),
            ("final_score", False, -150, 130),
            ("rank", False, -60, 165),
            ("grade", False, 40, 165),
            ("recommendation", False, 140, 135),
            ("scores_breakdown", False, 220, 70),
        ],
    },
}

# Relationships: (Ent1, Ent2, label, card1, card2, rx, ry)
relationships = [
    # Top tier
    ("Company", "Shift", "Menetapkan", "1", "N", 1250, 380),
    ("Company", "User", "Memiliki", "1", "N", 2550, 380),
    ("Company", "Employee", "Mempekerjakan", "1", "N", 1900, 665),
    ("Shift", "Employee", "Jadwal Kerja", "1", "N", 1250, 665),
    ("User", "Employee", "Profil Akun", "1", "1", 2550, 665),
    ("User", "Notification", "Menerima", "1", "N", 3275, 665),

    # Mid to Operational
    ("Employee", "Attendance", "Mencatat", "1", "N", 1190, 1275),
    ("Employee", "Leave_Request", "Mengajukan", "1", "N", 1650, 1275),
    ("Employee", "Overtime_Request", "Mengajukan", "1", "N", 2140, 1275),
    ("Employee", "Payroll_Slip", "Menerima", "1", "N", 2600, 1275),

    # Approvals from User (HR / Manager)
    ("User", "Leave_Request", "Menyetujui", "1", "N", 2850, 1140),
    ("User", "Overtime_Request", "Menyetujui", "1", "N", 3050, 1275),

    # SPK SMART Tier
    ("Performance_Period", "Performance_Evaluation", "Menaungi", "1", "N", 1790, 2240),
    ("Employee", "Performance_Evaluation", "Dievaluasi", "1", "N", 2250, 1920),
]

# SVG Building
svg = []
svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {WIDTH} {HEIGHT}" width="{WIDTH}" height="{HEIGHT}" style="background-color: #F8FAFC; font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, Helvetica, Arial, sans-serif;">')

svg.append('''
<defs>
  <filter id="shadow" x="-10%" y="-10%" width="130%" height="130%">
    <feDropShadow dx="0" dy="4" stdDeviation="6" flood-color="#0F172A" flood-opacity="0.10" />
  </filter>
  <filter id="pill-shadow" x="-10%" y="-10%" width="120%" height="120%">
    <feDropShadow dx="0" dy="2" stdDeviation="3" flood-color="#0F172A" flood-opacity="0.07" />
  </filter>
</defs>
''')

# Header
svg.append(f'''
<g id="header">
  <rect x="0" y="0" width="{WIDTH}" height="110" fill="#0B2545" />
  <text x="{WIDTH/2}" y="48" font-size="32" font-weight="800" fill="#FFFFFF" text-anchor="middle" letter-spacing="1">ENTITY RELATIONSHIP DIAGRAM (PETER CHEN NOTATION) — 11 TABEL</text>
  <text x="{WIDTH/2}" y="86" font-size="17" font-weight="500" fill="#93C5FD" text-anchor="middle">Sistem Informasi Manajemen Sumber Daya Manusia &amp; Evaluasi Kinerja (Metode SPK SMART) — PT SPINDO</text>
</g>
''')

# Draw relationship lines and cardinality
svg.append('<g id="relationship-lines">')
for ent1, ent2, label, c1, c2, rx, ry in relationships:
    e1 = entities[ent1]
    e2 = entities[ent2]
    # Line 1: Ent1 -> Rel
    svg.append(f'<line x1="{e1["x"]}" y1="{e1["y"]}" x2="{rx}" y2="{ry}" stroke="{LINE_COLOR}" stroke-width="2.6" />')
    # Line 2: Rel -> Ent2
    svg.append(f'<line x1="{rx}" y1="{ry}" x2="{e2["x"]}" y2="{e2["y"]}" stroke="{LINE_COLOR}" stroke-width="2.6" />')

    # Cardinality badge 1 (near ent1)
    bx1 = e1["x"] * 0.45 + rx * 0.55
    by1 = e1["y"] * 0.45 + ry * 0.55 - 14
    svg.append(f'<rect x="{bx1-15}" y="{by1-13}" width="30" height="26" rx="13" fill="{CARD_BG}" stroke="{CARD_BORDER}" stroke-width="1.6" filter="url(#pill-shadow)" />')
    svg.append(f'<text x="{bx1}" y="{by1+5}" font-size="14" font-weight="800" fill="{CARD_TEXT}" text-anchor="middle">{c1}</text>')

    # Cardinality badge 2 (near ent2)
    bx2 = rx * 0.45 + e2["x"] * 0.55
    by2 = ry * 0.45 + e2["y"] * 0.55 - 14
    svg.append(f'<rect x="{bx2-15}" y="{by2-13}" width="30" height="26" rx="13" fill="{CARD_BG}" stroke="{CARD_BORDER}" stroke-width="1.6" filter="url(#pill-shadow)" />')
    svg.append(f'<text x="{bx2}" y="{by2+5}" font-size="14" font-weight="800" fill="{CARD_TEXT}" text-anchor="middle">{c2}</text>')

svg.append('</g>')

# Draw attribute lines and ovals
svg.append('<g id="attributes">')
for ent_name, edata in entities.items():
    ex, ey = edata["x"], edata["y"]
    attrs = edata["attrs"]

    for aname, is_pk, dx, dy in attrs:
        ax = ex + dx
        ay = ey + dy

        # Line from entity center to attribute center
        svg.append(f'<line x1="{ex}" y1="{ey}" x2="{ax}" y2="{ay}" stroke="{LINE_COLOR}" stroke-width="1.8" />')

        # Ellipse
        bg_col = ATTR_PK_BG if is_pk else ATTR_BG
        border_col = ATTR_BORDER
        stroke_w = "2.4" if is_pk else "1.6"
        rx_val = 78
        ry_val = 27

        svg.append(f'<g transform="translate({ax},{ay})">')
        svg.append(f'<ellipse cx="0" cy="0" rx="{rx_val}" ry="{ry_val}" fill="{bg_col}" stroke="{border_col}" stroke-width="{stroke_w}" filter="url(#pill-shadow)" />')

        # Text inside ellipse
        if is_pk:
            svg.append(f'<text x="0" y="5" font-size="11.5" font-weight="800" fill="{ATTR_TEXT}" text-anchor="middle" text-decoration="underline">{aname}</text>')
        else:
            svg.append(f'<text x="0" y="4.5" font-size="11" font-weight="600" fill="{ATTR_TEXT}" text-anchor="middle">{aname}</text>')

        svg.append('</g>')

svg.append('</g>')

# Draw Relationships (Rhombus / Diamond)
svg.append('<g id="relationships">')
for ent1, ent2, label, c1, c2, rx, ry in relationships:
    rw = 180
    rh = 76
    pts = f"{rx},{ry - rh/2} {rx + rw/2},{ry} {rx},{ry + rh/2} {rx - rw/2},{ry}"
    svg.append(f'<g transform="translate(0,0)">')
    svg.append(f'<polygon points="{pts}" fill="{REL_BG}" stroke="{REL_BORDER}" stroke-width="2.5" filter="url(#shadow)" />')
    svg.append(f'<text x="{rx}" y="{ry + 5}" font-size="13" font-weight="700" fill="{REL_TEXT}" text-anchor="middle">{label}</text>')
    svg.append('</g>')
svg.append('</g>')

# Draw Entities (Blue Rectangles)
svg.append('<g id="entities">')
for ent_name, edata in entities.items():
    ex, ey, ew, eh, elabel = edata["x"], edata["y"], edata["w"], edata["h"], edata["label"]
    x0 = ex - ew/2
    y0 = ey - eh/2

    svg.append(f'<g transform="translate(0,0)">')
    svg.append(f'<rect x="{x0}" y="{y0}" width="{ew}" height="{eh}" rx="14" fill="{ENTITY_BG}" stroke="{ENTITY_BORDER}" stroke-width="2.8" filter="url(#shadow)" />')
    svg.append(f'<text x="{ex}" y="{ey + 6}" font-size="17" font-weight="800" fill="{ENTITY_TEXT}" text-anchor="middle" letter-spacing="0.5">{elabel}</text>')
    svg.append('</g>')
svg.append('</g>')

# Add Legend Box at bottom center
leg_x = 1900
leg_y = 2480
svg.append(f'''
<g id="legend" transform="translate({leg_x - 420}, {leg_y - 50})">
  <rect x="0" y="0" width="840" height="96" rx="16" fill="#FFFFFF" stroke="#CBD5E1" stroke-width="2" filter="url(#shadow)" />
  <text x="420" y="25" font-size="13" font-weight="800" fill="#0F172A" text-anchor="middle" letter-spacing="0.5">LEGENDA SIMBOL NOTASI PETER CHEN</text>

  <!-- Entity sample -->
  <rect x="35" y="42" width="110" height="36" rx="8" fill="{ENTITY_BG}" stroke="{ENTITY_BORDER}" stroke-width="1.8" />
  <text x="90" y="65" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">Entity</text>
  <text x="155" y="65" font-size="12" font-weight="600" fill="#475569">Entitas (Tabel)</text>

  <!-- Attr sample -->
  <ellipse cx="295" cy="60" rx="46" ry="18" fill="{ATTR_BG}" stroke="{ATTR_BORDER}" stroke-width="1.6" />
  <text x="295" y="64" font-size="11" font-weight="600" fill="{ATTR_TEXT}" text-anchor="middle">Attribute</text>
  <text x="355" y="65" font-size="12" font-weight="600" fill="#475569">Atribut (Kolom)</text>

  <!-- PK sample -->
  <ellipse cx="495" cy="60" rx="52" ry="18" fill="{ATTR_PK_BG}" stroke="{ATTR_BORDER}" stroke-width="2.2" />
  <text x="495" y="64" font-size="11" font-weight="800" fill="{ATTR_TEXT}" text-anchor="middle" text-decoration="underline">id_key (PK)</text>
  <text x="560" y="65" font-size="12" font-weight="600" fill="#475569">Primary Key</text>

  <!-- Rel sample -->
  <polygon points="695,44 740,60 695,76 650,60" fill="{REL_BG}" stroke="{REL_BORDER}" stroke-width="2" />
  <text x="695" y="64" font-size="11" font-weight="700" fill="#FFFFFF" text-anchor="middle">Relation</text>
  <text x="755" y="65" font-size="12" font-weight="600" fill="#475569">Relasi</text>
</g>
''')

svg.append('</svg>')

svg_content = "\n".join(svg)

svg_path = r"C:\Perkuliahan\Semester 7\Project SMT 7\SAAS HRIS\ERD_Chen_Notation_11_Tables.svg"
with open(svg_path, "w", encoding="utf-8") as f:
    f.write(svg_content)

html_content = f'''<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ERD Notasi Chen 11 Tabel — SAAS HRIS SPK SMART</title>
  <script src="https://cdn.jsdelivr.net/npm/svg-pan-zoom@3.6.1/dist/svg-pan-zoom.min.js"></script>
  <style>
    * {{
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }}
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: #F1F5F9;
      color: #0F172A;
      display: flex;
      flex-direction: column;
      height: 100vh;
      overflow: hidden;
    }}
    header {{
      background: #0B2545;
      color: #FFFFFF;
      padding: 14px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 2px solid #1E3A8A;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      z-index: 10;
    }}
    .title-box h1 {{
      font-size: 18px;
      font-weight: 800;
      letter-spacing: 0.5px;
      display: flex;
      align-items: center;
      gap: 10px;
    }}
    .badge {{
      font-size: 11px;
      background: #16A34A;
      padding: 3px 8px;
      border-radius: 6px;
      font-weight: 700;
    }}
    .subtitle {{
      font-size: 12px;
      color: #94A3B8;
      margin-top: 3px;
    }}
    .toolbar {{
      display: flex;
      gap: 10px;
      align-items: center;
    }}
    .btn {{
      background: #1E293B;
      color: #F8FAFC;
      border: 1px solid #334155;
      padding: 8px 14px;
      border-radius: 8px;
      font-size: 12px;
      font-weight: 600;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      text-decoration: none;
      transition: all 0.2s;
    }}
    .btn:hover {{
      background: #334155;
      border-color: #64748B;
    }}
    .btn-primary {{
      background: #16A34A;
      border-color: #15803D;
    }}
    .btn-primary:hover {{
      background: #15803D;
    }}
    #viewer-container {{
      flex: 1;
      width: 100%;
      height: 100%;
      background: #F8FAFC;
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
      bottom: 20px;
      left: 20px;
      background: rgba(15, 23, 42, 0.85);
      backdrop-filter: blur(8px);
      color: #F8FAFC;
      padding: 10px 16px;
      border-radius: 10px;
      font-size: 12px;
      display: flex;
      align-items: center;
      gap: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      pointer-events: none;
    }}
  </style>
</head>
<body>
  <header>
    <div class="title-box">
      <h1>
        <span>ERD Notasi Peter Chen (11 Tabel)</span>
        <span class="badge">SAAS HRIS SPK SMART</span>
      </h1>
      <div class="subtitle">Format: Entitas Kotak Biru, Relasi Belah Ketupat Hitam, dan Atribut Oval Hijau</div>
    </div>
    <div class="toolbar">
      <button class="btn" onclick="panZoom.zoomIn()">🔍 Zoom In (+)</button>
      <button class="btn" onclick="panZoom.zoomOut()">🔍 Zoom Out (-)</button>
      <button class="btn" onclick="panZoom.reset()">↺ Reset View</button>
      <a href="ERD_Chen_Notation_11_Tables.png" download="ERD_Chen_Notation_11_Tables.png" class="btn btn-primary">📥 Unduh Gambar PNG</a>
      <a href="ERD_Chen_Notation_11_Tables.svg" download="ERD_Chen_Notation_11_Tables.svg" class="btn">📥 Unduh Vektor SVG</a>
    </div>
  </header>

  <div id="viewer-container">
    <div id="svg-wrapper" style="width: 100%; height: 100%;">
      {svg_content}
    </div>
    <div class="floating-tips">
      💡 <span>Gunakan <strong>Scroll Mouse</strong> untuk Zoom dan <strong>Drag Klik-Kiri</strong> untuk Menggeser Diagram (Pan).</span>
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

html_path = r"C:\Perkuliahan\Semester 7\Project SMT 7\SAAS HRIS\ERD_Chen_Notation_Viewer.html"
with open(html_path, "w", encoding="utf-8") as f:
    f.write(html_content)

print("SVG and HTML viewer successfully updated!")
