import math

def get_pill_radius(name):
    rx = max(78, len(name) * 4.4 + 14)
    ry = 26
    return rx, ry

def dist_pt_seg(px, py, x1, y1, x2, y2):
    dx = x2 - x1
    dy = y2 - y1
    l2 = dx*dx + dy*dy
    if l2 == 0: return math.hypot(px-x1, py-y1)
    t = max(0, min(1, ((px - x1)*dx + (py - y1)*dy) / l2))
    proj_x = x1 + t*dx
    proj_y = y1 + t*dy
    return math.hypot(px - proj_x, py - proj_y)

def evaluate(entities):
    all_attrs = []
    for ename, edata in entities.items():
        ex, ey = edata['x'], edata['y']
        for aname, is_pk, dx, dy in edata['attrs']:
            rx, ry = get_pill_radius(aname)
            all_attrs.append({
                'entity': ename, 'name': aname,
                'x': ex + dx, 'y': ey + dy,
                'rx': rx, 'ry': ry,
                'ex': ex, 'ey': ey
            })

    overlaps = []
    for i in range(len(all_attrs)):
        for j in range(i + 1, len(all_attrs)):
            a1 = all_attrs[i]
            a2 = all_attrs[j]
            dx = abs(a1['x'] - a2['x'])
            dy = abs(a1['y'] - a2['y'])
            rx_sum = a1['rx'] + a2['rx']
            ry_sum = a1['ry'] + a2['ry']
            # Safety margin of 20px in X and 12px in Y
            dist_norm = (dx / (rx_sum + 20))**2 + (dy / (ry_sum + 12))**2
            if dist_norm < 1.0:
                overlaps.append((a1, a2, math.sqrt(dist_norm)))

    line_hits = []
    for a in all_attrs:
        ex, ey = a['ex'], a['ey']
        ax, ay = a['x'], a['y']
        for other in all_attrs:
            if other['name'] == a['name'] and other['entity'] == a['entity']:
                continue
            d = dist_pt_seg(other['x'], other['y'], ex, ey, ax, ay)
            dist_to_other = math.hypot(other['x'] - ex, other['y'] - ey)
            dist_to_a = math.hypot(ax - ex, ay - ey)
            if dist_to_other < dist_to_a - 15:
                # check ellipse clearance with 10px buffer
                norm_d = d / (other['ry'] + 10)
                if norm_d < 1.0:
                    line_hits.append((a, other, d))

    return overlaps, line_hits

