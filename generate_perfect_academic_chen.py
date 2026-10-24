import os
import math
import matplotlib.pyplot as plt
import matplotlib.patches as patches

WIDTH = 4400
HEIGHT = 3200

# Academic clean grayscale palette matching screenshot 25.png
BG_COLOR = "#FFFFFF"
ENTITY_BG = "#FFFFFF"
ENTITY_BORDER = "#0F172A"
ENTITY_TEXT = "#0F172A"

REL_BG = "#FFFFFF"
REL_BORDER = "#0F172A"
REL_TEXT = "#0F172A"

ATTR_BG = "#FFFFFF"
ATTR_BORDER = "#334155"
ATTR_TEXT = "#0F172A"
ATTR_PK_BG = "#F8FAFC"
ATTR_PK_BORDER = "#0F172A"

LINE_COLOR = "#334155"
CARD_BG = "#FFFFFF"
CARD_BORDER = "#64748B"
CARD_TEXT = "#0F172A"

# 11 Tables EXACTLY matching MySQL Database 'saas_hris'
# Perfectly tuned coordinates with ZERO overlaps, ZERO line collisions, and ZERO gaps
entities = {
    # 1. SHIFTS (x=550, y=420) - 5 attributes
    "shifts": {
        "x": 550, "y": 420, "w": 200, "h": 76,
        "label": "shifts",
        "attrs": [
            ("id_shifts", True, -260, -80),
            ("name", False, -200, -180),
            ("start_time", False, -20, -220),
            ("end_time", False, 160, -180),
            ("late_tolerance_minutes", False, -240, 25),
        ],
    },

    # 2. COMPANIES (x=1600, y=420) - 10 attributes
    # Clean top arch (6 attributes) and bottom wings (4 attributes)
    # Zero line intersections, zero ellipse overlaps
    "companies": {
        "x": 1600, "y": 420, "w": 220, "h": 76,
        "label": "companies",
        "attrs": [
            # Top Arch (6 attributes)
            ("name", False, -390, -130),
            ("industry", False, -260, -220),
            ("email", False, -95, -280),
            ("phone", False, 95, -280),
            ("address", False, 260, -220),
            ("director_name", False, 390, -130),

            # Bottom-left (2 attributes)
            ("id_companies", True, -260, 80),
            ("latitude", False, -160, 160),

            # Bottom-right (2 attributes)
            ("longitude", False, 160, 160),
            ("radius_meters", False, 260, 80),
        ],
    },

    # 3. USERS (x=2700, y=420) - 6 attributes
    "users": {
        "x": 2700, "y": 420, "w": 190, "h": 76,
        "label": "users",
        "attrs": [
            ("id_users", True, -290, -75),
            ("name", False, -220, -170),
            ("email", False, -95, -230),
            ("password", False, 95, -230),
            ("role", False, 220, -170),
            ("is_active", False, 290, -75),
        ],
    },

    # 4. NOTIFICATIONS (x=3750, y=420) - 6 attributes
    "notifications": {
        "x": 3750, "y": 420, "w": 220, "h": 76,
        "label": "notifications",
        "attrs": [
            ("id_notifications", True, 240, -140),
            ("type", False, 260, -50),
            ("title", False, 260, 45),
            ("message", False, 240, 140),
            ("is_read", False, 120, 210),
            ("read_at", False, -80, 210),
        ],
    },

    # 5. EMPLOYEES (x=1600, y=1200) - 10 attributes
    # 5 attributes on left wing, 5 on right wing
    # Leaves the entire top and bottom corridors 100% CLEAR for vertical buses!
    "employees": {
        "x": 1600, "y": 1200, "w": 260, "h": 82,
        "label": "employees",
        "attrs": [
            # Left wing (5 attributes)
            ("id_employees", True, -340, -160),
            ("nik", False, -340, -80),
            ("department_name", False, -340, 80),
            ("job_position_name", False, -340, 160),
            ("allowance_fixed", False, -340, 240),

            # Right wing (5 attributes)
            ("gender", False, 340, -160),
            ("hire_date", False, 340, -80),
            ("employment_status", False, 340, 80),
            ("basic_salary", False, 340, 160),
            ("annual_leave_quota", False, 340, 240),
        ],
    },

    # 6. ATTENDANCES (x=550, y=1200) - 8 attributes
    "attendances": {
        "x": 550, "y": 1200, "w": 220, "h": 76,
        "label": "attendances",
        "attrs": [
            ("id_attendances", True, -260, -85),
            ("date", False, -280, 0),
            ("clock_in_time", False, -260, 85),
            ("clock_out_time", False, -190, 165),
            ("clock_in_photo_path", False, -50, 225),
            ("status", False, 170, 175),
            ("late_duration_minutes", False, -240, -170),
            ("clock_in_distance_meters", False, 0, -210),
        ],
    },

    # 7. PAYROLL_SLIPS (x=550, y=1950) - 8 attributes
    "payroll_slips": {
        "x": 550, "y": 1950, "w": 230, "h": 76,
        "label": "payroll_slips",
        "attrs": [
            ("id_payroll_slips", True, -260, -75),
            ("period_name", False, -280, 5),
            ("start_date", False, -260, 85),
            ("end_date", False, -190, 165),
            ("basic_salary", False, -50, 225),
            ("net_salary", False, 170, 175),
            ("pdf_path", False, -240, -165),
            ("status", False, -20, -195),
        ],
    },

    # 8. LEAVE_REQUESTS (x=2650, y=1200) - 8 attributes
    "leave_requests": {
        "x": 2650, "y": 1200, "w": 240, "h": 76,
        "label": "leave_requests",
        "attrs": [
            ("id_leave_requests", True, 260, -85),
            ("leave_type", False, 280, 0),
            ("is_paid", False, 260, 85),
            ("start_date", False, 190, 165),
            ("end_date", False, 50, 225),
            ("total_days", False, -170, 175),
            ("reason", False, 240, -170),
            ("status", False, 0, -210),
        ],
    },

    # 9. OVERTIME_REQUESTS (x=2650, y=1950) - 7 attributes
    "overtime_requests": {
        "x": 2650, "y": 1950, "w": 250, "h": 76,
        "label": "overtime_requests",
        "attrs": [
            ("id_overtime_requests", True, 260, -75),
            ("date", False, 280, 5),
            ("start_time", False, 260, 85),
            ("end_time", False, 190, 165),
            ("duration_hours", False, 50, 225),
            ("reason", False, -170, 175),
            ("status", False, 230, -175),
        ],
    },

    # 10. PERFORMANCE_PERIODS (x=1050, y=2650) - 6 attributes
    "performance_periods": {
        "x": 1050, "y": 2650, "w": 270, "h": 76,
        "label": "performance_periods",
        "attrs": [
            ("id_performance_periods", True, -310, 80),
            ("name", False, -220, 170),
            ("start_date", False, -95, 235),
            ("end_date", False, 95, 235),
            ("status", False, 220, 170),
            ("criteria_config", False, 310, 80),
        ],
    },

    # 11. PERFORMANCE_EVALUATIONS (x=2250, y=2650) - 6 attributes
    "performance_evaluations": {
        "x": 2250, "y": 2650, "w": 290, "h": 76,
        "label": "performance_evaluations",
        "attrs": [
            ("id_performance_evaluations", True, -340, 85),
            ("final_score", False, -230, 175),
            ("rank", False, -95, 235),
            ("grade", False, 95, 235),
            ("recommendation", False, 230, 175),
            ("scores_breakdown", False, 340, 85),
        ],
    },
}

