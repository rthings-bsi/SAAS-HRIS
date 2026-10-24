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

def render_matplotlib(diag_key, data, out_png):
    title = data["title"]
    actor_name = data["actor_name"]
    usecases = data["usecases"]
    n_uc = len(usecases)

    # Dimensions
    fig_w = 12.0
    uc_h = 0.66
    gap = 0.38
    top_y = 1.05
    col_h = n_uc * uc_h + (n_uc - 1) * gap
    fig_h = max(9.8, top_y + col_h + 1.0)

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
    tab_w = max(4.2, len(title) * 0.088 + 0.6)
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

    # Actor right hand
    hand_x = max_x + 0.36
    hand_y = may - 0.02

    # 4. Actor to Login dashed line with <<include>> (matching Image 28 template)
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

    # 5. Left Column Use Cases
    uc_mpl_pos = []
    login_rx = 0.82
    login_ry = 0.35

    for i, uc_text in enumerate(usecases):
        uy = (top_y * 100.0) + i * (uc_h * 100.0 + gap * 100.0) + (uc_h * 100.0) / 2.0
        mux, muy = to_mpl(uc_x, uy)
        uc_mpl_pos.append((mux, muy, uc_text))

        # Solid line from Actor hand to Use Case left edge
        ax.plot([hand_x, mux - 0.98], [hand_y, muy], color='#000000', lw=1.2, zorder=2)

        # Vector from right edge of Use Case to Login center
        dx = mlx - (mux + 0.98)
        dy = mly - muy
        dist = math.hypot(dx, dy)
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

    # 6. Login to Input Email & Input Password
    mex, mey = to_mpl(input_x, email_y)
    mpx, mpy = to_mpl(input_x, pass_y)

    # To Email
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

    # To Password
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

    # 8. Input Email & Input Password Ovals
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
    plt.savefig(out_png, dpi=200, bbox_inches='tight', facecolor='#FFFFFF')
    plt.close()
    print(f"Generated rotated-angle PNG: {out_png}")

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
        "Mengelola data penggajian",
        "Mengelola penilaian kinerja SMART",
        "Mengelola notifikasi sistem",
    ]
}

out_png = os.path.join(base_dir, "UseCase_Diagram_Administrator.png")
render_matplotlib("admin", admin_data, out_png)
