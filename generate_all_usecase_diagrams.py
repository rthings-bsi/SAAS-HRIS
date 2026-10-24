import os
import math
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import Ellipse, Polygon

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

DIAGRAMS = {
    "admin": {
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
            "Mengelola data penggajian",
            "Mengelola penilaian kinerja SMART",
            "Mengelola notifikasi sistem",
        ]
    },
    "karyawan": {
        "title": "Use Case Sistem SAAS HRIS-Karyawan",
        "actor_name": "Karyawan",
        "filename": "UseCase_Diagram_Karyawan",
        "usecases": [
            "Melakukan presensi masuk & pulang",
            "Melihat riwayat presensi",
            "Mengajukan permohonan cuti",
            "Melihat kuota & status cuti",
            "Mengajukan permohonan lembur",
            "Melihat status lembur",
            "Melihat & unduh slip gaji",
            "Melihat hasil evaluasi kinerja",
            "Melihat notifikasi sistem",
        ]
    },
    "manager": {
        "title": "Use Case Sistem SAAS HRIS-Manager",
        "actor_name": "Manager",
        "filename": "UseCase_Diagram_Manager",
        "usecases": [
            "Menyetujui pengajuan cuti",
            "Menyetujui pengajuan lembur",
            "Memantau monitoring presensi tim",
            "Melakukan penilaian kinerja SPK",
            "Melihat rekap & ranking kinerja",
            "Melihat notifikasi sistem",
        ]
    }
}