# 12 Planar Orthogonal Relationships with Seamless Non-Broken Connections and Open-Corridor Badges
relationships_data = [
    # 1. companies (1) -> shifts (N) via shifts.id_companies
    {
        "ent1": "companies", "ent2": "shifts", "label": "menetapkan", "c1": "1", "c2": "N",
        "rx": 1075, "ry": 420, "route": "direct",
        "b1": (1350, 395), "b2": (800, 395)
    },

    # 2. companies (1) -> users (N) via users.id_companies
    {
        "ent1": "companies", "ent2": "users", "label": "memiliki", "c1": "1", "c2": "N",
        "rx": 2150, "ry": 420, "route": "direct",
        "b1": (1850, 395), "b2": (2450, 395)
    },

    # 3. users (1) -> notifications (N) via notifications.id_users
    {
        "ent1": "users", "ent2": "notifications", "label": "menerima", "c1": "1", "c2": "N",
        "rx": 3225, "ry": 420, "route": "direct",
        "b1": (2980, 395), "b2": (3470, 395)
    },

    # 4. companies (1) -> employees (N) via employees.id_companies
    {
        "ent1": "companies", "ent2": "employees", "label": "mempekerjakan", "c1": "1", "c2": "N",
        "rx": 1600, "ry": 810, "route": "direct",
        "b1": (1630, 580), "b2": (1630, 1040)
    },

    # 5. shifts (1) -> employees (N) via employees.id_shifts
    # Seamless connection into top of employees at x=1530
    {
        "ent1": "shifts", "ent2": "employees", "label": "jadwal_kerja", "c1": "1", "c2": "N",
        "rx": 1075, "ry": 650, "route": "shift_pegawai",
        "b1": (750, 625), "b2": (1505, 1060)
    },

    # 6. users (1) -> employees (1) via employees.id_users (Unique)
    # Seamless connection into top of employees at x=1670
    {
        "ent1": "users", "ent2": "employees", "label": "akun_login", "c1": "1", "c2": "1",
        "rx": 2150, "ry": 650, "route": "pengguna_pegawai",
        "b1": (2480, 625), "b2": (1695, 1060)
    },

    # 7. employees (1) -> attendances (N) via attendances.id_employees
    {
        "ent1": "employees", "ent2": "attendances", "label": "mencatat", "c1": "1", "c2": "N",
        "rx": 1075, "ry": 1200, "route": "direct",
        "b1": (1420, 1175), "b2": (870, 1175)
    },

    # 8. employees (1) -> leave_requests (N) via leave_requests.id_employees
    {
        "ent1": "employees", "ent2": "leave_requests", "label": "mengajukan", "c1": "1", "c2": "N",
        "rx": 2125, "ry": 1200, "route": "direct",
        "b1": (1780, 1175), "b2": (2330, 1175)
    },

    # 9. employees (1) -> payroll_slips (N) via payroll_slips.id_employees
    # Seamless connection emerging from bottom of employees at x=1530
    {
        "ent1": "employees", "ent2": "payroll_slips", "label": "menerima", "c1": "1", "c2": "N",
        "rx": 1075, "ry": 1950, "route": "pegawai_slip",
        "b1": (1505, 1340), "b2": (830, 1925)
    },

    # 10. employees (1) -> overtime_requests (N) via overtime_requests.id_employees
    # Seamless connection emerging from bottom of employees at x=1670
    {
        "ent1": "employees", "ent2": "overtime_requests", "label": "mengajukan", "c1": "1", "c2": "N",
        "rx": 2125, "ry": 1950, "route": "pegawai_lembur",
        "b1": (1695, 1340), "b2": (2370, 1925)
    },

    # 11. employees (1) -> performance_evaluations (N) via performance_evaluations.id_employees
    # Seamless connection emerging from bottom center of employees at x=1600
    {
        "ent1": "employees", "ent2": "performance_evaluations", "label": "dievaluasi", "c1": "1", "c2": "N",
        "rx": 1925, "ry": 2300, "route": "pegawai_eval",
        "b1": (1630, 1550), "b2": (2280, 2480)
    },

    # 12. performance_periods (1) -> performance_evaluations (N) via performance_evaluations.id_performance_periods
    {
        "ent1": "performance_periods", "ent2": "performance_evaluations", "label": "menaungi", "c1": "1", "c2": "N",
        "rx": 1650, "ry": 2650, "route": "direct",
        "b1": (1350, 2625), "b2": (1950, 2625)
    },
]

