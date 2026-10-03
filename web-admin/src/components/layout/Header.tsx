"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Menu, LogOut, Calendar } from "lucide-react";
import { formatDate } from "@/lib/utils";
import type { User } from "@/types";

interface HeaderProps {
  onOpenSidebar: () => void;
}

export function Header({ onOpenSidebar }: HeaderProps) {
  const router = useRouter();
  const today = new Date();
  const [currentUser] = useState<User | null>(() => {
    if (typeof window !== "undefined") {
      const stored = localStorage.getItem("hris_user");
      if (stored) {
        try {
          return JSON.parse(stored) as User;
        } catch {
          return null;
        }
      }
    }
    return null;
  });

  const handleLogout = () => {
    if (typeof window !== "undefined") {
      localStorage.removeItem("hris_token");
      localStorage.removeItem("hris_user");
      router.push("/login");
    }
  };

  const getInitials = (name: string) => {
    const parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.slice(0, 2).toUpperCase() || "HR";
  };

  return (
    <header className="sticky top-0 z-30 flex items-center justify-between h-14 sm:h-16 px-4 sm:px-6 bg-white/80 backdrop-blur-xl border-b border-slate-200/70 transition-colors shadow-2xs">
      <div className="flex items-center gap-3">
        {/* Mobile menu trigger */}
        <button
          type="button"
          onClick={onOpenSidebar}
          className="p-1.5 -ml-1.5 rounded-xl text-slate-500 hover:text-slate-900 hover:bg-slate-100/80 active:scale-95 lg:hidden focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 cursor-pointer transition-all"
          aria-label="Buka navigasi sidebar"
        >
          <Menu className="w-5 h-5" aria-hidden="true" />
        </button>

        {/* Current Date context with pill */}
        <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full bg-slate-100/80 border border-slate-200/70 text-slate-600 shadow-2xs">
          <Calendar className="w-3.5 h-3.5 text-slate-500" aria-hidden="true" />
          <span className="text-xs font-medium text-slate-700 tabular-nums">
            {formatDate(today)}
          </span>
        </div>
      </div>

      {/* Right User & Actions */}
      <div className="flex items-center gap-3">
        {/* Profile Card */}
        <div className="flex items-center gap-2.5 px-1.5 py-1">
          <div className="flex items-center justify-center w-8 h-8 rounded-full bg-orange-50 border border-orange-200 text-orange-600 font-semibold text-xs">
            {currentUser?.name ? getInitials(currentUser.name) : "HR"}
          </div>
          <div className="flex flex-col text-left">
            <span className="text-xs font-semibold text-slate-900 leading-tight">
              {currentUser?.name || "Administrator"}
            </span>
            <span className="text-[11px] text-slate-500 leading-tight capitalize">
              {currentUser?.role === "superadmin" || currentUser?.role === "super_admin"
                ? "Superadmin"
                : currentUser?.role || "HR Administrator"}
            </span>
          </div>
        </div>

        <div className="h-4 w-[1px] bg-slate-200" aria-hidden="true" />

        {/* Keluar Button */}
        <button
          type="button"
          onClick={handleLogout}
          aria-label="Keluar dari akun admin"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-xl text-slate-500 hover:text-rose-600 hover:bg-rose-50/80 active:scale-95 transition-all duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 cursor-pointer"
        >
          <LogOut className="w-4 h-4" aria-hidden="true" />
          <span className="hidden sm:inline">Keluar</span>
        </button>
      </div>
    </header>
  );
}
