import os
import math
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, Polygon

# Create high-resolution figure
fig, ax = plt.subplots(figsize=(42, 30), dpi=150)
ax.set_facecolor('#F8FAFC')
fig.patch.set_facecolor('#F8FAFC')

# Color palette matching screenshot 24.png
ENTITY_COLOR = '#4A85F6'       # Vivid clean blue
RELATION_COLOR = '#23272E'     # Dark charcoal
ATTR_COLOR = '#72E5A0'         # Mint green
ATTR_PK_COLOR = '#4ADE80'      # Bright mint green for PK
LINE_COLOR = '#94A3B8'         # Neutral silver gray
TEXT_DARK = '#0F172A'
TEXT_LIGHT = '#FFFFFF'

# Structure of 11 Entities with their attributes
# Each attribute: (name, is_pk)
entities_data = {
    'Company': {
        'pos': (21, 26),
        'attrs': [
            ('id_companies', True),
            ('name', False),
            ('industry', False),
            ('email', False),
            ('phone', False),
            ('latitude', False),
            ('longitude', False),
            ('radius_meters', False),
            ('director_name', False),
        ]
    },
    'Shift': {
        'pos': (7, 26),
        'attrs': [
            ('id_shifts', True),
            ('name', False),
            ('start_time', False),
            ('end_time', False),
            ('late_tolerance', False),
        ]
    },
    'User': {
        'pos': (35, 26),
        'attrs': [
            ('id_users', True),
            ('email', False),
            ('password', False),
            ('name', False),
            ('role', False),
            ('is_active', False),
        ]
    },
    'Employee': {
        'pos': (21, 18),
        'attrs': [
            ('id_employees', True),
            ('nik', False),
            ('department_name', False),
            ('job_position_name', False),
            ('gender', False),
            ('hire_date', False),
            ('basic_salary', False),
            ('allowance_fixed', False),
            ('annual_leave_quota', False),
        ]
    },
    'Notification': {
        'pos': (37, 18),
        'attrs': [
            ('id_notifications', True),
            ('type', False),
            ('title', False),
            ('message', False),
            ('is_read', False),
            ('read_at', False),
        ]
    },
    'Attendance': {
        'pos': (5, 10),
        'attrs': [
            ('id_attendances', True),
            ('date', False),
            ('clock_in_time', False),
            ('clock_out_time', False),
            ('clock_in_photo', False),
            ('status', False),
            ('late_duration', False),
            ('distance_meters', False),
        ]
    },
    'Leave_Request': {
        'pos': (15, 10),
        'attrs': [
            ('id_leave_requests', True),
            ('leave_type', False),
            ('start_date', False),
            ('end_date', False),
            ('total_days', False),
            ('reason', False),
            ('status', False),
        ]
    },
    'Overtime_Request': {
        'pos': (27, 10),
        'attrs': [
            ('id_overtime_requests', True),
            ('date', False),
            ('start_time', False),
            ('end_time', False),
            ('duration_hours', False),
            ('reason', False),
            ('status', False),
        ]
    },
    'Payroll_Slip': {
        'pos': (37, 10),
        'attrs': [
            ('id_payroll_slips', True),
            ('period_name', False),
            ('start_date', False),
            ('end_date', False),
            ('basic_salary', False),
            ('net_salary', False),
            ('pdf_path', False),
            ('status', False),
        ]
    },
    'Performance_Period': {
        'pos': (11, 2),
        'attrs': [
            ('id_perf_periods', True),
            ('name', False),
            ('start_date', False),
            ('end_date', False),
            ('status', False),
            ('criteria_config', False),
        ]
    },
    'Performance_Evaluation': {
        'pos': (27, 2),
        'attrs': [
            ('id_perf_eval', True),
            ('final_score', False),
            ('rank', False),
            ('grade', False),
            ('recommendation', False),
            ('scores_breakdown', False),
        ]
    },
}

# Relationships: (Ent1, Ent2, Name, Card1, Card2, Pos)
relationships = [
    # Top relationships
    ('Company', 'Shift', 'Menetapkan', '1', 'N', (14, 26)),
    ('Company', 'User', 'Memiliki', '1', 'N', (28, 26)),
    ('Company', 'Employee', 'Mempekerjakan', '1', 'N', (21, 22)),
    ('Shift', 'Employee', 'Jadwal', '1', 'N', (13, 21.5)),
    ('User', 'Employee', 'Akun Profil', '1', '1', (29, 21.5)),
    ('User', 'Notification', 'Menerima', '1', 'N', (36.2, 22)),

    # Mid-layer transactions
    ('Employee', 'Attendance', 'Mencatat', '1', 'N', (11, 14.5)),
    ('Employee', 'Leave_Request', 'Mengajukan', '1', 'N', (17.5, 14.5)),
    ('Employee', 'Overtime_Request', 'Mengajukan', '1', 'N', (24.5, 14.5)),
    ('Employee', 'Payroll_Slip', 'Menerima', '1', 'N', (30.5, 14.5)),

    # Bottom evaluations
    ('Performance_Period', 'Performance_Evaluation', 'Menaungi', '1', 'N', (19, 2)),
    ('Employee', 'Performance_Evaluation', 'Dievaluasi', '1', 'N', (24.5, 6)),
]

