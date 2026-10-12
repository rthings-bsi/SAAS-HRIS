"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutGrid,
  Users,
  Clock,
  Clock4,
  CalendarCheck,
  CreditCard,
  Building2,
  CalendarClock,
  LogOut,
  MapPin,
  Briefcase,
  ShieldCheck,
  Award,
  X,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { User, Company } from "@/types";

interface SidebarProps {
  isOpen?: boolean;
  onClose?: () => void;
}

interface NavItem {
  name: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
}

interface NavGroup {
  label?: string;
  items: NavItem[];
}

// Navigasi Terstruktur Berdasarkan Domain Fungsional HRIS Internal (Non-SaaS)
const navGroups: NavGroup[] = [
  {
    label: "Menu Utama",
    items: [
      { name: "Dashboard", href: "/dashboard", icon: LayoutGrid },
      { name: "Data Karyawan", href: "/employees", icon: Users },
    ],
  },
  {
    label: "Operasional HR",
    items: [
      { name: "Presensi Kehadiran", href: "/attendance", icon: Clock },
      { name: "Pengajuan Cuti", href: "/leaves", icon: CalendarCheck },
      { name: "Pengajuan Lembur", href: "/overtime", icon: Clock4 },
      { name: "Penggajian (Payroll)", href: "/payroll", icon: CreditCard },
      { name: "Penilaian Kinerja (SMART)", href: "/performance", icon: Award },
    ],
  },
  {
    label: "Struktur Organisasi",
    items: [
      { name: "Kantor Cabang", href: "/branches", icon: MapPin },
      { name: "Departemen", href: "/departments", icon: Building2 },
      { name: "Jabatan Posisi", href: "/job-positions", icon: Briefcase },
      { name: "Master Shift", href: "/shifts", icon: CalendarClock },
    ],
  },
  {
    label: "Pengaturan & Akses",
    items: [
      { name: "Profil Perusahaan", href: "/company-profile", icon: Building2 },
      { name: "Hak Akses & Role", href: "/roles", icon: ShieldCheck },
    ],
  },
];

interface RoleStyle {
  label: string;
  avatarBg: string;
  avatarText: string;
  avatarBorder: string;
  badgeBg: string;
  badgeText: string;
  badgeBorder: string;
}

const roleStyles: Record<string, RoleStyle> = {
  superadmin: {
    label: "Pimpinan / Direktur",
    avatarBg: "bg-amber-100",
    avatarText: "text-amber-800",
    avatarBorder: "border-amber-200",
    badgeBg: "bg-amber-50",
    badgeText: "text-amber-700",
    badgeBorder: "border-amber-200",
  },
  super_admin: {
    label: "Pimpinan / Direktur",
    avatarBg: "bg-amber-100",
    avatarText: "text-amber-800",
    avatarBorder: "border-amber-200",
    badgeBg: "bg-amber-50",
    badgeText: "text-amber-700",
    badgeBorder: "border-amber-200",
  },
  director: {
    label: "Direktur",
    avatarBg: "bg-amber-100",
    avatarText: "text-amber-800",
    avatarBorder: "border-amber-200",
    badgeBg: "bg-amber-50",
    badgeText: "text-amber-700",
    badgeBorder: "border-amber-200",
  },
  owner: {
    label: "Pimpinan",
    avatarBg: "bg-amber-100",
    avatarText: "text-amber-800",
    avatarBorder: "border-amber-200",
    badgeBg: "bg-amber-50",
    badgeText: "text-amber-700",
    badgeBorder: "border-amber-200",
  },
  hr: {
    label: "Admin HRD",
    avatarBg: "bg-blue-100",
    avatarText: "text-blue-800",
    avatarBorder: "border-blue-200",
    badgeBg: "bg-blue-50",
    badgeText: "text-blue-700",
    badgeBorder: "border-blue-200",
  },
  manager: {
    label: "Manager",
    avatarBg: "bg-emerald-100",
    avatarText: "text-emerald-800",
    avatarBorder: "border-emerald-200",
    badgeBg: "bg-emerald-50",
    badgeText: "text-emerald-700",
    badgeBorder: "border-emerald-200",
  },
  employee: {
    label: "Karyawan",
    avatarBg: "bg-slate-100",
    avatarText: "text-slate-800",
    avatarBorder: "border-slate-200",
    badgeBg: "bg-slate-100",
    badgeText: "text-slate-700",
    badgeBorder: "border-slate-200",
  },
};

