"use client";

import React, { useState, useEffect, useId } from "react";
import Link from "next/link";
import {
  CheckCircle2,
  XCircle,
  ShieldCheck,
  MapPin,
  Clock,
  CreditCard,
  CalendarCheck,
  ChevronDown,
  Smartphone,
  ChevronRight,
  Check,
  Building2,
  ArrowRight,
  ArrowUp,
  Crosshair,
  ScanFace,
  FileCheck,
  Eye,
  Menu,
  X,
} from "lucide-react";
import { cn, formatRupiah } from "@/lib/utils";

// Types
type HeroTab = "presensi" | "payroll" | "shift" | "cuti";

interface BranchGeo {
  id: string;
  name: string;
  address: string;
  radius: number;
  lat: number;
  lng: number;
  activeEmployees: number;
}

const BRANCH_LOCATIONS: BranchGeo[] = [
  {
    id: "sudirman",
    name: "Kantor Pusat Sudirman",
    address: "Jl. Jend. Sudirman Kav. 52-53, Jakarta Selatan",
    radius: 50,
    lat: -6.2248,
    lng: 106.8085,
    activeEmployees: 34,
  },
  {
    id: "bandung",
    name: "Outlet Cabang Dago",
    address: "Jl. Ir. H. Juanda No. 128, Bandung",
    radius: 35,
    lat: -6.8863,
    lng: 107.6152,
    activeEmployees: 16,
  },
  {
    id: "surabaya",
    name: "Hub Logistik Rungkut",
    address: "Kawasan Industri Rungkut Blok B-14, Surabaya",
    radius: 40,
    lat: -7.3245,
    lng: 112.7681,
    activeEmployees: 22,
  },
];

const faqs = [
  {
    q: "Bagaimana sistem mencegah karyawan menggunakan aplikasi Fake GPS atau Mock Location?",
    a: "Aplikasi mobile Flutter dilengkapi pendeteksi isMocked bawaan sistem operasi. Setiap clock-in memvalidasi sinyal satelit perangkat, mencocokkan koordinat dengan radius cabang terdaftar, serta mewajibkan swafoto kamera langsung tanpa galeri foto.",
  },
  {
    q: "Bagaimana cara kerja penghitungan denda keterlambatan pada payroll?",
    a: "Setiap menit keterlambatan di luar batas toleransi shift diakumulasikan secara otomatis. Formula kalkulasi mengalikan total menit dengan tarif sanksi perusahaan (misal Rp 1.500/menit), lalu langsung memotong take home pay saat periode payroll dihitung.",
  },
  {
    q: "Apakah HR Hub mendukung bisnis multi-cabang dengan jadwal shift berbeda?",
    a: "Ya. Anda dapat mendaftarkan cabang tanpa batas, menentukan radius geofencing per cabang, dan membuat pola shift bergilir (Pagi, Siang, Malam) untuk staf toko, resto, kafe, ataupun tim operasional pabrik.",
  },
  {
    q: "Bagaimana keamanan data antar-perusahaan (Multi-Tenancy) dijamin?",
    a: "Setiap transaksi dan kueri database diisolasi ketat menggunakan parameter id_companies dengan trait BelongsToCompany di tingkat model Laravel 11. Tidak ada data karyawan, riwayat absensi, atau nominal gaji yang dapat diakses oleh penyewa tenant lain.",
  },
  {
    q: "Apakah karyawan dapat mengunduh slip gaji secara mandiri?",
    a: "Ya. Begitu periode payroll difinalisasi oleh HR Admin, sistem otomatis meng-generate slip gaji digital berformat PDF standar resmi yang dapat diakses langsung oleh staf melalui ponsel masing-masing.",
  },
];

interface ShiftProfile {
  name: string;
  hours: string;
  tolerance: string;
  headcount: number;
  branch: string;
  badgeColor: string;
  roster: { name: string; role: string; time: string; status: string; onDuty: boolean }[];
}

const SHIFT_PROFILES: Record<"pagi" | "siang" | "malam", ShiftProfile> = {
  pagi: {
    name: "Shift Pagi",
    hours: "07:00 - 15:00 WIB",
    tolerance: "15 Menit",
    headcount: 14,
    branch: "Sudirman Hub & Dago",
    badgeColor: "bg-orange-50 text-orange-800 border-orange-200",
    roster: [
      { name: "Dimas Anggara", role: "Store Supervisor", time: "06:52 WIB", status: "Tepat Waktu", onDuty: true },
      { name: "Siti Rahma", role: "Kasir Utama", time: "06:55 WIB", status: "Tepat Waktu", onDuty: true },
      { name: "Bayu Setiawan", role: "Head Barista", time: "06:58 WIB", status: "Tepat Waktu", onDuty: true },
      { name: "Rini Safitri", role: "Kitchen Line", time: "07:02 WIB", status: "Telat 2m (Denda Rp 3.000)", onDuty: true },
    ],
  },
  siang: {
    name: "Shift Siang",
    hours: "15:00 - 23:00 WIB",
    tolerance: "15 Menit",
    headcount: 12,
    branch: "Sudirman Hub & Dago",
    badgeColor: "bg-blue-50 text-blue-800 border-blue-200",
    roster: [
      { name: "Ahmad Fauzi", role: "Closing Supervisor", time: "14:45 WIB", status: "Standby Masuk", onDuty: true },
      { name: "Dewi Sartika", role: "Kasir 2", time: "14:48 WIB", status: "Standby Masuk", onDuty: true },
      { name: "Fajar Nugraha", role: "Barista Sore", time: "14:50 WIB", status: "Standby Masuk", onDuty: true },
      { name: "Hendra Wijaya", role: "Kitchen Line 2", time: "14:52 WIB", status: "Standby Masuk", onDuty: true },
    ],
  },
  malam: {
    name: "Shift Malam",
    hours: "23:00 - 07:00 WIB",
    tolerance: "10 Menit",
    headcount: 6,
    branch: "Hub Rungkut (24 Jam)",
    badgeColor: "bg-purple-50 text-purple-800 border-purple-200",
    roster: [
      { name: "Rudi Hartono", role: "Security & Patroli", time: "22:50 WIB", status: "Jadwal Masuk", onDuty: false },
      { name: "Doni Prasetyo", role: "Kitchen & Stok Opname", time: "22:52 WIB", status: "Jadwal Masuk", onDuty: false },
      { name: "Eko Pratama", role: "Cleaning & Maintenance", time: "22:55 WIB", status: "Jadwal Masuk", onDuty: false },
    ],
  },
};

interface LeaveItem {
  id: string;
  name: string;
  role: string;
  type: string;
  duration: string;
  dates: string;
  reason: string;
  balanceBefore: number;
  daysDeducted: number;
  doctorLetter?: boolean;
}

const LEAVE_ITEMS: LeaveItem[] = [
  {
    id: "cuti-1",
    name: "Citra Dewi",
    role: "Staf Administrasi & Keuangan",
    type: "Cuti Tahunan",
    duration: "2 Hari Kerja",
    dates: "04 Mar 2026 - 05 Mar 2026",
    reason: "Urusan keluarga mendesak di luar kota",
    balanceBefore: 10,
    daysDeducted: 2,
  },
  {
    id: "cuti-2",
    name: "Bima Arya",
    role: "Barista Senior (Cabang Sudirman)",
    type: "Izin Sakit Resmi",
    duration: "1 Hari Kerja",
    dates: "06 Mar 2026",
    reason: "Demam berdarah (Surat Keterangan Dokter RS Siloam)",
    balanceBefore: 12,
    daysDeducted: 0,
    doctorLetter: true,
  },
  {
    id: "cuti-3",
    name: "Dian Lestari",
    role: "Kasir Cabang Dago",
    type: "Cuti Khusus (Pernikahan)",
    duration: "3 Hari Kerja",
    dates: "10 Mar 2026 - 12 Mar 2026",
    reason: "Pernikahan pekerja (Sesuai UU Ketenagakerjaan)",
    balanceBefore: 12,
    daysDeducted: 0,
  },
];