new_entities = {
    # 1. SHIFTS (x=550, y=420) - 5 attributes
    "shifts": {
        "x": 550, "y": 420, "w": 200, "h": 76, "label": "shifts",
        "attrs": [
            ("id_shifts", True, -260, -80),
            ("name", False, -200, -180),
            ("start_time", False, -20, -220),
            ("end_time", False, 160, -180),
            ("late_tolerance_minutes", False, -240, 25),
        ]
    },

    # 2. COMPANIES (x=1600, y=420) - 10 attributes
    "companies": {
        "x": 1600, "y": 420, "w": 220, "h": 76, "label": "companies",
        "attrs": [
            ("name", False, -390, -130),
            ("industry", False, -260, -220),
            ("email", False, -95, -280),
            ("phone", False, 95, -280),
            ("address", False, 260, -220),
            ("director_name", False, 390, -130),
            ("id_companies", True, -260, 80),
            ("latitude", False, -160, 160),
            ("longitude", False, 160, 160),
            ("radius_meters", False, 260, 80),
        ]
    },

    # 3. USERS (x=2700, y=420) - 6 attributes
    "users": {
        "x": 2700, "y": 420, "w": 190, "h": 76, "label": "users",
        "attrs": [
            ("id_users", True, -290, -75),
            ("name", False, -220, -170),
            ("email", False, -95, -230),
            ("password", False, 95, -230),
            ("role", False, 220, -170),
            ("is_active", False, 290, -75),
        ]
    },

    # 4. NOTIFICATIONS (x=3750, y=420) - 6 attributes
    "notifications": {
        "x": 3750, "y": 420, "w": 220, "h": 76, "label": "notifications",
        "attrs": [
            ("id_notifications", True, 240, -140),
            ("type", False, 260, -50),
            ("title", False, 260, 45),
            ("message", False, 240, 140),
            ("is_read", False, 120, 210),
            ("read_at", False, -80, 210),
        ]
    },

    # 5. EMPLOYEES (x=1600, y=1200) - 10 attributes
    # 5 on left wing, 5 on right wing -> TOP & BOTTOM are 100% CLEAR for vertical corridors!
    "employees": {
        "x": 1600, "y": 1200, "w": 260, "h": 82, "label": "employees",
        "attrs": [
            ("id_employees", True, -340, -160),
            ("nik", False, -340, -80),
            ("department_name", False, -340, 80),
            ("job_position_name", False, -340, 160),
            ("allowance_fixed", False, -340, 240),

            ("gender", False, 340, -160),
            ("hire_date", False, 340, -80),
            ("employment_status", False, 340, 80),
            ("basic_salary", False, 340, 160),
            ("annual_leave_quota", False, 340, 240),
        ]
    },

    # 6. ATTENDANCES (x=550, y=1200) - 8 attributes
    "attendances": {
        "x": 550, "y": 1200, "w": 220, "h": 76, "label": "attendances",
        "attrs": [
            ("id_attendances", True, -260, -85),
            ("date", False, -280, 0),
            ("clock_in_time", False, -260, 85),
            ("clock_out_time", False, -190, 165),
            ("clock_in_photo_path", False, -50, 225),
            ("status", False, 170, 175),
            ("late_duration_minutes", False, -240, -170),
            ("clock_in_distance_meters", False, 0, -210),
        ]
    },

    # 7. PAYROLL_SLIPS (x=550, y=1950) - 8 attributes
    "payroll_slips": {
        "x": 550, "y": 1950, "w": 230, "h": 76, "label": "payroll_slips",
        "attrs": [
            ("id_payroll_slips", True, -260, -75),
            ("period_name", False, -280, 5),
            ("start_date", False, -260, 85),
            ("end_date", False, -190, 165),
            ("basic_salary", False, -50, 225),
            ("net_salary", False, 170, 175),
            ("pdf_path", False, -240, -165),
            ("status", False, -20, -195),
        ]
    },

    # 8. LEAVE_REQUESTS (x=2650, y=1200) - 8 attributes
    "leave_requests": {
        "x": 2650, "y": 1200, "w": 240, "h": 76, "label": "leave_requests",
        "attrs": [
            ("id_leave_requests", True, 260, -85),
            ("leave_type", False, 280, 0),
            ("is_paid", False, 260, 85),
            ("start_date", False, 190, 165),
            ("end_date", False, 50, 225),
            ("total_days", False, -170, 175),
            ("reason", False, 240, -170),
            ("status", False, 0, -210),
        ]
    },

    # 9. OVERTIME_REQUESTS (x=2650, y=1950) - 7 attributes
    "overtime_requests": {
        "x": 2650, "y": 1950, "w": 250, "h": 76, "label": "overtime_requests",
        "attrs": [
            ("id_overtime_requests", True, 260, -75),
            ("date", False, 280, 5),
            ("start_time", False, 260, 85),
            ("end_time", False, 190, 165),
            ("duration_hours", False, 50, 225),
            ("reason", False, -170, 175),
            ("status", False, 230, -175),
        ]
    },

    # 10. PERFORMANCE_PERIODS (x=1050, y=2650) - 6 attributes
    "performance_periods": {
        "x": 1050, "y": 2650, "w": 270, "h": 76, "label": "performance_periods",
        "attrs": [
            ("id_performance_periods", True, -310, 80),
            ("name", False, -220, 170),
            ("start_date", False, -95, 235),
            ("end_date", False, 95, 235),
            ("status", False, 220, 170),
            ("criteria_config", False, 310, 80),
        ]
    },

    # 11. PERFORMANCE_EVALUATIONS (x=2250, y=2650) - 6 attributes
    "performance_evaluations": {
        "x": 2250, "y": 2650, "w": 290, "h": 76, "label": "performance_evaluations",
        "attrs": [
            ("id_performance_evaluations", True, -340, 85),
            ("final_score", False, -230, 175),
            ("rank", False, -95, 235),
            ("grade", False, 95, 235),
            ("recommendation", False, 230, 175),
            ("scores_breakdown", False, 340, 85),
        ]
    },
}

overlaps, line_hits = evaluate(new_entities)
print(f"Results with new layout:")
print(f"  Overlaps: {len(overlaps)}")
for a1, a2, score in overlaps:
    print(f"    Overlap: {a1['entity']}.{a1['name']} & {a2['entity']}.{a2['name']} (score={score:.2f}, dx={abs(a1['x']-a2['x'])}, dy={abs(a1['y']-a2['y'])})")
print(f"  Line Hits: {len(line_hits)}")
for a, other, d in line_hits:
    print(f"    Line Hit: Line to {a['entity']}.{a['name']} passes through {other['entity']}.{other['name']} (dist={d:.1f})")
