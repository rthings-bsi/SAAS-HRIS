"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { LogOut } from "lucide-react";
import type { User, Company } from "@/types";

interface HeaderProps {
  onOpenSidebar?: () => void;
}

export function Header({ onOpenSidebar }: HeaderProps) {
  const router = useRouter();
  const [currentUser, setCurrentUser] = useState<(User & { company?: Company }) | null>(null);

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

  const handleLogout = () => {
    if (typeof window !== "undefined") {
      localStorage.removeItem("hris_token");
      localStorage.removeItem("hris_user");
      router.push("/login");
    }
  };

  const getInitials = (name?: string) => {
    if (!name) return "HR";
    const parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.slice(0, 2).toUpperCase();
  };

  return (
    <header className="sticky top-0 z-30 flex items-center justify-between h-13 sm:h-14 px-3 sm:px-6 bg-white/95 backdrop-blur-md border-b border-slate-200/80 transition-colors shadow-2xs">
      {/* Brand & Workspace Identity (Mobile Top Nav) */}
      <div className="flex items-center gap-2.5 min-w-0">
        <Link
          href="/dashboard"
          className="flex items-center gap-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 rounded-lg p-0.5 min-w-0"
        >
          {/* Two Orange Pill Graphic */}
          <div
            className="relative w-6 h-7 flex items-center justify-center flex-shrink-0"
            aria-hidden="true"
          >
            <svg
              viewBox="0 0 32 36"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              className="w-6 h-7"
            >
              <defs>
                <linearGradient id="hdr_pill_l" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stopColor="#FB923C" />
                  <stop offset="100%" stopColor="#EA580C" />
                </linearGradient>
                <linearGradient id="hdr_pill_r" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stopColor="#EA580C" />
                  <stop offset="100%" stopColor="#C2410C" />
                </linearGradient>
              </defs>
              <circle cx="8" cy="6" r="3.5" fill="url(#hdr_pill_l)" />
              <rect x="4.5" y="14" width="7" height="19" rx="3.5" fill="url(#hdr_pill_l)" />
              <rect x="17" y="6" width="7.5" height="27" rx="3.75" fill="url(#hdr_pill_r)" />
            </svg>
          </div>

          <div className="flex flex-col min-w-0">
            <div className="flex items-center gap-1.5 leading-tight">
              <span className="text-sm font-bold tracking-tight text-slate-900">
                HR Hub
              </span>
              <span className="px-1.5 py-0.2 rounded text-[9px] font-bold bg-orange-50 text-orange-700 border border-orange-200/70 uppercase">
                Enterprise
              </span>
            </div>
            <span className="text-[10px] text-slate-500 font-medium leading-none truncate max-w-[120px] xs:max-w-[170px] sm:max-w-none">
              {currentUser?.company?.name || "PT Sumber Makmur"}
            </span>
          </div>
        </Link>
      </div>

      {/* Right User & Actions */}
      <div className="flex items-center gap-2 sm:gap-3 flex-shrink-0">
        {/* Profile Card */}
        <div className="flex items-center gap-2 py-1">
          <div className="flex items-center justify-center w-7 h-7 sm:w-8 sm:h-8 rounded-lg bg-orange-50 border border-orange-200 text-orange-700 font-bold text-xs flex-shrink-0">
            {getInitials(currentUser?.name)}
          </div>
          <div className="flex flex-col text-left max-w-[90px] sm:max-w-none">
            <span className="text-xs font-semibold text-slate-900 leading-tight truncate">
              {currentUser?.name || "Pengguna"}
            </span>
            <span className="text-[10px] text-slate-500 leading-none capitalize truncate">
              {currentUser?.role === "employee"
                ? "Karyawan"
                : currentUser?.role || "Staff"}
            </span>
          </div>
        </div>

        <div className="h-4 w-[1px] bg-slate-200" aria-hidden="true" />

        {/* Keluar Button */}
        <button
          type="button"
          onClick={handleLogout}
          aria-label="Keluar dari akun"
          className="inline-flex items-center gap-1 p-1.5 sm:px-2.5 sm:py-1.5 text-xs font-medium rounded-lg text-slate-500 hover:text-rose-600 hover:bg-rose-50/80 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 cursor-pointer"
        >
          <LogOut className="w-4 h-4" aria-hidden="true" />
          <span className="hidden sm:inline">Keluar</span>
        </button>
      </div>
    </header>
  );
}