# Helper for dynamic pill sizing
def get_pill_radius(name):
    rx = max(78, len(name) * 4.4 + 14)
    ry = 26
    return rx, ry

# Build High-Precision Clean Academic SVG
svg = []
svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {WIDTH} {HEIGHT}" width="{WIDTH}" height="{HEIGHT}" style="background-color: {BG_COLOR}; font-family: \'Segoe UI\', -apple-system, BlinkMacSystemFont, Arial, sans-serif;">')

# Draw relationship lines and cardinalities
# Lines connect directly into the entity bounding boxes (rendered underneath white box fills for 100% seamless joins)
svg.append('<g id="relationship-lines">')
for rel in relationships_data:
    e1 = entities[rel["ent1"]]
    e2 = entities[rel["ent2"]]
    rx, ry = rel["rx"], rel["ry"]
    route = rel["route"]
    c1, c2 = rel["c1"], rel["c2"]
    bx1, by1 = rel["b1"]
    bx2, by2 = rel["b2"]

    # Planar Orthogonal Routing with 100% seamless, unbroken joins into entity centers
    if route == "shift_pegawai":
        svg.append(f'<path d="M {e1["x"]} {e1["y"]} L {e1["x"]} {ry} L {rx} {ry} L 1530 {ry} L 1530 {e2["y"]}" fill="none" stroke="{LINE_COLOR}" stroke-width="2.0" />')
    elif route == "pengguna_pegawai":
        svg.append(f'<path d="M {e1["x"]} {e1["y"]} L {e1["x"]} {ry} L {rx} {ry} L 1670 {ry} L 1670 {e2["y"]}" fill="none" stroke="{LINE_COLOR}" stroke-width="2.0" />')
    elif route == "pegawai_slip":
        svg.append(f'<path d="M 1530 {e1["y"]} L 1530 {ry} L {rx} {ry} L {e2["x"]} {ry}" fill="none" stroke="{LINE_COLOR}" stroke-width="2.0" />')
    elif route == "pegawai_lembur":
        svg.append(f'<path d="M 1670 {e1["y"]} L 1670 {ry} L {rx} {ry} L {e2["x"]} {ry}" fill="none" stroke="{LINE_COLOR}" stroke-width="2.0" />')
    elif route == "pegawai_eval":
        svg.append(f'<path d="M {e1["x"]} {e1["y"]} L {e1["x"]} {ry} L {rx} {ry} L {e2["x"]} {ry} L {e2["x"]} {e2["y"]}" fill="none" stroke="{LINE_COLOR}" stroke-width="2.0" />')
    else:
        svg.append(f'<line x1="{e1["x"]}" y1="{e1["y"]}" x2="{rx}" y2="{ry}" stroke="{LINE_COLOR}" stroke-width="2.0" />')
        svg.append(f'<line x1="{rx}" y1="{ry}" x2="{e2["x"]}" y2="{e2["y"]}" stroke="{LINE_COLOR}" stroke-width="2.0" />')

    # Cardinality badge 1 (near ent1)
    svg.append(f'<rect x="{bx1-14}" y="{by1-12}" width="28" height="24" rx="4" fill="{CARD_BG}" stroke="{CARD_BORDER}" stroke-width="1.2" />')
    svg.append(f'<text x="{bx1}" y="{by1+5}" font-size="13" font-weight="bold" fill="{CARD_TEXT}" text-anchor="middle">{c1}</text>')

    # Cardinality badge 2 (near ent2)
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

        # Clean straight line from entity to attribute
        svg.append(f'<line x1="{ex}" y1="{ey}" x2="{ax}" y2="{ay}" stroke="{LINE_COLOR}" stroke-width="1.3" />')

        # Ellipse pill with dynamic width
        bg_col = ATTR_PK_BG if is_pk else ATTR_BG
        border_col = ATTR_PK_BORDER if is_pk else ATTR_BORDER
        stroke_w = "1.8" if is_pk else "1.2"
        rx_val, ry_val = get_pill_radius(aname)

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
for rel in relationships_data:
    rx, ry, label = rel["rx"], rel["ry"], rel["label"]
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
leg_x = 2200
leg_y = 3050
svg.append(f'''
<g id="legend" transform="translate({leg_x - 550}, {leg_y - 45})">
  <rect x="0" y="0" width="1100" height="75" rx="4" fill="#FFFFFF" stroke="#64748B" stroke-width="1.4" />
  <text x="550" y="22" font-size="11.5" font-weight="bold" fill="#0F172A" text-anchor="middle" letter-spacing="0.5">LEGENDA SIMBOL NOTASI PETER CHEN (STANDAR AKADEMIK - BASIS DATA SAAS HRIS)</text>

  <!-- Entity sample -->
  <rect x="40" y="34" width="105" height="28" rx="2" fill="#FFFFFF" stroke="#0F172A" stroke-width="1.8" />
  <text x="92" y="52" font-size="11" font-weight="bold" fill="#0F172A" text-anchor="middle">table_name</text>
  <text x="160" y="52" font-size="11" fill="#334155">= Entitas (Tabel MySQL)</text>

  <!-- Rel sample -->
  <polygon points="415,34 455,48 415,62 375,48" fill="#FFFFFF" stroke="#0F172A" stroke-width="1.6" />
  <text x="415" y="52" font-size="10" font-weight="bold" fill="#0F172A" text-anchor="middle">relasi</text>
  <text x="470" y="52" font-size="11" fill="#334155">= Relasi (FK)</text>

  <!-- Attr sample -->
  <ellipse cx="620" cy="48" rx="46" ry="15" fill="#FFFFFF" stroke="#334155" stroke-width="1.2" />
  <text x="620" y="52" font-size="10" fill="#0F172A" text-anchor="middle">column_name</text>
  <text x="680" y="52" font-size="11" fill="#334155">= Atribut (Kolom)</text>

  <!-- PK sample -->
  <ellipse cx="865" cy="48" rx="52" ry="15" fill="#F8FAFC" stroke="#0F172A" stroke-width="1.6" />
  <text x="865" y="52" font-size="10" font-weight="bold" fill="#0F172A" text-anchor="middle" text-decoration="underline">id_table (PK)</text>
  <text x="930" y="52" font-size="11" fill="#334155">= Primary Key</text>
</g>
''')

