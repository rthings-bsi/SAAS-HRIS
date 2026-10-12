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
  Award,
  Users,
  Menu,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { User } from "@/types";

interface MobileBottomNavProps {
  onOpenMenu?: () => void;
}

interface NavItem {
  name: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
  isMenuTrigger?: boolean;
}

export function MobileBottomNav({ onOpenMenu }: MobileBottomNavProps) {
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

  // 5 Tab untuk Karyawan (Layanan Mandiri ESS)
  const employeeNavItems: NavItem[] = [
    { name: "Dashboard", href: "/dashboard", icon: LayoutGrid },
    { name: "Lembur", href: "/overtime", icon: Clock4 },
    { name: "Cuti", href: "/leaves", icon: CalendarCheck },
    { name: "Slip Gaji", href: "/payroll", icon: CreditCard },
    { name: "Kinerja", href: "/performance", icon: Award },
  ];

  // 5 Tab untuk Admin / HR / Manager / Owner
  const adminNavItems: NavItem[] = [
    { name: "Dashboard", href: "/dashboard", icon: LayoutGrid },
    { name: "Karyawan", href: "/employees", icon: Users },
    { name: "Presensi", href: "/attendance", icon: Clock },
    { name: "Payroll", href: "/payroll", icon: CreditCard },
    { name: "Menu", href: "#menu", icon: Menu, isMenuTrigger: true },
  ];

  const items = isEmployee ? employeeNavItems : adminNavItems;

  return (
    <nav
      aria-label="Navigasi Bawah Mobile"
      className="fixed bottom-0 left-0 right-0 z-40 lg:hidden bg-white/85 backdrop-blur-xl border-t border-slate-200/70 shadow-[0_-1px_10px_rgba(0,0,0,0.03)] px-2 pt-1 pb-safe"
      style={{ paddingBottom: "max(0.5rem, env(safe-area-inset-bottom))" }}
    >
      <div className="grid grid-cols-5 items-center gap-1 max-w-md mx-auto">
        {items.map((item) => {
          if (item.isMenuTrigger) {
            return (
              <button
                key={item.name}
                type="button"
                onClick={onOpenMenu}
                className="flex flex-col items-center justify-center min-h-[48px] py-1 px-1 rounded-2xl text-slate-500 hover:text-slate-900 active:scale-90 transition-transform duration-150 select-none cursor-pointer"
                aria-label="Buka Menu Lainnya"
              >
                <div className="w-8 h-7 flex items-center justify-center rounded-xl">
                  <Menu className="w-5 h-5 text-slate-500 stroke-[1.8]" aria-hidden="true" />
                </div>
                <span className="text-[10px] font-medium leading-tight tracking-tight mt-0.5 text-slate-600">
                  {item.name}
                </span>
              </button>
            );
          }

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
                "relative flex flex-col items-center justify-center min-h-[48px] py-1 px-1 rounded-2xl transition-all duration-150 select-none active:scale-90",
                isActive
                  ? "text-orange-600 font-semibold"
                  : "text-slate-500 hover:text-slate-900 font-medium"
              )}
            >
              <div
                className={cn(
                  "relative w-8 h-7 flex items-center justify-center rounded-xl transition-all duration-200",
                  isActive
                    ? "bg-orange-50 text-orange-600"
                    : "text-slate-400 group-hover:text-slate-600"
                )}
              >
                <Icon
                  className={cn(
                    "w-5 h-5 transition-transform duration-200",
                    isActive
                      ? "stroke-[2.2] scale-105 text-orange-600"
                      : "stroke-[1.75] text-slate-400"
                  )}
                  aria-hidden="true"
                />
              </div>
              <span
                className={cn(
                  "text-[10.5px] leading-tight tracking-tight mt-0.5 truncate max-w-full transition-colors",
                  isActive ? "text-orange-600 font-bold" : "text-slate-500"
                )}
              >
                {item.name}
              </span>
              {isActive && (
                <span
                  className="absolute bottom-0.5 w-1 h-1 rounded-full bg-orange-600"
                  aria-hidden="true"
                />
              )}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
