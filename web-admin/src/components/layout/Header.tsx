"use client";

import { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Search,
  LogOut,
  ChevronDown,
  Building2,
  X,
  ShieldCheck,
} from "lucide-react";
import type { User, Company } from "@/types";
import { NotificationDropdown } from "./NotificationDropdown";
import { GlobalSearch } from "./GlobalSearch";

export function Header() {
  const router = useRouter();
  const [currentUser, setCurrentUser] = useState<(User & { company?: Company }) | null>(null);
  const [currentDateString, setCurrentDateString] = useState("Rabu, 14 Oktober 2026");
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [isMobileSearchOpen, setIsMobileSearchOpen] = useState(false);
  const profileMenuRef = useRef<HTMLDivElement>(null);

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

      // Format date in Indonesian format: "Rabu, 14 Oktober 2026"
      try {
        const now = new Date();
        const formatted = new Intl.DateTimeFormat("id-ID", {
          weekday: "long",
          day: "numeric",
          month: "long",
          year: "numeric",
        }).format(now);
        setCurrentDateString(formatted);
      } catch {
        setCurrentDateString("Rabu, 14 Oktober 2026");
      }
    }
  }, []);

  // Click outside to close profile popover
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (profileMenuRef.current && !profileMenuRef.current.contains(event.target as Node)) {
        setIsProfileOpen(false);
      }
    };

    if (isProfileOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [isProfileOpen]);

  // ESC key to close profile menu or mobile search
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setIsProfileOpen(false);
        setIsMobileSearchOpen(false);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const handleLogout = () => {
    if (typeof window !== "undefined") {
      localStorage.removeItem("hris_token");
      localStorage.removeItem("hris_user");
      localStorage.removeItem("token");
      router.push("/login");
    }
  };

  const getInitials = (name?: string) => {
    if (!name) return "SR";
    const parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.slice(0, 2).toUpperCase();
  };

  const getRoleBadge = (role?: string) => {
    switch (role) {
      case "superadmin":
      case "super_admin":
      case "director":
      case "owner":
        return "Super Admin";
      case "hr":
        return "Admin HRD";
      case "manager":
        return "Manager";
      case "employee":
        return "Karyawan";
      default:
        return "Super Admin";
    }
  };

  return (
    <header className="sticky top-0 z-50 flex items-center justify-between h-14 sm:h-16 px-4 sm:px-6 lg:px-8 bg-white/92 backdrop-blur-xl border-b border-slate-200/70 transition-colors shadow-[0_1px_4px_rgba(0,0,0,0.02)]">
      {/* Left: Mobile Brand Title (< lg) OR Desktop Indonesian Date (>= lg) */}
      <div className="flex items-center gap-3 min-w-0">
        {/* Mobile Brand Title (< lg) */}
        <div className="flex lg:hidden items-center gap-2.5 min-w-0">
          <Link
            href="/dashboard"
            className="flex items-center gap-2.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 rounded-xl p-0.5 min-w-0 active:scale-95 transition-transform"
          >
            <div className="w-8 h-8 rounded-xl bg-slate-50 border border-slate-200/80 flex items-center justify-center flex-shrink-0 shadow-2xs">
              <svg viewBox="0 0 32 36" fill="none" className="w-5 h-6">
                <rect x="2" y="10" width="7" height="22" rx="3.5" fill="#F97316" />
                <rect x="13" y="4" width="7" height="28" rx="3.5" fill="#094595" />
                <circle cx="5.5" cy="4.5" r="3.5" fill="#F97316" />
              </svg>
            </div>
            <div className="flex flex-col min-w-0">
              <div className="flex items-center gap-1.5">
                <span className="text-[15px] font-extrabold tracking-tight text-[#0B2545] leading-tight">
                  HR Hub
                </span>
                <span className="px-1.5 py-0.2 text-[8.5px] font-extrabold tracking-wider rounded-md uppercase bg-[#DCFCE7] text-[#15803D] border border-[#BBF7D0] leading-none">
                  SPINDO
                </span>
              </div>
              <span className="text-[10px] text-slate-400 font-medium truncate leading-none mt-0.5">
                {currentUser?.role === "employee" ? "Portal Karyawan" : "Admin Panel"}
              </span>
            </div>
          </Link>
        </div>

        {/* Desktop Date Display (>= lg) matching 12.webp */}
        <div className="hidden lg:flex items-center gap-2 text-xs font-medium text-slate-500 select-none">
          <span className="w-2 h-2 rounded-full bg-emerald-500" aria-hidden="true" />
          <span>{currentDateString}</span>
        </div>
      </div>

      {/* Center: Global Search Command Palette (Desktop Pill & Mobile Dialog) */}
      <GlobalSearch
        isMobileOpen={isMobileSearchOpen}
        onCloseMobile={() => setIsMobileSearchOpen(false)}
        currentUser={currentUser}
      />

      {/* Right: Quick Search Button (Mobile), Notification Bell, & Modern Profile Menu */}
      <div className="flex items-center gap-2 sm:gap-3 flex-shrink-0">
        {/* Mobile Search Trigger Button (< md) */}
        <button
          type="button"
          onClick={() => setIsMobileSearchOpen(true)}
          aria-label="Buka pencarian"
          className="md:hidden p-2 rounded-xl border border-slate-200/80 bg-white text-slate-600 hover:text-slate-900 hover:bg-slate-50 active:scale-95 transition-all shadow-2xs focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 cursor-pointer min-w-[44px] min-h-[44px] flex items-center justify-center"
        >
          <Search className="w-4 h-4" aria-hidden="true" />
        </button>

        {/* Interactive Notification Popover with Live Badge & Anti-Slop States */}
        <NotificationDropdown />

        {/* User Profile Container & Interactive Popover (Hanya tampil pada mobile/tablet, disembunyikan pada desktop karena sudah tersedia di sidebar) */}
        <div className="relative lg:hidden" ref={profileMenuRef}>
          <button
            type="button"
            onClick={() => setIsProfileOpen((prev) => !prev)}
            aria-expanded={isProfileOpen}
            aria-haspopup="true"
            aria-label="Buka menu profil pengguna"
            className="flex items-center gap-2 p-1 rounded-2xl hover:bg-slate-50 active:scale-95 transition-all border border-transparent hover:border-slate-200/60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 cursor-pointer min-h-[44px]"
          >
            {/* Squircle Avatar */}
            <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-blue-50 to-blue-100 border border-blue-200/80 text-blue-700 font-extrabold text-xs flex items-center justify-center flex-shrink-0 shadow-2xs">
              {getInitials(currentUser?.name)}
            </div>

            {/* Desktop User Info */}
            <div className="hidden sm:flex flex-col text-left max-w-[120px]">
              <span className="text-xs font-bold text-[#0B2545] truncate leading-tight">
                {currentUser?.name || "Siti Rahma"}
              </span>
              <span className="text-[10px] text-slate-400 font-medium leading-none truncate mt-0.5">
                {getRoleBadge(currentUser?.role)}
              </span>
            </div>

            <ChevronDown
              className={`w-3.5 h-3.5 text-slate-400 transition-transform duration-200 ${
                isProfileOpen ? "rotate-180 text-slate-700" : ""
              }`}
              aria-hidden="true"
            />
          </button>

          {/* Elegant Modern Profile Dropdown Menu */}
          {isProfileOpen && (
            <div
              role="menu"
              aria-orientation="vertical"
              className="absolute right-0 mt-2 w-72 max-w-[calc(100vw-1.5rem)] rounded-2xl bg-white/98 backdrop-blur-2xl border border-slate-200/80 shadow-[0_12px_32px_-4px_rgba(11,37,69,0.15),0_2px_8px_rgba(0,0,0,0.04)] p-3 text-sm z-50 animate-fade-in-up"
            >
              {/* Profile Card Header */}
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-100 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-700 font-extrabold text-sm flex items-center justify-center flex-shrink-0 shadow-2xs">
                  {getInitials(currentUser?.name)}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="font-bold text-slate-900 text-xs truncate">
                    {currentUser?.name || "Siti Rahma"}
                  </div>
                  <div className="text-[11px] text-slate-400 truncate mt-0.5">
                    {currentUser?.email || "user@spindo.co.id"}
                  </div>
                  <div className="inline-flex items-center gap-1 mt-1 px-1.5 py-0.2 rounded-md bg-emerald-50 text-[#15803D] text-[9px] font-bold border border-emerald-200/60 uppercase">
                    {getRoleBadge(currentUser?.role)}
                  </div>
                </div>
              </div>

              {/* Company Info */}
              <div className="px-3 py-2 text-[11px] text-slate-500 flex items-center gap-2 my-1">
                <Building2 className="w-3.5 h-3.5 text-slate-400 flex-shrink-0" aria-hidden="true" />
                <span className="truncate">
                  {currentUser?.company?.name || "PT. Steel Pipe Industry Of Indonesia, Tbk"}
                </span>
              </div>

              {/* Menu Links (Khusus Admin / Non-Employee) */}
              {currentUser?.role !== "employee" && (
                <div className="space-y-0.5 py-1.5 border-t border-slate-100">
                  <Link
                    href="/company-profile"
                    onClick={() => setIsProfileOpen(false)}
                    role="menuitem"
                    className="flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-slate-700 hover:text-slate-900 hover:bg-slate-50 rounded-xl transition-colors"
                  >
                    <Building2 className="w-3.5 h-3.5 text-slate-400" aria-hidden="true" />
                    <span>Profil Perusahaan</span>
                  </Link>
                  <Link
                    href="/roles"
                    onClick={() => setIsProfileOpen(false)}
                    role="menuitem"
                    className="flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-slate-700 hover:text-slate-900 hover:bg-slate-50 rounded-xl transition-colors"
                  >
                    <ShieldCheck className="w-3.5 h-3.5 text-slate-400" aria-hidden="true" />
                    <span>Hak Akses & Role</span>
                  </Link>
                </div>
              )}

              {/* Log Out Button */}
              <div className="pt-1.5 border-t border-slate-100">
                <button
                  type="button"
                  onClick={handleLogout}
                  role="menuitem"
                  className="w-full flex items-center gap-2.5 px-3 py-2 text-xs font-semibold text-rose-600 hover:bg-rose-50 rounded-xl transition-colors cursor-pointer"
                >
                  <LogOut className="w-3.5 h-3.5 text-rose-500" aria-hidden="true" />
                  <span>Keluar dari Akun</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