# Helper to draw an entity (Blue Rectangle)
def draw_entity(ax, x, y, name, w=3.4, h=1.4):
    rect = patches.FancyBboxPatch(
        (x - w/2, y - h/2), w, h,
        boxstyle="round,pad=0.1,rounding_size=0.15",
        ec="#2563EB", fc=ENTITY_COLOR, lw=2.5, zorder=4
    )
    ax.add_patch(rect)
    ax.text(
        x, y, name.replace('_', ' '),
        color=TEXT_LIGHT, fontsize=13, fontweight='bold',
        ha='center', va='center', zorder=5, fontfamily='sans-serif'
    )

# Helper to draw a relationship (Dark Rhombus)
def draw_relationship(ax, x, y, name, w=2.8, h=1.4):
    pts = [
        [x, y + h/2],
        [x + w/2, y],
        [x, y - h/2],
        [x - w/2, y]
    ]
    poly = patches.Polygon(pts, closed=True, ec="#0F172A", fc=RELATION_COLOR, lw=2.5, zorder=4)
    ax.add_patch(poly)
    ax.text(
        x, y, name,
        color=TEXT_LIGHT, fontsize=10.5, fontweight='bold',
        ha='center', va='center', zorder=5, fontfamily='sans-serif'
    )

# Helper to draw an attribute (Mint Green Ellipse)
def draw_attribute(ax, x, y, name, is_pk=False, rx=1.35, ry=0.55):
    ellipse = patches.Ellipse(
        (x, y), rx*2, ry*2,
        ec="#10B981" if is_pk else "#34D399",
        fc=ATTR_PK_COLOR if is_pk else ATTR_COLOR,
        lw=2.2 if is_pk else 1.8, zorder=4
    )
    ax.add_patch(ellipse)

    # Text
    txt = ax.text(
        x, y, name,
        color=TEXT_DARK, fontsize=8.5, fontweight='bold' if is_pk else 'normal',
        ha='center', va='center', zorder=5, fontfamily='sans-serif'
    )
    if is_pk:
        # Underline primary key
        txt.set_path_effects([]) # Standard matplotlib underline via text
        ax.plot([x - rx*0.65, x + rx*0.65], [y - 0.22, y - 0.22], color=TEXT_DARK, lw=1.5, zorder=6)

# Draw Relationship lines & diamonds
for ent1_name, ent2_name, rel_name, c1, c2, rpos in relationships:
    e1 = entities_data[ent1_name]['pos']
    e2 = entities_data[ent2_name]['pos']
    rx, ry = rpos

    # Line from E1 to Rel
    ax.plot([e1[0], rx], [e1[1], ry], color=LINE_COLOR, lw=2.2, zorder=2)
    # Line from Rel to E2
    ax.plot([rx, e2[0]], [ry, e2[1]], color=LINE_COLOR, lw=2.2, zorder=2)

    # Draw Cardinality Labels
    # Near E1
    mid1_x = e1[0]*0.4 + rx*0.6
    mid1_y = e1[1]*0.4 + ry*0.6
    ax.text(
        mid1_x + (0.3 if rx >= e1[0] else -0.3),
        mid1_y + 0.3,
        c1, fontsize=11, fontweight='bold', color='#1E293B',
        bbox=dict(boxstyle="circle,pad=0.2", fc="#E2E8F0", ec="#CBD5E1", lw=1),
        ha='center', va='center', zorder=6
    )

    # Near E2
    mid2_x = rx*0.4 + e2[0]*0.6
    mid2_y = ry*0.4 + e2[1]*0.6
    ax.text(
        mid2_x + (0.3 if e2[0] >= rx else -0.3),
        mid2_y + 0.3,
        c2, fontsize=11, fontweight='bold', color='#1E293B',
        bbox=dict(boxstyle="circle,pad=0.2", fc="#E2E8F0", ec="#CBD5E1", lw=1),
        ha='center', va='center', zorder=6
    )

    # Draw Rhombus
    draw_relationship(ax, rx, ry, rel_name)