def generate_actor_svg(data):
    title = data["title"]
    actor_name = data["actor_name"]
    usecases = data["usecases"]
    n_uc = len(usecases)

    WIDTH = 1200
    uc_h = 66
    gap = 38
    top_y = 110
    col_h = n_uc * uc_h + (n_uc - 1) * gap
    HEIGHT = max(960, top_y + col_h + 100)

    actor_x = 75
    cy = top_y + col_h / 2.0

    uc_x = 340
    login_x = 760
    login_y = cy

    input_x = 1040
    email_y = cy - 130
    pass_y = cy + 130

    svg = []
    svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {WIDTH} {HEIGHT}" width="{WIDTH}" height="{HEIGHT}" style="background-color: #FFFFFF; font-family: Arial, sans-serif;">')

    # Marker definitions
    svg.append('''<defs>
      <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
        <path d="M 1 1 L 9 5 L 1 9" fill="none" stroke="#000000" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" />
      </marker>
    </defs>''')

    # 1. Outer Frame
    tab_w = max(420, len(title) * 8.6 + 50)
    tab_h = 28
    svg.append(f'<rect x="25" y="20" width="{WIDTH - 50}" height="{HEIGHT - 40}" fill="none" stroke="#000000" stroke-width="1.5" />')

    # Top-left folded/slanted tab
    svg.append(f'<polygon points="25,20 {tab_w},20 {tab_w - 14},{20 + tab_h} 25,{20 + tab_h}" fill="#FFFFFF" stroke="#000000" stroke-width="1.5" />')
    svg.append(f'<text x="42" y="{20 + 19}" font-size="13.5" font-weight="bold" fill="#000000">{title}</text>')

    # 2. Inner System Boundary
    inner_x = 155
    inner_y = 56
    inner_w = WIDTH - inner_x - 45
    inner_h = HEIGHT - inner_y - 35
    svg.append(f'<rect x="{inner_x}" y="{inner_y}" width="{inner_w}" height="{inner_h}" fill="#FFFFFF" stroke="#000000" stroke-width="1.3" />')

    # 3. Actor Stick Figure
    head_cy = cy - 45
    svg.append(f'<circle cx="{actor_x}" cy="{head_cy}" r="22" fill="#FFFFFF" stroke="#000000" stroke-width="1.8" />')
    svg.append(f'<line x1="{actor_x}" y1="{head_cy + 22}" x2="{actor_x}" y2="{cy + 30}" stroke="#000000" stroke-width="1.8" />')
    svg.append(f'<line x1="{actor_x - 36}" y1="{cy + 2}" x2="{actor_x + 36}" y2="{cy + 2}" stroke="#000000" stroke-width="1.8" />')
    svg.append(f'<line x1="{actor_x}" y1="{cy + 30}" x2="{actor_x - 30}" y2="{cy + 85}" stroke="#000000" stroke-width="1.8" />')
    svg.append(f'<line x1="{actor_x}" y1="{cy + 30}" x2="{actor_x + 30}" y2="{cy + 85}" stroke="#000000" stroke-width="1.8" />')
    svg.append(f'<text x="{actor_x}" y="{cy + 110}" font-size="14.5" font-weight="bold" fill="#000000" text-anchor="middle">{actor_name}</text>')

    actor_hand_x = actor_x + 36
    actor_hand_y = cy + 2

    # 4. Actor to Login dashed line with <<include>>
    svg.append(f'<line x1="{actor_hand_x}" y1="{actor_hand_y}" x2="{login_x - 80}" y2="{login_y}" stroke="#000000" stroke-width="1.2" stroke-dasharray="5,4" marker-end="url(#arrow)" />')
    mid_ax = (actor_hand_x + login_x - 80) / 2.0
    mid_ay = (actor_hand_y + login_y) / 2.0
    svg.append(f'<rect x="{mid_ax - 34}" y="{mid_ay - 8}" width="68" height="16" fill="#FFFFFF" />')
    svg.append(f'<text x="{mid_ax}" y="{mid_ay + 4}" font-size="11.5" fill="#000000" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>')

    # 5. Use Case Lines & Ovals
    login_rx = 82
    login_ry = 35

    uc_positions = []
    for i, uc_text in enumerate(usecases):
        uy = top_y + i * (uc_h + gap) + uc_h / 2.0
        uc_positions.append((uc_x, uy, uc_text))

        # Solid line from Actor hand to Use Case left edge
        svg.append(f'<line x1="{actor_hand_x}" y1="{actor_hand_y}" x2="{uc_x - 98}" y2="{uy}" stroke="#000000" stroke-width="1.2" />')

        # Dashed line from Use Case right edge to Login
        dx = login_x - (uc_x + 98)
        dy = login_y - uy
        ang = math.atan2(dy, dx)
        target_x = login_x - login_rx * math.cos(ang)
        target_y = login_y - login_ry * math.sin(ang)

        svg.append(f'<line x1="{uc_x + 98}" y1="{uy}" x2="{target_x}" y2="{target_y}" stroke="#000000" stroke-width="1.2" stroke-dasharray="5,4" marker-end="url(#arrow)" />')

        mid_lx = (uc_x + 98 + target_x) / 2.0
        mid_ly = (uy + target_y) / 2.0
        deg = math.degrees(math.atan2(target_y - uy, target_x - (uc_x + 98)))
        if deg > 90: deg -= 180
        elif deg < -90: deg += 180

        svg.append(f'<g transform="translate({mid_lx}, {mid_ly}) rotate({deg})">')
        svg.append(f'<rect x="-34" y="-8" width="68" height="16" fill="#FFFFFF" />')
        svg.append(f'<text x="0" y="4" font-size="11" fill="#000000" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>')
        svg.append('</g>')

    # Render Use Case Ovals
    for ux, uy, uc_text in uc_positions:
        rx = 100
        ry = 34
        svg.append(f'<ellipse cx="{ux}" cy="{uy}" rx="{rx}" ry="{ry}" fill="#FFFFFF" stroke="#000000" stroke-width="1.4" />')

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

    # 6. Login to Input Email & Input Password
    # Email
    ang_em = math.atan2(email_y - login_y, input_x - login_x)
    em_start_x = login_x + login_rx * math.cos(ang_em)
    em_start_y = login_y + login_ry * math.sin(ang_em)
    em_target_x = input_x - 88 * math.cos(ang_em)
    em_target_y = email_y - 32 * math.sin(ang_em)

    svg.append(f'<line x1="{em_start_x}" y1="{em_start_y}" x2="{em_target_x}" y2="{em_target_y}" stroke="#000000" stroke-width="1.2" stroke-dasharray="5,4" marker-end="url(#arrow)" />')
    em_mid_x = (em_start_x + em_target_x) / 2.0
    em_mid_y = (em_start_y + em_target_y) / 2.0
    deg_em = math.degrees(ang_em)
    if deg_em > 90: deg_em -= 180
    elif deg_em < -90: deg_em += 180

    svg.append(f'<g transform="translate({em_mid_x}, {em_mid_y}) rotate({deg_em})">')
    svg.append(f'<rect x="-34" y="-8" width="68" height="16" fill="#FFFFFF" />')
    svg.append(f'<text x="0" y="4" font-size="11" fill="#000000" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>')
    svg.append('</g>')

    # Password
    ang_pw = math.atan2(pass_y - login_y, input_x - login_x)
    pw_start_x = login_x + login_rx * math.cos(ang_pw)
    pw_start_y = login_y + login_ry * math.sin(ang_pw)
    pw_target_x = input_x - 92 * math.cos(ang_pw)
    pw_target_y = pass_y - 32 * math.sin(ang_pw)

    svg.append(f'<line x1="{pw_start_x}" y1="{pw_start_y}" x2="{pw_target_x}" y2="{pw_target_y}" stroke="#000000" stroke-width="1.2" stroke-dasharray="5,4" marker-end="url(#arrow)" />')
    pw_mid_x = (pw_start_x + pw_target_x) / 2.0
    pw_mid_y = (pw_start_y + pw_target_y) / 2.0
    deg_pw = math.degrees(ang_pw)
    if deg_pw > 90: deg_pw -= 180
    elif deg_pw < -90: deg_pw += 180

    svg.append(f'<g transform="translate({pw_mid_x}, {pw_mid_y}) rotate({deg_pw})">')
    svg.append(f'<rect x="-34" y="-8" width="68" height="16" fill="#FFFFFF" />')
    svg.append(f'<text x="0" y="4" font-size="11" fill="#000000" text-anchor="middle">&lt;&lt;include&gt;&gt;</text>')
    svg.append('</g>')

    # 7. Render Login Oval
    svg.append(f'<ellipse cx="{login_x}" cy="{login_y}" rx="{login_rx}" ry="{login_ry}" fill="#FFFFFF" stroke="#000000" stroke-width="1.5" />')
    svg.append(f'<text x="{login_x}" y="{login_y + 5}" font-size="13.5" font-weight="bold" fill="#000000" text-anchor="middle">Login</text>')

    # 8. Render Input Email & Input Password Ovals
    svg.append(f'<ellipse cx="{input_x}" cy="{email_y}" rx="88" ry="32" fill="#FFFFFF" stroke="#000000" stroke-width="1.4" />')
    svg.append(f'<text x="{input_x}" y="{email_y + 4.5}" font-size="12" fill="#000000" text-anchor="middle">Input email</text>')

    svg.append(f'<ellipse cx="{input_x}" cy="{pass_y}" rx="92" ry="32" fill="#FFFFFF" stroke="#000000" stroke-width="1.4" />')
    svg.append(f'<text x="{input_x}" y="{pass_y + 4.5}" font-size="12" fill="#000000" text-anchor="middle">Input password</text>')

    svg.append('</svg>')
    return "\n".join(svg), WIDTH, HEIGHT

