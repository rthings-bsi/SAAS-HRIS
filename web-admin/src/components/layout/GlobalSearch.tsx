"use client";

import React, { useState, useEffect, useRef, useMemo, useCallback } from "react";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import {
  Search,
  X,
  LayoutDashboard,
  Users,
  CalendarCheck,
  Clock,
  CalendarRange,
  Timer,
  Banknote,
  Award,
  Building2,
  Briefcase,
  ShieldCheck,
  Building,
  UserPlus,
  CornerDownLeft,
  ArrowRight,
  SearchX,
  Loader2,
  CheckCircle2,
  Zap,
} from "lucide-react";
import { apiClient } from "@/lib/axios";
import type { ApiResponse, Employee, User, Company } from "@/types";

export type AllowedRole = "superadmin" | "super_admin" | "owner" | "hr" | "manager" | "employee";

const ALL_ROLES: AllowedRole[] = ["superadmin", "super_admin", "owner", "hr", "manager", "employee"];
const ADMIN_HR_MANAGER: AllowedRole[] = ["superadmin", "super_admin", "owner", "hr", "manager"];
const ADMIN_HR_ONLY: AllowedRole[] = ["superadmin", "super_admin", "owner", "hr"];
const EMPLOYEE_ONLY: AllowedRole[] = ["employee"];

export interface MenuItem {
  id: string;
  title: string;
  category: "menu" | "action";
  description: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
  keywords: string[];
  badge?: string;
  badgeColor?: string;
  allowedRoles: AllowedRole[];
}

