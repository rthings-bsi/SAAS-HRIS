import os
import math
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, Ellipse, Polygon

def format_lines(text, max_chars=18):
    words = text.split()
    lines = []
    curr = []
    curr_len = 0
    for w in words:
        if curr_len + len(w) + (1 if curr else 0) <= max_chars:
            curr.append(w)
            curr_len += len(w) + (1 if curr else 0)
        else:
            if curr:
                lines.append(" ".join(curr))
            curr = [w]
            curr_len = len(w)
    if curr:
        lines.append(" ".join(curr))
    return lines

def generate_svg(diag_key, data):
    title = data["title"]
    actor_name = data["actor_name"]
    usecases = data["usecases"]
    n_uc = len(usecases)

    # Dimensions
    WIDTH = 1180
    # Dynamic height based on number of use cases
    uc_h = 64
    gap = 36
    top_y = 105
    col_height = n_uc * uc_h + (n_uc - 1) * gap
    bottom_y = top_y + col_height
    HEIGHT = max(950, bottom_y + 80)

    # Coordinates
    actor_x = 75
    cy = top_y + col_height / 2.0

    uc_x = 320
    login_x = 730
    login_y = cy

    input_x = 1000
    email_y = cy - 130
    pass_y = cy + 130

    svg = []
    svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {WIDTH} {HEIGHT}" width="{WIDTH}" height="{HEIGHT}" style="background-color: #FFFFFF; font-family: Arial, sans-serif;">')

    # Definitions (markers)
    svg.append('''<defs>
      <!-- Open arrowhead matching Image 28 template -->
      <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
        <path d="M 1 1 L 9 5 L 1 9" fill="none" stroke="#000000" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" />
      </marker>
    </defs>''')

    # 1. Outer Frame & Header Tab
    tab_w = max(380, len(title) * 8.8 + 50)
    tab_h = 28
    svg.append(f'<rect x="25" y="20" width="{WIDTH - 50}" height="{HEIGHT - 40}" fill="none" stroke="#000000" stroke-width="1.6" />')

    # Slanted tab at top-left
    svg.append(f'<polygon points="25,20 {tab_w},20 {tab_w - 14},{20 + tab_h} 25,{20 + tab_h}" fill="#FFFFFF" stroke="#000000" stroke-width="1.6" />')
    svg.append(f'<text x="45" y="{20 + 19}" font-size="14" font-weight="bold" fill="#000000">{title}</text>')

    # 2. Inner System Boundary Rectangle
    inner_x = 150
    inner_y = 58
    inner_w = WIDTH - inner_x - 45
    inner_h = HEIGHT - inner_y - 35
    svg.append(f'<rect x="{inner_x}" y="{inner_y}" width="{inner_w}" height="{inner_h}" fill="#FFFFFF" stroke="#000000" stroke-width="1.4" />')

    # 3. Actor Stick Figure
    head_cy = cy - 45
    svg.append(f'<circle cx="{actor_x}" cy="{head_cy}" r="22" fill="#FFFFFF" stroke="#000000" stroke-width="1.8" />')
    svg.append(f'<line x1="{actor_x}" y1="{head_cy + 22}" x2="{actor_x}" y2="{cy + 30}" stroke="#000000" stroke-width="1.8" />')
    svg.append(f'<line x1="{actor_x - 38}" y1="{cy + 2}" x2="{actor_x + 38}" y2="{cy + 2}" stroke="#000000" stroke-width="1.8" />')
    svg.append(f'<line x1="{actor_x}" y1="{cy + 30}" x2="{actor_x - 30}" y2="{cy + 85}" stroke="#000000" stroke-width="1.8" />')
    svg.append(f'<line x1="{actor_x}" y1="{cy + 30}" x2="{actor_x + 30}" y2="{cy + 85}" stroke="#000000" stroke-width="1.8" />')
    svg.append(f'<text x="{actor_x}" y="{cy + 110}" font-size="15" font-weight="bold" fill="#000000" text-anchor="middle">{actor_name}</text>')

    # 4. Actor to Login dashed line with <<include>> (matching Image 28)
    actor_hand_x = actor_x + 38
    actor_hand_y = cy + 2
    svg.append(f'<line x1="{actor_hand_x}" y1="{actor_hand_y}" x2="{login_x - 72}" y2="{login_y}" stroke="#000000" stroke-width="1.3" stroke-dasharray="5,4" marker-end="url(#arrow)" />')
    # <<include>> pill
    mid_ax = (actor_hand_x + login_x - 72) / 2.0
    mid_ay = (actor_hand_y + login_y) / 2.0
    svg.append(f'<rect x="{mid_ax - 36}" y="{mid_ay - 9}" width="72" height="18" fill="#FFFFFF" />')
    svg.append(f'<text x="{mid_ax}" y="{mid_ay + 4}" font-size="12" fill="#000000" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>')

    # 5. Left Column Use Cases
    uc_positions = []
    for i, uc_text in enumerate(usecases):
        uy = top_y + i * (uc_h + gap) + uc_h / 2.0
        uc_positions.append((uc_x, uy, uc_text))

        # Solid line from Actor to this Use Case
        svg.append(f'<line x1="{actor_hand_x}" y1="{actor_hand_y}" x2="{uc_x - 88}" y2="{uy}" stroke="#000000" stroke-width="1.4" />')

        # Dashed line from this Use Case to Login with <<include>>
        # Angle towards Login ellipse
        angle = math.atan2(login_y - uy, login_x - (uc_x + 88))
        target_lx = login_x - 70 * math.cos(angle)
        target_ly = login_y - 32 * math.sin(angle)

        svg.append(f'<line x1="{uc_x + 88}" y1="{uy}" x2="{target_lx}" y2="{target_ly}" stroke="#000000" stroke-width="1.3" stroke-dasharray="5,4" marker-end="url(#arrow)" />')

        # <<include>> label
        lm_x = (uc_x + 88 + target_lx) / 2.0
        lm_y = (uy + target_ly) / 2.0
        svg.append(f'<rect x="{lm_x - 34}" y="{lm_y - 8}" width="68" height="16" fill="#FFFFFF" />')
        svg.append(f'<text x="{lm_x}" y="{lm_y + 4}" font-size="11.5" fill="#000000" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>')

    # 6. Render Use Case Ovals on Left Column
    for ux, uy, uc_text in uc_positions:
        rx = 95
        ry = 32
        svg.append(f'<ellipse cx="{ux}" cy="{uy}" rx="{rx}" ry="{ry}" fill="#FFFFFF" stroke="#000000" stroke-width="1.5" />')

        lines = format_lines(uc_text, max_chars=18)
        if len(lines) == 1:
            svg.append(f'<text x="{ux}" y="{uy + 4.5}" font-size="12" fill="#000000" text-anchor="middle">{lines[0]}</text>')
        elif len(lines) == 2:
            svg.append(f'<text x="{ux}" y="{uy - 3}" font-size="11.5" fill="#000000" text-anchor="middle">{lines[0]}</text>')
            svg.append(f'<text x="{ux}" y="{uy + 12}" font-size="11.5" fill="#000000" text-anchor="middle">{lines[1]}</text>')
        else:
            svg.append(f'<text x="{ux}" y="{uy - 10}" font-size="11" fill="#000000" text-anchor="middle">{lines[0]}</text>')
            svg.append(f'<text x="{ux}" y="{uy + 4}" font-size="11" fill="#000000" text-anchor="middle">{lines[1]}</text>')
            svg.append(f'<text x="{ux}" y="{uy + 18}" font-size="11" fill="#000000" text-anchor="middle">{lines[2]}</text>')

    # 7. Login to Input Email & Input Password
    # Login to Email
    svg.append(f'<line x1="{login_x + 55}" y1="{login_y - 20}" x2="{input_x - 72}" y2="{email_y}" stroke="#000000" stroke-width="1.3" stroke-dasharray="5,4" marker-end="url(#arrow)" />')
    em_mid_x = (login_x + 55 + input_x - 72) / 2.0
    em_mid_y = (login_y - 20 + email_y) / 2.0
    svg.append(f'<rect x="{em_mid_x - 34}" y="{em_mid_y - 8}" width="68" height="16" fill="#FFFFFF" />')
    svg.append(f'<text x="{em_mid_x}" y="{em_mid_y + 4}" font-size="11.5" fill="#000000" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>')

    # Login to Password
    svg.append(f'<line x1="{login_x + 55}" y1="{login_y + 20}" x2="{input_x - 72}" y2="{pass_y}" stroke="#000000" stroke-width="1.3" stroke-dasharray="5,4" marker-end="url(#arrow)" />')
    pw_mid_x = (login_x + 55 + input_x - 72) / 2.0
    pw_mid_y = (login_y + 20 + pass_y) / 2.0
    svg.append(f'<rect x="{pw_mid_x - 34}" y="{pw_mid_y - 8}" width="68" height="16" fill="#FFFFFF" />')
    svg.append(f'<text x="{pw_mid_x}" y="{pw_mid_y + 4}" font-size="11.5" fill="#000000" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>')

    # 8. Render Login Oval
    login_rx = 76
    login_ry = 32
    svg.append(f'<ellipse cx="{login_x}" cy="{login_y}" rx="{login_rx}" ry="{login_ry}" fill="#FFFFFF" stroke="#000000" stroke-width="1.5" />')
    svg.append(f'<text x="{login_x}" y="{login_y + 5}" font-size="13.5" font-weight="bold" fill="#000000" text-anchor="middle">Login</text>')

    # 9. Render Input Email & Input Password Ovals
    svg.append(f'<ellipse cx="{input_x}" cy="{email_y}" rx="80" ry="30" fill="#FFFFFF" stroke="#000000" stroke-width="1.5" />')
    svg.append(f'<text x="{input_x}" y="{email_y + 4.5}" font-size="12" fill="#000000" text-anchor="middle">Input email</text>')

    svg.append(f'<ellipse cx="{input_x}" cy="{pass_y}" rx="85" ry="30" fill="#FFFFFF" stroke="#000000" stroke-width="1.5" />')
    svg.append(f'<text x="{input_x}" y="{pass_y + 4.5}" font-size="12" fill="#000000" text-anchor="middle">Input password</text>')

    svg.append('</svg>')
    return "\n".join(svg), WIDTH, HEIGHT

base_dir = r"C:\Perkuliahan\Semester 7\Project SMT 7\SAAS HRIS"
admin_data = {
    "title": "Use Case Sistem SAAS HRIS-Administrator",
    "actor_name": "Admin",
    "filename": "UseCase_Diagram_Administrator",
    "usecases": [
        "Mengelola data profil perusahaan",
        "Mengelola master shift kerja",
        "Mengelola data karyawan",
        "Mengelola manajemen user",
        "Mengelola data presensi",
        "Mengelola pengajuan cuti",
        "Mengelola pengajuan lembur",
        "Mengelola penggajian & slip gaji",
        "Mengelola penilaian kinerja SMART",
        "Mengelola notifikasi sistem",
    ]
}

svg_content, w, h = generate_svg("admin", admin_data)
out_svg = os.path.join(base_dir, "UseCase_Diagram_Administrator.svg")
with open(out_svg, "w", encoding="utf-8") as f:
    f.write(svg_content)

print(f"Generated {out_svg} with dimensions {w}x{h}")