def render_actor_matplotlib(data, out_png):
    title = data["title"]
    actor_name = data["actor_name"]
    usecases = data["usecases"]
    n_uc = len(usecases)

    fig_w = 12.0
    uc_h = 0.66
    gap = 0.38
    top_y = 1.05
    col_h = n_uc * uc_h + (n_uc - 1) * gap
    fig_h = max(9.6, top_y + col_h + 1.0)

    def to_mpl(x, y):
        return x / 100.0, fig_h - (y / 100.0)

    fig, ax = plt.subplots(figsize=(fig_w, fig_h), dpi=220)
    fig.patch.set_facecolor('#FFFFFF')
    ax.set_facecolor('#FFFFFF')

    actor_x = 75
    cy = (top_y * 100.0) + (col_h * 100.0) / 2.0

    uc_x = 340
    login_x = 760
    login_y = cy

    input_x = 1040
    email_y = cy - 130
    pass_y = cy + 130

    # 1. Outer Frame
    outer_w = fig_w - 0.5
    outer_h = fig_h - 0.5
    rect_outer = patches.Rectangle((0.25, 0.25), outer_w, outer_h, fill=False, edgecolor='#000000', linewidth=1.5)
    ax.add_patch(rect_outer)

    # Tab at top-left
    tab_w = max(4.2, len(title) * 0.086 + 0.5)
    tab_h = 0.32
    tab_pts = [
        [0.25, fig_h - 0.25],
        [0.25 + tab_w, fig_h - 0.25],
        [0.25 + tab_w - 0.16, fig_h - 0.25 - tab_h],
        [0.25, fig_h - 0.25 - tab_h]
    ]
    tab_poly = patches.Polygon(tab_pts, closed=True, facecolor='#FFFFFF', edgecolor='#000000', linewidth=1.5, zorder=5)
    ax.add_patch(tab_poly)
    ax.text(0.42, fig_h - 0.25 - tab_h/2.0 - 0.02, title, fontsize=10.5, fontweight='bold', color='#000000', va='center', zorder=6)

    # 2. Inner System Boundary
    inner_x = 1.55
    inner_y = 0.55
    inner_w = fig_w - inner_x - 0.45
    inner_h = fig_h - 1.25
    rect_inner = patches.Rectangle((inner_x, inner_y), inner_w, inner_h, fill=False, edgecolor='#000000', linewidth=1.3)
    ax.add_patch(rect_inner)

    # 3. Actor Stick Figure
    max_x, may = to_mpl(actor_x, cy)
    head_r = 0.22
    circle_head = patches.Circle((max_x, may + 0.45), head_r, facecolor='#FFFFFF', edgecolor='#000000', linewidth=1.8, zorder=10)
    ax.add_patch(circle_head)

    # Spine
    ax.plot([max_x, max_x], [may + 0.23, may - 0.30], color='#000000', lw=1.8, zorder=10)
    # Arms
    ax.plot([max_x - 0.36, max_x + 0.36], [may - 0.02, may - 0.02], color='#000000', lw=1.8, zorder=10)
    # Left leg
    ax.plot([max_x, max_x - 0.30], [may - 0.30, may - 0.85], color='#000000', lw=1.8, zorder=10)
    # Right leg
    ax.plot([max_x, max_x + 0.30], [may - 0.30, may - 0.85], color='#000000', lw=1.8, zorder=10)
    # Actor Label
    ax.text(max_x, may - 1.10, actor_name, fontsize=12, fontweight='bold', color='#000000', ha='center', va='center', zorder=10)

    hand_x = max_x + 0.36
    hand_y = may - 0.02

    # 4. Actor to Login dashed line
    mlx, mly = to_mpl(login_x, login_y)
    ax.annotate(
        "", xy=(mlx - 0.80, mly), xytext=(hand_x, hand_y),
        arrowprops=dict(arrowstyle="->", linestyle="--", color="#000000", lw=1.2, shrinkA=0, shrinkB=0),
        zorder=3
    )
    mid_ax = (hand_x + mlx - 0.80) / 2.0
    mid_ay = (hand_y + mly) / 2.0
    ax.text(mid_ax, mid_ay, "<<include>>", fontsize=8.5, color='#000000', ha='center', va='center',
            bbox=dict(boxstyle='square,pad=0.15', fc='#FFFFFF', ec='none'), zorder=4)

    # 5. Use Case Lines & Ovals
    login_rx = 0.82
    login_ry = 0.35

    uc_mpl_pos = []
    for i, uc_text in enumerate(usecases):
        uy = (top_y * 100.0) + i * (uc_h * 100.0 + gap * 100.0) + (uc_h * 100.0) / 2.0
        mux, muy = to_mpl(uc_x, uy)
        uc_mpl_pos.append((mux, muy, uc_text))

        # Solid line from Actor hand to Use Case
        ax.plot([hand_x, mux - 0.98], [hand_y, muy], color='#000000', lw=1.2, zorder=2)

        # Vector to Login
        dx = mlx - (mux + 0.98)
        dy = mly - muy
        ang = math.atan2(dy, dx)
        target_x = mlx - login_rx * math.cos(ang)
        target_y = mly - login_ry * math.sin(ang)

        ax.annotate(
            "", xy=(target_x, target_y), xytext=(mux + 0.98, muy),
            arrowprops=dict(arrowstyle="->", linestyle="--", color="#000000", lw=1.2, shrinkA=0, shrinkB=0),
            zorder=3
        )

        mid_lx = (mux + 0.98 + target_x) / 2.0
        mid_ly = (muy + target_y) / 2.0

        deg = math.degrees(math.atan2(target_y - muy, target_x - (mux + 0.98)))
        if deg > 90: deg -= 180
        elif deg < -90: deg += 180

        ax.text(mid_lx, mid_ly, "<<include>>", fontsize=8, color='#000000', ha='center', va='center',
                rotation=deg, bbox=dict(boxstyle='square,pad=0.12', fc='#FFFFFF', ec='none'), zorder=4)

    # Render Use Case Ellipses
    for mux, muy, uc_text in uc_mpl_pos:
        ellipse = Ellipse((mux, muy), 2.05, 0.70, facecolor='#FFFFFF', edgecolor='#000000', lw=1.4, zorder=5)
        ax.add_patch(ellipse)

        lines = format_lines(uc_text, max_chars=18)
        if len(lines) == 1:
            ax.text(mux, muy, lines[0], fontsize=8.5, color='#000000', ha='center', va='center', zorder=6)
        elif len(lines) == 2:
            ax.text(mux, muy + 0.08, lines[0], fontsize=8, color='#000000', ha='center', va='center', zorder=6)
            ax.text(mux, muy - 0.08, lines[1], fontsize=8, color='#000000', ha='center', va='center', zorder=6)
        else:
            ax.text(mux, muy + 0.14, lines[0], fontsize=7.5, color='#000000', ha='center', va='center', zorder=6)
            ax.text(mux, muy, lines[1], fontsize=7.5, color='#000000', ha='center', va='center', zorder=6)
            ax.text(mux, muy - 0.14, lines[2], fontsize=7.5, color='#000000', ha='center', va='center', zorder=6)

    # 6. Login to Email & Password
    mex, mey = to_mpl(input_x, email_y)
    mpx, mpy = to_mpl(input_x, pass_y)

    ang_em = math.atan2(mey - mly, mex - mlx)
    em_start_x = mlx + login_rx * math.cos(ang_em)
    em_start_y = mly + login_ry * math.sin(ang_em)
    em_target_x = mex - 0.88 * math.cos(ang_em)
    em_target_y = mey - 0.32 * math.sin(ang_em)

    ax.annotate(
        "", xy=(em_target_x, em_target_y), xytext=(em_start_x, em_start_y),
        arrowprops=dict(arrowstyle="->", linestyle="--", color="#000000", lw=1.2, shrinkA=0, shrinkB=0),
        zorder=3
    )
    em_mid_x = (em_start_x + em_target_x) / 2.0
    em_mid_y = (em_start_y + em_target_y) / 2.0
    deg_em = math.degrees(ang_em)
    if deg_em > 90: deg_em -= 180
    elif deg_em < -90: deg_em += 180
    ax.text(em_mid_x, em_mid_y, "<<include>>", fontsize=8, color='#000000', ha='center', va='center',
            rotation=deg_em, bbox=dict(boxstyle='square,pad=0.12', fc='#FFFFFF', ec='none'), zorder=4)

    ang_pw = math.atan2(mpy - mly, mpx - mlx)
    pw_start_x = mlx + login_rx * math.cos(ang_pw)
    pw_start_y = mly + login_ry * math.sin(ang_pw)
    pw_target_x = mpx - 0.92 * math.cos(ang_pw)
    pw_target_y = mpy - 0.32 * math.sin(ang_pw)

    ax.annotate(
        "", xy=(pw_target_x, pw_target_y), xytext=(pw_start_x, pw_start_y),
        arrowprops=dict(arrowstyle="->", linestyle="--", color="#000000", lw=1.2, shrinkA=0, shrinkB=0),
        zorder=3
    )
    pw_mid_x = (pw_start_x + pw_target_x) / 2.0
    pw_mid_y = (pw_start_y + pw_target_y) / 2.0
    deg_pw = math.degrees(ang_pw)
    if deg_pw > 90: deg_pw -= 180
    elif deg_pw < -90: deg_pw += 180
    ax.text(pw_mid_x, pw_mid_y, "<<include>>", fontsize=8, color='#000000', ha='center', va='center',
            rotation=deg_pw, bbox=dict(boxstyle='square,pad=0.12', fc='#FFFFFF', ec='none'), zorder=4)

    # 7. Login Oval
    login_ellipse = Ellipse((mlx, mly), login_rx * 2, login_ry * 2, facecolor='#FFFFFF', edgecolor='#000000', lw=1.5, zorder=5)
    ax.add_patch(login_ellipse)
    ax.text(mlx, mly, "Login", fontsize=10, fontweight='bold', color='#000000', ha='center', va='center', zorder=6)

    # 8. Input Email & Input Password
    email_ellipse = Ellipse((mex, mey), 1.76, 0.65, facecolor='#FFFFFF', edgecolor='#000000', lw=1.4, zorder=5)
    ax.add_patch(email_ellipse)
    ax.text(mex, mey, "Input email", fontsize=8.5, color='#000000', ha='center', va='center', zorder=6)

    pass_ellipse = Ellipse((mpx, mpy), 1.84, 0.65, facecolor='#FFFFFF', edgecolor='#000000', lw=1.4, zorder=5)
    ax.add_patch(pass_ellipse)
    ax.text(mpx, mpy, "Input password", fontsize=8.5, color='#000000', ha='center', va='center', zorder=6)

    ax.set_xlim(0, fig_w)
    ax.set_ylim(0, fig_h)
    ax.axis('off')

    plt.tight_layout()
    plt.savefig(out_png, dpi=220, bbox_inches='tight', facecolor='#FFFFFF')
    plt.close()
    print(f"Generated PNG: {out_png}")