const SYSTEM_MENU_ITEMS: MenuItem[] = [
  {
    id: "dashboard",
    title: "Dashboard Utama",
    category: "menu",
    description: "Ringkasan metrik operasional, absensi hari ini, dan grafik kinerja",
    href: "/dashboard",
    icon: LayoutDashboard,
    keywords: ["beranda", "home", "ringkasan", "statistik", "overview", "metrik"],
    badge: "Utama",
    badgeColor: "bg-slate-100 text-slate-700 border-slate-200",
    allowedRoles: ALL_ROLES,
  },
  {
    id: "employees",
    title: "Data Karyawan",
    category: "menu",
    description: "Kelola profil staf, kontrak kerja, gaji pokok, dan biodata",
    href: "/employees",
    icon: Users,
    keywords: ["pegawai", "staf", "staff", "pekerja", "tenaga kerja", "nik", "biodata"],
    badge: "Master",
    badgeColor: "bg-blue-50 text-blue-700 border-blue-200",
    allowedRoles: ADMIN_HR_MANAGER,
  },
  {
    id: "attendance",
    title: "Presensi & Absensi",
    category: "menu",
    description: "Rekap kehadiran harian, jam masuk/pulang, radius geofence, dan swafoto",
    href: "/attendance",
    icon: CalendarCheck,
    keywords: ["absen", "hadir", "kehadiran", "clock in", "clock out", "geofence", "gps", "terlambat"],
    badge: "Operasional",
    badgeColor: "bg-emerald-50 text-emerald-700 border-emerald-200",
    allowedRoles: ALL_ROLES,
  },
  {
    id: "shifts",
    title: "Jadwal & Shift Kerja",
    category: "menu",
    description: "Pengaturan shift harian, toleransi keterlambatan, dan rotasi kerja",
    href: "/shifts",
    icon: Clock,
    keywords: ["jam kerja", "rotasi", "pagi", "siang", "malam", "jadwal", "shift"],
    allowedRoles: ADMIN_HR_MANAGER,
  },
  {
    id: "leaves",
    title: "Pengajuan Cuti & Izin",
    category: "menu",
    description: "Kelola permohonan cuti tahunan, sakit, sisa kuota, dan verifikasi atasan",
    href: "/leaves",
    icon: CalendarRange,
    keywords: ["izin", "sakit", "cuti tahunan", "permohonan cuti", "kuota cuti", "approval"],
    badge: "Persetujuan",
    badgeColor: "bg-amber-50 text-amber-700 border-amber-200",
    allowedRoles: ALL_ROLES,
  },
  {
    id: "overtime",
    title: "Pengajuan Lembur",
    category: "menu",
    description: "Pengajuan jam lembur kerja, kalkulasi durasi, kompensasi, dan verifikasi",
    href: "/overtime",
    icon: Timer,
    keywords: ["overtime", "jam lembur", "lembur kerja", "kompensasi lembur", "tugas tambahan"],
    badge: "Persetujuan",
    badgeColor: "bg-amber-50 text-amber-700 border-amber-200",
    allowedRoles: ALL_ROLES,
  },
  {
    id: "payroll-admin",
    title: "Penggajian (Payroll)",
    category: "menu",
    description: "Perhitungan gaji bulanan, rincian tunjangan, potongan, dan cetak slip",
    href: "/payroll",
    icon: Banknote,
    keywords: ["gaji", "payroll", "slip gaji", "tunjangan", "potongan", "take home pay", "upah"],
    badge: "Keuangan",
    badgeColor: "bg-indigo-50 text-indigo-700 border-indigo-200",
    allowedRoles: ADMIN_HR_MANAGER,
  },
  {
    id: "payroll-employee",
    title: "Slip Gaji Saya",
    category: "menu",
    description: "Lihat dan unduh slip gaji bulanan serta rincian take-home pay Anda",
    href: "/payroll",
    icon: Banknote,
    keywords: ["slip gaji", "gaji saya", "upah", "penghasilan", "take home pay", "tunjangan"],
    badge: "Layanan Mandiri",
    badgeColor: "bg-emerald-50 text-emerald-700 border-emerald-200",
    allowedRoles: EMPLOYEE_ONLY,
  },
  {
    id: "performance",
    title: "Penilaian Kinerja SMART",
    category: "menu",
    description: "Sistem pendukung keputusan evaluasi kinerja berbasis Simple Multi-Attribute Rating",
    href: "/performance",
    icon: Award,
    keywords: ["kinerja", "kpi", "smart", "evaluasi", "ranking", "penilaian", "rapor", "bobot"],
    badge: "Evaluasi",
    badgeColor: "bg-purple-50 text-purple-700 border-purple-200",
    allowedRoles: ALL_ROLES,
  },
  {
    id: "branches",
    title: "Struktur Cabang Kantor",
    category: "menu",
    description: "Titik lokasi kantor, koordinat GPS, dan radius validasi presensi",
    href: "/branches",
    icon: Building2,
    keywords: ["kantor cabang", "lokasi", "geofencing", "radius kantor", "koordinat", "peta"],
    allowedRoles: ADMIN_HR_MANAGER,
  },
  {
    id: "departments",
    title: "Departemen & Divisi",
    category: "menu",
    description: "Daftar unit divisi dan struktur departemen organisasi perusahaan",
    href: "/departments",
    icon: Briefcase,
    keywords: ["divisi", "bagian", "unit kerja", "organisasi", "departemen"],
    allowedRoles: ADMIN_HR_MANAGER,
  },
  {
    id: "job-positions",
    title: "Master Jabatan",
    category: "menu",
    description: "Daftar level posisi kerja dan jenjang karier karyawan",
    href: "/job-positions",
    icon: Award,
    keywords: ["posisi", "jabatan", "pangkat", "level", "jenjang karir"],
    allowedRoles: ADMIN_HR_MANAGER,
  },
  {
    id: "roles",
    title: "Konfigurasi Hak Akses & Role",
    category: "menu",
    description: "Pengaturan wewenang pengguna dan konfigurasi matriks peran",
    href: "/roles",
    icon: ShieldCheck,
    keywords: ["hak akses", "permission", "super admin", "hr", "manager", "peran", "role", "otoritas"],
    badge: "Sistem",
    badgeColor: "bg-rose-50 text-rose-700 border-rose-200",
    allowedRoles: ADMIN_HR_ONLY,
  },
  {
    id: "company-profile",
    title: "Profil Perusahaan",
    category: "menu",
    description: "Informasi identitas entitas PT SPINDO, kontak, dan logo",
    href: "/company-profile",
    icon: Building,
    keywords: ["entitas", "spindo", "pt spindo", "logo", "alamat kantor", "profil kantor"],
    allowedRoles: ADMIN_HR_ONLY,
  },
];