# Draw Entities and their Attributes
for ent_name, data in entities_data.items():
    ex, ey = data['pos']
    attrs = data['attrs']
    n_attrs = len(attrs)

    # Calculate attribute positions around entity
    # We position them fan-shaped based on entity location to prevent overlapping
    angles = []

    if ey >= 24: # Top row entities (Company, Shift, User)
        # Fan upward
        start_angle = math.pi * 0.1
        end_angle = math.pi * 0.9
        dist = 2.8
    elif ey <= 4: # Bottom row entities (Performance)
        # Fan downward
        start_angle = -math.pi * 0.9
        end_angle = -math.pi * 0.1
        dist = 2.7
    elif ex <= 8: # Left edge (Attendance)
        # Fan outward left & top
        start_angle = math.pi * 0.4
        end_angle = math.pi * 1.3
        dist = 2.7
    elif ex >= 34: # Right edge (Payroll, Notification)
        # Fan outward right
        start_angle = -math.pi * 0.35
        end_angle = math.pi * 0.55
        dist = 2.8
    else: # Middle rows
        # Distribute horizontally/vertically where free
        start_angle = -math.pi * 0.75
        end_angle = math.pi * 0.75
        dist = 2.7

    for i, (attr_name, is_pk) in enumerate(attrs):
        if n_attrs == 1:
            angle = (start_angle + end_angle) / 2
        else:
            angle = start_angle + (end_angle - start_angle) * (i / (n_attrs - 1))

        # Add slight alternating radial distance to prevent ellipse overlapping
        r = dist + (0.6 if i % 2 == 1 else 0.0)
        ax_pos = ex + r * math.cos(angle) * 1.5
        ay_pos = ey + r * math.sin(angle) * 1.2

        # Line from entity to attribute
        ax.plot([ex, ax_pos], [ey, ay_pos], color=LINE_COLOR, lw=1.8, zorder=2)

        # Draw Attribute
        draw_attribute(ax, ax_pos, ay_pos, attr_name, is_pk=is_pk)

    # Draw Entity
    draw_entity(ax, ex, ey, ent_name)

# Title and Legend Header
ax.text(
    21, 29.2, "ENTITY RELATIONSHIP DIAGRAM (CHEN'S NOTATION) - 11 TABLES",
    fontsize=22, fontweight='heavy', color='#0B2545',
    ha='center', va='center', fontfamily='sans-serif'
)
ax.text(
    21, 28.5, "Sistem Informasi Manajemen SDM & Penilaian Kinerja Karyawan (Metode SPK SMART) - PT SPINDO",
    fontsize=13, fontweight='medium', color='#64748B',
    ha='center', va='center', fontfamily='sans-serif'
)

# Visual Legend Box at bottom right
leg_x, leg_y = 36.5, 3.2
leg_box = patches.FancyBboxPatch(
    (leg_x - 3.8, leg_y - 2.0), 7.6, 3.8,
    boxstyle="round,pad=0.2,rounding_size=0.2",
    ec="#CBD5E1", fc="#FFFFFF", lw=2, zorder=10
)
ax.add_patch(leg_box)
ax.text(leg_x, leg_y + 1.2, "LEGENDA NOTASI CHEN", fontsize=11, fontweight='bold', color='#0F172A', ha='center', va='center', zorder=11)

# Entity sample
draw_entity(ax, leg_x - 2.2, leg_y + 0.4, "Entity", w=1.8, h=0.7)
ax.text(leg_x - 0.7, leg_y + 0.4, "= Entitas (Tabel)", fontsize=9, color='#334155', va='center', zorder=11)

# Attribute sample
draw_attribute(ax, leg_x - 2.2, leg_y - 0.4, "Attribute", rx=0.9, ry=0.35)
ax.text(leg_x - 0.7, leg_y - 0.4, "= Atribut (Kolom)", fontsize=9, color='#334155', va='center', zorder=11)

# PK sample
draw_attribute(ax, leg_x - 2.2, leg_y - 1.1, "Primary_Key", is_pk=True, rx=0.95, ry=0.35)
ax.text(leg_x - 0.7, leg_y - 1.1, "= Primary Key (Garis Bawah)", fontsize=9, color='#334155', va='center', zorder=11)

# Relation sample
draw_relationship(ax, leg_x - 2.2, leg_y - 1.8, "Rel", w=1.6, h=0.6)
ax.text(leg_x - 0.7, leg_y - 1.8, "= Relasi (Hubungan Antar Tabel)", fontsize=9, color='#334155', va='center', zorder=11)

ax.set_xlim(0, 42)
ax.set_ylim(0, 30)
ax.axis('off')

# Save PNG and SVG
out_png = os.path.join(os.path.dirname(__file__), 'ERD_Chen_Notation_11_Tables.png')
out_svg = os.path.join(os.path.dirname(__file__), 'ERD_Chen_Notation_11_Tables.svg')

plt.tight_layout()
plt.savefig(out_png, dpi=200, bbox_inches='tight', facecolor='#F8FAFC')
plt.savefig(out_svg, format='svg', bbox_inches='tight', facecolor='#F8FAFC')
plt.close()

print(f"ERD Image generated: {out_png}")
print(f"ERD SVG generated: {out_svg}")