base_dir = r"C:\Perkuliahan\Semester 7\Project SMT 7\SAAS HRIS"

svg_contents = {}
for key, data in DIAGRAMS.items():
    svg_str, w, h = generate_actor_svg(data)
    svg_contents[key] = svg_str

    svg_file = os.path.join(base_dir, f"{data['filename']}.svg")
    with open(svg_file, "w", encoding="utf-8") as f:
        f.write(svg_str)
    print(f"Saved SVG: {svg_file}")

    png_file = os.path.join(base_dir, f"{data['filename']}.png")
    render_actor_matplotlib(data, png_file)

# Interactive HTML Viewer with Tab Switching
viewer_html = f'''<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Diagram Use Case — Sistem Informasi SAAS HRIS (Standar Skripsi / Akademik)</title>
  <script src="https://cdn.jsdelivr.net/npm/svg-pan-zoom@3.6.1/dist/svg-pan-zoom.min.js"></script>
  <style>
    * {{
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }}
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
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
      padding: 10px 20px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 1px solid #E2E8F0;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
      z-index: 20;
    }}
    .title-box h1 {{
      font-size: 15px;
      font-weight: 700;
      display: flex;
      align-items: center;
      gap: 10px;
    }}
    .badge {{
      font-size: 11px;
      background: #EFF6FF;
      color: #1D4ED8;
      border: 1px solid #BFDBFE;
      padding: 2px 8px;
      border-radius: 4px;
      font-weight: 600;
    }}
    .subtitle {{
      font-size: 12px;
      color: #64748B;
      margin-top: 2px;
    }}
    .tabs {{
      display: flex;
      background: #F1F5F9;
      padding: 3px;
      border-radius: 8px;
      gap: 4px;
    }}
    .tab-btn {{
      background: transparent;
      border: none;
      padding: 6px 14px;
      font-size: 12px;
      font-weight: 600;
      color: #475569;
      cursor: pointer;
      border-radius: 6px;
      transition: all 0.15s ease;
    }}
    .tab-btn:hover {{
      color: #0F172A;
    }}
    .tab-btn.active {{
      background: #FFFFFF;
      color: #0F172A;
      box-shadow: 0 1px 2px rgba(0,0,0,0.08);
    }}
    .toolbar {{
      display: flex;
      gap: 6px;
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
      transition: all 0.15s ease;
    }}
    .btn:hover {{
      background: #F1F5F9;
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
    .svg-wrapper {{
      width: 100%;
      height: 100%;
      display: none;
    }}
    .svg-wrapper.active {{
      display: block;
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
      box-shadow: 0 2px 6px rgba(0,0,0,0.06);
      pointer-events: none;
    }}
  </style>
</head>
<body>
  <header>
    <div class="title-box">
      <h1>
        <span>Use Case Diagram (Standar Template UML)</span>
        <span class="badge">Sistem SAAS HRIS</span>
      </h1>
      <div class="subtitle">Format Lengkap Buku Skripsi: Aktor, Sistem Boundary, Relasi Asosiasi &amp; &lt;&lt;include&gt;&gt;</div>
    </div>

    <!-- Tab Selector -->
    <div class="tabs">
      <button class="tab-btn active" onclick="switchTab('admin')">🏢 Administrator</button>
      <button class="tab-btn" onclick="switchTab('karyawan')">👥 Karyawan</button>
      <button class="tab-btn" onclick="switchTab('manager')">👔 Manager</button>
    </div>

    <div class="toolbar">
      <button class="btn" onclick="zoomIn()">🔍 Zoom In</button>
      <button class="btn" onclick="zoomOut()">🔍 Zoom Out</button>
      <button class="btn" onclick="resetZoom()">↺ Reset</button>
      <a id="btn-download-png" href="UseCase_Diagram_Administrator.png" download="UseCase_Diagram_Administrator.png" class="btn btn-primary">📥 Unduh PNG</a>
      <a id="btn-download-svg" href="UseCase_Diagram_Administrator.svg" download="UseCase_Diagram_Administrator.svg" class="btn">📥 Unduh SVG</a>
    </div>
  </header>

  <div id="viewer-container">
    <div id="wrapper-admin" class="svg-wrapper active">
      {svg_contents["admin"]}
    </div>
    <div id="wrapper-karyawan" class="svg-wrapper">
      {svg_contents["karyawan"]}
    </div>
    <div id="wrapper-manager" class="svg-wrapper">
      {svg_contents["manager"]}
    </div>

    <div class="floating-tips">
      💡 <span>Gunakan <strong>Scroll Mouse</strong> untuk Zoom dan <strong>Drag Klik-Kiri</strong> untuk Menggeser Diagram.</span>
    </div>
  </div>

  <script>
    let currentPanZoom = null;
    let currentRole = 'admin';

    function initPanZoom(role) {{
      if (currentPanZoom) {{
        currentPanZoom.destroy();
        currentPanZoom = null;
      }}
      const svgEl = document.querySelector('#wrapper-' + role + ' svg');
      svgEl.id = 'svg-' + role;
      currentPanZoom = svgPanZoom('#svg-' + role, {{
        zoomEnabled: true,
        controlIconsEnabled: false,
        fit: true,
        center: true,
        minZoom: 0.2,
        maxZoom: 10,
        zoomScaleSensitivity: 0.2
      }});
    }}

    function switchTab(role) {{
      currentRole = role;
      document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
      event.target.classList.add('active');

      document.querySelectorAll('.svg-wrapper').forEach(w => w.classList.remove('active'));
      document.getElementById('wrapper-' + role).classList.add('active');

      // Update download links
      const filenameMap = {{
        'admin': 'UseCase_Diagram_Administrator',
        'karyawan': 'UseCase_Diagram_Karyawan',
        'manager': 'UseCase_Diagram_Manager'
      }};
      const fname = filenameMap[role];
      document.getElementById('btn-download-png').href = fname + '.png';
      document.getElementById('btn-download-png').download = fname + '.png';
      document.getElementById('btn-download-svg').href = fname + '.svg';
      document.getElementById('btn-download-svg').download = fname + '.svg';

      setTimeout(() => initPanZoom(role), 50);
    }}

    function zoomIn() {{ if (currentPanZoom) currentPanZoom.zoomIn(); }}
    function zoomOut() {{ if (currentPanZoom) currentPanZoom.zoomOut(); }}
    function resetZoom() {{ if (currentPanZoom) currentPanZoom.reset(); }}

    window.addEventListener('DOMContentLoaded', () => {{
      initPanZoom('admin');
    }});
  </script>
</body>
</html>
'''

viewer_file = os.path.join(base_dir, "UseCase_Diagram_Viewer.html")
with open(viewer_file, "w", encoding="utf-8") as f:
    f.write(viewer_html)
print(f"Generated Viewer: {viewer_file}")
