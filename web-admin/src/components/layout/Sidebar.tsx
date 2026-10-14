"use client";

import { useEffect, useState, useCallback } from "react";
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
  PanelLeftClose,
  PanelLeftOpen,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { User, Company } from "@/types";

interface NavItem {
  name: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
}

interface NavGroup {
  label: string;
  items: NavItem[];
}

const navGroups: NavGroup[] = [
  {
    label: "MENU UTAMA",
    items: [
      { name: "Dashboard", href: "/dashboard", icon: LayoutGrid },
      { name: "Data Karyawan", href: "/employees", icon: Users },
    ],
  },
  {
    label: "OPERASIONAL HR",
    items: [
      { name: "Presensi Kehadiran", href: "/attendance", icon: Clock },
      { name: "Pengajuan Cuti", href: "/leaves", icon: CalendarCheck },
      { name: "Pengajuan Lembur", href: "/overtime", icon: Clock4 },
      { name: "Penggajian (Payroll)", href: "/payroll", icon: CreditCard },
      { name: "Penilaian Kinerja (SMART)", href: "/performance", icon: Award },
    ],
  },
  {
    label: "STRUKTUR ORGANISASI",
    items: [
      { name: "Kantor Cabang", href: "/branches", icon: MapPin },
      { name: "Departemen", href: "/departments", icon: Building2 },
      { name: "Jabatan Posisi", href: "/job-positions", icon: Briefcase },
      { name: "Master Shift", href: "/shifts", icon: CalendarClock },
    ],
  },
  {
    label: "PENGATURAN & AKSES",
    items: [
      { name: "Profil Perusahaan", href: "/company-profile", icon: Building2 },
      { name: "Hak Akses & Role", href: "/roles", icon: ShieldCheck },
    ],
  },
];