const QUICK_ACTIONS: MenuItem[] = [
  // 1. Admin & HR Actions
  {
    id: "action-add-employee",
    title: "Tambah Karyawan Baru",
    category: "action",
    description: "Daftarkan profil pegawai baru ke dalam sistem HR",
    href: "/employees?action=add",
    icon: UserPlus,
    keywords: ["tambah pegawai", "buat karyawan", "tambah staf", "registrasi pegawai"],
    allowedRoles: ADMIN_HR_ONLY,
  },
  {
    id: "action-verify-leave",
    title: "Verifikasi Pengajuan Cuti",
    category: "action",
    description: "Tinjau dan tindak lanjuti permohonan izin cuti staf",
    href: "/leaves",
    icon: CalendarRange,
    keywords: ["verifikasi cuti", "persetujuan cuti", "approval cuti", "tinjau izin"],
    allowedRoles: ADMIN_HR_MANAGER,
  },
  {
    id: "action-verify-overtime",
    title: "Verifikasi Pengajuan Lembur",
    category: "action",
    description: "Tinjau dan setujui permohonan lembur kerja karyawan",
    href: "/overtime",
    icon: Timer,
    keywords: ["verifikasi lembur", "persetujuan lembur", "approval overtime"],
    allowedRoles: ADMIN_HR_MANAGER,
  },
  {
    id: "action-view-payroll",
    title: "Rekap Penggajian (Payroll)",
    category: "action",
    description: "Buka ringkasan kalkulasi gaji bulanan dan slip upah staf",
    href: "/payroll",
    icon: Banknote,
    keywords: ["buka gaji", "cek payroll", "rekap gaji", "proses payroll"],
    allowedRoles: ADMIN_HR_MANAGER,
  },

  // 2. Employee Self-Service Actions
  {
    id: "action-emp-attendance",
    title: "Presensi Hari Ini",
    category: "action",
    description: "Catat kehadiran jam masuk atau jam pulang kerja harian Anda",
    href: "/attendance",
    icon: CalendarCheck,
    keywords: ["clock in", "clock out", "absen sekarang", "presensi masuk", "presensi pulang"],
    allowedRoles: EMPLOYEE_ONLY,
  },
  {
    id: "action-emp-leave",
    title: "Ajukan Cuti / Izin",
    category: "action",
    description: "Buka formulir pengajuan cuti tahunan atau izin sakit",
    href: "/leaves",
    icon: CalendarRange,
    keywords: ["ajukan cuti", "izin sakit", "permohonan cuti", "form cuti"],
    allowedRoles: EMPLOYEE_ONLY,
  },
  {
    id: "action-emp-overtime",
    title: "Ajukan Jam Lembur",
    category: "action",
    description: "Buka formulir pengajuan jam kerja lembur tambahan",
    href: "/overtime",
    icon: Timer,
    keywords: ["ajukan lembur", "tambah lembur", "form lembur"],
    allowedRoles: EMPLOYEE_ONLY,
  },
  {
    id: "action-emp-payroll",
    title: "Lihat Slip Gaji Saya",
    category: "action",
    description: "Periksa rincian penerimaan upah dan slip gaji Anda",
    href: "/payroll",
    icon: Banknote,
    keywords: ["cek gaji", "slip gaji", "gaji saya", "upah", "take home pay"],
    allowedRoles: EMPLOYEE_ONLY,
  },
];

interface GlobalSearchProps {
  isMobileOpen?: boolean;
  onCloseMobile?: () => void;
  currentUser?: (User & { company?: Company }) | null;
}

const normalizeRole = (role?: string): AllowedRole => {
  if (!role) return "employee";
  const r = role.toLowerCase().trim();
  if (r === "superadmin" || r === "super_admin") return "superadmin";
  if (r === "owner") return "owner";
  if (r === "hr") return "hr";
  if (r === "manager") return "manager";
  return "employee";
};

