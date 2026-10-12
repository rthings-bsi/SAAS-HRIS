"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import {
  Eye,
  EyeOff,
  ArrowRight,
  Loader2,
} from "lucide-react";
import apiClient, { ApiError } from "@/lib/axios";
import type { ApiResponse, AuthSession } from "@/types";

export default function SplitGatewayLandingPage() {
  const router = useRouter();

  const [email, setEmail] = useState("admin@powerhrm.com");
  const [password, setPassword] = useState("password");
  const [showPassword, setShowPassword] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    setIsLoading(true);

    try {
      const response = await apiClient.post<ApiResponse<AuthSession>>(
        "/auth/login",
        { email, password }
      );

      const token =
        response.data.data?.token || response.data.data?.access_token;

      if (response.data.success && token) {
        localStorage.setItem("hris_token", token);
        localStorage.setItem("token", token);
        if (response.data.data?.user) {
          localStorage.setItem(
            "hris_user",
            JSON.stringify(response.data.data.user)
          );
        }
        router.push("/dashboard");
      } else {
        setErrorMessage(response.data.message || "Gagal masuk ke sistem.");
      }
    } catch (err: unknown) {
      if (err instanceof ApiError) {
        if (err.errors) {
          const detailMsgs = Object.values(err.errors).flat().join(" ");
          setErrorMessage(detailMsgs || err.message);
        } else {
          setErrorMessage(err.message);
        }
      } else if (err instanceof Error) {
        setErrorMessage(err.message);
      } else {
        setErrorMessage("Terjadi kesalahan pada koneksi jaringan.");
      }
    } finally {
      setIsLoading(false);
    }
  };

  const handleQuickFill = (fillEmail: string) => {
    setEmail(fillEmail);
    setPassword("password");
    setErrorMessage(null);
  };

  return (
    <div className="min-h-screen w-full flex flex-col lg:flex-row bg-white font-sans selection:bg-orange-500 selection:text-white">
      {/* ========================================================= */}
      {/* KOLOM KIRI: Brand & Showcase Informasi Sistem (50% Lebar) */}
      {/* Sesuai Tema Orange / Slate HR Hub (DESIGN.md & Mobile)    */}
      {/* ========================================================= */}
      <div className="w-full lg:w-1/2 bg-gradient-to-br from-orange-600 via-orange-700 to-slate-900 text-white p-8 sm:p-12 lg:p-16 flex flex-col justify-between relative overflow-hidden min-h-[460px] lg:min-h-screen">
        {/* Subtle Decorative Ambient Shape */}
        <div
          className="absolute -top-24 -right-24 w-96 h-96 rounded-full bg-amber-400/15 blur-3xl pointer-events-none"
          aria-hidden="true"
        />
        <div
          className="absolute -bottom-24 -left-24 w-96 h-96 rounded-full bg-orange-950/40 blur-3xl pointer-events-none"
          aria-hidden="true"
        />

        {/* 1. Header Brand & Logo */}
        <div className="relative z-10">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-white/15 backdrop-blur-sm border border-white/25 flex items-center justify-center flex-shrink-0 shadow-inner">
              <svg
                viewBox="0 0 32 36"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                className="w-6 h-7"
                aria-hidden="true"
              >
                <defs>
                  <linearGradient id="lp_pill_left" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#FED7AA" />
                    <stop offset="100%" stopColor="#FFFFFF" />
                  </linearGradient>
                  <linearGradient id="lp_pill_right" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#FFFFFF" />
                    <stop offset="100%" stopColor="#FDBA74" />
                  </linearGradient>
                </defs>
                <circle cx="8" cy="6" r="3.5" fill="url(#lp_pill_left)" />
                <rect x="4.5" y="14" width="7" height="19" rx="3.5" fill="url(#lp_pill_left)" />
                <rect x="17" y="6" width="7.5" height="27" rx="3.75" fill="url(#lp_pill_right)" />
              </svg>
            </div>
            <div>
              <span className="font-extrabold text-base tracking-wider block uppercase font-mono text-white">
                HR HUB
              </span>
              <span className="text-[11px] text-orange-200 font-medium block">
                HRIS & SPK SMART • Single Company
              </span>
            </div>
          </div>
        </div>

        {/* 2. Middle Content: Tag, Title, Subtitle, Pills */}
        <div className="relative z-10 my-auto py-10 max-w-xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 backdrop-blur-sm border border-white/20 text-orange-100 text-xs font-medium mb-6">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-400" />
            Sistem Kepegawaian & Kinerja
          </div>

          <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold tracking-tight text-white leading-tight">
            Manajemen SDM & SPK SMART
          </h1>

          <p className="mt-4 text-sm sm:text-base text-orange-100/90 leading-relaxed max-w-lg">
            Kelola absensi berbasis radius GPS, administrasi cuti, penggajian, dan evaluasi kinerja pegawai menggunakan metode SMART secara mandiri dan terintegrasi.
          </p>

          {/* 3 Pills Informasi */}
          <div className="mt-8 flex flex-wrap gap-2.5">
            <div className="px-3 py-1.5 rounded-full bg-white/10 backdrop-blur-sm border border-white/15 text-xs text-white font-medium flex items-center gap-1.5">
              <span className="font-semibold">Presensi GPS</span>
              <span className="text-orange-200">Radius kantor</span>
            </div>
            <div className="px-3 py-1.5 rounded-full bg-white/10 backdrop-blur-sm border border-white/15 text-xs text-white font-medium flex items-center gap-1.5">
              <span className="font-semibold">Penggajian</span>
              <span className="text-orange-200">Slip digital</span>
            </div>
            <div className="px-3 py-1.5 rounded-full bg-white/10 backdrop-blur-sm border border-white/15 text-xs text-white font-medium flex items-center gap-1.5">
              <span className="font-semibold">SPK SMART</span>
              <span className="text-orange-200">K1-K4 terbobot</span>
            </div>
          </div>
        </div>

        {/* 3. Footer Kiri */}
        <div className="relative z-10 text-xs text-orange-200/80 font-medium">
          <p>© {new Date().getFullYear()} HR Hub • HRIS & SPK SMART</p>
          <p className="text-[11px] text-orange-200/60 mt-0.5">Sistem Internal Perusahaan</p>
        </div>
      </div>

      {/* ========================================================= */}
      {/* KOLOM KANAN: Login Form Bersih & Minimalis (50% Lebar)    */}
      {/* ========================================================= */}
      <div className="w-full lg:w-1/2 bg-white flex items-center justify-center p-6 sm:p-12 lg:p-16">
        <div className="w-full max-w-md space-y-6">
          {/* Badge & Title */}
          <div>
            <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-orange-50 text-orange-700 border border-orange-200/80 text-xs font-semibold mb-4">
              <span className="w-1.5 h-1.5 rounded-full bg-orange-500" />
              Akses Terbatas
            </div>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              Halo
            </h2>
            <p className="mt-1 text-sm text-slate-500">
              Pakai akun HRIS kamu untuk masuk ke sistem
            </p>
          </div>

          {/* Form Login */}
          <form onSubmit={handleSubmit} className="space-y-4">
            {errorMessage && (
              <div
                role="alert"
                className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-xs text-rose-700 font-medium"
              >
                {errorMessage}
              </div>
            )}

            <div>
              <label
                htmlFor="email"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Username / Email
              </label>
              <input
                id="email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="nama@perusahaan.com"
                className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-sm focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500 focus:bg-white transition-all placeholder:text-slate-400"
              />
            </div>

            <div>
              <label
                htmlFor="password"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Password
              </label>
              <div className="relative">
                <input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-sm focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500 focus:bg-white transition-all pr-11 placeholder:text-slate-400"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? "Sembunyikan password" : "Tampilkan password"}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors p-1"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <div className="text-center pt-1">
              <span className="text-xs text-slate-500">
                Lupa password?{" "}
                <button
                  type="button"
                  onClick={() => alert("Silakan hubungi administrator HR untuk reset password akun Anda.")}
                  className="text-orange-600 hover:text-orange-700 font-semibold underline underline-offset-2 transition-colors"
                >
                  Hubungi Admin
                </button>
              </span>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3 px-4 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-bold text-sm transition-all duration-150 flex items-center justify-center gap-2 disabled:opacity-50 cursor-pointer shadow-sm hover:shadow-md active:scale-[0.99] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-500 focus-visible:ring-offset-2"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>Memverifikasi...</span>
                </>
              ) : (
                <>
                  <span>Masuk</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>

          {/* Quick Login Helper Chips (Untuk Kemudahan Testing) */}
          <div className="pt-4 border-t border-slate-100">
            <span className="text-[11px] font-medium text-slate-400 block mb-2">
              Akun Cepat (Testing):
            </span>
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => handleQuickFill("admin@powerhrm.com")}
                className="px-2.5 py-1 rounded-lg bg-orange-50 hover:bg-orange-100 text-orange-800 border border-orange-200/70 text-xs font-semibold transition-colors"
              >
                Admin Utama
              </button>
              <button
                type="button"
                onClick={() => handleQuickFill("hr@solusidigital.co.id")}
                className="px-2.5 py-1 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-medium transition-colors"
              >
                HR Manager
              </button>
              <button
                type="button"
                onClick={() => handleQuickFill("rickysatria442@gmail.com")}
                className="px-2.5 py-1 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-medium transition-colors"
              >
                Pimpinan
              </button>
              <button
                type="button"
                onClick={() => handleQuickFill("ahmad.fauzi@solusidigital.co.id")}
                className="px-2.5 py-1 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold transition-colors"
              >
                Karyawan (Ahmad)
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
