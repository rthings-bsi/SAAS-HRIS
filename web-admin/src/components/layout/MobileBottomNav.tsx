"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutGrid,
  Clock,
  Clock4,
  CalendarCheck,
  CreditCard,
  Users,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { User } from "@/types";

interface NavItem {
  name: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
}

export function MobileBottomNav() {
  const pathname = usePathname();
  const [currentUser, setCurrentUser] = useState<User | null>(null);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const stored = localStorage.getItem("hris_user");
      if (stored) {
        try {
          setCurrentUser(JSON.parse(stored) as User);
        } catch {
          setCurrentUser(null);
        }
      }
    }
  }, []);

  const isEmployee = currentUser?.role === "employee";

  // 5 Tab Cepat untuk Karyawan (ESS)
  const employeeNavItems: NavItem[] = [
    { name: "Beranda", href: "/dashboard", icon: LayoutGrid },
    { name: "Presensi", href: "/attendance", icon: Clock },
    { name: "Lembur", href: "/overtime", icon: Clock4 },
    { name: "Cuti", href: "/leaves", icon: CalendarCheck },
    { name: "Gaji", href: "/payroll", icon: CreditCard },
  ];

  // 5 Tab Cepat untuk Admin / HR / Manager / Owner
  const adminNavItems: NavItem[] = [
    { name: "Beranda", href: "/dashboard", icon: LayoutGrid },
    { name: "Karyawan", href: "/employees", icon: Users },
    { name: "Presensi", href: "/attendance", icon: Clock },
    { name: "Cuti", href: "/leaves", icon: CalendarCheck },
    { name: "Payroll", href: "/payroll", icon: CreditCard },
  ];

  const items = isEmployee ? employeeNavItems : adminNavItems;

  return (
    <nav
      aria-label="Navigasi Bawah Mobile"
      className="fixed inset-x-3 sm:inset-x-auto sm:left-1/2 sm:-translate-x-1/2 sm:w-full sm:max-w-md z-40 lg:hidden"
      style={{ bottom: "max(0.75rem, env(safe-area-inset-bottom))" }}
    >
      <div className="relative px-2 py-1.5 rounded-[26px] bg-white/92 backdrop-blur-2xl border border-slate-200/80 shadow-[0_12px_36px_-6px_rgba(11,37,69,0.14),0_2px_10px_rgba(0,0,0,0.04)] ring-1 ring-slate-900/[0.04]">
        <div className="grid grid-cols-5 items-center gap-1">
          {items.map((item) => {
            const isActive =
              item.href === "/dashboard"
                ? pathname === "/dashboard" || pathname === "/"
                : pathname === item.href || pathname.startsWith(`${item.href}/`);
            const Icon = item.icon;

            return (
              <Link
                key={item.name}
                href={item.href}
                aria-current={isActive ? "page" : undefined}
                className={cn(
                  "group relative flex flex-col items-center justify-center min-h-[50px] py-1 px-1 rounded-2xl select-none transition-all duration-200 active:scale-90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600",
                  isActive ? "text-[#15803D]" : "text-slate-500 hover:text-slate-900"
                )}
              >
                {/* Elevated Active Squircle vs Soft Inactive Icon */}
                <div
                  className={cn(
                    "w-10 h-7 flex items-center justify-center rounded-xl transition-all duration-200",
                    isActive
                      ? "bg-[#16A34A] text-white shadow-[0_3px_10px_rgba(22,163,74,0.32)] scale-105"
                      : "text-slate-400 group-hover:text-slate-600 group-hover:bg-slate-100/60"
                  )}
                >
                  <Icon
                    className={cn(
                      "w-4 h-4 transition-transform duration-200",
                      isActive ? "stroke-[2.4] text-white" : "stroke-[1.8]"
                    )}
                    aria-hidden="true"
                  />
                </div>

                {/* Tab Label */}
                <span
                  className={cn(
                    "text-[10px] leading-tight tracking-tight mt-1 truncate max-w-full transition-colors",
                    isActive ? "font-bold text-[#15803D]" : "font-medium text-slate-500"
                  )}
                >
                  {item.name}
                </span>
              </Link>
            );
          })}
        </div>
      </div>
    </nav>
  );
}
