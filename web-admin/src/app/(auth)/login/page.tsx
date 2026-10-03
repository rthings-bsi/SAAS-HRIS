"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Mail, KeyRound, Loader2, Eye, EyeOff } from "lucide-react";
import apiClient, { ApiError } from "@/lib/axios";
import type { ApiResponse, AuthSession } from "@/types";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("admin@powerhrm.com");
  const [password, setPassword] = useState("password");
  const [showPassword, setShowPassword] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  React.useEffect(() => {
    if (typeof window !== "undefined") {
      const existingToken = localStorage.getItem("hris_token");
      if (existingToken) {
        router.replace("/dashboard");
      }
    }
  }, [router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    setIsLoading(true);

    try {
      const response = await apiClient.post<ApiResponse<AuthSession>>(
        "/auth/login",
        { email, password }
      );

      const token = response.data.data?.token || response.data.data?.access_token;

      if (response.data.success && token) {
        localStorage.setItem("hris_token", token);
        if (response.data.data?.user) {
          localStorage.setItem("hris_user", JSON.stringify(response.data.data.user));
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

  const handleFillDemo = () => {
    setEmail("admin@powerhrm.com");
    setPassword("password");
  };

  return (
    <main className="relative flex min-h-screen flex-col items-center justify-center bg-gradient-to-b from-orange-50/30 via-[#F8FAFC] to-slate-100/50 px-4 py-8 overflow-hidden">
      {/* Subtle Architectural Dot Matrix */}
      <div className="absolute inset-0 bg-architectural-dots pointer-events-none -z-10" aria-hidden="true" />
      {/* Soft Center Backlight */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-radial from-orange-400/8 via-amber-300/3 to-transparent rounded-full blur-3xl pointer-events-none -z-10" aria-hidden="true" />

      {/* Brand Header */}
      <div className="flex flex-col items-center mb-6">
        <div className="relative w-14 h-14 flex items-center justify-center" aria-hidden="true">
          <svg viewBox="0 0 56 56" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-14 h-14">
            <defs>
              <linearGradient id="hrhub_grad1" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#FB923C" />
                <stop offset="100%" stopColor="#EA580C" />
              </linearGradient>
              <linearGradient id="hrhub_grad2" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#EA580C" />
                <stop offset="100%" stopColor="#C2410C" />
              </linearGradient>
              <linearGradient id="hrhub_ribbon" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#FED7AA" stopOpacity="0.85" />
                <stop offset="100%" stopColor="#FFEDD5" stopOpacity="0.35" />
              </linearGradient>
            </defs>
            {/* Left Dot */}
            <circle cx="18" cy="11" r="4" fill="url(#hrhub_grad1)" />
            {/* Left Capsule */}
            <rect x="14" y="19" width="8" height="23" rx="4" fill="url(#hrhub_grad1)" />
            {/* Translucent Ribbon Connector */}
            <path
              d="M22 26 C 26 22, 28 18, 34 14 C 33 22, 28 30, 22 34 Z"
              fill="url(#hrhub_ribbon)"
            />
            {/* Right Taller Capsule */}
            <rect x="33" y="9" width="9" height="35" rx="4.5" fill="url(#hrhub_grad2)" />
          </svg>
        </div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 mt-2">
          HR Hub
        </h1>
      </div>

      {/* Main Login Card */}
      <div className="w-full max-w-[420px] rounded-3xl border border-slate-200/90 bg-white p-7 sm:p-9 shadow-sm">
        <div className="text-center mb-6">
          <h2 className="text-2xl font-bold tracking-tight text-slate-900">
            Welcome back
          </h2>
          <p className="text-sm text-slate-500 mt-1.5 font-normal">
            Enter your credentials to access your account
          </p>
        </div>

        {errorMessage && (
          <div
            role="alert"
            className="mb-5 rounded-xl border border-rose-200 bg-rose-50 p-3 text-xs text-rose-700 font-medium"
          >
            {errorMessage}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label
              htmlFor="email"
              className="block text-xs font-semibold text-slate-800 mb-1.5"
            >
              Email
            </label>
            <div className="relative flex items-center">
              <span className="absolute left-3.5 text-slate-400 pointer-events-none">
                <Mail className="w-4 h-4" aria-hidden="true" />
              </span>
              <input
                id="email"
                name="email"
                type="email"
                required
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@powerhrm.com"
                className="w-full rounded-xl border border-slate-200 bg-white pl-10 pr-3.5 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20 transition-all font-normal"
              />
            </div>
          </div>

          <div>
            <label
              htmlFor="password"
              className="block text-xs font-semibold text-slate-800 mb-1.5"
            >
              Password
            </label>
            <div className="relative flex items-center">
              <span className="absolute left-3.5 text-slate-400 pointer-events-none">
                <KeyRound className="w-4 h-4" aria-hidden="true" />
              </span>
              <input
                id="password"
                name="password"
                type={showPassword ? "text" : "password"}
                required
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full rounded-xl border border-slate-200 bg-white pl-10 pr-10 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20 transition-all font-normal"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                aria-label={showPassword ? "Sembunyikan kata sandi" : "Tampilkan kata sandi"}
                className="absolute right-3 text-slate-400 hover:text-slate-600 transition-colors p-1 rounded-md cursor-pointer"
              >
                {showPassword ? (
                  <EyeOff className="w-4 h-4" aria-hidden="true" />
                ) : (
                  <Eye className="w-4 h-4" aria-hidden="true" />
                )}
              </button>
            </div>
          </div>

          {/* Primary Submit Button */}
          <button
            type="submit"
            disabled={isLoading}
            className="w-full h-11 mt-2 inline-flex items-center justify-center rounded-xl bg-orange-600 hover:bg-orange-700 active:bg-orange-800 text-white font-semibold text-sm shadow-sm transition-all duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 focus-visible:ring-offset-2 disabled:opacity-60 cursor-pointer"
          >
            {isLoading ? (
              <span className="inline-flex items-center gap-2">
                <Loader2 className="w-4 h-4 animate-spin text-white" aria-hidden="true" />
                <span>Signing in...</span>
              </span>
            ) : (
              <span>Sign In</span>
            )}
          </button>
        </form>

        {/* Demo Credentials Hint */}
        <div className="mt-4 text-center">
          <button
            type="button"
            onClick={handleFillDemo}
            className="text-xs text-slate-500 hover:text-orange-600 transition-colors cursor-pointer"
          >
            Demo credentials pre-filled
          </button>
        </div>

        {/* Tenant Registration Link */}
        <div className="mt-6 pt-4 border-t border-slate-100 text-center text-xs text-slate-500">
          Perusahaan baru?{" "}
          <Link
            href="/register"
            className="font-semibold text-orange-600 hover:text-orange-700 hover:underline focus:outline-none focus:ring-1 focus:ring-orange-600 rounded"
          >
            Daftarkan Perusahaan
          </Link>
        </div>
      </div>
    </main>
  );
}
