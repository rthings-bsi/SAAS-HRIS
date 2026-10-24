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

def check_collisions(entities):
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
            # Allow at least 15px margin
            dist_norm = (dx / (rx_sum + 15))**2 + (dy / (ry_sum + 10))**2
            if dist_norm < 1.0:
                overlaps.append((a1, a2))

    line_hits = []
    for a in all_attrs:
        ex, ey = a['ex'], a['ey']
        ax, ay = a['x'], a['y']
        for other in all_attrs:
            if other['name'] == a['name'] and other['entity'] == a['entity']:
                continue
            d = dist_pt_seg(other['x'], other['y'], ex, ey, ax, ay)
            # Check ellipse boundary distance
            # Using conservative rx, ry
            dist_to_other = math.hypot(other['x'] - ex, other['y'] - ey)
            dist_to_a = math.hypot(ax - ex, ay - ey)
            if dist_to_other < dist_to_a - 10:
                # check if within ellipse
                ed = ((other['x'] - (ex + (ax-ex)*dist_to_other/dist_to_a))/other['rx'])**2 + \
                     ((other['y'] - (ey + (ay-ey)*dist_to_other/dist_to_a))/other['ry'])**2
                if d < other['ry'] + 10:
                    line_hits.append((a, other, d))

    return overlaps, line_hits

print("Module loaded")