export default function LandingPage() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [scrollProgress, setScrollProgress] = useState(0);
  const [isScrolled, setIsScrolled] = useState(false);
  const [showBackToTop, setShowBackToTop] = useState(false);
  const [activeSection, setActiveSection] = useState("hero");

  // Hero Simulator State
  const [heroTab, setHeroTab] = useState<HeroTab>("presensi");
  const [isClockedIn, setIsClockedIn] = useState(false);
  const [clockInTime, setClockInTime] = useState("08:52:14 WIB");
  const [selectedBranch, setSelectedBranch] = useState<BranchGeo>(BRANCH_LOCATIONS[0]);
  const [simulatedDistance, setSimulatedDistance] = useState(24);

  // Interactive Shift Roster State
  const [activeShift, setActiveShift] = useState<"pagi" | "siang" | "malam">("pagi");

  // Interactive Multi-Leave Queue State
  const [selectedLeaveId, setSelectedLeaveId] = useState("cuti-1");
  const [leaveStatuses, setLeaveStatuses] = useState<Record<string, "pending" | "approved" | "rejected">>({
    "cuti-1": "pending",
    "cuti-2": "pending",
    "cuti-3": "pending",
  });

  // Digital Payslip Preview State
  const [showPayslipModal, setShowPayslipModal] = useState(false);

  // Interactive Payroll Demo State
  const [demoBasicSalary, setDemoBasicSalary] = useState(6500000);
  const [demoLateMinutes, setDemoLateMinutes] = useState(25);
  const lateFineRatePerMinute = 1500; // Rp 1.500 per menit keterlambatan
  const demoFixedAllowance = 1200000;
  const demoLateDeduction = demoLateMinutes * lateFineRatePerMinute;
  const demoBpjsTk = Math.round(demoBasicSalary * 0.03); // JHT 2% + JP 1%
  const demoBpjsKes = Math.round(demoBasicSalary * 0.01); // 1%
  const demoTakeHomePay =
    demoBasicSalary + demoFixedAllowance - demoLateDeduction - demoBpjsTk - demoBpjsKes;

  // ROI Calculator State
  const [employeeCount, setEmployeeCount] = useState<number>(35);
  const sliderId = useId();

  // Pricing State
  const [billingCycle, setBillingCycle] = useState<"monthly" | "annually">("annually");

  // FAQ State
  const [openFaqIndex, setOpenFaqIndex] = useState<number | null>(0);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Scroll Progress, Active Spy and Filmic Reveal Observer
  useEffect(() => {
    if (typeof window !== "undefined") {
      const token = localStorage.getItem("hris_token");
      setIsAuthenticated(Boolean(token));

      const handleScroll = () => {
        const totalScroll = document.documentElement.scrollHeight - window.innerHeight;
        const currentScroll = window.scrollY;
        if (totalScroll > 0) {
          setScrollProgress((currentScroll / totalScroll) * 100);
        }
        setIsScrolled(currentScroll > 20);
        setShowBackToTop(currentScroll > 450);
        setMobileMenuOpen(false);

        // Section Spy
        const sections = ["hero", "simulator", "solusi", "kalkulator", "harga", "faq"];
        for (const sec of sections) {
          const el = document.getElementById(sec);
          if (el) {
            const rect = el.getBoundingClientRect();
            if (rect.top <= 200 && rect.bottom >= 200) {
              setActiveSection(sec);
              break;
            }
          }
        }
      };

      window.addEventListener("scroll", handleScroll, { passive: true });

      // Intersection Observer with refined threshold & root margin for silky reveals
      const observer = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              entry.target.classList.add("revealed");
            }
          });
        },
        { threshold: 0.12, rootMargin: "0px 0px -40px 0px" }
      );

      const revealElements = document.querySelectorAll(
        ".scroll-reveal, .scroll-reveal-left, .scroll-reveal-right, .scroll-reveal-scale"
      );
      revealElements.forEach((el) => observer.observe(el));

      return () => {
        window.removeEventListener("scroll", handleScroll);
        revealElements.forEach((el) => observer.unobserve(el));
      };
    }
  }, []);

  // ROI Computations
  const hoursSavedPerMonth = Math.round(employeeCount * 0.75);
  const adminSavingsPerMonth = hoursSavedPerMonth * 55000;
  const payrollLeakageSavings = employeeCount * 95000;
  const totalAnnualSavings = (adminSavingsPerMonth + payrollLeakageSavings) * 12;

  const isWithinRadius = simulatedDistance <= selectedBranch.radius;

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans selection:bg-orange-500 selection:text-white">
      {/* Ambient Top Scroll Progress Indicator */}
      <div
        className="fixed top-0 left-0 right-0 h-[2.5px] bg-slate-200/40 z-[100] pointer-events-none"
        aria-hidden="true"
      >
        <div
          className="h-full bg-gradient-to-r from-orange-500 via-amber-400 to-orange-600 origin-left transition-transform duration-75 ease-out relative"
          style={{ transform: `scaleX(${scrollProgress / 100})` }}
        >
          {/* Leading edge light ping */}
          <div className="absolute right-0 top-1/2 -translate-y-1/2 w-3 h-3 bg-orange-400/80 rounded-full blur-[2px]" />
        </div>
      </div>

      {/* 1. Global Navigation Bar */}
      <header
        className={cn(
          "sticky top-0 z-50 transition-all duration-300",
          isScrolled
            ? "bg-white/80 backdrop-blur-xl border-b border-slate-200/70 shadow-2xs"
            : "bg-white/90 backdrop-blur-md border-b border-slate-200/50"
        )}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          {/* Brand Logo */}
          <Link
            href="/"
            className="flex items-center gap-2.5 group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 rounded-xl p-1 active:scale-95 transition-transform"
          >
            <div className="relative w-7 h-8 flex items-center justify-center flex-shrink-0" aria-hidden="true">
              <svg
                viewBox="0 0 32 36"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                className="w-7 h-8 transition-transform group-hover:scale-105 duration-200"
              >
                <defs>
                  <linearGradient id="brand_pill_l" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#FB923C" />
                    <stop offset="100%" stopColor="#EA580C" />
                  </linearGradient>
                  <linearGradient id="brand_pill_r" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#EA580C" />
                    <stop offset="100%" stopColor="#C2410C" />
                  </linearGradient>
                </defs>
                <circle cx="8" cy="6" r="3.5" fill="url(#brand_pill_l)" />
                <rect x="4.5" y="14" width="7" height="19" rx="3.5" fill="url(#brand_pill_l)" />
                <rect x="17" y="6" width="7.5" height="27" rx="3.75" fill="url(#brand_pill_r)" />
              </svg>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="text-[17px] font-bold tracking-tight text-slate-900 leading-none">
                HR Hub
              </span>
              <span className="px-1.5 py-0.5 text-[9px] font-bold tracking-wider rounded bg-orange-100 text-orange-700 uppercase leading-none">
                SaaS
              </span>
            </div>
          </Link>

          {/* Desktop Navigation Links with Active Scroll Spy */}
          <nav className="hidden lg:flex items-center gap-7 text-xs font-semibold text-slate-600">
            <a
              href="#simulator"
              className={cn(
                "transition-colors py-1 hover:text-orange-600 active:scale-95",
                activeSection === "simulator" ? "text-orange-600 font-bold" : ""
              )}
            >
              Fitur & Demo
            </a>
            <a
              href="#solusi"
              className={cn(
                "transition-colors py-1 hover:text-orange-600 active:scale-95",
                activeSection === "solusi" ? "text-orange-600 font-bold" : ""
              )}
            >
              Keunggulan
            </a>
            <a
              href="#kalkulator"
              className={cn(
                "transition-colors py-1 hover:text-orange-600 active:scale-95",
                activeSection === "kalkulator" ? "text-orange-600 font-bold" : ""
              )}
            >
              Kalkulator Hemat
            </a>
            <a
              href="#harga"
              className={cn(
                "transition-colors py-1 hover:text-orange-600 active:scale-95",
                activeSection === "harga" ? "text-orange-600 font-bold" : ""
              )}
            >
              Paket Harga
            </a>
            <a
              href="#faq"
              className={cn(
                "transition-colors py-1 hover:text-orange-600 active:scale-95",
                activeSection === "faq" ? "text-orange-600 font-bold" : ""
              )}
            >
              FAQ
            </a>
          </nav>

          {/* Auth Action Buttons + Mobile Menu Toggle */}
          <div className="flex items-center gap-2">
            {isAuthenticated ? (
              <Link
                href="/dashboard"
                className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-semibold text-xs shadow-xs transition-all active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600"
              >
                <span>Buka Dashboard</span>
                <ChevronRight className="w-3.5 h-3.5" />
              </Link>
            ) : (
              <>
                <Link
                  href="/login"
                  className="hidden sm:inline-flex px-3 py-1.5 text-xs font-semibold text-slate-700 hover:text-slate-900 hover:bg-slate-100 rounded-xl transition-all active:scale-95"
                >
                  Masuk
                </Link>
                <Link
                  href="/register"
                  className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-semibold text-xs shadow-xs transition-all active:scale-[0.98]"
                >
                  <span>Coba Gratis</span>
                </Link>
              </>
            )}

            {/* Mobile Hamburger Toggle */}
            <button
              type="button"
              aria-label={mobileMenuOpen ? "Tutup menu navigasi" : "Buka menu navigasi"}
              aria-expanded={mobileMenuOpen}
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="lg:hidden p-2 rounded-xl text-slate-600 hover:text-slate-900 hover:bg-slate-100 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600"
            >
              {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {/* Mobile Frosted Glass Drawer */}
        {mobileMenuOpen && (
          <div className="lg:hidden bg-white/95 backdrop-blur-xl border-b border-slate-200/80 px-4 pt-3 pb-5 space-y-3 animate-in fade-in slide-in-from-top-2 duration-200">
            <nav className="flex flex-col space-y-1 text-sm font-medium text-slate-700">
              <a
                href="#simulator"
                onClick={() => setMobileMenuOpen(false)}
                className="px-3 py-2.5 rounded-xl hover:bg-slate-100 hover:text-orange-600 transition-colors flex items-center justify-between"
              >
                <span>Fitur & Demo</span>
                <ChevronRight className="w-4 h-4 text-slate-400" />
              </a>
              <a
                href="#solusi"
                onClick={() => setMobileMenuOpen(false)}
                className="px-3 py-2.5 rounded-xl hover:bg-slate-100 hover:text-orange-600 transition-colors flex items-center justify-between"
              >
                <span>Keunggulan</span>
                <ChevronRight className="w-4 h-4 text-slate-400" />
              </a>
              <a
                href="#kalkulator"
                onClick={() => setMobileMenuOpen(false)}
                className="px-3 py-2.5 rounded-xl hover:bg-slate-100 hover:text-orange-600 transition-colors flex items-center justify-between"
              >
                <span>Kalkulator Hemat</span>
                <ChevronRight className="w-4 h-4 text-slate-400" />
              </a>
              <a
                href="#harga"
                onClick={() => setMobileMenuOpen(false)}
                className="px-3 py-2.5 rounded-xl hover:bg-slate-100 hover:text-orange-600 transition-colors flex items-center justify-between"
              >
                <span>Paket Harga</span>
                <ChevronRight className="w-4 h-4 text-slate-400" />
              </a>
              <a
                href="#faq"
                onClick={() => setMobileMenuOpen(false)}
                className="px-3 py-2.5 rounded-xl hover:bg-slate-100 hover:text-orange-600 transition-colors flex items-center justify-between"
              >
                <span>FAQ</span>
                <ChevronRight className="w-4 h-4 text-slate-400" />
              </a>
            </nav>

            {!isAuthenticated && (
              <div className="pt-2 border-t border-slate-100 flex flex-col gap-2">
                <Link
                  href="/login"
                  onClick={() => setMobileMenuOpen(false)}
                  className="w-full text-center py-2.5 rounded-xl border border-slate-200 text-slate-800 font-semibold text-xs hover:bg-slate-50 transition-colors"
                >
                  Masuk ke Portal Karyawan
                </Link>
                <Link
                  href="/register"
                  onClick={() => setMobileMenuOpen(false)}
                  className="w-full text-center py-2.5 rounded-xl bg-orange-600 text-white font-semibold text-xs shadow-xs hover:bg-orange-700 transition-colors"
                >
                  Daftarkan Perusahaan
                </Link>
              </div>
            )}
          </div>
        )}
      </header>

      {/* 2. Hero Section: Asymmetric, High-Craft Editorial Layout */}
      <section id="hero" className="relative pt-12 pb-16 lg:pt-20 lg:pb-24 border-b border-slate-200/60 bg-gradient-to-b from-orange-50/35 via-white to-slate-50/40 overflow-hidden">
        {/* Subtle Architectural Dot Matrix Underlay */}
        <div className="absolute inset-0 bg-architectural-dots pointer-events-none -z-10" aria-hidden="true" />
        {/* Ambient Warm Hero Orb (Top-Right Depth) */}
        <div className="absolute -top-28 right-0 w-[520px] h-[520px] bg-radial from-orange-500/7 via-orange-400/2 to-transparent rounded-full blur-3xl pointer-events-none -z-10" aria-hidden="true" />
        {/* Soft Ambient Secondary Bloom */}
        <div className="absolute -bottom-20 left-1/4 w-[420px] h-[420px] bg-radial from-amber-400/5 via-orange-300/2 to-transparent rounded-full blur-3xl pointer-events-none -z-10" aria-hidden="true" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            {/* Left Column: Direct Value Proposition (Simple, High-Impact & Clean) */}
            <div className="lg:col-span-6 space-y-6 sm:space-y-7">
              <h1 className="text-4xl sm:text-5xl lg:text-[56px] font-black tracking-tight text-slate-950 leading-[1.12]">
                Lebih dari Solusi, HRIS{" "}
                <span className="block sm:inline">
                  yang <span className="text-orange-600">#BeraniJamin</span>
                </span>
              </h1>

              <p className="text-base sm:text-lg text-slate-600 leading-relaxed font-normal max-w-xl">
                Jelajahi bagaimana HR Hub menjamin keakuratan presensi GPS anti-fake, otomasi rekap shift, dan penggajian tepat waktu tanpa spreadsheet manual.
              </p>

              {/* Direct Simple CTAs */}
              <div className="flex flex-wrap items-center gap-3 pt-2">
                <a
                  href="https://wa.me/6281234567890?text=Halo%20Tim%20HR%20Hub,%20saya%20tertarik%20konsultasi%20layanan%20HRIS"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2.5 px-6 py-3.5 rounded-xl bg-black hover:bg-slate-800 text-white font-bold text-sm shadow-md hover:shadow-lg transition-all duration-200 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 cursor-pointer"
                >
                  <svg
                    viewBox="0 0 24 24"
                    className="w-4 h-4 fill-current text-white shrink-0"
                    aria-hidden="true"
                  >
                    <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c0-5.445 4.43-9.874 9.876-9.874 2.634 0 5.113 1.026 6.974 2.888a9.806 9.806 0 012.894 6.988c0 5.446-4.43 9.875-9.876 9.875m8.409-18.281C18.254 1.309 15.429 0 12.046 0 5.405 0 .007 5.398.005 12.043c-.001 2.124.555 4.197 1.611 6.026L0 24l6.102-1.6c1.767.964 3.754 1.472 5.776 1.472h.005c6.64 0 12.039-5.398 12.042-12.043 0-3.218-1.252-6.244-3.516-8.51" />
                  </svg>
                  <span>Hubungi Sales</span>
                </a>

                <Link
                  href="/register"
                  className="inline-flex items-center gap-2 px-5 py-3.5 rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-slate-800 font-semibold text-sm shadow-2xs transition-all duration-200 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600"
                >
                  <span>Daftarkan Perusahaan</span>
                  <ArrowRight className="w-4 h-4 text-slate-500" />
                </Link>
              </div>
            </div>

            {/* Right Column: Hero Visual Podium with Tilted Phone, Character & Badges (Matching Reference) */}
            <div className="lg:col-span-6 flex flex-col items-center justify-center py-2 relative select-none">
              {/* Main Visual Composition Stage with bounded height and width */}
              <div className="relative w-full max-w-[540px] h-[460px] sm:h-[490px] flex items-center justify-center">
                {/* 1. Giant Warm Circular Backdrop Podium (Positioned to the Right) */}
                <div className="absolute right-0 sm:right-4 top-1/2 -translate-y-1/2 w-[300px] h-[300px] sm:w-[370px] sm:h-[370px] rounded-full bg-gradient-to-tr from-orange-600 via-orange-500 to-amber-400 shadow-2xl shadow-orange-500/25 flex items-center justify-center">
                  {/* Glowing Ambient Halo */}
                  <div
                    className="absolute inset-0 rounded-full bg-orange-500/25 blur-2xl -z-10"
                    aria-hidden="true"
                  />

                  {/* 2. Professional HR Figure - Positioned cleanly inside circle, face 100% visible */}
                  <div className="absolute inset-0 rounded-full overflow-hidden">
                    <img
                      src="/hero-person.png"
                      alt="HR Hub Professional"
                      className="absolute inset-x-0 bottom-0 w-full h-[96%] object-contain object-bottom translate-x-2 sm:translate-x-3.5 scale-105"
                    />
                    {/* Warm Ambient Bottom Vignette */}
                    <div
                      className="absolute inset-0 bg-gradient-to-t from-orange-600/70 via-transparent to-transparent pointer-events-none"
                      aria-hidden="true"
                    />
                  </div>

                  {/* 3. Static High-Craft Verification Badges */}
                  {/* Top-Right Badge: Attendance Security Verified */}
                  <div className="absolute -top-3 right-4 sm:right-8 z-30 w-11 h-11 sm:w-12 sm:h-12 rounded-2xl bg-white border border-slate-200/90 shadow-lg shadow-slate-900/8 flex items-center justify-center">
                    <ShieldCheck className="w-6 h-6 text-orange-600 stroke-[2]" />
                  </div>

                  {/* Bottom-Right Badge: Biometric Face Scan */}
                  <div className="absolute bottom-6 -right-2 sm:right-0 z-30 w-11 h-11 sm:w-12 sm:h-12 rounded-2xl bg-white border border-slate-200/90 shadow-lg shadow-slate-900/8 flex items-center justify-center">
                    <ScanFace className="w-6 h-6 text-emerald-600 stroke-[2]" />
                  </div>
                </div>

                {/* Left-Center Badge: Geofence GPS Radius Valid */}
                <div className="absolute top-[26%] -left-1 sm:left-1 z-30 w-10 h-10 sm:w-11 sm:h-11 rounded-2xl bg-white border border-slate-200/90 shadow-lg shadow-slate-900/8 flex items-center justify-center">
                  <MapPin className="w-5 h-5 text-blue-600 stroke-[2]" />
                </div>

                {/* 4. Foreground Tilted Smartphone Mockup (Shifted to Left, Tilted, NOT covering the face) */}
                <div className="absolute left-2 sm:left-6 top-1/2 -translate-y-1/2 z-20 transform -rotate-6 sm:-rotate-8 hover:rotate-0 transition-transform duration-500 ease-out origin-center">
                  {/* Phone Chassis with High Craft Sheen */}
                  <div className="relative w-[225px] sm:w-[245px] h-[440px] sm:h-[465px] rounded-[42px] p-[7px] bg-gradient-to-b from-slate-700 via-slate-800 to-slate-950 shadow-[0_25px_60px_-15px_rgba(15,23,42,0.45)] ring-1 ring-slate-600/60 flex flex-col">
                    {/* Left Hardware Buttons */}
                    <div className="absolute -left-[3px] top-20 w-[3px] h-5 bg-slate-600 rounded-l-xs shadow-xs" />
                    <div className="absolute -left-[3px] top-28 w-[3px] h-9 bg-slate-600 rounded-l-xs shadow-xs" />
                    <div className="absolute -left-[3px] top-40 w-[3px] h-9 bg-slate-600 rounded-l-xs shadow-xs" />

                    {/* Right Hardware Buttons */}
                    <div className="absolute -right-[3px] top-24 w-[3px] h-12 bg-slate-600 rounded-r-xs shadow-xs" />
                    <div className="absolute -right-[2px] bottom-26 w-[2px] h-10 bg-slate-500/80 rounded-r-xs" />

                    {/* Phone Display Screen */}
                    <div className="relative rounded-[36px] overflow-hidden bg-slate-50 flex flex-col justify-between flex-1 border border-slate-200/50">
                      {/* Top Section: Dynamic Island & iOS Status Bar */}
                      <div className="relative bg-white pt-2 pb-1.5 px-3 flex items-center justify-between border-b border-slate-100">
                        {/* 09:41 Time */}
                        <span className="text-[10px] font-bold font-mono tracking-tight text-slate-900">
                          09:41
                        </span>

                        {/* Dynamic Island */}
                        <div className="w-16 h-[15px] bg-black rounded-full flex items-center justify-between px-1.5 shadow-xs">
                          <div className="w-1.5 h-1.5 rounded-full bg-slate-900 border border-slate-800" />
                          <div className="w-1 h-1 rounded-full bg-emerald-500/90 animate-pulse" />
                        </div>

                        {/* 5G & Battery */}
                        <div className="flex items-center gap-1 text-slate-800">
                          <span className="text-[9px] font-bold">5G</span>
                          <div className="w-3.5 h-2.5 border border-slate-800 rounded-xs p-0.5 flex items-center">
                            <div className="w-full h-full bg-slate-900 rounded-3xs" />
                          </div>
                        </div>
                      </div>

                      {/* App Header Bar */}
                      <div className="bg-white px-3 py-1.5 border-b border-slate-100 flex items-center justify-between">
                        <div>
                          <span className="text-[8.5px] font-bold uppercase tracking-wider text-orange-600 block">
                            HR Hub Mobile
                          </span>
                          <h4 className="text-[11px] font-bold text-slate-900 leading-tight">
                            Ahmad Fauzi
                          </h4>
                          <span className="text-[9px] text-slate-500">
                            Sales Field • Sudirman
                          </span>
                        </div>
                        <div className="w-6 h-6 rounded-full bg-orange-100 text-orange-700 font-bold text-[9.5px] flex items-center justify-center border border-orange-200">
                          AF
                        </div>
                      </div>

                      {/* App Main Body */}
                      <div className="p-2 space-y-1.5 flex-1 flex flex-col justify-between">
                        {/* 1. Live Shift & Clock */}
                        <div className="bg-white rounded-xl p-2 border border-slate-200/80 shadow-2xs space-y-0.5">
                          <div className="flex items-center justify-between text-[9.5px]">
                            <div className="flex items-center gap-1 font-bold text-slate-700">
                              <Clock className="w-3 h-3 text-orange-600" />
                              <span>Shift Pagi</span>
                            </div>
                            <span className="px-1.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 text-[8.5px] font-bold border border-emerald-200">
                              Tepat Waktu
                            </span>
                          </div>

                          <div className="text-center py-0.5">
                            <div className="text-lg font-extrabold text-slate-900 font-mono tracking-tight leading-tight">
                              08:52:14
                            </div>
                            <span className="text-[8.5px] text-slate-500 font-medium block">
                              Jadwal: 08:00 - 17:00 WIB
                            </span>
                          </div>
                        </div>

                        {/* 2. GPS Geofence & Liveness Radar Widget */}
                        <div className="bg-white rounded-xl p-2 border border-slate-200/80 shadow-2xs space-y-1">
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-1.5">
                              <div className="w-5 h-5 rounded-md bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
                                <MapPin className="w-3 h-3" />
                              </div>
                              <div>
                                <div className="text-[10px] font-bold text-slate-900 leading-tight">
                                  Kantor Sudirman
                                </div>
                                <span className="text-[8px] text-slate-500">
                                  Radius: 50m (Aman)
                                </span>
                              </div>
                            </div>
                            <span className="text-[10px] font-mono font-bold text-emerald-700">
                              14m
                            </span>
                          </div>

                          <div className="w-full bg-slate-100 rounded-full h-1 overflow-hidden">
                            <div className="bg-emerald-500 h-full rounded-full w-[28%]" />
                          </div>

                          <div className="flex items-center justify-between text-[8.5px] text-slate-600 pt-0.5">
                            <div className="flex items-center gap-0.5">
                              <CheckCircle2 className="w-2.5 h-2.5 text-emerald-600" />
                              <span>GPS Asli</span>
                            </div>
                            <div className="flex items-center gap-0.5">
                              <ShieldCheck className="w-2.5 h-2.5 text-emerald-600" />
                              <span>Anti-Mock</span>
                            </div>
                          </div>
                        </div>

                        {/* 3. Selfie Liveness Validation Strip */}
                        <div className="bg-white rounded-xl p-1.5 border border-slate-200/80 shadow-2xs flex items-center justify-between text-xs">
                          <div className="flex items-center gap-1.5">
                            <div className="w-4.5 h-4.5 rounded-md bg-orange-50 text-orange-600 flex items-center justify-center font-bold text-[8.5px]">
                              📷
                            </div>
                            <div>
                              <span className="font-bold text-slate-900 block text-[9.5px] leading-tight">
                                Swafoto Wajah
                              </span>
                              <span className="text-[8px] text-slate-500">
                                Kamera Liveness Siap
                              </span>
                            </div>
                          </div>
                          <span className="px-1.5 py-0.5 rounded-md bg-emerald-50 text-emerald-700 text-[8.5px] font-bold border border-emerald-200">
                            ✓ Lolos
                          </span>
                        </div>

                        {/* Tactile Clock-In Button */}
                        <div>
                          <button
                            type="button"
                            onClick={() => {
                              setIsClockedIn(!isClockedIn);
                              setClockInTime(new Date().toLocaleTimeString("id-ID", { hour12: false }) + " WIB");
                            }}
                            className={cn(
                              "w-full py-2 px-2.5 rounded-xl font-bold text-[11px] transition-all duration-150 cursor-pointer flex items-center justify-center gap-1.5 shadow-xs active:scale-[0.98]",
                              isClockedIn
                                ? "bg-emerald-600 hover:bg-emerald-700 text-white"
                                : "bg-orange-600 hover:bg-orange-700 text-white"
                            )}
                          >
                            {isClockedIn ? (
                              <>
                                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-100" />
                                <span>Hadir ({clockInTime})</span>
                              </>
                            ) : (
                              <>
                                <Smartphone className="w-3.5 h-3.5 text-orange-100" />
                                <span>Clock In Sekarang</span>
                              </>
                            )}
                          </button>
                          <span className="block text-center text-[8.5px] text-slate-400 mt-0.5">
                            {isClockedIn ? "Sentuh reset" : "Sentuh untuk simulasi"}
                          </span>
                        </div>
                      </div>

                      {/* Integrated Live HR Telemetry Dock */}
                      <div className="bg-white border-t border-slate-100 px-3 py-1 flex items-center justify-between text-[9px]">
                        <span className="text-slate-500">HR Sinkron:</span>
                        <strong className="text-slate-900 font-mono font-bold">
                          32 / 34 (94%)
                        </strong>
                      </div>

                      {/* iOS Home Indicator Bar */}
                      <div className="bg-white pb-1 flex justify-center">
                        <div className="w-20 h-0.5 bg-slate-900/30 rounded-full" />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* 5. Bottom Module Pill Tags (Crisp, Symmetrical 2-Row Dock Matching Reference) */}
              <div className="mt-8 sm:mt-10 flex flex-col items-center gap-2 z-20 w-full max-w-lg select-none">
                {/* Row 1 (5 items) */}
                <div className="flex items-center justify-center gap-1.5 sm:gap-2">
                  <span className="px-3 sm:px-3.5 py-1.5 rounded-full bg-orange-500 text-white font-bold text-xs shadow-2xs hover:scale-105 active:scale-95 transition-all duration-150 cursor-default select-none">
                    Presensi
                  </span>
                  <span className="px-3 sm:px-3.5 py-1.5 rounded-full bg-slate-800 text-white font-bold text-xs shadow-2xs hover:scale-105 active:scale-95 transition-all duration-150 cursor-default select-none">
                    Shift
                  </span>
                  <span className="px-3 sm:px-3.5 py-1.5 rounded-full bg-slate-800 text-white font-bold text-xs shadow-2xs hover:scale-105 active:scale-95 transition-all duration-150 cursor-default select-none">
                    Cuti
                  </span>
                  <span className="px-3 sm:px-3.5 py-1.5 rounded-full bg-orange-500 text-white font-bold text-xs shadow-2xs hover:scale-105 active:scale-95 transition-all duration-150 cursor-default select-none">
                    Payroll
                  </span>
                  <span className="px-3 sm:px-3.5 py-1.5 rounded-full bg-slate-800 text-white font-bold text-xs shadow-2xs hover:scale-105 active:scale-95 transition-all duration-150 cursor-default select-none">
                    Slip Gaji
                  </span>
                </div>

                {/* Row 2 (5 items) */}
                <div className="flex items-center justify-center gap-1.5 sm:gap-2">
                  <span className="px-3 sm:px-3.5 py-1.5 rounded-full bg-slate-800 text-white font-bold text-xs shadow-2xs hover:scale-105 active:scale-95 transition-all duration-150 cursor-default select-none">
                    Karyawan
                  </span>
                  <span className="px-3 sm:px-3.5 py-1.5 rounded-full bg-orange-500 text-white font-bold text-xs shadow-2xs hover:scale-105 active:scale-95 transition-all duration-150 cursor-default select-none">
                    Geofence
                  </span>
                  <span className="px-3 sm:px-3.5 py-1.5 rounded-full bg-slate-800 text-white font-bold text-xs shadow-2xs hover:scale-105 active:scale-95 transition-all duration-150 cursor-default select-none">
                    Approval
                  </span>
                  <span className="px-3 sm:px-3.5 py-1.5 rounded-full bg-slate-800 text-white font-bold text-xs shadow-2xs hover:scale-105 active:scale-95 transition-all duration-150 cursor-default select-none">
                    Cabang
                  </span>
                  <span className="px-3 sm:px-3.5 py-1.5 rounded-full bg-orange-500 text-white font-bold text-xs shadow-2xs hover:scale-105 active:scale-95 transition-all duration-150 cursor-default select-none">
                    Laporan
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 3. Interactive Multi-Module Simulator Section */}
      <section id="simulator" className="relative py-16 sm:py-20 bg-slate-50/90 border-b border-slate-200/70 overflow-hidden">
        {/* Subtle Central Top Radial Bloom */}
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_0%,rgba(234,88,12,0.035),transparent_65%)] pointer-events-none -z-10" aria-hidden="true" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
          <div className="scroll-reveal text-center max-w-3xl mx-auto mb-10">
          <span className="text-xs font-bold text-orange-600 uppercase tracking-wider mb-2 block">
            Eksplorasi Fitur Langsung
          </span>
          <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
            Workbench Interaktif Operasional HR
          </h2>
          <p className="mt-2 text-sm text-slate-600">
            Pilih modul di bawah untuk menguji logika presensi, perhitungan payroll, manajemen shift, dan approval cuti.
          </p>
        </div>

        {/* Simulator Tabs */}
        <div className="scroll-reveal">
          {/* High-End Segmented Control Pill Bar */}
          <div className="flex justify-center mb-6 sm:mb-8 overflow-x-auto max-w-full py-1">
            <div
              role="tablist"
              aria-label="Modul Workbench HR Hub"
              className="inline-flex items-center gap-1 sm:gap-1.5 p-1.5 rounded-full bg-slate-100/90 border border-slate-200/80 shadow-2xs max-w-full overflow-x-auto"
            >
              {[
                { id: "presensi", label: "Presensi Geofence GPS", icon: MapPin },
                { id: "payroll", label: "Kalkulasi Payroll & PPh 21", icon: CreditCard },
                { id: "shift", label: "Master Jadwal Shift", icon: Clock },
                { id: "cuti", label: "Persetujuan Cuti Digital", icon: CalendarCheck },
              ].map(({ id, label, icon: Icon }) => {
                const isActive = heroTab === id;
                return (
                  <button
                    key={id}
                    type="button"
                    role="tab"
                    id={`tab-${id}`}
                    aria-selected={isActive}
                    aria-controls={`panel-${id}`}
                    onClick={() => setHeroTab(id as HeroTab)}
                    className={cn(
                      "flex items-center gap-2 sm:gap-2.5 rounded-full text-xs sm:text-[13px] transition-all duration-200 cursor-pointer select-none whitespace-nowrap focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 active:scale-95",
                      isActive
                        ? "bg-white text-slate-900 border border-slate-200/90 pl-1.5 pr-4 sm:pr-5 py-1.5 shadow-xs font-bold"
                        : "px-3.5 sm:px-4 py-2 sm:py-2.5 text-slate-600 hover:text-slate-900 hover:bg-slate-200/60 font-semibold"
                    )}
                  >
                    {isActive ? (
                      <div className="w-7 h-7 sm:w-7.5 sm:h-7.5 rounded-full bg-orange-600 text-white flex items-center justify-center shrink-0 shadow-xs">
                        <Icon className="w-3.5 h-3.5 text-white stroke-[2.2]" />
                      </div>
                    ) : (
                      <Icon className="w-4 h-4 text-slate-400 shrink-0 stroke-[1.8]" />
                    )}
                    <span
                      className={cn(
                        isActive
                          ? "font-bold text-slate-900"
                          : "font-semibold text-slate-500"
                      )}
                    >
                      {label}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Dynamic Tab Body */}
          <div>
            {/* Tab 1: Presensi Geofence */}
            {heroTab === "presensi" && (() => {
              // Map coordinate geometry (viewBox 0 0 640 360)
              const mapOfficeX = 320;
              const mapOfficeY = 175;
              const mapRadiusPx = (selectedBranch.radius / 50) * 96;
              const mapStaffDistPx = (simulatedDistance / 50) * 96;
              // Clean 40° downward-right angle prevents any overlap with top-left office label
              const mapAngleRad = 40 * (Math.PI / 180);
              const mapStaffX = mapOfficeX + Math.cos(mapAngleRad) * mapStaffDistPx;
              const mapStaffY = mapOfficeY + Math.sin(mapAngleRad) * mapStaffDistPx;

              const branchStreetInfo: Record<
                string,
                {
                  mainAvenue: string;
                  cross1: string;
                  district: string;
                  city: string;
                  poi1: string;
                  poi2: string;
                  park: string;
                }
              > = {
                sudirman: {
                  mainAvenue: "Jl. Jendral Sudirman",
                  cross1: "Jl. Senopati",
                  district: "Kebayoran Baru",
                  city: "Jakarta Selatan",
                  poi1: "Stasiun MRT Istora Mandiri",
                  poi2: "Pacific Place SCBD",
                  park: "SCBD Urban Park",
                },
                bandung: {
                  mainAvenue: "Jl. Ir. H. Juanda (Dago)",
                  cross1: "Jl. Dipati Ukur",
                  district: "Coblong",
                  city: "Kota Bandung",
                  poi1: "Dago Business Plaza",
                  poi2: "Simpang Dago Mall",
                  park: "Taman Hutan Dago",
                },
                surabaya: {
                  mainAvenue: "Jl. Rungkut Industri",
                  cross1: "Jl. Berbek Industri",
                  district: "Rungkut",
                  city: "Surabaya",
                  poi1: "Sentra Bisnis SIER",
                  poi2: "Transmart Rungkut",
                  park: "Taman Ekosistem SIER",
                },
              };

              const streetData = branchStreetInfo[selectedBranch.id] || branchStreetInfo.sudirman;

              return (
                <div id="panel-presensi" role="tabpanel" aria-labelledby="tab-presensi" className="animate-fade-in-up space-y-5">
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
                    {/* Authentic Google Maps Light Cartography Canvas */}
                    <div className="lg:col-span-7 bg-[#F1F3F4] border border-slate-200/90 rounded-2xl relative overflow-hidden h-[390px] flex flex-col justify-between shadow-md select-none">
                      {/* Real Google Maps Vector Cartography Layer */}
                      <svg
                        className="absolute inset-0 w-full h-full pointer-events-none"
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 640 360"
                        preserveAspectRatio="xMidYMid slice"
                        aria-hidden="true"
                      >
                        <defs>
                          {/* Radial gradient for geofence safe zone */}
                          <radialGradient id="gmap-geofence-glow" cx="50%" cy="50%" r="50%">
                            <stop offset="0%" stopColor="#EA580C" stopOpacity="0.16" />
                            <stop offset="70%" stopColor="#EA580C" stopOpacity="0.08" />
                            <stop offset="100%" stopColor="#EA580C" stopOpacity="0.01" />
                          </radialGradient>

                          {/* Authentic Google Maps building footprint shadow */}
                          <filter id="gmap-building-shadow" x="-5%" y="-5%" width="115%" height="120%">
                            <feDropShadow dx="1" dy="1.5" stdDeviation="1" floodColor="#D0D7DE" floodOpacity="0.65" />
                          </filter>
                        </defs>

                        {/* Google Maps Base Landmass Palette */}
                        <rect width="640" height="360" fill="#F1F3F4" />

                        {/* City Parcels & Architectural Footprints (Google Maps Warm Gray Blocks) */}
                        <g fill="#E8EAED" stroke="#DDE1E5" strokeWidth="0.8" filter="url(#gmap-building-shadow)">
                          {/* Top Quadrant Blocks */}
                          <rect x="20" y="44" width="134" height="98" rx="4" />
                          <rect x="172" y="44" width="94" height="98" rx="4" />
                          <rect x="374" y="44" width="112" height="98" rx="4" />
                          <rect x="504" y="44" width="116" height="98" rx="4" />

                          {/* Bottom Quadrant Blocks */}
                          <rect x="20" y="206" width="134" height="110" rx="4" />
                          <rect x="172" y="206" width="94" height="110" rx="4" />
                          <rect x="374" y="206" width="112" height="110" rx="4" />
                          <rect x="504" y="206" width="116" height="110" rx="4" />
                        </g>

                        {/* Google Maps Lush Green Parks & Foliage (Signature #CEEAD6 Pastel Green) */}
                        <g>
                          <rect x="28" y="52" width="118" height="82" rx="3" fill="#CEEAD6" stroke="#A8DAB5" strokeWidth="0.8" />
                          <circle cx="50" cy="74" r="6" fill="#A8DAB5" opacity="0.6" />
                          <circle cx="70" cy="80" r="8" fill="#A8DAB5" opacity="0.6" />
                          <circle cx="95" cy="72" r="7" fill="#A8DAB5" opacity="0.6" />
                          <text x="40" y="104" fill="#137333" fontSize="8.5" fontWeight="600" letterSpacing="0.2">
                            {streetData.park}
                          </text>

                          <rect x="512" y="214" width="100" height="94" rx="3" fill="#CEEAD6" stroke="#A8DAB5" strokeWidth="0.8" />
                          <circle cx="538" cy="240" r="7" fill="#A8DAB5" opacity="0.6" />
                          <circle cx="565" cy="248" r="9" fill="#A8DAB5" opacity="0.6" />
                          <text x="526" y="278" fill="#137333" fontSize="8" fontWeight="600">
                            Taman Kota
                          </text>
                        </g>

                        {/* Secondary Cross Street (Google Maps White Asphalt Ribbon with Border) */}
                        <g>
                          <rect x="0" y="152" width="640" height="26" fill="#FFFFFF" stroke="#DDE1E5" strokeWidth="1" />
                          <line x1="0" y1="165" x2="640" y2="165" stroke="#F1F3F4" strokeWidth="1.5" strokeDasharray="6 6" />
                          <text x="32" y="168" fill="#5F6368" fontSize="8" fontWeight="500">
                            {streetData.cross1}
                          </text>
                        </g>

                        {/* Primary Central Boulevard (Sudirman White Road Ribbon) */}
                        <g>
                          <rect x="284" y="0" width="72" height="360" fill="#FFFFFF" stroke="#CBD5E1" strokeWidth="1.2" />
                          {/* Lane Dividers */}
                          <line x1="318" y1="0" x2="318" y2="360" stroke="#F1F3F4" strokeWidth="1.5" strokeDasharray="5 5" />
                          <line x1="322" y1="0" x2="322" y2="360" stroke="#F1F3F4" strokeWidth="1.5" strokeDasharray="5 5" />
                          {/* Zebra Crossings */}
                          <g stroke="#CBD5E1" strokeWidth="2" strokeDasharray="3 3">
                            <line x1="288" y1="144" x2="352" y2="144" />
                            <line x1="288" y1="186" x2="352" y2="186" />
                          </g>
                          <text
                            transform="translate(305, 335) rotate(-90)"
                            fill="#3C4043"
                            fontSize="8.5"
                            fontWeight="700"
                            letterSpacing="0.8"
                          >
                            {streetData.mainAvenue}
                          </text>
                        </g>

                        {/* Google Maps Points of Interest (POIs) with Authentic Badges */}
                        <g>
                          {/* MRT Transit Station POI */}
                          <g transform="translate(182, 80)">
                            <rect x="0" y="0" width="18" height="18" rx="9" fill="#E8F0FE" stroke="#4285F4" strokeWidth="0.8" />
                            <text x="9" y="12" textAnchor="middle" fill="#1A73E8" fontSize="8.5" fontWeight="bold">M</text>
                            <text x="24" y="12" fill="#3C4043" fontSize="8" fontWeight="600">{streetData.poi1}</text>
                          </g>

                          {/* Commercial Center POI */}
                          <g transform="translate(384, 80)">
                            <rect x="0" y="0" width="18" height="18" rx="9" fill="#FEF7E0" stroke="#F9AB00" strokeWidth="0.8" />
                            <text x="9" y="12" textAnchor="middle" fill="#E37400" fontSize="8.5" fontWeight="bold">★</text>
                            <text x="24" y="12" fill="#3C4043" fontSize="8" fontWeight="600">{streetData.poi2}</text>
                          </g>
                        </g>

                        {/* Radar Pulse Animation (Subtle Orange Geofence Waves) */}
                        <circle
                          cx={mapOfficeX}
                          cy={mapOfficeY}
                          r={mapRadiusPx}
                          fill="none"
                          stroke={isWithinRadius ? "rgba(234, 88, 12, 0.35)" : "rgba(225, 29, 72, 0.35)"}
                          strokeWidth="2"
                          className="animate-geofence-ping"
                        />

                        {/* Geofence Perimeter Safe Zone */}
                        <circle
                          cx={mapOfficeX}
                          cy={mapOfficeY}
                          r={mapRadiusPx}
                          fill="url(#gmap-geofence-glow)"
                          stroke={isWithinRadius ? "#EA580C" : "#E11D48"}
                          strokeWidth="2"
                          strokeDasharray="6 4"
                        />

                        {/* Google Maps Route Caliper Line (Walking route from staff to office) */}
                        <line
                          x1={mapOfficeX}
                          y1={mapOfficeY}
                          x2={mapStaffX}
                          y2={mapStaffY}
                          stroke={isWithinRadius ? "#1A73E8" : "#E11D48"}
                          strokeWidth="3"
                          strokeLinecap="round"
                          strokeDasharray="6 5"
                        />

                        {/* Geofence Radius Limit Tag */}
                        <g transform={`translate(${mapOfficeX}, ${mapOfficeY - mapRadiusPx - 4})`}>
                          <rect
                            x="-34"
                            y="-9"
                            width="68"
                            height="18"
                            rx="9"
                            fill="#FFFFFF"
                            stroke="#EA580C"
                            strokeWidth="1.2"
                            filter="url(#gmap-building-shadow)"
                          />
                          <text
                            x="0"
                            y="3.5"
                            textAnchor="middle"
                            fill="#EA580C"
                            fontSize="8"
                            fontWeight="800"
                            fontFamily="monospace"
                          >
                            RADIUS {selectedBranch.radius}M
                          </text>
                        </g>
                      </svg>

                      {/* Google Maps Top Search & Place Card */}
                      <div className="relative z-10 p-3 flex items-center justify-between pointer-events-auto">
                        {/* Floating Place Card (Google Maps Search Bar Look) */}
                        <div className="bg-white rounded-xl shadow-md border border-slate-200/90 px-3.5 py-2 flex items-center gap-2.5 max-w-[280px] sm:max-w-none">
                          <div className="w-7 h-7 rounded-lg bg-orange-600 text-white flex items-center justify-center shrink-0 shadow-2xs">
                            <Building2 className="w-4 h-4" />
                          </div>
                          <div className="min-w-0">
                            <div className="flex items-center gap-1.5">
                              <span className="font-bold text-slate-900 text-xs truncate">
                                {selectedBranch.name}
                              </span>
                              <span className="px-1.5 py-0.2 rounded-full text-[9px] font-mono bg-orange-50 text-orange-700 font-bold border border-orange-200 shrink-0">
                                {selectedBranch.radius}m
                              </span>
                            </div>
                            <span className="text-[10.5px] text-slate-500 truncate block">
                              {streetData.mainAvenue}, {streetData.district}
                            </span>
                          </div>
                        </div>

                        {/* Google Maps Map Layer / Compass Widget */}
                        <div className="hidden sm:flex items-center gap-1.5 bg-white rounded-xl shadow-md border border-slate-200/90 p-1">
                          <div className="w-7 h-7 rounded-lg bg-slate-50 text-slate-700 flex items-center justify-center font-bold text-xs shadow-2xs border border-slate-200" title="Arah Utara">
                            <span className="text-rose-600 font-black font-mono">N</span>
                          </div>
                          <div className="px-2 py-1 text-[10px] font-semibold text-slate-600 flex items-center gap-1">
                            <Crosshair className="w-3 h-3 text-emerald-600" />
                            <span>GPS L1/L5</span>
                          </div>
                        </div>
                      </div>

                      {/* Iconic Google Maps Office Destination Marker (Red Teardrop Pin) */}
                      <div
                        className="absolute z-20 pointer-events-none -translate-x-1/2 -translate-y-full flex flex-col items-center"
                        style={{ left: `${(mapOfficeX / 640) * 100}%`, top: `${(mapOfficeY / 360) * 100}%` }}
                      >
                        {/* Office Floating Place Label */}
                        <div className="px-2.5 py-1 rounded-lg bg-white text-slate-900 text-[10px] font-bold shadow-md flex items-center gap-1.5 border border-slate-200/90 whitespace-nowrap mb-1">
                          <span className="w-2 h-2 rounded-full bg-orange-500" />
                          <span>Titik Kantor: {selectedBranch.name.replace("Kantor Pusat ", "").replace("Outlet Cabang ", "").replace("Hub Logistik ", "")}</span>
                        </div>

                        {/* Google Maps Teardrop SVG Pin */}
                        <svg width="28" height="36" viewBox="0 0 28 36" fill="none" className="drop-shadow-md">
                          <path
                            d="M14 0C6.268 0 0 6.268 0 14C0 24.5 14 36 14 36C14 36 28 24.5 28 14C28 6.268 21.732 0 14 0Z"
                            fill="#EA4335"
                          />
                          <circle cx="14" cy="14" r="6" fill="#FFFFFF" />
                          <circle cx="14" cy="14" r="3" fill="#EA4335" />
                        </svg>
                      </div>

                      {/* Iconic Google Maps User Location Puck (Blue Pulsing Location Marker) */}
                      <div
                        className="absolute z-20 pointer-events-none -translate-x-1/2 -translate-y-1/2 transition-all duration-300"
                        style={{ left: `${(mapStaffX / 640) * 100}%`, top: `${(mapStaffY / 360) * 100}%` }}
                      >
                        {/* Blue Accuracy Ring (Google Maps Style) */}
                        <div className="relative flex items-center justify-center">
                          <span
                            className={cn(
                              "absolute w-8 h-8 rounded-full animate-ping opacity-60",
                              isWithinRadius ? "bg-blue-400" : "bg-rose-400"
                            )}
                          />
                          {/* Inner Glowing Accuracy Halo */}
                          <div
                            className={cn(
                              "w-8 h-8 rounded-full absolute",
                              isWithinRadius ? "bg-blue-500/20" : "bg-rose-500/20"
                            )}
                          />
                          {/* Solid Google Blue Puck with White Border */}
                          <div
                            className={cn(
                              "relative w-5 h-5 rounded-full border-2 border-white shadow-md flex items-center justify-center text-white transition-colors duration-200",
                              isWithinRadius ? "bg-[#1A73E8]" : "bg-rose-600"
                            )}
                          >
                            <div className="w-1.5 h-1.5 rounded-full bg-white" />
                          </div>
                        </div>

                        {/* Staff Floating Callout Pill */}
                        <div className="absolute left-1/2 -translate-x-1/2 top-6 whitespace-nowrap">
                          <div
                            className={cn(
                              "px-2.5 py-1 rounded-lg text-[9.5px] font-bold shadow-md flex items-center gap-1.5 border bg-white",
                              isWithinRadius
                                ? "text-slate-900 border-blue-200"
                                : "text-rose-900 border-rose-200"
                            )}
                          >
                            <span className={cn("w-2 h-2 rounded-full", isWithinRadius ? "bg-blue-600" : "bg-rose-600")} />
                            <span>Staf: {simulatedDistance}m ({isWithinRadius ? "Valid" : "Di Luar"})</span>
                          </div>
                        </div>
                      </div>

                      {/* Floating Telemetry HUD Card (Top Left Inside Canvas) */}
                      <div className="absolute left-3 top-16 z-10 pointer-events-none">
                        <div className="bg-white/95 backdrop-blur-md border border-slate-200/90 rounded-xl p-2.5 shadow-md text-slate-800 space-y-1">
                          <div className="text-[9px] font-mono text-slate-500 uppercase tracking-wider font-semibold">
                            Radius Geofence GPS
                          </div>
                          <div className="flex items-baseline gap-1.5">
                            <span className={cn(
                              "text-lg font-mono font-black",
                              isWithinRadius ? "text-emerald-600" : "text-rose-600"
                            )}>
                              {simulatedDistance}m
                            </span>
                            <span className="text-[10px] text-slate-500 font-mono">
                              / batas {selectedBranch.radius}m
                            </span>
                          </div>
                          <div className="flex items-center gap-1 text-[9.5px] font-semibold">
                            <span className={cn("w-1.5 h-1.5 rounded-full", isWithinRadius ? "bg-emerald-500" : "bg-rose-500")} />
                            <span className={isWithinRadius ? "text-emerald-700" : "text-rose-700"}>
                              {isWithinRadius ? "Diizinkan Clock-In" : "Di Luar Zona Resmi"}
                            </span>
                          </div>
                        </div>
                      </div>

                      {/* Google Maps Bottom Bar: Zoom & Attribution Strip */}
                      <div className="relative z-10 flex items-center justify-between text-xs p-2.5 bg-white/95 backdrop-blur-md border-t border-slate-200/90 rounded-b-2xl">
                        {/* Live Distance Status */}
                        <div className="flex items-center gap-2 font-mono text-[11px] text-slate-700">
                          <span className="relative flex h-2 w-2">
                            <span className={cn("animate-ping absolute inline-flex h-full w-full rounded-full opacity-75", isWithinRadius ? "bg-emerald-400" : "bg-rose-400")} />
                            <span className={cn("relative inline-flex rounded-full h-2 w-2", isWithinRadius ? "bg-emerald-500" : "bg-rose-500")} />
                          </span>
                          <span>
                            Jarak: <strong className="text-slate-900 font-bold">{simulatedDistance}m</strong> / Maks {selectedBranch.radius}m
                          </span>
                        </div>

                        {/* Status Verification Pill */}
                        <div className="flex items-center gap-2">
                          <span
                            className={cn(
                              "font-bold px-2.5 py-0.5 rounded-full text-[10px] flex items-center gap-1 shadow-2xs tracking-wide",
                              isWithinRadius
                                ? "bg-emerald-50 text-emerald-800 border border-emerald-200"
                                : "bg-rose-50 text-rose-800 border border-rose-200"
                            )}
                          >
                            {isWithinRadius ? <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" /> : <XCircle className="w-3.5 h-3.5 text-rose-600" />}
                            <span>{isWithinRadius ? "RADIUS TERVERIFIKASI" : "DI LUAR RADIUS"}</span>
                          </span>

                          {/* Google Attribution Watermark */}
                          <span className="hidden sm:inline text-[9px] font-sans text-slate-400 font-medium">
                            Google Maps Cartography
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Right Control & Live Verification Workbench */}
                    <div className="lg:col-span-5 space-y-4">
                      {/* Branch Switcher: Segmented Cards */}
                      <div>
                        <div className="text-xs font-semibold text-slate-700 mb-1.5 flex items-center justify-between">
                          <span>Lokasi Kantor Cabang:</span>
                          <span className="text-[11px] text-slate-500 font-mono">Radius Toleransi</span>
                        </div>
                        <div className="grid grid-cols-3 gap-2">
                          {BRANCH_LOCATIONS.map((b) => {
                            const isSelected = selectedBranch.id === b.id;
                            const shortCity = b.id === "sudirman" ? "Sudirman" : b.id === "bandung" ? "Dago" : "Rungkut";
                            const fullCity = b.id === "sudirman" ? "Jakarta" : b.id === "bandung" ? "Bandung" : "Surabaya";

                            return (
                              <button
                                key={b.id}
                                type="button"
                                onClick={() => setSelectedBranch(b)}
                                className={cn(
                                  "p-2.5 rounded-xl text-left transition-all border cursor-pointer flex flex-col justify-between select-none",
                                  isSelected
                                    ? "bg-orange-50/80 border-orange-500 text-orange-950 font-bold shadow-xs ring-1 ring-orange-400/40"
                                    : "bg-white border-slate-200 text-slate-700 hover:bg-slate-50 hover:border-slate-300"
                                )}
                              >
                                <div>
                                  <div className="text-xs font-bold text-slate-900 truncate">
                                    {shortCity}
                                  </div>
                                  <div className="text-[10px] text-slate-500 truncate">
                                    {fullCity}
                                  </div>
                                </div>
                                <span className={cn(
                                  "mt-2 inline-block text-[9.5px] font-mono font-bold px-1.5 py-0.5 rounded-md w-fit",
                                  isSelected ? "bg-orange-100 text-orange-800" : "bg-slate-100 text-slate-600"
                                )}>
                                  {b.radius}m
                                </span>
                              </button>
                            );
                          })}
                        </div>
                      </div>

                      {/* Interactive Tactical Distance Controller */}
                      <div className="bg-white p-4 rounded-2xl border border-slate-200/90 shadow-2xs space-y-2.5">
                        <div className="flex justify-between items-center text-xs font-semibold text-slate-700">
                          <span>Simulasi Posisi GPS Staf:</span>
                          <span className={cn(
                            "font-mono font-extrabold text-sm px-2.5 py-0.5 rounded-lg border",
                            isWithinRadius
                              ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                              : "bg-rose-50 text-rose-700 border-rose-200"
                          )}>
                            {simulatedDistance} Meter
                          </span>
                        </div>

                        {/* Draggable Slider Bar */}
                        <input
                          id="sim-geo-range"
                          type="range"
                          min="5"
                          max="80"
                          step="5"
                          value={simulatedDistance}
                          onChange={(e) => setSimulatedDistance(Number(e.target.value))}
                          className="w-full h-2 bg-slate-100 rounded-lg appearance-none cursor-pointer accent-orange-600"
                        />

                        {/* One-Touch Quick Scenario Presets */}
                        <div className="flex items-center gap-1.5 pt-0.5">
                          {[
                            { label: "10m (Meja Kerja)", val: 10 },
                            { label: "30m (Lobi Depan)", val: 30 },
                            { label: "65m (Di Luar Radius)", val: 65 },
                          ].map(({ label, val }) => (
                            <button
                              key={val}
                              type="button"
                              onClick={() => setSimulatedDistance(val)}
                              className={cn(
                                "flex-1 py-1.5 rounded-lg text-[10px] font-semibold border transition-all cursor-pointer text-center",
                                simulatedDistance === val
                                  ? "bg-slate-900 text-white border-slate-900 shadow-2xs"
                                  : "bg-slate-50 text-slate-600 border-slate-200 hover:bg-slate-100"
                              )}
                            >
                              {label}
                            </button>
                          ))}
                        </div>
                      </div>

                      {/* Live Security Verification & Immediate Action Test */}
                      <div className={cn(
                        "p-4 rounded-2xl border text-xs space-y-3 transition-colors",
                        isWithinRadius
                          ? "bg-emerald-50/70 border-emerald-200/90 text-emerald-950"
                          : "bg-rose-50/70 border-rose-200/90 text-rose-950"
                      )}>
                        <div className="flex items-center justify-between font-bold">
                          <div className="flex items-center gap-1.5">
                            {isWithinRadius ? (
                              <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                            ) : (
                              <XCircle className="w-4 h-4 text-rose-600 shrink-0" />
                            )}
                            <span className="text-xs">
                              {isWithinRadius
                                ? "Presensi Diizinkan (Lolos Geofencing)"
                                : "Presensi Ditolak Otomatis (Out of Bounds)"}
                            </span>
                          </div>
                          <span className={cn(
                            "text-[9px] uppercase font-mono px-2 py-0.5 rounded-full font-bold shrink-0",
                            isWithinRadius ? "bg-emerald-100 text-emerald-800" : "bg-rose-100 text-rose-800"
                          )}>
                            {isWithinRadius ? "Sinyal Valid" : "Di Luar Batas"}
                          </span>
                        </div>

                        <p className="text-[11px] leading-relaxed text-slate-600">
                          {isWithinRadius
                            ? `Staf berada pada jarak ${simulatedDistance}m dari titik nol (toleransi cabang: ${selectedBranch.radius}m). Sensor hardware GPS lolos anti-mock dan swafoto wajah dapat dikirim.`
                            : `Staf berjarak ${simulatedDistance}m, melampaui batas toleransi ${selectedBranch.radius}m. Tombol presensi otomatis terkunci untuk mencegah absensi titip nama.`}
                        </p>

                        <div className="pt-2 border-t border-slate-200/70 flex items-center justify-between text-[10px] text-slate-500 font-mono">
                          <span>Anti-Fake GPS: <strong className="text-emerald-700">Terproteksi</strong></span>
                          <span>Sinkronisasi: <strong className="text-slate-700">Real-time Cloud</strong></span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })()}

            {/* Tab 2: Payroll Engine */}
            {heroTab === "payroll" && (
              <div id="panel-payroll" role="tabpanel" aria-labelledby="tab-payroll" className="animate-fade-in-up space-y-5">
                <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-center">
                  <div className="md:col-span-6 bg-white border border-slate-200 shadow-2xs p-5 sm:p-6 rounded-2xl space-y-3 font-mono text-xs text-slate-800">
                    <div className="flex justify-between border-b border-slate-200 pb-2.5">
                      <div className="flex flex-col">
                        <span className="font-bold text-slate-900 text-sm">Rian Pratama</span>
                        <span className="text-[11px] text-slate-500 font-sans">NIP: EMP-2024-0089 • Staf Operasional Gudang</span>
                      </div>
                      <span className="text-[11px] px-2.5 py-0.5 rounded bg-slate-100 text-slate-700 h-fit font-sans font-semibold border border-slate-200">
                        Periode Mar 2026
                      </span>
                    </div>
                    <div className="flex justify-between text-slate-700">
                      <span>Gaji Pokok:</span>
                      <span className="font-bold text-slate-900">{formatRupiah(demoBasicSalary)}</span>
                    </div>
                    <div className="flex justify-between text-slate-700">
                      <span>Tunjangan Tetap:</span>
                      <span className="font-bold text-slate-900">{formatRupiah(demoFixedAllowance)}</span>
                    </div>
                    <div className="flex justify-between text-rose-600">
                      <span>Denda Telat ({demoLateMinutes}m x Rp 1.500):</span>
                      <span className="font-bold">- {formatRupiah(demoLateDeduction)}</span>
                    </div>
                    <div className="flex justify-between text-rose-600">
                      <span>BPJS Ketenagakerjaan (3%):</span>
                      <span className="font-bold">- {formatRupiah(demoBpjsTk)}</span>
                    </div>
                    <div className="flex justify-between text-rose-600">
                      <span>BPJS Kesehatan (1%):</span>
                      <span className="font-bold">- {formatRupiah(demoBpjsKes)}</span>
                    </div>
                    <div className="pt-3 border-t border-slate-200 flex justify-between text-sm font-bold text-emerald-800 bg-emerald-50/80 -mx-2 px-3 py-2 rounded-xl border border-emerald-100">
                      <span>Take Home Pay:</span>
                      <span>{formatRupiah(demoTakeHomePay)}</span>
                    </div>

                    <div className="pt-2">
                      <button
                        type="button"
                        onClick={() => setShowPayslipModal(true)}
                        className="w-full py-2 px-3 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-sans font-semibold text-xs transition-colors flex items-center justify-center gap-2 cursor-pointer shadow-xs"
                      >
                        <Eye className="w-3.5 h-3.5 text-orange-400" />
                        <span>Lihat Pratinjau Slip Gaji PDF Resmi</span>
                      </button>
                    </div>
                  </div>

                  <div className="md:col-span-6 space-y-4">
                    <div>
                      <div className="flex justify-between text-xs font-semibold text-slate-700 mb-1.5">
                        <label htmlFor="sim-salary">Simulasi Gaji Pokok:</label>
                        <span className="font-mono text-slate-900 font-bold">{formatRupiah(demoBasicSalary)}</span>
                      </div>
                      <input
                        id="sim-salary"
                        type="range"
                        min="3000000"
                        max="15000000"
                        step="500000"
                        value={demoBasicSalary}
                        onChange={(e) => setDemoBasicSalary(Number(e.target.value))}
                        className="w-full h-2.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-orange-600"
                      />
                    </div>

                    <div>
                      <div className="flex justify-between text-xs font-semibold text-slate-700 mb-1.5">
                        <label htmlFor="sim-late">Keterlambatan Akumulatif:</label>
                        <span className="font-mono text-rose-600 font-bold">{demoLateMinutes} Menit</span>
                      </div>
                      <input
                        id="sim-late"
                        type="range"
                        min="0"
                        max="120"
                        step="5"
                        value={demoLateMinutes}
                        onChange={(e) => setDemoLateMinutes(Number(e.target.value))}
                        className="w-full h-2.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-rose-600"
                      />
                    </div>

                    <div className="bg-slate-50 border border-slate-200/80 rounded-xl p-3 text-xs text-slate-600 space-y-1">
                      <div className="font-semibold text-slate-900 flex items-center gap-1.5">
                        <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                        <span>Kepatuhan Regulasi Indonesia:</span>
                      </div>
                      <p className="text-[11px] leading-relaxed">
                        Rumus pemotongan BPJS Ketenagakerjaan (JHT 2% + JP 1%) dan BPJS Kesehatan (1%) terhitung otomatis sesuai PP No. 44/2015 tanpa formula manual spreadsheet.
                      </p>
                    </div>
                  </div>
                </div>

                {/* Digital Payslip Modal Preview */}
                {showPayslipModal && (
                  <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs animate-fade-in-up">
                    <div className="bg-white rounded-3xl border border-slate-200 shadow-2xl max-w-lg w-full p-6 sm:p-7 space-y-4 relative">
                      <button
                        type="button"
                        onClick={() => setShowPayslipModal(false)}
                        className="absolute top-4 right-4 p-1.5 rounded-full text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
                        aria-label="Tutup pratinjau"
                      >
                        <XCircle className="w-5 h-5" />
                      </button>

                      <div className="border-b border-slate-200 pb-3">
                        <div className="flex items-center justify-between">
                          <div>
                            <span className="text-xs font-bold text-orange-600 font-mono tracking-wider uppercase">
                              HR Hub Digital Slip
                            </span>
                            <h3 className="text-base font-extrabold text-slate-900">
                              SLIP GAJI KARYAWAN
                            </h3>
                          </div>
                          <span className="text-[10px] font-mono font-bold px-2 py-0.5 rounded bg-emerald-100 text-emerald-800 border border-emerald-200">
                            DIGITAL VERIFIED
                          </span>
                        </div>
                        <p className="text-xs text-slate-500 mt-1">
                          Periode Pembayaran: 01 Maret 2026 s/d 31 Maret 2026
                        </p>
                      </div>

                      <div className="grid grid-cols-2 gap-2 text-xs font-mono bg-slate-50 p-3 rounded-xl border border-slate-200/80">
                        <div>
                          <span className="text-slate-400 text-[10px] block">NAMA KARYAWAN:</span>
                          <span className="font-bold text-slate-900">Rian Pratama</span>
                        </div>
                        <div>
                          <span className="text-slate-400 text-[10px] block">NOMOR INDUK PEGAWAI:</span>
                          <span className="font-bold text-slate-900">EMP-2024-0089</span>
                        </div>
                        <div>
                          <span className="text-slate-400 text-[10px] block">JABATAN & CABANG:</span>
                          <span className="font-bold text-slate-900">Gudang / Sudirman Hub</span>
                        </div>
                        <div>
                          <span className="text-slate-400 text-[10px] block">TANGGAL TRANSFER:</span>
                          <span className="font-bold text-slate-900">28 Maret 2026</span>
                        </div>
                      </div>

                      <div className="space-y-1.5 text-xs font-mono border-t border-b border-slate-100 py-3">
                        <div className="flex justify-between text-slate-700">
                          <span>Gaji Pokok Bulanan:</span>
                          <span className="font-bold text-slate-900">{formatRupiah(demoBasicSalary)}</span>
                        </div>
                        <div className="flex justify-between text-slate-700">
                          <span>Tunjangan Tetap Operasional:</span>
                          <span className="font-bold text-slate-900">{formatRupiah(demoFixedAllowance)}</span>
                        </div>
                        <div className="flex justify-between text-rose-600">
                          <span>Denda Telat ({demoLateMinutes}m x Rp 1.500):</span>
                          <span className="font-bold">- {formatRupiah(demoLateDeduction)}</span>
                        </div>
                        <div className="flex justify-between text-rose-600">
                          <span>BPJS Ketenagakerjaan (3% JHT+JP):</span>
                          <span className="font-bold">- {formatRupiah(demoBpjsTk)}</span>
                        </div>
                        <div className="flex justify-between text-rose-600">
                          <span>BPJS Kesehatan (1% Karyawan):</span>
                          <span className="font-bold">- {formatRupiah(demoBpjsKes)}</span>
                        </div>
                        <div className="pt-2 border-t border-slate-200 flex justify-between text-sm font-bold text-slate-900">
                          <span>Gaji Bersih (Take Home Pay):</span>
                          <span className="text-emerald-700">{formatRupiah(demoTakeHomePay)}</span>
                        </div>
                      </div>

                      <div className="flex items-center justify-between text-[10px] text-slate-400 font-mono">
                        <span>Otentikasi: SHA256-SANCTUM-VERIFIED</span>
                        <button
                          type="button"
                          onClick={() => setShowPayslipModal(false)}
                          className="px-3 py-1.5 rounded-lg bg-orange-600 text-white font-sans font-bold text-xs hover:bg-orange-700 transition-colors cursor-pointer"
                        >
                          Tutup Pratinjau
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Tab 3: Shift Management */}
            {heroTab === "shift" && (
              <div id="panel-shift" role="tabpanel" aria-labelledby="tab-shift" className="animate-fade-in-up space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div className="text-xs font-bold text-slate-900">
                    Pilih Pola Shift Operasional:
                  </div>
                  <span className="text-[11px] text-slate-500 font-mono">
                    Rotasi otomatis sinkron dengan GPS cabang
                  </span>
                </div>

                {/* Interactive Shift Selector Cards */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  {(["pagi", "siang", "malam"] as const).map((shiftKey) => {
                    const prof = SHIFT_PROFILES[shiftKey];
                    const isSelected = activeShift === shiftKey;

                    return (
                      <button
                        key={shiftKey}
                        type="button"
                        onClick={() => setActiveShift(shiftKey)}
                        className={cn(
                          "p-4 rounded-2xl border text-left transition-all cursor-pointer flex flex-col justify-between",
                          isSelected
                            ? "bg-white border-orange-500 shadow-md ring-2 ring-orange-500/20"
                            : "bg-slate-50 border-slate-200 text-slate-700 hover:bg-white hover:border-slate-300 shadow-2xs"
                        )}
                      >
                        <div className="flex items-center justify-between">
                          <span className="font-bold text-xs text-slate-900">{prof.name}</span>
                          <span className={cn(
                            "px-2 py-0.5 rounded text-[10px] font-mono font-semibold border",
                            prof.badgeColor
                          )}>
                            {prof.hours}
                          </span>
                        </div>
                        <div className="mt-3 flex items-baseline justify-between">
                          <span className="text-xl font-bold font-mono text-slate-900">{prof.headcount} Orang</span>
                          <span className="text-[10px] text-slate-500 font-mono">Tol. {prof.tolerance}</span>
                        </div>
                      </button>
                    );
                  })}
                </div>

                {/* Active Roster List for Selected Shift */}
                <div className="bg-white border border-slate-200/90 rounded-2xl p-4 sm:p-5 shadow-2xs space-y-3">
                  <div className="flex items-center justify-between border-b border-slate-100 pb-2.5">
                    <div className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                      <span className="text-xs font-bold text-slate-900">
                        Daftar Staf Bertugas: {SHIFT_PROFILES[activeShift].name} ({SHIFT_PROFILES[activeShift].hours})
                      </span>
                    </div>
                    <span className="text-[11px] font-mono text-slate-500 hidden sm:inline">
                      Cabang: {SHIFT_PROFILES[activeShift].branch}
                    </span>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                    {SHIFT_PROFILES[activeShift].roster.map((staf, idx) => (
                      <div
                        key={idx}
                        className="flex items-center justify-between p-3 rounded-xl bg-slate-50 border border-slate-200/80 text-xs"
                      >
                        <div>
                          <div className="font-bold text-slate-900">{staf.name}</div>
                          <div className="text-[10px] text-slate-500">{staf.role}</div>
                        </div>
                        <div className="text-right">
                          <span className={cn(
                            "px-2 py-0.5 rounded text-[10px] font-mono font-bold inline-block",
                            staf.onDuty
                              ? "bg-emerald-100 text-emerald-800 border border-emerald-200"
                              : "bg-slate-200 text-slate-700 border border-slate-300"
                          )}>
                            {staf.status}
                          </span>
                          <div className="text-[9px] text-slate-400 font-mono mt-0.5">{staf.time}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Tab 4: Cuti & Izin */}
            {heroTab === "cuti" && (
              <div id="panel-cuti" role="tabpanel" aria-labelledby="tab-cuti" className="animate-fade-in-up space-y-4">
                <div className="text-xs font-bold text-slate-900 mb-1">
                  Antrean Permohonan Cuti & Izin Karyawan:
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
                  {/* Left Column: Request Selector Cards */}
                  <div className="lg:col-span-5 space-y-2">
                    {LEAVE_ITEMS.map((item) => {
                      const isSelected = selectedLeaveId === item.id;
                      const status = leaveStatuses[item.id];

                      return (
                        <button
                          key={item.id}
                          type="button"
                          onClick={() => setSelectedLeaveId(item.id)}
                          className={cn(
                            "w-full p-3 rounded-xl text-left border transition-all cursor-pointer flex flex-col justify-between",
                            isSelected
                              ? "bg-white border-orange-500 shadow-xs ring-1 ring-orange-400/40"
                              : "bg-slate-50 border-slate-200 hover:bg-white hover:border-slate-300"
                          )}
                        >
                          <div className="flex items-center justify-between">
                            <span className="font-bold text-xs text-slate-900">{item.name}</span>
                            <span className={cn(
                              "text-[10px] font-mono font-bold px-2 py-0.5 rounded-full",
                              status === "approved"
                                ? "bg-emerald-100 text-emerald-800"
                                : status === "rejected"
                                ? "bg-rose-100 text-rose-800"
                                : "bg-amber-100 text-amber-800"
                            )}>
                              {status === "approved" ? "Disetujui" : status === "rejected" ? "Ditolak" : "Menunggu"}
                            </span>
                          </div>
                          <div className="text-[11px] text-slate-500 mt-1 flex justify-between">
                            <span>{item.type}</span>
                            <span className="font-mono">{item.duration}</span>
                          </div>
                        </button>
                      );
                    })}
                  </div>

                  {/* Right Column: Approval Workbench Details */}
                  {(() => {
                    const currentItem = LEAVE_ITEMS.find((it) => it.id === selectedLeaveId) || LEAVE_ITEMS[0];
                    const currentStatus = leaveStatuses[currentItem.id];

                    return (
                      <div className="lg:col-span-7 bg-white border border-slate-200/90 rounded-2xl p-5 shadow-2xs space-y-3.5 flex flex-col justify-between">
                        <div>
                          <div className="flex items-start justify-between border-b border-slate-100 pb-3">
                            <div>
                              <span className="text-[10px] font-mono font-bold text-orange-600 uppercase tracking-wider">
                                {currentItem.type}
                              </span>
                              <h3 className="text-sm font-bold text-slate-900">{currentItem.name}</h3>
                              <p className="text-[11px] text-slate-500">{currentItem.role}</p>
                            </div>
                            <span className="text-xs font-mono font-bold px-2.5 py-1 rounded-lg bg-slate-100 text-slate-700 border border-slate-200">
                              {currentItem.duration}
                            </span>
                          </div>

                          <div className="mt-3 space-y-2 text-xs">
                            <div className="flex items-center justify-between text-slate-600">
                              <span>Tanggal Pelaksanaan:</span>
                              <span className="font-mono font-semibold text-slate-900">{currentItem.dates}</span>
                            </div>
                            <div className="flex items-center justify-between text-slate-600">
                              <span>Alasan Pengajuan:</span>
                              <span className="font-medium text-slate-800 italic">{currentItem.reason}</span>
                            </div>
                            {currentItem.doctorLetter && (
                              <div className="flex items-center justify-between text-emerald-700 bg-emerald-50 p-2 rounded-lg border border-emerald-100">
                                <span className="flex items-center gap-1.5">
                                  <FileCheck className="w-3.5 h-3.5 text-emerald-600" />
                                  <span>Dokumen Pendukung:</span>
                                </span>
                                <span className="font-mono font-bold text-[11px]">Surat_Dokter_Valid.pdf</span>
                              </div>
                            )}

                            {/* Live Quota Calculator */}
                            <div className="pt-2 border-t border-slate-100 flex items-center justify-between font-mono text-xs">
                              <span className="text-slate-500">Saldo Cuti Tahunan:</span>
                              <span className="font-bold text-slate-900">
                                {currentItem.balanceBefore} Hari
                                {currentStatus === "approved" && currentItem.daysDeducted > 0 && (
                                  <span className="text-emerald-700"> → {currentItem.balanceBefore - currentItem.daysDeducted} Hari</span>
                                )}
                              </span>
                            </div>
                          </div>
                        </div>

                        {/* Action Buttons */}
                        <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-2">
                          {currentStatus === "pending" ? (
                            <>
                              <button
                                type="button"
                                onClick={() => setLeaveStatuses((prev) => ({ ...prev, [currentItem.id]: "rejected" }))}
                                className="px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-rose-50 text-slate-700 hover:text-rose-700 font-bold text-xs transition-colors cursor-pointer border border-slate-200"
                              >
                                Tolak Permohonan
                              </button>
                              <button
                                type="button"
                                onClick={() => setLeaveStatuses((prev) => ({ ...prev, [currentItem.id]: "approved" }))}
                                className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs transition-colors cursor-pointer shadow-xs"
                              >
                                Setujui & Potong Saldo
                              </button>
                            </>
                          ) : (
                            <div className="flex items-center justify-between w-full">
                              <span className={cn(
                                "px-3 py-1 rounded-full text-xs font-bold font-mono",
                                currentStatus === "approved" ? "bg-emerald-100 text-emerald-800" : "bg-rose-100 text-rose-800"
                              )}>
                                {currentStatus === "approved" ? "Permohonan Berhasil Disetujui" : "Permohonan Ditolak"}
                              </span>
                              <button
                                type="button"
                                onClick={() => setLeaveStatuses((prev) => ({ ...prev, [currentItem.id]: "pending" }))}
                                className="text-xs text-slate-500 hover:text-slate-800 underline cursor-pointer"
                              >
                                Ubah Keputusan
                              </button>
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })()}
                </div>
              </div>
            )}
          </div>
        </div>
        </div>
      </section>

      {/* 4. Solusi & Keunggulan Nyata Bisnis (Asymmetric Flagship Layout, Anti-Slop R-14) */}
      <section id="solusi" className="relative py-16 sm:py-20 bg-gradient-to-b from-white via-slate-50/25 to-white border-b border-slate-200/80 overflow-hidden">
        {/* Soft Ambient Light Wash */}
        <div className="absolute top-1/2 left-0 w-80 h-80 bg-radial from-orange-400/4 to-transparent rounded-full blur-3xl pointer-events-none -z-10" aria-hidden="true" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
          <div className="scroll-reveal text-center max-w-3xl mx-auto mb-14">
            <span className="text-xs font-bold text-orange-600 uppercase tracking-wider mb-2 block font-mono">
              Solusi Operasional Terpadu
            </span>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              Tiga Alasan Pemilik Usaha Beralih ke HR Hub
            </h2>
            <p className="mt-2 text-sm text-slate-600 leading-relaxed">
              Singkirkan spreadsheet yang rawan salah rumus dan grup WhatsApp yang berantakan. Bangun disiplin kerja tanpa menambah beban staf administrasi.
            </p>
          </div>

          {/* Asymmetric Flagship Showcase */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
            {/* Flagship Hero Card (7 Cols) */}
            <div className="scroll-reveal-left lg:col-span-7 bg-white border border-slate-200/90 rounded-3xl p-6 sm:p-8 flex flex-col justify-between shadow-2xs hover:border-slate-300 transition-all">
              <div>
                <div className="flex flex-wrap items-center justify-between gap-2 mb-6">
                  <div className="flex items-center gap-2">
                    <div className="w-10 h-10 rounded-xl bg-orange-100 text-orange-700 flex items-center justify-center font-bold">
                      <MapPin className="w-5 h-5 text-orange-600" />
                    </div>
                    <div>
                      <span className="text-[10px] font-mono font-bold px-2 py-0.5 rounded bg-orange-50 text-orange-700 border border-orange-200 uppercase">
                        Flagship Engine
                      </span>
                      <span className="text-xs font-bold text-slate-900 block mt-0.5">
                        Presensi Lapangan & Kantor
                      </span>
                    </div>
                  </div>
                  <span className="text-[11px] font-mono font-semibold px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 flex items-center gap-1.5">
                    <ShieldCheck className="w-3.5 h-3.5" />
                    <span>Hardware Anti-Mock Level 3</span>
                  </span>
                </div>

                <h3 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight leading-snug">
                  Validasi Titik GPS & Anti-Mock Ketat dengan Swafoto Langsung
                </h3>
                <p className="mt-3 text-xs sm:text-sm text-slate-600 leading-relaxed">
                  Karyawan hanya bisa melakukan presensi jika berada tepat dalam radius meter cabang resmi perusahaan. Sistem memeriksa status <code>isMocked</code> perangkat secara native, memblokir aplikasi Fake GPS, dan mewajibkan kamera depan aktif secara langsung tanpa akses galeri foto.
                </p>

                {/* Telemetry Indicator Component */}
                <div className="mt-6 p-4 rounded-2xl bg-slate-50 border border-slate-200/80 space-y-3 font-mono text-xs">
                  <div className="flex items-center justify-between border-b border-slate-200/70 pb-2.5">
                    <span className="text-slate-500 text-[11px]">STATUS RADAR CABANG:</span>
                    <span className="font-bold text-slate-900">Sudirman Central (R: 50m)</span>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 text-[11px]">
                    <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                      <span className="text-slate-400 block text-[10px]">AKURASI GPS:</span>
                      <span className="font-bold text-slate-900">± 3.2 Meter</span>
                    </div>
                    <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                      <span className="text-slate-400 block text-[10px]">FAKE GPS GUARD:</span>
                      <span className="font-bold text-emerald-700">DITOLAK OTOMATIS</span>
                    </div>
                    <div className="bg-white p-2.5 rounded-xl border border-slate-200">
                      <span className="text-slate-400 block text-[10px]">VERIFIKASI WAJAH:</span>
                      <span className="font-bold text-slate-900">Sensor Kamera Asli</span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="pt-6 mt-6 border-t border-slate-100 flex items-center justify-between text-xs">
                <span className="text-slate-500 font-medium">
                  Tersedia di aplikasi mobile Android & iOS native karyawan
                </span>
                <a
                  href="#simulator"
                  onClick={() => setHeroTab("presensi")}
                  className="font-bold text-orange-600 hover:text-orange-700 flex items-center gap-1 font-sans transition-colors cursor-pointer"
                >
                  <span>Lihat Demo Peta</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </a>
              </div>
            </div>

            {/* Stacked Supporting Operational Pillars (5 Cols) */}
            <div className="lg:col-span-5 flex flex-col justify-between gap-6">
              {/* Pilar 2 */}
              <div className="scroll-reveal-right stagger-1 flex-1 bg-white border border-slate-200/90 rounded-3xl p-6 sm:p-7 flex flex-col justify-between shadow-2xs hover:border-slate-300 transition-all">
                <div>
                  <div className="flex items-center justify-between mb-3">
                    <div className="w-9 h-9 rounded-xl bg-emerald-100 text-emerald-800 flex items-center justify-center font-bold">
                      <CreditCard className="w-4 h-4 text-emerald-600" />
                    </div>
                    <span className="text-[10px] font-mono font-bold px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 border border-emerald-200">
                      PP NO. 44/2015
                    </span>
                  </div>
                  <h3 className="text-base sm:text-lg font-bold text-slate-900 mb-2">
                    Kalkulasi Penggajian & Denda Telat Akurat
                  </h3>
                  <p className="text-xs text-slate-600 leading-relaxed">
                    Menit keterlambatan akumulatif otomatis dipotong sesuai tarif per menit yang ditentukan perusahaan. Formula BPJS Ketenagakerjaan (3%) dan BPJS Kesehatan (1%) terhitung otomatis dan siap cetak PDF.
                  </p>
                </div>
                <div className="pt-4 mt-4 border-t border-slate-100 flex items-center gap-2 text-xs text-slate-700 font-medium">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                  <span>Karyawan unduh slip gaji PDF mandiri di ponsel</span>
                </div>
              </div>

              {/* Pilar 3 */}
              <div className="scroll-reveal-right stagger-2 flex-1 bg-white border border-slate-200/90 rounded-3xl p-6 sm:p-7 flex flex-col justify-between shadow-2xs hover:border-slate-300 transition-all">
                <div>
                  <div className="flex items-center justify-between mb-3">
                    <div className="w-9 h-9 rounded-xl bg-blue-100 text-blue-800 flex items-center justify-center font-bold">
                      <Clock className="w-4 h-4 text-blue-600" />
                    </div>
                    <span className="text-[10px] font-mono font-bold px-2 py-0.5 rounded bg-blue-50 text-blue-700 border border-blue-200">
                      MULTI-CABANG
                    </span>
                  </div>
                  <h3 className="text-base sm:text-lg font-bold text-slate-900 mb-2">
                    Master Shift Ritel & Persetujuan Cuti 1-Klik
                  </h3>
                  <p className="text-xs text-slate-600 leading-relaxed">
                    Pola kerja bergilir (Pagi, Siang, Malam) fleksibel untuk outlet toko, restoran, dan staf lapangan. Pengajuan izin sakit dilengkapi lampiran surat dokter dan saldo cuti terpotong tanpa selisih.
                  </p>
                </div>
                <div className="pt-4 mt-4 border-t border-slate-100 flex items-center gap-2 text-xs text-slate-700 font-medium">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                  <span>Sinkronisasi otomatis antar cabang dan manajer</span>
                </div>
              </div>
            </div>
          </div>

          <div className="mt-12 text-center">
            <a
              href="#kalkulator"
              className="inline-flex items-center gap-2 text-xs sm:text-sm font-bold text-orange-600 hover:text-orange-700 transition-colors p-2"
            >
              <span>Hitung estimasi penghematan jam kerja & biaya operasional Anda</span>
              <ChevronDown className="w-4 h-4" />
            </a>
          </div>
        </div>
      </section>

      {/* 7. Interactive ROI & Cost Savings Calculator */}
      <section id="kalkulator" className="relative py-16 sm:py-20 bg-gradient-to-b from-slate-100/70 via-slate-50/80 to-slate-100/60 border-b border-slate-200/80 overflow-hidden">
        {/* Localized Warm Glow Behind Right Calculator Card */}
        <div className="absolute right-0 top-1/2 -translate-y-1/2 w-96 h-96 bg-radial from-orange-400/8 via-amber-300/3 to-transparent rounded-full blur-3xl pointer-events-none -z-10" aria-hidden="true" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 items-center">
            <div className="scroll-reveal-left lg:col-span-5 space-y-4">
              <span className="px-3 py-1 rounded-full bg-orange-100 text-orange-800 text-xs font-bold border border-orange-200 inline-block">
                Simulasi Efisiensi
              </span>
              <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight leading-tight">
                Berapa Biaya & Jam Kerja yang Bisa Dihemat Bisnis Anda?
              </h2>
              <p className="text-slate-600 text-xs sm:text-sm leading-relaxed">
                Kalkulasi efisiensi berdasarkan rata-rata 45 menit/karyawan/bulan untuk rekapitulasi data kehadiran dan eliminasi human-error pada payroll.
              </p>

              <div className="pt-4 space-y-2 text-xs text-slate-700 border-t border-slate-200">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                  <span>Dihitung berdasarkan standar upah administratif per jam</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                  <span>Pencegahan kebocoran denda telat yang lolos dari rekap</span>
                </div>
              </div>
            </div>

            <div className="scroll-reveal-right lg:col-span-7 bg-white border border-slate-200 rounded-2xl p-6 sm:p-8 shadow-xs">
              <div className="mb-6">
                <div className="flex items-center justify-between mb-2">
                  <label htmlFor={sliderId} className="text-xs font-bold text-slate-900">
                    Jumlah Karyawan Aktif Perusahaan
                  </label>
                  <span className="text-xl font-bold text-orange-600 font-mono">
                    {employeeCount} Orang
                  </span>
                </div>
                <input
                  id={sliderId}
                  type="range"
                  min="5"
                  max="200"
                  step="5"
                  value={employeeCount}
                  onChange={(e) => setEmployeeCount(Number(e.target.value))}
                  aria-valuemin={5}
                  aria-valuemax={200}
                  aria-valuenow={employeeCount}
                  className="w-full h-2.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-orange-600"
                />
                <div className="flex justify-between text-[11px] text-slate-500 mt-1.5 font-mono">
                  <span>5 Pegawai</span>
                  <span>100 Pegawai</span>
                  <span>200+ Pegawai</span>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="rounded-xl bg-slate-50 border border-slate-200 p-4">
                  <span className="text-xs text-slate-500 font-semibold block">
                    Waktu HR Terhemat
                  </span>
                  <div className="text-2xl font-extrabold text-slate-900 mt-1 font-mono">
                    ~{hoursSavedPerMonth} Jam / Bulan
                  </div>
                  <span className="text-[11px] text-emerald-700 mt-1 block font-medium">
                    Bisa dialihkan untuk pengembangan tim
                  </span>
                </div>

                <div className="rounded-xl bg-slate-50 border border-slate-200 p-4">
                  <span className="text-xs text-slate-500 font-semibold block">
                    Efisiensi Biaya Operasional
                  </span>
                  <div className="text-2xl font-extrabold text-orange-600 mt-1 font-mono truncate">
                    {formatRupiah(adminSavingsPerMonth)}
                  </div>
                  <span className="text-[11px] text-slate-500 mt-1 block">
                    Estimasi penghematan beban admin bulanan
                  </span>
                </div>

                <div className="sm:col-span-2 rounded-xl bg-orange-50/80 border border-orange-200 p-4 flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <span className="text-xs text-orange-950 font-semibold block">
                      Estimasi Net Benefit Tahunan (Efisiensi Jam + Payroll)
                    </span>
                    <div className="text-xl sm:text-2xl font-bold text-slate-900 font-mono mt-0.5">
                      {formatRupiah(totalAnnualSavings)} / tahun
                    </div>
                  </div>
                  <Link
                    href="/register"
                    className="px-4 py-2 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-bold text-xs transition-colors shadow-xs"
                  >
                    Mulai Hemat Sekarang
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 8. Pricing Section with Smooth Sliding Toggle */}
      <section id="harga" className="relative py-16 sm:py-20 bg-slate-50/70 border-b border-slate-200/70 overflow-hidden">
        {/* Subtle Ambient Warm Glow behind recommended tier */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[640px] h-[360px] bg-radial from-orange-400/6 via-amber-300/2 to-transparent rounded-full blur-3xl pointer-events-none -z-10" aria-hidden="true" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
          <div className="scroll-reveal text-center max-w-3xl mx-auto mb-10">
          <span className="text-xs font-bold text-orange-600 uppercase tracking-wider mb-2 block">
            Paket Investasi
          </span>
          <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
            Biaya Transparan Sesuai Skala Bisnis
          </h2>
          <p className="mt-2 text-sm text-slate-600">
            Tanpa biaya setup tersembunyi. Upgrade atau ubah paket kapan saja saat skala operasional bertambah.
          </p>

          <div className="mt-6 inline-flex items-center p-1 rounded-full bg-slate-200/80 border border-slate-300/80 shadow-2xs">
            <button
              type="button"
              onClick={() => setBillingCycle("monthly")}
              className={cn(
                "px-4 py-2 rounded-full text-xs font-semibold transition-all cursor-pointer active:scale-95 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600",
                billingCycle === "monthly"
                  ? "bg-white text-slate-900 shadow-xs"
                  : "text-slate-600 hover:text-slate-900"
              )}
            >
              Tagihan Bulanan
            </button>
            <button
              type="button"
              onClick={() => setBillingCycle("annually")}
              className={cn(
                "px-4 py-2 rounded-full text-xs font-semibold transition-all cursor-pointer flex items-center gap-1.5 active:scale-95 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600",
                billingCycle === "annually"
                  ? "bg-orange-600 text-white shadow-xs"
                  : "text-slate-600 hover:text-slate-900"
              )}
            >
              <span>Tagihan Tahunan</span>
              <span className={cn(
                "px-2 py-0.5 rounded-full text-[10px] font-bold uppercase",
                billingCycle === "annually" ? "bg-white text-orange-600" : "bg-orange-100 text-orange-700"
              )}>
                Diskon 20%
              </span>
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 items-stretch">
          {/* Plan 1: Starter */}
          <div className="scroll-reveal stagger-1 rounded-2xl border border-slate-200/80 bg-white/95 backdrop-blur-sm p-6 sm:p-7 shadow-[0_1px_3px_rgba(0,0,0,0.03),0_1px_2px_rgba(0,0,0,0.02)] flex flex-col justify-between">
            <div>
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                Usaha Mikro / Starter
              </span>
              <h3 className="text-xl font-bold text-slate-900 mt-1">Starter Pack</h3>
              <p className="text-xs text-slate-500 mt-1.5">
                Kedai, kafe, toko ruko, atau bisnis rintisan baru.
              </p>

              <div className="mt-5 mb-5 font-mono">
                <span className="text-3xl font-extrabold text-slate-900">
                  {billingCycle === "annually" ? "Rp 79.000" : "Rp 99.000"}
                </span>
                <span className="text-xs text-slate-500 font-sans"> / bulan</span>
              </div>

              <div className="space-y-2.5 text-xs text-slate-700 border-t border-slate-100 pt-5">
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Hingga 15 Karyawan Aktif</span>
                </div>
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Presensi GPS & Swafoto Selfie</span>
                </div>
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Maksimal 2 Lokasi Cabang</span>
                </div>
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Pengajuan & Saldo Cuti</span>
                </div>
                <div className="flex items-center gap-2 text-slate-400">
                  <XCircle className="w-3.5 h-3.5 shrink-0" />
                  <span>Kalkulasi Payroll Terotomasi</span>
                </div>
              </div>
            </div>

            <Link
              href="/register?plan=starter"
              className="mt-6 w-full py-2.5 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-800 font-bold text-xs text-center transition-all duration-150 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 block shadow-2xs"
            >
              Pilih Paket Starter
            </Link>
          </div>

          {/* Plan 2: Growth Pro */}
          <div className="scroll-reveal-scale stagger-2 rounded-2xl border-2 border-orange-500 bg-white/95 backdrop-blur-sm p-6 sm:p-7 shadow-md flex flex-col justify-between relative">
            <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-0.5 rounded-full bg-orange-600 text-white text-[10px] font-bold uppercase tracking-wider shadow-xs">
              Rekomendasi Utama
            </div>

            <div>
              <span className="text-[11px] font-bold text-orange-600 uppercase tracking-wider">
                Bisnis Berkembang
              </span>
              <h3 className="text-xl font-bold text-slate-900 mt-1">Growth Pro</h3>
              <p className="text-xs text-slate-500 mt-1.5">
                Otomatiskan seluruh operasional harian dan kalkulasi payroll.
              </p>

              <div className="mt-5 mb-5 font-mono">
                <span className="text-3xl font-extrabold text-slate-900">
                  {billingCycle === "annually" ? "Rp 199.000" : "Rp 249.000"}
                </span>
                <span className="text-xs text-slate-500 font-sans"> / bulan</span>
              </div>

              <div className="space-y-2.5 text-xs text-slate-800 font-medium border-t border-slate-100 pt-5">
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-orange-600 shrink-0" />
                  <span className="font-bold">Hingga 50 Karyawan Aktif</span>
                </div>
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-orange-600 shrink-0" />
                  <span>Presensi GPS & Anti-Mock Lokasi</span>
                </div>
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-orange-600 shrink-0" />
                  <span>Multi-Cabang Hingga 5 Kantor</span>
                </div>
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-orange-600 shrink-0" />
                  <span className="font-bold text-slate-900">Otomasi Payroll & Denda Terlambat</span>
                </div>
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-orange-600 shrink-0" />
                  <span>Download Slip Gaji PDF Digital</span>
                </div>
              </div>
            </div>

            <Link
              href="/register?plan=growth"
              className="mt-6 w-full py-2.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-bold text-xs text-center transition-all duration-150 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 shadow-xs block"
            >
              Mulai Uji Coba 14 Hari
            </Link>
          </div>

          {/* Plan 3: Enterprise */}
          <div className="scroll-reveal stagger-3 rounded-2xl border border-slate-200/80 bg-white/95 backdrop-blur-sm p-6 sm:p-7 shadow-[0_1px_3px_rgba(0,0,0,0.03),0_1px_2px_rgba(0,0,0,0.02)] flex flex-col justify-between">
            <div>
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                Multi-Cabang & Skala Besar
              </span>
              <h3 className="text-xl font-bold text-slate-900 mt-1">Enterprise</h3>
              <p className="text-xs text-slate-500 mt-1.5">
                Untuk perusahaan dengan cabang banyak dan kebutuhan kustomisasi role.
              </p>

              <div className="mt-5 mb-5 font-mono">
                <span className="text-3xl font-extrabold text-slate-900">
                  {billingCycle === "annually" ? "Rp 499.000" : "Rp 599.000"}
                </span>
                <span className="text-xs text-slate-500 font-sans"> / bulan</span>
              </div>

              <div className="space-y-2.5 text-xs text-slate-700 border-t border-slate-100 pt-5">
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span className="font-bold">Karyawan Tanpa Batas</span>
                </div>
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Cabang & Titik Koordinat Tanpa Batas</span>
                </div>
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Semua Fitur Payroll & Slip Gaji</span>
                </div>
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Role & Hak Akses Supervisor Kustom</span>
                </div>
                <div className="flex items-center gap-2">
                  <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>Dukungan Teknis Prioritas</span>
                </div>
              </div>
            </div>

            <Link
              href="/register?plan=enterprise"
              className="mt-6 w-full py-2.5 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-800 font-bold text-xs text-center transition-all duration-150 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 block shadow-2xs"
            >
              Pilih Paket Enterprise
            </Link>
          </div>
        </div>
        </div>
      </section>

      {/* 9. Accessible FAQ Section */}
      <section id="faq" className="relative py-16 sm:py-20 bg-gradient-to-b from-white via-slate-50/40 to-slate-100/50 border-t border-slate-200/70 overflow-hidden">
        {/* Soft Ambient Wash */}
        <div className="absolute bottom-0 right-0 w-80 h-80 bg-radial from-orange-400/4 via-slate-200/20 to-transparent rounded-full blur-3xl pointer-events-none -z-10" aria-hidden="true" />
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 relative">
          <div className="scroll-reveal text-center mb-10">
            <span className="text-xs font-bold text-orange-600 uppercase tracking-wider mb-2 block">
              Pertanyaan Umum
            </span>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              Hal yang Sering Ditanyakan
            </h2>
            <p className="mt-2 text-sm text-slate-600">
              Jawaban seputar teknis presensi, kalkulasi payroll, dan keamanan multi-tenancy.
            </p>
          </div>

          <div className="scroll-reveal space-y-3">
            {faqs.map((faq, idx) => {
              const isOpen = openFaqIndex === idx;
              const buttonId = `faq-btn-${idx}`;
              const panelId = `faq-panel-${idx}`;

              return (
                <div key={faq.q} className="rounded-2xl border border-slate-200/80 overflow-hidden bg-white/95 backdrop-blur-sm shadow-[0_1px_3px_rgba(0,0,0,0.03),0_1px_2px_rgba(0,0,0,0.02)] transition-colors">
                  <button
                    id={buttonId}
                    type="button"
                    aria-expanded={isOpen}
                    aria-controls={panelId}
                    onClick={() => setOpenFaqIndex(isOpen ? null : idx)}
                    className="w-full p-4 sm:p-5 text-left flex items-center justify-between gap-4 hover:bg-slate-50/80 transition-colors cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 active:scale-[0.99]"
                  >
                    <span className="text-xs sm:text-sm font-bold text-slate-900">
                      {faq.q}
                    </span>
                    <ChevronDown
                      className={cn(
                        "w-4 h-4 text-slate-400 shrink-0 transition-transform duration-200",
                        isOpen ? "rotate-180 text-orange-600" : ""
                      )}
                    />
                  </button>

                  <div
                    id={panelId}
                    role="region"
                    aria-labelledby={buttonId}
                    data-open={isOpen}
                    className="accordion-wrapper"
                  >
                    <div className="accordion-inner">
                      <div className="px-5 pb-5 pt-1 text-xs sm:text-sm text-slate-600 leading-relaxed border-t border-slate-100">
                        {faq.a}
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* 10. Direct High-Craft CTA Banner */}
      <section className="relative py-16 sm:py-20 bg-slate-900 text-white overflow-hidden border-t border-slate-800/80">
        {/* Dark Zenith Amber Spotlight */}
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_75%_55%_at_50%_-10%,rgba(234,88,12,0.16),rgba(15,23,42,0))] pointer-events-none -z-10" aria-hidden="true" />
        <div className="scroll-reveal max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center relative">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-orange-500/20 text-orange-400 text-xs font-semibold mb-4 border border-orange-500/30">
            <span className="w-1.5 h-1.5 rounded-full bg-orange-400" />
            <span>Mulai Dalam 5 Menit</span>
          </div>

          <h2 className="text-2xl sm:text-4xl font-extrabold tracking-tight leading-tight">
            Siap Tinggalkan Absensi Manual & Rumus Rumit?
          </h2>
          <p className="mt-4 text-sm text-slate-300 max-w-xl mx-auto">
            Daftarkan perusahaan Anda sekarang dan nikmati kemudahan rekapitulasi kehadiran staf, shift, dan gaji tanpa selisih.
          </p>

          <div className="mt-7 flex flex-wrap items-center justify-center gap-3">
            <Link
              href="/register"
              className="px-6 py-3 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-bold text-sm shadow-xs transition-all duration-150 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600"
            >
              Daftar Perusahaan Anda
            </Link>
            <Link
              href="/login"
              className="px-5 py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold text-sm transition-all duration-150 border border-slate-700 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600"
            >
              Masuk Portal Klien
            </Link>
          </div>

          <p className="mt-3.5 text-xs text-slate-400">
            Gratis 14 hari penuh. Batal kapan saja tanpa kartu kredit.
          </p>
        </div>
      </section>

      {/* 11. Global Footer */}
      <footer className="bg-slate-950 text-slate-400 py-12 border-t border-slate-800/60 text-xs relative">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8 pb-8 border-b border-slate-900">
            <div>
              <div className="flex items-center gap-2 mb-3">
                <span className="text-base font-bold text-white tracking-tight">HR Hub</span>
                <span className="text-[10px] font-semibold px-2 py-0.5 rounded-md bg-orange-500/20 text-orange-400 border border-orange-500/30">
                  Indonesia
                </span>
              </div>
              <p className="text-slate-500 leading-relaxed text-xs">
                Platform SaaS HRIS terpadu yang memadukan presensi mobile GPS anti-fake dengan sistem otomasi penggajian akurat untuk UMKM & Startup.
              </p>
            </div>

            <div>
              <span className="text-slate-200 font-semibold uppercase tracking-wider block mb-3 text-[11px]">
                Fitur Produk
              </span>
              <ul className="space-y-2">
                <li><a href="#simulator" onClick={() => setHeroTab("presensi")} className="hover:text-white transition-colors">Presensi GPS Geofencing</a></li>
                <li><a href="#simulator" onClick={() => setHeroTab("payroll")} className="hover:text-white transition-colors">Kalkulasi Otomatis Payroll</a></li>
                <li><a href="#simulator" onClick={() => setHeroTab("shift")} className="hover:text-white transition-colors">Manajemen Shift & Cabang</a></li>
                <li><a href="#simulator" onClick={() => setHeroTab("cuti")} className="hover:text-white transition-colors">Pengajuan & Saldo Cuti</a></li>
              </ul>
            </div>

            <div>
              <span className="text-slate-200 font-semibold uppercase tracking-wider block mb-3 text-[11px]">
                Solusi Usaha
              </span>
              <ul className="space-y-2 text-slate-400">
                <li>Retail & Toko Ruko</li>
                <li>Kafe & Usaha Kuliner (F&B)</li>
                <li>Startup & Agensi Kreatif</li>
                <li>Distribusi & Logistik</li>
              </ul>
            </div>

            <div>
              <span className="text-slate-200 font-semibold uppercase tracking-wider block mb-3 text-[11px]">
                Keamanan Data
              </span>
              <div className="space-y-2 text-slate-400">
                <div className="flex items-center gap-2">
                  <ShieldCheck className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
                  <span>Isolasi Multi-Tenant Mutlak</span>
                </div>
                <div className="flex items-center gap-2">
                  <ShieldCheck className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
                  <span>Enkripsi Token Sanctum</span>
                </div>
                <div className="flex items-center gap-2">
                  <ShieldCheck className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
                  <span>Validasi Lokasi Mock-Shield</span>
                </div>
              </div>
            </div>
          </div>

          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 text-slate-600">
            <span>&copy; {new Date().getFullYear()} HR Hub Indonesia. Hak Cipta Dilindungi.</span>
            <div className="flex items-center gap-6">
              <Link href="/login" className="hover:text-slate-400 transition-colors">
                Portal Admin
              </Link>
              <Link href="/register" className="hover:text-slate-400 transition-colors">
                Daftar Perusahaan
              </Link>
            </div>
          </div>
        </div>
      </footer>

      {/* Floating Modern Quick-Jump Back to Top Button */}
      <button
        type="button"
        onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
        className={cn(
          "fixed bottom-6 right-6 z-40 p-2.5 rounded-full bg-white/95 text-slate-700 hover:text-orange-600 border border-slate-200/90 shadow-lg backdrop-blur-md transition-all duration-300 ease-out focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 cursor-pointer group hover:scale-105 active:scale-95",
          showBackToTop ? "opacity-100 translate-y-0 pointer-events-auto" : "opacity-0 translate-y-4 pointer-events-none"
        )}
        aria-label="Kembali ke atas halaman"
        title="Kembali ke atas"
      >
        <ArrowUp className="w-4 h-4 transition-transform group-hover:-translate-y-0.5 duration-200" />
      </button>
    </div>
  );
}