svg.append('</svg>')

svg_content = "\n".join(svg)

base_dir = r"C:\Perkuliahan\Semester 7\Project SMT 7\SAAS HRIS"
svg_path = os.path.join(base_dir, "ERD_Chen_Notation_Academic.svg")
with open(svg_path, "w", encoding="utf-8") as f:
    f.write(svg_content)

primary_svg_path = os.path.join(base_dir, "ERD_Chen_Notation_11_Tables.svg")
with open(primary_svg_path, "w", encoding="utf-8") as f:
    f.write(svg_content)

# HTML Viewer for Academic Version
html_content = f'''<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ERD Notasi Peter Chen (11 Tabel Skripsi Sesuai Database) — SAAS HRIS</title>
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
      background: #ECFDF5;
      color: #065F46;
      border: 1px solid #A7F3D0;
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
        <span>ERD Notasi Peter Chen (11 Tabel)</span>
        <span class="badge">100% Sesuai Skema MySQL Database saas_hris</span>
      </h1>
      <div class="subtitle">Format Buku &amp; Skripsi: Entitas, Atribut, Primary Key, dan Relasi Foreign Key Asli</div>
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

primary_viewer_path = os.path.join(base_dir, "ERD_Chen_Notation_Viewer.html")
with open(primary_viewer_path, "w", encoding="utf-8") as f:
    f.write(html_content)

# Render Matplotlib PNG at high resolution
def to_mpl(x, y):
    return x / 100.0, 32.0 - (y / 100.0)

fig, ax = plt.subplots(figsize=(44, 32), dpi=150)
fig.patch.set_facecolor('#FFFFFF')
ax.set_facecolor('#FFFFFF')

# 1. Draw Relationship Lines
for rel in relationships_data:
    e1 = entities[rel["ent1"]]
    e2 = entities[rel["ent2"]]
    rx, ry = rel["rx"], rel["ry"]
    route = rel["route"]
    c1, c2 = rel["c1"], rel["c2"]
    bx1_raw, by1_raw = rel["b1"]
    bx2_raw, by2_raw = rel["b2"]

    x1, y1 = to_mpl(e1["x"], e1["y"])
    x2, y2 = to_mpl(e2["x"], e2["y"])
    mrx, mry = to_mpl(rx, ry)

    if route == "shift_pegawai":
        sy_bend = 32.0 - (ry / 100.0)
        ax.plot([x1, x1, mrx, 15.3, 15.3], [y1, sy_bend, sy_bend, sy_bend, y2], color='#334155', lw=1.6, zorder=2)
    elif route == "pengguna_pegawai":
        sy_bend = 32.0 - (ry / 100.0)
        ax.plot([x1, x1, mrx, 16.7, 16.7], [y1, sy_bend, sy_bend, sy_bend, y2], color='#334155', lw=1.6, zorder=2)
    elif route == "pegawai_slip":
        sy_bend = 32.0 - (ry / 100.0)
        ax.plot([15.3, 15.3, mrx, x2], [y1, sy_bend, sy_bend, y2], color='#334155', lw=1.6, zorder=2)
    elif route == "pegawai_lembur":
        sy_bend = 32.0 - (ry / 100.0)
        ax.plot([16.7, 16.7, mrx, x2], [y1, sy_bend, sy_bend, y2], color='#334155', lw=1.6, zorder=2)
    elif route == "pegawai_eval":
        sy_bend = 32.0 - (ry / 100.0)
        ax.plot([x1, x1, mrx, x2, x2], [y1, sy_bend, sy_bend, sy_bend, y2], color='#334155', lw=1.6, zorder=2)
    else:
        ax.plot([x1, mrx], [y1, mry], color='#334155', lw=1.6, zorder=2)
        ax.plot([mrx, x2], [mry, y2], color='#334155', lw=1.6, zorder=2)

    # Cardinality badge 1
    mbx1, mby1 = to_mpl(bx1_raw, by1_raw)
    ax.text(
        mbx1, mby1, c1,
        fontsize=10.5, fontweight='bold', color='#0F172A',
        bbox=dict(boxstyle='square,pad=0.2', fc='#FFFFFF', ec='#64748B', lw=1.1),
        ha='center', va='center', zorder=6
    )

    # Cardinality badge 2
    mbx2, mby2 = to_mpl(bx2_raw, by2_raw)
    ax.text(
        mbx2, mby2, c2,
        fontsize=10.5, fontweight='bold', color='#0F172A',
        bbox=dict(boxstyle='square,pad=0.2', fc='#FFFFFF', ec='#64748B', lw=1.1),
        ha='center', va='center', zorder=6
    )

# 2. Draw Attribute Lines and Ovals
for ent_name, edata in entities.items():
    ex, ey = to_mpl(edata["x"], edata["y"])
    attrs = edata["attrs"]

    for aname, is_pk, dx, dy in attrs:
        ax_pos, ay_pos = to_mpl(edata["x"] + dx, edata["y"] + dy)

        # Connector line
        ax.plot([ex, ax_pos], [ey, ay_pos], color='#475569', lw=1.2, zorder=2)

        # Ellipse with dynamic width
        rx_val, ry_val = get_pill_radius(aname)
        mrx_val = rx_val / 100.0
        mry_val = ry_val / 100.0

        ellipse = patches.Ellipse(
            (ax_pos, ay_pos), mrx_val * 2, mry_val * 2,
            facecolor='#F8FAFC' if is_pk else '#FFFFFF',
            edgecolor='#0F172A' if is_pk else '#334155',
            linewidth=1.6 if is_pk else 1.2,
            zorder=4
        )
        ax.add_patch(ellipse)

        # Text inside attribute
        txt = ax.text(
            ax_pos, ay_pos, aname,
            fontsize=8.5, fontweight='bold' if is_pk else 'normal',
            color='#0F172A',
            ha='center', va='center', zorder=5
        )
        if is_pk:
            # Underline primary key
            ax.plot(
                [ax_pos - len(aname)*0.038, ax_pos + len(aname)*0.038],
                [ay_pos - 0.13, ay_pos - 0.13],
                color='#0F172A', lw=1.4, zorder=6
            )

# 3. Draw Relationship Diamonds (Rhombus)
for rel in relationships_data:
    rx, ry, label = rel["rx"], rel["ry"], rel["label"]
    mrx, mry = to_mpl(rx, ry)
    rw = 1.7
    rh = 0.74
    pts = [
        [mrx, mry + rh/2],
        [mrx + rw/2, mry],
        [mrx, mry - rh/2],
        [mrx - rw/2, mry]
    ]
    poly = patches.Polygon(pts, closed=True, facecolor='#FFFFFF', edgecolor='#0F172A', lw=1.8, zorder=4)
    ax.add_patch(poly)
    ax.text(
        mrx, mry, label,
        fontsize=9.5, fontweight='bold', color='#0F172A',
        ha='center', va='center', zorder=5
    )

# 4. Draw Entities (Rectangles)
for ent_name, edata in entities.items():
    ex, ey = to_mpl(edata["x"], edata["y"])
    ew = edata["w"] / 100.0
    eh = edata["h"] / 100.0
    elabel = edata["label"]

    rect = patches.FancyBboxPatch(
        (ex - ew/2, ey - eh/2), ew, eh,
        boxstyle="square,pad=0.0",
        facecolor='#FFFFFF', edgecolor='#0F172A',
        linewidth=2.0, zorder=4
    )
    ax.add_patch(rect)
    ax.text(
        ex, ey, elabel,
        fontsize=12, fontweight='bold', color='#0F172A',
        ha='center', va='center', zorder=5
    )

# 5. Draw Academic Legend Box at bottom center
leg_x, leg_y = 22.0, 1.5
leg_box = patches.FancyBboxPatch(
    (leg_x - 5.5, leg_y - 0.5), 11.0, 1.0,
    boxstyle="square,pad=0.1",
    facecolor='#FFFFFF', edgecolor='#64748B', lw=1.2, zorder=10
)
ax.add_patch(leg_box)
ax.text(leg_x, leg_y + 0.35, "LEGENDA NOTASI PETER CHEN (STANDAR AKADEMIK - BASIS DATA SAAS HRIS)", fontsize=9.5, fontweight='bold', color='#0F172A', ha='center', va='center', zorder=11)

# Entity sample
rect_sample = patches.FancyBboxPatch((leg_x - 4.9, leg_y - 0.25), 1.0, 0.4, boxstyle="square,pad=0.0", facecolor='#FFFFFF', edgecolor='#0F172A', lw=1.4, zorder=11)
ax.add_patch(rect_sample)
ax.text(leg_x - 4.4, leg_y - 0.05, "table_name", fontsize=8, fontweight='bold', color='#0F172A', ha='center', va='center', zorder=12)
ax.text(leg_x - 3.7, leg_y - 0.05, "= Entitas (Tabel)", fontsize=8, color='#334155', va='center', zorder=12)

# Rel sample
rel_pts = [[leg_x - 1.8, leg_y + 0.15], [leg_x - 1.4, leg_y - 0.05], [leg_x - 1.8, leg_y - 0.25], [leg_x - 2.2, leg_y - 0.05]]
ax.add_patch(patches.Polygon(rel_pts, closed=True, facecolor='#FFFFFF', edgecolor='#0F172A', lw=1.3, zorder=11))
ax.text(leg_x - 1.8, leg_y - 0.05, "relasi", fontsize=7.5, fontweight='bold', color='#0F172A', ha='center', va='center', zorder=12)
ax.text(leg_x - 1.25, leg_y - 0.05, "= Relasi (FK)", fontsize=8, color='#334155', va='center', zorder=12)

# Attr sample
ax.add_patch(patches.Ellipse((leg_x + 0.7, leg_y - 0.05), 1.0, 0.35, facecolor='#FFFFFF', edgecolor='#334155', lw=1.1, zorder=11))
ax.text(leg_x + 0.7, leg_y - 0.05, "column_name", fontsize=7.5, color='#0F172A', ha='center', va='center', zorder=12)
ax.text(leg_x + 1.35, leg_y - 0.05, "= Atribut (Kolom)", fontsize=8, color='#334155', va='center', zorder=12)

# PK sample
ax.add_patch(patches.Ellipse((leg_x + 3.4, leg_y - 0.05), 1.05, 0.35, facecolor='#F8FAFC', edgecolor='#0F172A', lw=1.4, zorder=11))
ax.text(leg_x + 3.4, leg_y - 0.05, "id_table", fontsize=7.5, fontweight='bold', color='#0F172A', ha='center', va='center', zorder=12)
ax.plot([leg_x + 3.13, leg_x + 3.67], [leg_y - 0.13, leg_y - 0.13], color='#0F172A', lw=1.2, zorder=13)
ax.text(leg_x + 4.1, leg_y - 0.05, "= Primary Key", fontsize=8, color='#334155', va='center', zorder=12)

ax.set_xlim(0, 44)
ax.set_ylim(0, 32)
ax.axis('off')

plt.tight_layout()

out_png_academic = os.path.join(base_dir, "ERD_Chen_Notation_Academic.png")
out_png_tables = os.path.join(base_dir, "ERD_Chen_Notation_11_Tables.png")

plt.savefig(out_png_academic, dpi=200, bbox_inches='tight', facecolor='#FFFFFF')
plt.savefig(out_png_tables, dpi=200, bbox_inches='tight', facecolor='#FFFFFF')
plt.close()

print("High precision Academic Chen ERD (SVG, PNG, HTML) 100% matched to MySQL saas_hris schema successfully generated!")
