"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ShieldAlert, ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/Button";
import type { User, UserRole } from "@/types";

export type SystemRole = "superadmin" | "super_admin" | "owner" | "hr" | "manager" | "employee";

interface RoleGuardProps {
  allowedRoles: SystemRole[];
  children: React.ReactNode;
  fallbackTitle?: string;
  fallbackMessage?: string;
}

export function RoleGuard({
  allowedRoles,
  children,
  fallbackTitle = "Akses Dibatasi",
  fallbackMessage = "Halaman ini memerlukan wewenang khusus dan tidak dapat diakses oleh peran akun Anda.",
}: RoleGuardProps) {
  const router = useRouter();
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [isReady, setIsReady] = useState(false);

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
      setIsReady(true);
    }
  }, []);

  if (!isReady) {
    return (
      <div className="flex items-center justify-center min-h-[50vh]">
        <div className="flex items-center gap-2.5 text-xs text-slate-500 font-medium">
          <span className="w-4 h-4 border-2 border-emerald-600 border-t-transparent rounded-full animate-spin" />
          <span>Memverifikasi hak akses...</span>
        </div>
      </div>
    );
  }

  const role = (currentUser?.role?.toLowerCase() || "employee") as SystemRole;
  const isAllowed =
    allowedRoles.includes(role) ||
    (role === "super_admin" && allowedRoles.includes("superadmin")) ||
    (role === "superadmin" && allowedRoles.includes("super_admin"));

  if (!isAllowed) {
    return (
      <div
        role="alert"
        aria-live="polite"
        className="flex flex-col items-center justify-center min-h-[60vh] text-center p-6 max-w-md mx-auto"
      >
        <div className="w-16 h-16 rounded-2xl bg-amber-50 border border-amber-200/80 flex items-center justify-center text-amber-600 mb-4 shadow-2xs">
          <ShieldAlert className="w-8 h-8" aria-hidden="true" />
        </div>
        <h2 className="text-base sm:text-lg font-bold text-slate-900 tracking-tight">
          {fallbackTitle}
        </h2>
        <p className="text-xs sm:text-sm text-slate-500 mt-2 leading-relaxed">
          {fallbackMessage}
        </p>
        <div className="mt-2 inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-slate-100 border border-slate-200 text-[11px] font-semibold text-slate-600">
          <span>Role Akun Anda:</span>
          <span className="capitalize text-slate-900">{currentUser?.role || "Karyawan"}</span>
        </div>

        <div className="mt-6 flex items-center gap-3">
          <Button
            type="button"
            variant="secondary"
            onClick={() => router.back()}
            className="text-xs font-semibold gap-1.5"
          >
            <ArrowLeft className="w-3.5 h-3.5" aria-hidden="true" />
            <span>Kembali</span>
          </Button>
          <Button
            type="button"
            onClick={() => router.push("/dashboard")}
            className="text-xs font-semibold"
          >
            Buka Dashboard
          </Button>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