const employeeNavGroups: NavGroup[] = [
  {
    label: "Menu Utama",
    items: [
      { name: "Dashboard", href: "/dashboard", icon: LayoutGrid },
    ],
  },
  {
    label: "Layanan Mandiri",
    items: [
      { name: "Pengajuan Lembur", href: "/overtime", icon: Clock4 },
      { name: "Pengajuan Cuti", href: "/leaves", icon: CalendarCheck },
      { name: "Slip Gaji Saya", href: "/payroll", icon: CreditCard },
      { name: "Penilaian Kinerja (SMART)", href: "/performance", icon: Award },
    ],
  },
];

export function Sidebar({ isOpen = false, onClose }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();

  const [currentUser, setCurrentUser] = useState<User | null>(null);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const stored = localStorage.getItem("hris_user");
      if (stored) {
        try {
          setCurrentUser(JSON.parse(stored) as User & { company?: Company });
        } catch {
          setCurrentUser(null);
        }
      }
    }
  }, []);

  // Handle ESC key to close mobile drawer & prevent background scroll
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && onClose) {
        onClose();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    const originalOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      document.body.style.overflow = originalOverflow;
    };
  }, [isOpen, onClose]);

  const handleLogout = () => {
    if (typeof window !== "undefined") {
      localStorage.removeItem("hris_token");
      localStorage.removeItem("hris_user");
      router.push("/login");
    }
  };

  const currentRoleStyle =
    (currentUser?.role && roleStyles[currentUser.role]) || roleStyles.hr;

  const currentNavGroups =
    currentUser?.role === "employee" ? employeeNavGroups : navGroups;

  const getInitials = (name?: string) => {
    if (!name) return "HR";
    const parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.slice(0, 2).toUpperCase();
  };

  return (
    <>
      {/* Mobile Backdrop with smooth fade transition */}
      <div
        role="presentation"
        aria-hidden="true"
        onClick={onClose}
        className={cn(
          "fixed inset-0 z-40 bg-slate-900/40 backdrop-blur-sm transition-opacity duration-300 ease-in-out lg:hidden",
          isOpen ? "opacity-100 pointer-events-auto" : "opacity-0 pointer-events-none"
        )}
      />

      {/* Main Sidebar Aside */}
      <aside
        className={cn(
          "fixed top-0 bottom-0 left-0 z-50 flex flex-col w-[270px] bg-slate-50/90 lg:bg-slate-50/75 backdrop-blur-xl border-r border-slate-200/80 transition-transform duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] lg:translate-x-0 lg:static lg:z-auto select-none",
          isOpen ? "translate-x-0 shadow-2xl" : "-translate-x-full lg:shadow-none"
        )}
        aria-label="Sidebar Navigasi"
      >
        {/* Brand / Logo Header */}
        <div className="flex items-center justify-between px-4 py-3.5 border-b border-slate-200/70">
          <Link
            href="/dashboard"
            onClick={onClose}
            className="flex items-center gap-3 group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 rounded-xl p-1 -m-1 transition-colors hover:bg-slate-50/80 min-w-0"
          >
            {/* Two Orange Pill Graphic */}
            <div
              className="relative w-8 h-9 flex items-center justify-center flex-shrink-0"
              aria-hidden="true"
            >
              <svg
                viewBox="0 0 32 36"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                className="w-8 h-9 transition-transform group-hover:scale-105 duration-200"
              >
                <defs>
                  <linearGradient id="sb_pill_left" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#FB923C" />
                    <stop offset="100%" stopColor="#EA580C" />
                  </linearGradient>
                  <linearGradient id="sb_pill_right" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#EA580C" />
                    <stop offset="100%" stopColor="#C2410C" />
                  </linearGradient>
                </defs>
                <circle cx="8" cy="6" r="3.5" fill="url(#sb_pill_left)" />
                <rect x="4.5" y="14" width="7" height="19" rx="3.5" fill="url(#sb_pill_left)" />
                <rect x="17" y="6" width="7.5" height="27" rx="3.75" fill="url(#sb_pill_right)" />
              </svg>
            </div>

            {/* Brand Title & Workspace */}
            <div className="flex flex-col min-w-0">
              <div className="flex items-center gap-1.5">
                <span className="text-[15px] font-bold tracking-tight text-slate-900 leading-tight">
                  HR Hub
                </span>
                <span className="px-1.5 py-0.5 text-[9px] font-bold tracking-wide rounded-full border uppercase leading-none bg-orange-50 text-orange-700 border-orange-200/70">
                  ENTERPRISE
                </span>
              </div>
              <div className="text-[11.5px] text-slate-500 font-normal leading-tight mt-1 truncate flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 flex-shrink-0" />
                <span className="truncate font-medium">
                  {currentUser?.company?.name || "PT Sumber Makmur"}
                </span>
              </div>
            </div>
          </Link>

          {/* Close button for mobile */}
          {onClose && (
            <button
              type="button"
              onClick={onClose}
              className="flex items-center justify-center w-8 h-8 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 lg:hidden focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 cursor-pointer transition-colors"
              aria-label="Tutup navigasi sidebar"
            >
              <X className="w-5 h-5" aria-hidden="true" />
            </button>
          )}
        </div>

        {/* Navigation list */}
        <nav
          className="flex-1 px-3 py-3 space-y-3.5 overflow-y-auto"
          aria-label="Menu Utama"
        >
          {currentNavGroups.map((group, groupIdx) => (
            <div
              key={group.label || groupIdx}
              className={cn("space-y-1", groupIdx > 0 && "pt-3")}
            >
              {group.label && (
                <div className="px-3 pb-1 text-[10.5px] font-bold uppercase tracking-wider text-slate-400/90 select-none">
                  {group.label}
                </div>
              )}

              {group.items.map((item) => {
                const isActive =
                  item.href === "/dashboard"
                    ? pathname === "/dashboard" || pathname === "/"
                    : pathname === item.href || pathname.startsWith(`${item.href}/`);
                const Icon = item.icon;

                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    onClick={onClose}
                    aria-current={isActive ? "page" : undefined}
                    className={cn(
                      "group relative flex items-center gap-3 px-3 py-2 text-[13px] rounded-xl transition-all duration-150 select-none outline-none focus-visible:ring-2 focus-visible:ring-orange-500 active:scale-[0.98]",
                      isActive
                        ? "bg-white text-orange-600 font-semibold shadow-[0_1px_3px_rgba(0,0,0,0.06),0_1px_2px_rgba(0,0,0,0.03)] border border-slate-200/80"
                        : "text-slate-600 hover:bg-slate-200/60 hover:text-slate-900 font-medium hover:translate-x-0.5"
                    )}
                  >
                    {/* Smooth left accent pill */}
                    <span
                      className={cn(
                        "absolute left-0 top-1.5 bottom-1.5 w-1 rounded-r-full transition-all duration-200",
                        isActive
                          ? "bg-orange-600 opacity-100 scale-y-100"
                          : "bg-transparent opacity-0 scale-y-0"
                      )}
                      aria-hidden="true"
                    />

                    <Icon
                      className={cn(
                        "w-[18px] h-[18px] flex-shrink-0 transition-transform duration-200",
                        isActive
                          ? "text-orange-600 stroke-[2.2]"
                          : "text-slate-400 group-hover:text-slate-700 group-hover:scale-105 stroke-[1.75]"
                      )}
                      aria-hidden="true"
                    />
                    <span className="leading-tight truncate flex-1">{item.name}</span>
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>

        {/* Bottom Section: User Identity & Action */}
        <div className="p-3 border-t border-slate-200/70 mt-auto bg-slate-100/40">
          <div className="flex items-center justify-between p-2.5 rounded-2xl bg-white/95 backdrop-blur-md border border-slate-200/80 shadow-[0_1px_3px_rgba(0,0,0,0.03)] gap-2 transition-all hover:border-slate-300/80">
            <div className="flex items-center gap-2.5 min-w-0">
              <div
                className={cn(
                  "w-8 h-8 rounded-lg flex items-center justify-center font-bold text-xs flex-shrink-0 border transition-transform duration-200 hover:scale-105",
                  currentRoleStyle.avatarBg,
                  currentRoleStyle.avatarText,
                  currentRoleStyle.avatarBorder
                )}
              >
                {getInitials(currentUser?.name)}
              </div>
              <div className="flex flex-col min-w-0">
                <span className="text-xs font-semibold text-slate-900 truncate leading-tight">
                  {currentUser?.name || "Administrator"}
                </span>
                <div className="flex items-center gap-1.5 mt-0.5">
                  <span
                    className={cn(
                      "inline-flex items-center px-1.5 py-0.5 text-[9.5px] font-semibold rounded-full border leading-none tracking-tight",
                      currentRoleStyle.badgeBg,
                      currentRoleStyle.badgeText,
                      currentRoleStyle.badgeBorder
                    )}
                  >
                    {currentRoleStyle.label}
                  </span>
                </div>
              </div>
            </div>

            <button
              type="button"
              onClick={handleLogout}
              title="Keluar dari akun"
              aria-label="Keluar dari akun"
              className="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50/80 active:scale-95 transition-all duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 cursor-pointer flex-shrink-0"
            >
              <LogOut className="w-4 h-4" aria-hidden="true" />
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
