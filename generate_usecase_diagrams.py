import os
import math
import matplotlib.pyplot as plt
import matplotlib.patches as patches

# Helper to wrap text into two or three lines
def format_lines(text, max_chars_per_line=18):
    words = text.split()
    lines = []
    curr = []
    curr_len = 0
    for w in words:
        if curr_len + len(w) + (1 if curr else 0) <= max_chars_per_line:
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

# Diagrams definitions matching Image 28 template
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
            "Mengelola penggajian & slip gaji",
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

print("Diagram definitions loaded successfully.")
