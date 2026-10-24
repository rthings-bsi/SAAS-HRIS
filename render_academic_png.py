import os
import math
import matplotlib.pyplot as plt
import matplotlib.patches as patches

# Coordinate system in Matplotlib (0 to 42 in X, 0 to 32 in Y)
# Note: In matplotlib, Y=0 is bottom and Y=32 is top, so we invert Y from SVG:
# mpl_y = 32 - (svg_y / 100)
# mpl_x = svg_x / 100

def to_mpl(x, y):
    return x / 100.0, 32.0 - (y / 100.0)

fig, ax = plt.subplots(figsize=(42, 32), dpi=150)
fig.patch.set_facecolor('#FFFFFF')
ax.set_facecolor('#FFFFFF')

# Import data from entities and relationships in generate_clean_academic_chen
from generate_clean_academic_chen import entities, relationships

# 1. Draw Relationship Lines and Cardinality
for ent1, ent2, label, c1, c2, rx, ry in relationships:
    e1 = entities[ent1]
    e2 = entities[ent2]

    x1, y1 = to_mpl(e1["x"], e1["y"])
    x2, y2 = to_mpl(e2["x"], e2["y"])
    mrx, mry = to_mpl(rx, ry)

    # Line Ent1 -> Rel
    ax.plot([x1, mrx], [y1, mry], color='#475569', lw=1.6, zorder=2)
    # Line Rel -> Ent2
    ax.plot([mrx, x2], [mry, y2], color='#475569', lw=1.6, zorder=2)

    # Cardinality badge 1
    bx1 = x1 * 0.45 + mrx * 0.55
    by1 = y1 * 0.45 + mry * 0.55 + 0.15
    ax.text(
        bx1, by1, c1,
        fontsize=10.5, fontweight='bold', color='#0F172A',
        bbox=dict(boxstyle='square,pad=0.2', fc='#FFFFFF', ec='#64748B', lw=1.1),
        ha='center', va='center', zorder=6
    )

    # Cardinality badge 2
    bx2 = mrx * 0.45 + x2 * 0.55
    by2 = mry * 0.45 + y2 * 0.55 + 0.15
    ax.text(
        bx2, by2, c2,
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
        ax.plot([ex, ax_pos], [ey, ay_pos], color='#64748B', lw=1.2, zorder=2)

        # Ellipse
        rx_val = 0.85
        ry_val = 0.32
        ellipse = patches.Ellipse(
            (ax_pos, ay_pos), rx_val * 2, ry_val * 2,
            facecolor='#F8FAFC' if is_pk else '#FFFFFF',
            edgecolor='#0F172A' if is_pk else '#475569',
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
for ent1, ent2, label, c1, c2, rx, ry in relationships:
    mrx, mry = to_mpl(rx, ry)
    rw = 1.7
    rh = 0.74
    pts = [
        [mrx, mry + rh/2],
        [mrx + rw/2, mry],
        [mrx, mry - rh/2],
        [mrx - rw/2, mry]
    ]
    poly = patches.Polygon(pts, closed=True, facecolor='#FFFFFF', edgecolor='#1E293B', lw=1.8, zorder=4)
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
        facecolor='#FFFFFF', edgecolor='#1E293B',
        linewidth=2.0, zorder=4
    )
    ax.add_patch(rect)
    ax.text(
        ex, ey, elabel,
        fontsize=12, fontweight='bold', color='#0F172A',
        ha='center', va='center', zorder=5
    )

# 5. Draw Academic Legend Box at bottom center
leg_x, leg_y = 21.0, 1.5
leg_box = patches.FancyBboxPatch(
    (leg_x - 3.8, leg_y - 0.5), 7.6, 1.0,
    boxstyle="square,pad=0.1",
    facecolor='#FFFFFF', edgecolor='#64748B', lw=1.2, zorder=10
)
ax.add_patch(leg_box)
ax.text(leg_x, leg_y + 0.35, "LEGENDA NOTASI PETER CHEN (STANDAR AKADEMIK)", fontsize=9.5, fontweight='bold', color='#0F172A', ha='center', va='center', zorder=11)

# Entity sample
rect_sample = patches.FancyBboxPatch((leg_x - 3.4, leg_y - 0.25), 0.9, 0.4, boxstyle="square,pad=0.0", facecolor='#FFFFFF', edgecolor='#1E293B', lw=1.4, zorder=11)
ax.add_patch(rect_sample)
ax.text(leg_x - 2.95, leg_y - 0.05, "Entitas", fontsize=8, fontweight='bold', color='#0F172A', ha='center', va='center', zorder=12)
ax.text(leg_x - 2.1, leg_y - 0.05, "= Tabel", fontsize=8, color='#334155', va='center', zorder=12)

# Rel sample
rel_pts = [[leg_x - 1.2, leg_y + 0.15], [leg_x - 0.8, leg_y - 0.05], [leg_x - 1.2, leg_y - 0.25], [leg_x - 1.6, leg_y - 0.05]]
ax.add_patch(patches.Polygon(rel_pts, closed=True, facecolor='#FFFFFF', edgecolor='#1E293B', lw=1.3, zorder=11))
ax.text(leg_x - 1.2, leg_y - 0.05, "relasi", fontsize=7.5, fontweight='bold', color='#0F172A', ha='center', va='center', zorder=12)
ax.text(leg_x - 0.55, leg_y - 0.05, "= Relasi", fontsize=8, color='#334155', va='center', zorder=12)

# Attr sample
ax.add_patch(patches.Ellipse((leg_x + 0.55, leg_y - 0.05), 0.9, 0.35, facecolor='#FFFFFF', edgecolor='#475569', lw=1.1, zorder=11))
ax.text(leg_x + 0.55, leg_y - 0.05, "atribut", fontsize=7.5, color='#0F172A', ha='center', va='center', zorder=12)
ax.text(leg_x + 1.15, leg_y - 0.05, "= Atribut", fontsize=8, color='#334155', va='center', zorder=12)

# PK sample
ax.add_patch(patches.Ellipse((leg_x + 2.2, leg_y - 0.05), 0.95, 0.35, facecolor='#F8FAFC', edgecolor='#0F172A', lw=1.4, zorder=11))
ax.text(leg_x + 2.2, leg_y - 0.05, "id_key", fontsize=7.5, fontweight='bold', color='#0F172A', ha='center', va='center', zorder=12)
ax.plot([leg_x + 1.95, leg_x + 2.45], [leg_y - 0.13, leg_y - 0.13], color='#0F172A', lw=1.2, zorder=13)
ax.text(leg_x + 2.85, leg_y - 0.05, "= Primary Key", fontsize=8, color='#334155', va='center', zorder=12)

ax.set_xlim(0, 42)
ax.set_ylim(0, 32)
ax.axis('off')

plt.tight_layout()

base_dir = r"C:\Perkuliahan\Semester 7\Project SMT 7\SAAS HRIS"
out_png_academic = os.path.join(base_dir, "ERD_Chen_Notation_Academic.png")
out_png_tables = os.path.join(base_dir, "ERD_Chen_Notation_11_Tables.png")

plt.savefig(out_png_academic, dpi=200, bbox_inches='tight', facecolor='#FFFFFF')
plt.savefig(out_png_tables, dpi=200, bbox_inches='tight', facecolor='#FFFFFF')
plt.close()

print(f"Academic PNG generated: {out_png_academic}")