const employeeNavGroups: NavGroup[] = [
  {
    label: "MENU UTAMA",
    items: [
      { name: "Dashboard", href: "/dashboard", icon: LayoutGrid },
    ],
  },
  {
    label: "LAYANAN MANDIRI",
    items: [
      { name: "Presensi Hari Ini", href: "/attendance", icon: Clock },
      { name: "Pengajuan Lembur", href: "/overtime", icon: Clock4 },
      { name: "Pengajuan Cuti", href: "/leaves", icon: CalendarCheck },
      { name: "Slip Gaji Saya", href: "/payroll", icon: CreditCard },
      { name: "Penilaian Kinerja (SMART)", href: "/performance", icon: Award },
    ],
  },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  const [currentUser, setCurrentUser] = useState<(User & { company?: Company }) | null>(null);
  const [isCollapsed, setIsCollapsed] = useState(false);

  // Load user data & saved sidebar collapse preference
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

      const savedCollapsed = localStorage.getItem("hris_sidebar_collapsed");
      if (savedCollapsed === "true") {
        setIsCollapsed(true);
      }
    }
  }, []);

  const toggleCollapsed = useCallback(() => {
    setIsCollapsed((prev) => {
      const next = !prev;
      if (typeof window !== "undefined") {
        localStorage.setItem("hris_sidebar_collapsed", String(next));
      }
      return next;
    });
  }, []);

  // Keyboard shortcut Ctrl+B or Cmd+B to toggle sidebar collapse
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "b") {
        e.preventDefault();
        toggleCollapsed();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [toggleCollapsed]);

  const handleLogout = () => {
    if (typeof window !== "undefined") {
      localStorage.removeItem("hris_token");
      localStorage.removeItem("hris_user");
      localStorage.removeItem("token");
      router.push("/login");
    }
  };

  const currentNavGroups =
    currentUser?.role === "employee" ? employeeNavGroups : navGroups;

  const getInitials = (name?: string) => {
    if (!name) return "SR";
    const parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.slice(0, 2).toUpperCase();
  };

  const getRoleMeta = (role?: string) => {
    switch (role) {
      case "superadmin":
      case "super_admin":
      case "director":
      case "owner":
        return {
          label: "Super Admin",
          badgeStyle: "bg-purple-50 text-purple-700 border-purple-200/80",
          avatarBg: "bg-purple-100 text-purple-700",
        };
      case "hr":
        return {
          label: "Admin HRD",
          badgeStyle: "bg-indigo-50 text-indigo-700 border-indigo-200/80",
          avatarBg: "bg-indigo-100 text-indigo-700",
        };
      case "manager":
        return {
          label: "Manager",
          badgeStyle: "bg-amber-50 text-amber-700 border-amber-200/80",
          avatarBg: "bg-amber-100 text-amber-700",
        };
      case "employee":
        return {
          label: "Karyawan",
          badgeStyle: "bg-emerald-50 text-emerald-700 border-emerald-200/80",
          avatarBg: "bg-emerald-100 text-emerald-700",
        };
      default:
        return {
          label: "Super Admin",
          badgeStyle: "bg-purple-50 text-purple-700 border-purple-200/80",
          avatarBg: "bg-purple-100 text-purple-700",
        };
    }
  };

  const userRoleMeta = getRoleMeta(currentUser?.role);

  return (
    <aside
      className={cn(
        "hidden lg:flex flex-col bg-white border-r border-slate-200/80 select-none flex-shrink-0 transition-all duration-200 ease-in-out z-20",
        isCollapsed ? "w-[68px]" : "w-[260px]"
      )}
      aria-label="Sidebar Navigasi"
    >
      {/* 1. Brand / Logo Header */}
      <div
        className={cn(
          "flex items-center border-b border-slate-100 h-16 transition-all duration-200",
          isCollapsed ? "justify-center px-2" : "justify-between px-4"
        )}
      >
        <Link
          href="/dashboard"
          title="HR Hub Enterprise"
          className={cn(
            "flex items-center gap-2.5 group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 rounded-xl p-1 -m-1 transition-colors min-w-0",
            isCollapsed && "justify-center"
          )}
        >
          {/* Logo Mark Matching 12.webp */}
          <div
            className="relative w-8 h-8 flex items-center justify-center flex-shrink-0"
            aria-hidden="true"
          >
            <svg viewBox="0 0 32 36" fill="none" className="w-7 h-8 transition-transform group-hover:scale-105">
              <rect x="2" y="10" width="7" height="22" rx="3.5" fill="#F97316" />
              <rect x="13" y="4" width="7" height="28" rx="3.5" fill="#094595" />
              <circle cx="5.5" cy="4.5" r="3.5" fill="#F97316" />
            </svg>
          </div>

          {/* Brand Title & Enterprise Badge (Visible when expanded) */}
          {!isCollapsed && (
            <div className="flex flex-col min-w-0">
              <div className="flex items-center gap-1.5">
                <span className="text-base font-extrabold tracking-tight text-[#0B2545] leading-tight">
                  HR Hub
                </span>
                <span className="px-1.5 py-0.5 text-[8.5px] font-extrabold tracking-wider rounded-md border uppercase leading-none bg-[#DCFCE7] text-[#15803D] border-[#BBF7D0]">
                  ENTERPRISE
                </span>
              </div>
              <span className="text-[10px] text-slate-400 font-medium truncate mt-0.5">
                Portal Manajemen HRIS
              </span>
            </div>
          )}
        </Link>

        {/* In-Rail Collapse/Expand Toggle Button (Anti-Slop R-32 & No Orphaned Header Buttons) */}
        {!isCollapsed && (
          <button
            type="button"
            onClick={toggleCollapsed}
            title="Ciutkan Sidebar (Ctrl+B)"
            aria-label="Ciutkan Sidebar"
            className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 cursor-pointer flex-shrink-0"
          >
            <PanelLeftClose className="w-4 h-4" aria-hidden="true" />
          </button>
        )}
      </div>

      {/* Tenant Company Context Card (Visible when expanded) */}
      {!isCollapsed && (
        <div className="px-3 pt-2.5 pb-1">
          <div
            title={currentUser?.company?.name || "PT. Steel Pipe Industry Of Indonesia, Tbk"}
            className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl bg-slate-50 border border-slate-200/70 text-slate-600"
          >
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse flex-shrink-0" aria-hidden="true" />
            <span className="text-[11px] font-semibold text-slate-700 truncate leading-none">
              {currentUser?.company?.name || "PT. Steel Pipe Industry Of Indonesia, Tbk"}
            </span>
          </div>
        </div>
      )}

      {/* Collapsed Rail Expand Action Button */}
      {isCollapsed && (
        <div className="flex justify-center py-2 border-b border-slate-100">
          <button
            type="button"
            onClick={toggleCollapsed}
            title="Bentangkan Sidebar (Ctrl+B)"
            aria-label="Bentangkan Sidebar"
            className="p-2 rounded-xl text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 cursor-pointer"
          >
            <PanelLeftOpen className="w-4 h-4" aria-hidden="true" />
          </button>
        </div>
      )}

      {/* 2. Navigation Menu List with Custom Sleek Scrollbar */}
      <nav
        className={cn(
          "flex-1 py-2 overflow-y-auto sidebar-scrollbar space-y-3",
          isCollapsed ? "px-2" : "px-3"
        )}
        aria-label="Menu Utama"
      >
        {currentNavGroups.map((group, groupIdx) => (
          <div key={group.label} className="space-y-0.5">
            {/* Section Header */}
            {!isCollapsed ? (
              <div className="px-2.5 pt-2.5 pb-1 text-[10px] font-extrabold uppercase tracking-wider text-slate-400 select-none">
                {group.label}
              </div>
            ) : (
              groupIdx > 0 && <div className="my-2 border-t border-slate-100" />
            )}

            {/* Menu Links */}
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
                  title={isCollapsed ? item.name : undefined}
                  aria-label={item.name}
                  aria-current={isActive ? "page" : undefined}
                  className={cn(
                    "group flex items-center rounded-xl transition-all duration-150 select-none outline-none focus-visible:ring-2 focus-visible:ring-emerald-500",
                    isCollapsed
                      ? "justify-center p-2.5 my-1"
                      : "gap-2.5 px-3 py-2 text-[13px] my-0.5",
                    isActive
                      ? "bg-[#16A34A] text-white font-semibold shadow-xs"
                      : "text-slate-600 hover:bg-slate-100/70 hover:text-slate-900 font-medium"
                  )}
                >
                  <Icon
                    className={cn(
                      "w-[18px] h-[18px] flex-shrink-0 transition-transform duration-150",
                      isActive
                        ? "text-white stroke-[2.2]"
                        : "text-slate-400 group-hover:text-slate-700 stroke-[1.8]"
                    )}
                    aria-hidden="true"
                  />
                  {!isCollapsed && (
                    <span className="leading-tight truncate flex-1">{item.name}</span>
                  )}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

      {/* 3. Bottom Section: Elevated User Identity Card */}
      <div className={cn("border-t border-slate-100 mt-auto bg-slate-50/50", isCollapsed ? "p-2" : "p-3")}>
        {!isCollapsed ? (
          <div className="flex items-center justify-between p-2 rounded-xl bg-white border border-slate-200/80 shadow-2xs gap-2 hover:border-slate-300 transition-colors">
            <div className="flex items-center gap-2.5 min-w-0">
              {/* Squircle Avatar with Dynamic Role Colors */}
              <div
                className={cn(
                  "w-8 h-8 rounded-lg font-extrabold text-xs flex items-center justify-center flex-shrink-0 shadow-2xs border border-black/5",
                  userRoleMeta.avatarBg
                )}
              >
                {getInitials(currentUser?.name)}
              </div>

              <div className="flex flex-col min-w-0">
                <span className="text-xs font-bold text-[#0B2545] truncate leading-tight">
                  {currentUser?.name || "Ricky satria"}
                </span>
                <span
                  className={cn(
                    "text-[9.5px] font-bold px-1.5 py-0.2 rounded border leading-tight mt-0.5 w-fit",
                    userRoleMeta.badgeStyle
                  )}
                >
                  {userRoleMeta.label}
                </span>
              </div>
            </div>

            <button
              type="button"
              onClick={handleLogout}
              title="Keluar dari akun"
              aria-label="Keluar dari akun"
              className="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 cursor-pointer flex-shrink-0"
            >
              <LogOut className="w-4 h-4" aria-hidden="true" />
            </button>
          </div>
        ) : (
          <div className="flex flex-col items-center gap-2 py-1">
            <div
              title={`${currentUser?.name || "Ricky satria"} (${userRoleMeta.label})`}
              className={cn(
                "w-9 h-9 rounded-xl font-extrabold text-xs flex items-center justify-center flex-shrink-0 shadow-2xs border border-black/5 cursor-default",
                userRoleMeta.avatarBg
              )}
            >
              {getInitials(currentUser?.name)}
            </div>
            <button
              type="button"
              onClick={handleLogout}
              title="Keluar dari akun"
              aria-label="Keluar dari akun"
              className="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 cursor-pointer"
            >
              <LogOut className="w-4 h-4" aria-hidden="true" />
            </button>
          </div>
        )}
      </div>
    </aside>
  );
}
