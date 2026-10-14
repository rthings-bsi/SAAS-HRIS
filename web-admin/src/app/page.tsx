"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import {
  Mail,
  Lock,
  Eye,
  EyeOff,
  ArrowRight,
  Loader2,
} from "lucide-react";
import apiClient, { ApiError } from "@/lib/axios";
import type { ApiResponse, AuthSession } from "@/types";

export default function CorporateLoginPage() {
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

  return (
    <div className="min-h-screen w-full flex flex-col lg:flex-row bg-white font-sans selection:bg-[#094595] selection:text-white relative overflow-x-hidden">
      {/* ========================================================= */}
      {/* PANEL KIRI: Showcase PT SPINDO & Fitur Sistem (~56% Lebar) */}
      {/* Sesuai Desain Visual Korporat Navy/Green PT SPINDO        */}
      {/* ========================================================= */}
      <div
        className="w-full lg:w-[56%] relative bg-[#EBF5FB] bg-cover bg-no-repeat bg-right flex flex-col justify-between p-8 sm:p-12 lg:p-16 min-h-[580px] lg:min-h-screen overflow-hidden"
        style={{ backgroundImage: "url('/login-bg-spindo.jpg')" }}
      >
        {/* 1. Header Brand & Logo */}
        <div className="relative z-10 flex items-center gap-3.5">
          {/* Logo Mark Squircle Navy */}
          <div className="w-12 h-12 rounded-2xl bg-[#094595] flex items-center justify-center flex-shrink-0 shadow-sm">
            <svg
              viewBox="0 0 32 36"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              className="w-6 h-7"
              aria-hidden="true"
            >
              <circle cx="8" cy="7" r="3.5" fill="#FFFFFF" />
              <rect x="4.5" y="14" width="7" height="18" rx="3.5" fill="#FFFFFF" />
              <rect x="17.5" y="7" width="7" height="25" rx="3.5" fill="#FFFFFF" />
            </svg>
          </div>
          <div>
            <span className="font-extrabold text-xl tracking-tight block text-[#0B3A6F] leading-tight">
              HR HUB
            </span>
            <span className="text-xs text-slate-500 font-medium block">
              HRIS & SPK SMART - Single Company
            </span>
          </div>
        </div>

        {/* 2. Middle Content: Heading, Subtitle, 3 Feature Cards */}
        <div className="relative z-10 my-auto py-8 sm:py-12 max-w-xl">
          {/* Heading */}
          <h1 className="text-4xl sm:text-5xl lg:text-[54px] font-extrabold text-[#0B3A6F] leading-[1.12] tracking-tight">
            Manajemen
            <br />
            SDM & SPK{" "}
            <span className="text-[#22A349]">SMART</span>
          </h1>

          {/* Description */}
          <p className="mt-5 text-sm sm:text-base text-slate-600 leading-relaxed max-w-lg">
            Kelola absensi berbasis radius GPS, administrasi cuti, penggajian, dan
            evaluasi kinerja pegawai menggunakan metode SMART secara mandiri dan
            terintegrasi.
          </p>

          {/* 3 Feature Cards */}
          <div className="mt-8 grid grid-cols-1 sm:grid-cols-3 gap-3 max-w-xl">
            {/* Card 1: Presensi GPS */}
            <div className="bg-[#F0FDF4]/90 backdrop-blur-sm border border-[#DCFCE7] rounded-2xl p-3 flex items-center gap-3 shadow-xs transition-transform hover:-translate-y-0.5">
              <div className="w-9 h-9 rounded-xl bg-white flex items-center justify-center flex-shrink-0 shadow-xs border border-emerald-100">
                <svg className="w-5 h-5 text-[#22A349]" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                  <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5a2.5 2.5 0 1 1 0-5 2.5 2.5 0 0 1 0 5z" />
                </svg>
              </div>
              <div>
                <span className="text-xs font-bold text-[#0B3A6F] block leading-tight">
                  Presensi GPS
                </span>
                <span className="text-[11px] text-slate-500 block leading-tight mt-0.5">
                  Radius kantor
                </span>
              </div>
            </div>

            {/* Card 2: Penggajian */}
            <div className="bg-[#F0FDF4]/90 backdrop-blur-sm border border-[#DCFCE7] rounded-2xl p-3 flex items-center gap-3 shadow-xs transition-transform hover:-translate-y-0.5">
              <div className="w-9 h-9 rounded-xl bg-white flex items-center justify-center flex-shrink-0 shadow-xs border border-emerald-100">
                <svg className="w-5 h-5 text-[#22A349]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z" />
                  <path d="M12 12v5" />
                  <path d="m14.5 14.5-2.5 2.5-2.5-2.5" />
                </svg>
              </div>
              <div>
                <span className="text-xs font-bold text-[#0B3A6F] block leading-tight">
                  Penggajian
                </span>
                <span className="text-[11px] text-slate-500 block leading-tight mt-0.5">
                  Slip digital
                </span>
              </div>
            </div>

            {/* Card 3: SPK SMART */}
            <div className="bg-[#F0FDF4]/90 backdrop-blur-sm border border-[#DCFCE7] rounded-2xl p-3 flex items-center gap-3 shadow-xs transition-transform hover:-translate-y-0.5">
              <div className="w-9 h-9 rounded-xl bg-white flex items-center justify-center flex-shrink-0 shadow-xs border border-emerald-100">
                <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                  <rect x="3" y="12" width="4.5" height="9" rx="1" fill="#0B3A6F" />
                  <rect x="10" y="8" width="4.5" height="13" rx="1" fill="#0B3A6F" />
                  <rect x="17" y="4" width="4.5" height="17" rx="1" fill="#0B3A6F" />
                  <path d="M2 11l6.5-5 6 3.5 7.5-6.5" stroke="#22A349" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </div>
              <div>
                <span className="text-xs font-bold text-[#0B3A6F] block leading-tight">
                  SPK SMART
                </span>
                <span className="text-[11px] text-slate-500 block leading-tight mt-0.5">
                  K1-K4 terbobot
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* 3. Footer di atas Polygon Navy Bawah-Kiri */}
        <div className="relative z-10 pt-6">
          <p className="text-xs text-white font-medium">
            © 2026 HR Hub • HRIS & SPK SMART
          </p>
          <p className="text-[11px] text-white/80 mt-0.5">
            Sistem HRIS Perusahaan
          </p>
        </div>
      </div>

      {/* ========================================================= */}
      {/* PANEL KANAN: Formulir Login Minimalis & Bersih (~44% Lebar) */}
      {/* Sesuai Mockup 11.webp Dengan Aksen Sudut Hijau/Navy        */}
      {/* ========================================================= */}
      <div className="w-full lg:w-[44%] bg-white flex flex-col justify-center items-center p-6 sm:p-12 lg:p-16 relative min-h-screen">
        {/* Aksen Geometris Sudut Kanan Atas */}
        <div className="absolute top-0 right-0 pointer-events-none select-none z-20 w-36 sm:w-44 h-auto">
          <Image
            src="/top-right-accent.png"
            alt=""
            width={176}
            height={150}
            priority
            className="w-full h-auto"
            aria-hidden="true"
          />
        </div>

        {/* Form Container */}
        <div className="w-full max-w-[420px] relative z-10 space-y-6">
          {/* Title */}
          <div>
            <h2 className="text-3xl sm:text-4xl font-extrabold text-[#0B2545] tracking-tight">
              Halo
            </h2>
            <p className="mt-1 text-sm text-slate-500 font-normal">
              Pakai akun HRIS kamu untuk masuk ke sistem
            </p>
          </div>

          {/* Form Login */}
          <form onSubmit={handleSubmit} className="space-y-4">
            {errorMessage && (
              <div
                role="alert"
                className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-xs text-rose-700 font-medium leading-relaxed"
              >
                {errorMessage}
              </div>
            )}

            {/* Input 1: Username / Email */}
            <div>
              <label
                htmlFor="email"
                className="block text-xs font-bold text-[#0B2545] mb-2"
              >
                Username / Email
              </label>
              <div className="relative flex items-center">
                <div className="absolute left-3.5 pointer-events-none text-slate-400">
                  <Mail className="w-4 h-4" aria-hidden="true" />
                </div>
                <input
                  id="email"
                  type="email"
                  required
                  autoComplete="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="rickysatria@hris.com"
                  className="w-full pl-10 pr-4 py-3 rounded-2xl bg-white border border-slate-200 text-slate-800 text-sm focus:outline-none focus:border-[#094595] focus:ring-2 focus:ring-[#094595]/15 transition-all placeholder:text-slate-400 shadow-xs"
                />
              </div>
            </div>

            {/* Input 2: Password */}
            <div>
              <label
                htmlFor="password"
                className="block text-xs font-bold text-[#0B2545] mb-2"
              >
                Password
              </label>
              <div className="relative flex items-center">
                <div className="absolute left-3.5 pointer-events-none text-slate-400">
                  <Lock className="w-4 h-4" aria-hidden="true" />
                </div>
                <input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  required
                  autoComplete="current-password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full pl-10 pr-11 py-3 rounded-2xl bg-white border border-slate-200 text-slate-800 text-sm focus:outline-none focus:border-[#094595] focus:ring-2 focus:ring-[#094595]/15 transition-all placeholder:text-slate-400 shadow-xs"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? "Sembunyikan password" : "Tampilkan password"}
                  className="absolute right-3.5 text-slate-400 hover:text-slate-600 transition-colors p-1 rounded-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#094595]"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Link Lupa Password & Hubungi Admin */}
            <div className="flex items-center justify-end text-xs text-slate-500 pt-1 pb-1">
              <span>Lupa password?</span>
              <span className="mx-1.5 text-slate-300">|</span>
              <button
                type="button"
                onClick={() =>
                  alert(
                    "Silakan hubungi administrator HR atau tim IT internal untuk mereset kata sandi akun Anda."
                  )
                }
                className="text-[#16A34A] hover:text-emerald-700 font-semibold cursor-pointer hover:underline transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-emerald-500 rounded"
              >
                Hubungi Admin
              </button>
            </div>

            {/* Primary Submit Button */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3.5 px-4 rounded-2xl bg-[#094595] hover:bg-[#07387B] active:scale-[0.99] text-white font-bold text-sm transition-all duration-150 flex items-center justify-center gap-2 disabled:opacity-50 cursor-pointer shadow-sm hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#094595] focus-visible:ring-offset-2"
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
        </div>
      </div>
    </div>
  );
}