export function GlobalSearch({ isMobileOpen = false, onCloseMobile, currentUser }: GlobalSearchProps) {
  const router = useRouter();
  const [query, setQuery] = useState("");
  const [isOpen, setIsOpen] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(0);

  const containerRef = useRef<HTMLDivElement>(null);
  const desktopInputRef = useRef<HTMLInputElement>(null);
  const mobileInputRef = useRef<HTMLInputElement>(null);
  const resultsListRef = useRef<HTMLDivElement>(null);

  // User State & Role Detection
  const [internalUser, setInternalUser] = useState<(User & { company?: Company }) | null>(currentUser || null);

  useEffect(() => {
    if (currentUser) {
      setInternalUser(currentUser);
    } else if (typeof window !== "undefined") {
      const stored = localStorage.getItem("hris_user");
      if (stored) {
        try {
          setInternalUser(JSON.parse(stored) as User & { company?: Company });
        } catch {
          setInternalUser(null);
        }
      }
    }
  }, [currentUser]);

  const activeRole: AllowedRole = useMemo(() => {
    return normalizeRole(internalUser?.role);
  }, [internalUser?.role]);

  // Regular employees cannot search other employees' records
  const canSearchEmployees = useMemo(() => {
    return ["superadmin", "super_admin", "owner", "hr", "manager"].includes(activeRole);
  }, [activeRole]);

  // Fetch employees list with caching (Only enabled for authorized administrative roles)
  const { data: employees = [], isLoading: isLoadingEmployees } = useQuery({
    queryKey: ["employees-global-search"],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<Employee[]>>("/employees");
      if (res.data?.success && Array.isArray(res.data.data)) {
        return res.data.data;
      }
      return [];
    },
    enabled: canSearchEmployees,
    staleTime: 60 * 1000,
  });

  // Global Keyboard Shortcut: ⌘K or Ctrl+K to open/focus search
  useEffect(() => {
    const handleGlobalKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setIsOpen(true);
        setTimeout(() => {
          desktopInputRef.current?.focus();
          desktopInputRef.current?.select();
        }, 10);
      }
      if (e.key === "Escape") {
        setIsOpen(false);
        if (onCloseMobile) onCloseMobile();
      }
    };

    window.addEventListener("keydown", handleGlobalKeyDown);
    return () => window.removeEventListener("keydown", handleGlobalKeyDown);
  }, [onCloseMobile]);

  // Click outside listener for desktop popover
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };

    if (isOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [isOpen]);

  // Focus mobile input & lock body scroll when mobile modal opens
  useEffect(() => {
    if (isMobileOpen) {
      const originalOverflow = document.body.style.overflow;
      document.body.style.overflow = "hidden";
      setTimeout(() => {
        mobileInputRef.current?.focus();
      }, 50);
      return () => {
        document.body.style.overflow = originalOverflow;
      };
    }
  }, [isMobileOpen]);

  // Normalize search tokens
  const normalizedQuery = useMemo(() => query.trim().toLowerCase(), [query]);

  // Filtered Menu Items strictly based on User Role permissions
  const filteredMenus = useMemo(() => {
    const roleAllowedMenus = SYSTEM_MENU_ITEMS.filter((item) =>
      item.allowedRoles.includes(activeRole)
    );

    if (!normalizedQuery) return roleAllowedMenus;

    return roleAllowedMenus.filter((item) => {
      const matchTitle = item.title.toLowerCase().includes(normalizedQuery);
      const matchDesc = item.description.toLowerCase().includes(normalizedQuery);
      const matchKeywords = item.keywords.some((kw) => kw.toLowerCase().includes(normalizedQuery));
      return matchTitle || matchDesc || matchKeywords;
    });
  }, [activeRole, normalizedQuery]);

  // Filtered Quick Actions strictly based on User Role permissions
  const filteredActions = useMemo(() => {
    const roleAllowedActions = QUICK_ACTIONS.filter((action) =>
      action.allowedRoles.includes(activeRole)
    );

    if (!normalizedQuery) return roleAllowedActions;

    return roleAllowedActions.filter((action) => {
      const matchTitle = action.title.toLowerCase().includes(normalizedQuery);
      const matchDesc = action.description.toLowerCase().includes(normalizedQuery);
      const matchKeywords = action.keywords.some((kw) => kw.toLowerCase().includes(normalizedQuery));
      return matchTitle || matchDesc || matchKeywords;
    });
  }, [activeRole, normalizedQuery]);

  // Filtered Employees (Strictly gated: non-employees only)
  const filteredEmployees = useMemo(() => {
    if (!canSearchEmployees || !normalizedQuery) return [];
    return employees
      .filter((emp) => {
        const name = (emp.user?.name || emp.name || "").toLowerCase();
        const nik = (emp.nik || "").toLowerCase();
        const email = (emp.user?.email || "").toLowerCase();
        const phone = (emp.phone || "").toLowerCase();
        const dept = (emp.department?.name || emp.department_name || "").toLowerCase();
        const pos = (emp.job_position?.name || emp.job_position_name || "").toLowerCase();

        return (
          name.includes(normalizedQuery) ||
          nik.includes(normalizedQuery) ||
          email.includes(normalizedQuery) ||
          phone.includes(normalizedQuery) ||
          dept.includes(normalizedQuery) ||
          pos.includes(normalizedQuery)
        );
      })
      .slice(0, 5); // Limit to top 5 results for clean display
  }, [canSearchEmployees, employees, normalizedQuery]);

  // Flattened list for keyboard arrow navigation
  const allSelectableItems = useMemo(() => {
    const list: Array<
      | { type: "action"; item: MenuItem }
      | { type: "menu"; item: MenuItem }
      | { type: "employee"; item: Employee }
    > = [];

    // If query is empty: show actions then all authorized menus
    if (!normalizedQuery) {
      filteredActions.forEach((item) => list.push({ type: "action", item }));
      filteredMenus.forEach((item) => list.push({ type: "menu", item }));
    } else {
      // If typing: show matching employees first (for authorized roles), then menus, then actions
      filteredEmployees.forEach((emp) => list.push({ type: "employee", item: emp }));
      filteredMenus.forEach((item) => list.push({ type: "menu", item }));
      filteredActions.forEach((item) => list.push({ type: "action", item }));
    }

    return list;
  }, [normalizedQuery, filteredActions, filteredMenus, filteredEmployees]);

  // Reset selected index when results change
  useEffect(() => {
    setSelectedIndex(0);
  }, [query]);

  // Execute selection
  const handleSelect = useCallback(
    (index: number) => {
      const selected = allSelectableItems[index];
      if (!selected) return;

      setIsOpen(false);
      if (onCloseMobile) onCloseMobile();
      setQuery("");

      if (selected.type === "action" || selected.type === "menu") {
        router.push(selected.item.href);
      } else if (selected.type === "employee") {
        const emp = selected.item;
        const targetSearch = emp.nik || emp.user?.name || "";
        router.push(`/employees?search=${encodeURIComponent(targetSearch)}`);
      }
    },
    [allSelectableItems, onCloseMobile, router]
  );

  // Keyboard navigation handler
  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (allSelectableItems.length === 0) return;

    if (e.key === "ArrowDown") {
      e.preventDefault();
      setSelectedIndex((prev) => (prev + 1) % allSelectableItems.length);
      setTimeout(() => {
        const activeEl = resultsListRef.current?.querySelector('[data-active="true"]');
        activeEl?.scrollIntoView({ block: "nearest" });
      }, 10);
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setSelectedIndex((prev) => (prev - 1 + allSelectableItems.length) % allSelectableItems.length);
      setTimeout(() => {
        const activeEl = resultsListRef.current?.querySelector('[data-active="true"]');
        activeEl?.scrollIntoView({ block: "nearest" });
      }, 10);
    } else if (e.key === "Enter") {
      e.preventDefault();
      handleSelect(selectedIndex);
    }
  };

  const getInitials = (name?: string) => {
    if (!name) return "ST";
    const parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.slice(0, 2).toUpperCase();
  };

  const renderResultsList = (isMobile = false) => {
    const totalCount = allSelectableItems.length;

    if (totalCount === 0 && normalizedQuery) {
      return (
        <div className="p-8 text-center flex flex-col items-center justify-center">
          <div className="w-12 h-12 rounded-2xl bg-slate-100 border border-slate-200/80 flex items-center justify-center text-slate-400 mb-3 shadow-2xs">
            <SearchX className="w-6 h-6" aria-hidden="true" />
          </div>
          <p className="text-sm font-bold text-slate-800">
            Tidak ditemukan hasil untuk &quot;{query}&quot;
          </p>
          <p className="text-xs text-slate-500 max-w-sm mt-1 leading-relaxed">
            {canSearchEmployees
              ? "Periksa ejaan kata kunci atau cari berdasarkan nama staf, NIK (contoh: EMP-001), atau nama menu seperti Cuti, Lembur, dan Payroll."
              : "Periksa ejaan kata kunci atau ketik menu yang ingin Anda akses seperti Presensi, Cuti, Lembur, atau Slip Gaji."}
          </p>
          <button
            type="button"
            onClick={() => setQuery("")}
            className="mt-4 px-3.5 py-2 text-xs font-semibold text-[#094595] bg-blue-50 hover:bg-blue-100 border border-blue-200 rounded-xl transition-colors cursor-pointer active:scale-95"
          >
            Bersihkan Pencarian
          </button>
        </div>
      );
    }

    let runningIndex = 0;

    const listContent = (
      <>
        {/* 1. Matching Employees Section (Only for authorized non-employee roles) */}
        {filteredEmployees.length > 0 && (
          <div>
            <div className="px-3 py-1.5 text-[10.5px] font-bold text-slate-400 uppercase tracking-wider flex items-center justify-between">
              <span>Pegawai ({filteredEmployees.length})</span>
              <span className="text-[10px] text-slate-400 font-normal">Tekan Enter untuk pilih</span>
            </div>
            <div className="space-y-1">
              {filteredEmployees.map((emp) => {
                const currentIndex = runningIndex++;
                const isSelected = selectedIndex === currentIndex;
                const empName = emp.user?.name || emp.name || "Karyawan";
                const deptName = emp.department?.name || emp.department_name || "Staf";
                const posName = emp.job_position?.name || emp.job_position_name || "Pegawai";

                return (
                  <button
                    key={`emp-${emp.id_employees}`}
                    type="button"
                    data-active={isSelected}
                    onMouseDown={(e) => e.preventDefault()}
                    onClick={() => handleSelect(currentIndex)}
                    onMouseEnter={() => setSelectedIndex(currentIndex)}
                    className={`w-full text-left px-3.5 py-3 rounded-xl flex items-center gap-3 transition-all cursor-pointer min-h-[50px] active:scale-[0.99] ${
                      isSelected
                        ? "bg-blue-50/90 text-[#0B3A6F] border border-blue-200 shadow-2xs"
                        : "hover:bg-slate-50 text-slate-700 border border-transparent"
                    }`}
                  >
                    <div
                      className={`w-9 h-9 rounded-xl flex items-center justify-center font-bold text-xs flex-shrink-0 shadow-2xs border ${
                        isSelected
                          ? "bg-[#094595] text-white border-[#094595]"
                          : "bg-blue-50 text-blue-700 border-blue-200/80"
                      }`}
                    >
                      {getInitials(empName)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-xs text-slate-900 truncate">
                          {empName}
                        </span>
                        <span className="px-1.5 py-0.5 text-[10px] font-mono font-medium rounded-md bg-slate-100 text-slate-600 border border-slate-200 flex-shrink-0">
                          {emp.nik}
                        </span>
                      </div>
                      <div className="flex items-center gap-2 text-[11px] text-slate-500 mt-0.5 truncate">
                        <span>{posName}</span>
                        <span>•</span>
                        <span className="truncate">{deptName}</span>
                      </div>
                    </div>
                    <div className="flex items-center gap-1 text-[11px] font-semibold text-[#094595] flex-shrink-0">
                      <span className="hidden sm:inline">Buka</span>
                      <ArrowRight className="w-3.5 h-3.5" aria-hidden="true" />
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {/* 2. Quick Actions Section (Role-Aware) */}
        {filteredActions.length > 0 && (
          <div>
            <div className="px-3 py-1.5 text-[10.5px] font-bold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500" aria-hidden="true" />
              <span>Aksi Cepat</span>
            </div>
            <div className="space-y-1">
              {filteredActions.map((action) => {
                const currentIndex = runningIndex++;
                const isSelected = selectedIndex === currentIndex;
                const Icon = action.icon;

                return (
                  <button
                    key={action.id}
                    type="button"
                    data-active={isSelected}
                    onMouseDown={(e) => e.preventDefault()}
                    onClick={() => handleSelect(currentIndex)}
                    onMouseEnter={() => setSelectedIndex(currentIndex)}
                    className={`w-full text-left px-3.5 py-3 rounded-xl flex items-center gap-3 transition-all cursor-pointer min-h-[50px] active:scale-[0.99] ${
                      isSelected
                        ? "bg-amber-50/90 text-amber-950 border border-amber-200 shadow-2xs"
                        : "hover:bg-slate-50 text-slate-700 border border-transparent"
                    }`}
                  >
                    <div
                      className={`w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 border ${
                        isSelected
                          ? "bg-amber-600 text-white border-amber-600"
                          : "bg-amber-50 text-amber-700 border-amber-200/80"
                      }`}
                    >
                      <Icon className="w-4 h-4" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="font-bold text-xs text-slate-900 truncate">
                        {action.title}
                      </div>
                      <div className="text-[11px] text-slate-500 truncate">
                        {action.description}
                      </div>
                    </div>
                    {isSelected && (
                      <CornerDownLeft className="w-3.5 h-3.5 text-amber-600 flex-shrink-0" />
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {/* 3. Navigation Menus Section (Filtered by User Role) */}
        {filteredMenus.length > 0 && (
          <div>
            <div className="px-3 py-1.5 text-[10.5px] font-bold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-slate-400" aria-hidden="true" />
              <span>{normalizedQuery ? "Menu & Fitur Terkait" : activeRole === "employee" ? "Layanan Mandiri Sistem" : "Navigasi Sistem"}</span>
            </div>
            <div className="space-y-1">
              {filteredMenus.map((menu) => {
                const currentIndex = runningIndex++;
                const isSelected = selectedIndex === currentIndex;
                const Icon = menu.icon;

                return (
                  <button
                    key={menu.id}
                    type="button"
                    data-active={isSelected}
                    onMouseDown={(e) => e.preventDefault()}
                    onClick={() => handleSelect(currentIndex)}
                    onMouseEnter={() => setSelectedIndex(currentIndex)}
                    className={`w-full text-left px-3.5 py-3 rounded-xl flex items-center gap-3 transition-all cursor-pointer min-h-[50px] active:scale-[0.99] ${
                      isSelected
                        ? "bg-blue-50/90 text-[#0B3A6F] border border-blue-200 shadow-2xs"
                        : "hover:bg-slate-50 text-slate-700 border border-transparent"
                    }`}
                  >
                    <div
                      className={`w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 border ${
                        isSelected
                          ? "bg-[#094595] text-white border-[#094595]"
                          : "bg-slate-100 text-slate-600 border-slate-200/80"
                      }`}
                    >
                      <Icon className="w-4 h-4" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-xs text-slate-900 truncate">
                          {menu.title}
                        </span>
                        {menu.badge && (
                          <span
                            className={`px-1.5 py-0.2 text-[9px] font-extrabold rounded-md uppercase border ${menu.badgeColor}`}
                          >
                            {menu.badge}
                          </span>
                        )}
                      </div>
                      <div className="text-[11px] text-slate-500 truncate">
                        {menu.description}
                      </div>
                    </div>
                    {isSelected && (
                      <CornerDownLeft className="w-3.5 h-3.5 text-[#094595] flex-shrink-0" />
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        )}
      </>
    );

    if (isMobile) {
      return (
        <div ref={resultsListRef} className="space-y-4 focus:outline-none">
          {listContent}
        </div>
      );
    }

    return (
      <div
        ref={resultsListRef}
        className="max-h-[min(65vh,480px)] overflow-y-auto p-2 space-y-4 focus:outline-none"
        tabIndex={-1}
      >
        {listContent}
      </div>
    );
  };

  return (
    <>
      {/* =========================================================================
          1. DESKTOP SEARCH CONTAINER & DROPDOWN (>= md)
         ========================================================================= */}
      <div ref={containerRef} className="hidden md:block relative w-full max-w-md mx-6">
        <div className="relative w-full flex items-center">
          <div className="absolute left-3.5 pointer-events-none text-slate-400">
            {isLoadingEmployees && query.length > 0 ? (
              <Loader2 className="w-4 h-4 animate-spin text-emerald-600" aria-hidden="true" />
            ) : (
              <Search className="w-4 h-4" aria-hidden="true" />
            )}
          </div>
          <input
            ref={desktopInputRef}
            type="search"
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              setIsOpen(true);
            }}
            onFocus={() => setIsOpen(true)}
            onKeyDown={handleKeyDown}
            placeholder={
              canSearchEmployees
                ? "Cari staf, menu, atau informasi sistem..."
                : "Cari menu, permohonan cuti, lembur, atau slip gaji..."
            }
            aria-label="Pencarian global"
            aria-expanded={isOpen}
            aria-haspopup="listbox"
            role="combobox"
            className="w-full pl-9 pr-14 py-2 rounded-full bg-slate-50 border border-slate-200/80 text-xs text-slate-800 placeholder:text-slate-400 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/15 transition-all shadow-2xs"
          />
          {/* Right Action / Shortcut Badge */}
          <div className="absolute right-2.5 flex items-center gap-1.5">
            {query.length > 0 ? (
              <button
                type="button"
                onClick={() => {
                  setQuery("");
                  desktopInputRef.current?.focus();
                }}
                className="p-1 rounded-full text-slate-400 hover:text-slate-700 hover:bg-slate-200/60 transition-colors cursor-pointer"
                aria-label="Bersihkan pencarian"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            ) : (
              <kbd className="hidden lg:inline-flex items-center gap-0.5 px-1.5 py-0.5 text-[10px] font-mono font-semibold text-slate-400 bg-white border border-slate-200 rounded-md shadow-2xs select-none pointer-events-none">
                <span className="text-[9px]">⌘</span>K
              </kbd>
            )}
          </div>
        </div>

        {/* Desktop Dropdown Popover */}
        {isOpen && (
          <div className="absolute top-full left-0 right-0 mt-2 bg-white rounded-2xl border border-slate-200/90 shadow-2xl z-50 overflow-hidden animate-fade-in-up">
            {renderResultsList()}

            {/* Footer Navigation Hints */}
            <div className="px-4 py-2.5 bg-slate-50 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-400 select-none">
              <div className="flex items-center gap-3">
                <span className="flex items-center gap-1">
                  <kbd className="px-1.5 py-0.5 text-[9.5px] font-mono bg-white border border-slate-200 rounded text-slate-600">
                    ↑
                  </kbd>
                  <kbd className="px-1.5 py-0.5 text-[9.5px] font-mono bg-white border border-slate-200 rounded text-slate-600">
                    ↓
                  </kbd>
                  <span>Pilih</span>
                </span>
                <span className="flex items-center gap-1">
                  <kbd className="px-1.5 py-0.5 text-[9.5px] font-mono bg-white border border-slate-200 rounded text-slate-600">
                    ↵
                  </kbd>
                  <span>Buka</span>
                </span>
                <span className="flex items-center gap-1">
                  <kbd className="px-1.5 py-0.5 text-[9.5px] font-mono bg-white border border-slate-200 rounded text-slate-600">
                    ESC
                  </kbd>
                  <span>Tutup</span>
                </span>
              </div>
              <span className="font-semibold text-slate-500">
                {activeRole === "employee" ? "Portal Karyawan" : "Admin HR Hub"}
              </span>
            </div>
          </div>
        )}
      </div>

      {/* =========================================================================
          2. MOBILE SEARCH FULLSCREEN OVERLAY (< md)
         ========================================================================= */}
      {isMobileOpen && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label="Pencarian sistem mobile"
          className="fixed inset-0 z-50 bg-white flex flex-col md:hidden overflow-hidden animate-fade-in"
        >
          {/* Top Search Input Bar with Safe Area Support */}
          <div
            className="border-b border-slate-200/80 bg-white flex items-center gap-2.5 px-3.5 py-2.5 flex-shrink-0 shadow-xs"
            style={{ paddingTop: "max(0.75rem, env(safe-area-inset-top))" }}
          >
            <div className="relative flex-1 flex items-center">
              <Search
                className="w-4 h-4 text-slate-400 absolute left-3.5 pointer-events-none"
                aria-hidden="true"
              />
              <input
                ref={mobileInputRef}
                type="search"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder={
                  canSearchEmployees
                    ? "Cari staf, menu, atau fitur..."
                    : "Cari menu, presensi, cuti, atau slip gaji..."
                }
                autoComplete="off"
                autoCorrect="off"
                autoCapitalize="none"
                spellCheck={false}
                className="w-full h-11 pl-10 pr-10 rounded-xl bg-slate-100 border border-slate-200/80 text-[16px] text-slate-900 placeholder:text-slate-400 focus:outline-none focus:bg-white focus:border-[#094595] focus:ring-2 focus:ring-[#094595]/15 transition-all shadow-2xs"
              />
              {query.length > 0 && (
                <button
                  type="button"
                  onClick={() => {
                    setQuery("");
                    mobileInputRef.current?.focus();
                  }}
                  className="absolute right-1 w-9 h-9 flex items-center justify-center rounded-full text-slate-400 hover:text-slate-700 active:scale-90 cursor-pointer"
                  aria-label="Bersihkan input"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>
            <button
              type="button"
              onClick={() => {
                if (onCloseMobile) onCloseMobile();
              }}
              className="min-w-[48px] h-11 px-2.5 flex items-center justify-center text-sm font-bold text-[#094595] hover:text-[#07387B] active:scale-95 transition-all cursor-pointer select-none rounded-xl"
              aria-label="Tutup pencarian"
            >
              Batal
            </button>
          </div>

          {/* Quick Filter Shortcuts on Mobile (when query is empty) */}
          {!normalizedQuery && (
            <div className="px-3.5 py-2.5 bg-slate-50 border-b border-slate-100 flex items-center gap-1.5 overflow-x-auto no-scrollbar select-none flex-shrink-0">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider flex-shrink-0 mr-1">
                Pintasan:
              </span>
              <button
                type="button"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => {
                  router.push("/attendance");
                  onCloseMobile?.();
                }}
                className="px-2.5 py-1.5 rounded-xl text-xs font-semibold bg-white border border-slate-200 text-slate-700 active:scale-95 flex-shrink-0 shadow-2xs hover:bg-slate-50 cursor-pointer"
              >
                Presensi
              </button>
              <button
                type="button"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => {
                  router.push("/leaves");
                  onCloseMobile?.();
                }}
                className="px-2.5 py-1.5 rounded-xl text-xs font-semibold bg-white border border-slate-200 text-slate-700 active:scale-95 flex-shrink-0 shadow-2xs hover:bg-slate-50 cursor-pointer"
              >
                Cuti
              </button>
              <button
                type="button"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => {
                  router.push("/overtime");
                  onCloseMobile?.();
                }}
                className="px-2.5 py-1.5 rounded-xl text-xs font-semibold bg-white border border-slate-200 text-slate-700 active:scale-95 flex-shrink-0 shadow-2xs hover:bg-slate-50 cursor-pointer"
              >
                Lembur
              </button>
              <button
                type="button"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => {
                  router.push("/payroll");
                  onCloseMobile?.();
                }}
                className="px-2.5 py-1.5 rounded-xl text-xs font-semibold bg-white border border-slate-200 text-slate-700 active:scale-95 flex-shrink-0 shadow-2xs hover:bg-slate-50 cursor-pointer"
              >
                Slip Gaji
              </button>
              {canSearchEmployees && (
                <button
                  type="button"
                  onMouseDown={(e) => e.preventDefault()}
                  onClick={() => {
                    router.push("/employees");
                    onCloseMobile?.();
                  }}
                  className="px-2.5 py-1.5 rounded-xl text-xs font-semibold bg-white border border-slate-200 text-slate-700 active:scale-95 flex-shrink-0 shadow-2xs hover:bg-slate-50 cursor-pointer"
                >
                  Karyawan
                </button>
              )}
            </div>
          )}

          {/* Results List */}
          <div
            className="flex-1 overflow-y-auto overscroll-contain p-3 space-y-4 focus:outline-none"
            style={{ paddingBottom: "max(2.5rem, env(safe-area-inset-bottom))" }}
          >
            {renderResultsList(true)}
          </div>
        </div>
      )}
    </>
  );
}
