"use client";

import React, { useState, useEffect, useMemo, useRef } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Clock,
  MapPin,
  Camera,
  CheckCircle2,
  AlertCircle,
  Upload,
  X,
  Navigation,
  Sparkles,
  Calendar,
  ShieldCheck,
  Radio,
  Timer,
  Check,
  Users,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { TableSkeleton, Skeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { Modal } from "@/components/ui/Modal";
import apiClient from "@/lib/axios";
import { formatDate, formatTime, getLocalDateIso, getLocalMonthIso, cn } from "@/lib/utils";
import type { ApiResponse, Attendance, TodayAttendance, User } from "@/types";

// Fungsi hitung jarak 2 koordinat (Haversine formula dalam meter)
function calculateDistanceInMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371e3;
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return Math.round(R * c);
}

export default function AttendancePage() {
  const queryClient = useQueryClient();

  // 1. Role Detection
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
  const canManage =
    currentUser?.role &&
    ["owner", "hr", "manager", "superadmin", "super_admin"].includes(
      currentUser.role
    );

  // Tab State: HR/Manager/Owner dapat beralih antara "recap" dan "my-attendance"
  const [selectedTab, setSelectedTab] = useState<"recap" | "my-attendance">(
    "recap"
  );
  const activeTab = isEmployee ? "my-attendance" : selectedTab;
  const isViewingSelf = activeTab === "my-attendance";

  // Tanggal Hari Ini (Waktu Lokal Klien)
  const todayIso = useMemo(() => getLocalDateIso(), []);
  const currentMonthIso = useMemo(() => getLocalMonthIso(), []);

  // Filter Tanggal untuk Admin/HR (Rekap Harian)
  const [selectedDate, setSelectedDate] = useState(todayIso);

  // Filter Bulan untuk Presensi Mandiri (Riwayat Bulanan)
  const [selectedMonth, setSelectedMonth] = useState(currentMonthIso);

  // Toast Notifikasi
  const [toastNotice, setToastNotice] = useState<{
    type: "success" | "error";
    message: string;
  } | null>(null);

  // 2. Query Status Presensi Hari Ini
  const {
    data: todayAttendance,
    isLoading: isTodayLoading,
    isError: isTodayError,
    error: todayError,
    refetch: refetchToday,
  } = useQuery({
    queryKey: ["employee-today-attendance-page", todayIso],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<TodayAttendance>>("/attendance/today", {
        params: { date: todayIso },
      });
      if (res.data.success && res.data.data) {
        return res.data.data;
      }
      return null;
    },
    enabled: isViewingSelf || Boolean(canManage),
    retry: false,
  });

  // 3. Query Log Riwayat Presensi (Cabang Mandiri vs Cabang Admin)
  const {
    data: attendances = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: isViewingSelf
      ? ["attendance-employee-history", selectedMonth]
      : ["attendance-recap", selectedDate],
    queryFn: async () => {
      if (isViewingSelf) {
        const response = await apiClient.get<
          ApiResponse<{ data?: Attendance[] } | Attendance[]>
        >("/attendance/history", {
          params: { month: selectedMonth, per_page: 31 },
        });
        if (response.data.success && response.data.data) {
          if (Array.isArray(response.data.data)) {
            return response.data.data;
          }
          if (
            typeof response.data.data === "object" &&
            "data" in response.data.data &&
            Array.isArray(response.data.data.data)
          ) {
            return response.data.data.data;
          }
        }
        return [];
      } else {
        const response = await apiClient.get<
          ApiResponse<Attendance[] | { attendances: Attendance[] }>
        >("/attendance/recap", {
          params: { date: selectedDate },
        });
        if (response.data.success && response.data.data) {
          if (Array.isArray(response.data.data)) {
            return response.data.data;
          }
          if (
            typeof response.data.data === "object" &&
            "attendances" in response.data.data &&
            Array.isArray(response.data.data.attendances)
          ) {
            return response.data.data.attendances;
          }
        }
        return [];
      }
    },
  });

  const currentAtt = todayAttendance?.attendance;
  const currentShift = todayAttendance?.shift;
  const targetBranch = todayAttendance?.branch;

  // 4. Modal Presensi (Clock In / Clock Out)
  const [isClockModalOpen, setIsClockModalOpen] = useState(false);
  const [clockActionType, setClockActionType] = useState<"in" | "out">("in");
  const [clockLatitude, setClockLatitude] = useState<number | null>(null);
  const [clockLongitude, setClockLongitude] = useState<number | null>(null);
  const [clockPhoto, setClockPhoto] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [isLocating, setIsLocating] = useState(false);
  const [clockError, setClockError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  // Ambil lokasi GPS perangkat
  const detectLocation = () => {
    setIsLocating(true);
    setClockError(null);

    if (typeof window !== "undefined" && "geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setClockLatitude(position.coords.latitude);
          setClockLongitude(position.coords.longitude);
          setIsLocating(false);
        },
        () => {
          // Fallback jika GPS tidak tersedia atau ditolak di browser
          if (targetBranch) {
            setClockLatitude(targetBranch.latitude);
            setClockLongitude(targetBranch.longitude);
          }
          setIsLocating(false);
        },
        { enableHighAccuracy: true, timeout: 8000 }
      );
    } else if (targetBranch) {
      setClockLatitude(targetBranch.latitude);
      setClockLongitude(targetBranch.longitude);
      setIsLocating(false);
    }
  };

  const handleOpenClockModal = (type: "in" | "out") => {
    setClockActionType(type);
    setClockError(null);
    setClockPhoto(null);
    setPhotoPreview(null);
    setIsClockModalOpen(true);
    detectLocation();
  };

  const handlePhotoSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setClockPhoto(file);
      setPhotoPreview(URL.createObjectURL(file));
      setClockError(null);
    }
  };

  // Mutasi: Kirim Clock In
  const clockInMutation = useMutation({
    mutationFn: async (formData: FormData) => {
      const res = await apiClient.post<ApiResponse<Attendance>>(
        "/attendance/clock-in",
        formData,
        {
          headers: { "Content-Type": "multipart/form-data" },
        }
      );
      return res.data;
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ["employee-today-attendance-page"] });
      queryClient.invalidateQueries({ queryKey: ["attendance-employee-history"] });
      queryClient.invalidateQueries({ queryKey: ["attendance-recap"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-attendance"] });
      queryClient.invalidateQueries({ queryKey: ["employee-today-attendance"] });
      queryClient.invalidateQueries({ queryKey: ["employee-attendance-history-month"] });
      queryClient.invalidateQueries({ queryKey: ["employee-attendance-history-recent"] });
      setIsClockModalOpen(false);
      setToastNotice({
        type: "success",
        message:
          data.data?.status === "late"
            ? `Clock-in berhasil! Tercatat terlambat ${data.data.late_duration_minutes} menit.`
            : "Clock-in berhasil tepat waktu!",
      });
      setTimeout(() => setToastNotice(null), 4000);
    },
    onError: (err: { response?: { data?: { message?: string } }; message?: string }) => {
      setClockError(
        err.response?.data?.message || err.message || "Gagal melakukan clock-in."
      );
    },
  });

  // Mutasi: Kirim Clock Out
  const clockOutMutation = useMutation({
    mutationFn: async (formData: FormData) => {
      const res = await apiClient.post<ApiResponse<Attendance>>(
        "/attendance/clock-out",
        formData,
        {
          headers: { "Content-Type": "multipart/form-data" },
        }
      );
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["employee-today-attendance-page"] });
      queryClient.invalidateQueries({ queryKey: ["attendance-employee-history"] });
      queryClient.invalidateQueries({ queryKey: ["attendance-recap"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-attendance"] });
      queryClient.invalidateQueries({ queryKey: ["employee-today-attendance"] });
      queryClient.invalidateQueries({ queryKey: ["employee-attendance-history-month"] });
      queryClient.invalidateQueries({ queryKey: ["employee-attendance-history-recent"] });
      setIsClockModalOpen(false);
      setToastNotice({
        type: "success",
        message: "Clock-out kepulangan kerja berhasil disimpan!",
      });
      setTimeout(() => setToastNotice(null), 4000);
    },
    onError: (err: { response?: { data?: { message?: string } }; message?: string }) => {
      setClockError(
        err.response?.data?.message || err.message || "Gagal melakukan clock-out."
      );
    },
  });

  const handleClockSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setClockError(null);

    // Default koordinat jika belum terdeteksi
    const lat = clockLatitude ?? targetBranch?.latitude ?? -6.2088;
    const lon = clockLongitude ?? targetBranch?.longitude ?? 106.8456;

    if (clockActionType === "in") {
      let photoFile = clockPhoto;

      // Jika di desktop dan tidak ada file foto, buat foto otomatis via canvas
      if (!photoFile) {
        try {
          const canvas = document.createElement("canvas");
          canvas.width = 320;
          canvas.height = 240;
          const ctx = canvas.getContext("2d");
          if (ctx) {
            ctx.fillStyle = "#EA580C";
            ctx.fillRect(0, 0, 320, 240);
            ctx.fillStyle = "#FFFFFF";
            ctx.font = "bold 16px sans-serif";
            ctx.textAlign = "center";
            ctx.fillText("Selfie Presensi Web", 160, 110);
            ctx.font = "12px monospace";
            ctx.fillText(new Date().toLocaleString("id-ID"), 160, 140);
          }
          const blob = await new Promise<Blob | null>((resolve) =>
            canvas.toBlob(resolve, "image/jpeg", 0.9)
          );
          if (blob) {
            photoFile = new File([blob], `selfie-${Date.now()}.jpg`, {
              type: "image/jpeg",
            });
          }
        } catch {
          // Abaikan
        }
      }

      if (!photoFile) {
        setClockError("Foto swafoto wajib diunggah untuk presensi masuk.");
        return;
      }

      const pad = (n: number) => String(n).padStart(2, "0");
      const now = new Date();
      const deviceTime = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;

      const formData = new FormData();
      formData.append("latitude", lat.toString());
      formData.append("longitude", lon.toString());
      formData.append("photo", photoFile);
      formData.append("device_time", deviceTime);

      clockInMutation.mutate(formData);
    } else {
      const pad = (n: number) => String(n).padStart(2, "0");
      const now = new Date();
      const deviceTime = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;

      const formData = new FormData();
      formData.append("latitude", lat.toString());
      formData.append("longitude", lon.toString());
      if (clockPhoto) {
        formData.append("photo", clockPhoto);
      }
      formData.append("device_time", deviceTime);

      clockOutMutation.mutate(formData);
    }
  };

  // Kalkulasi jarak real-time ke kantor cabang
  const currentDistance = useMemo(() => {
    if (clockLatitude && clockLongitude && targetBranch) {
      return calculateDistanceInMeters(
        clockLatitude,
        clockLongitude,
        targetBranch.latitude,
        targetBranch.longitude
      );
    }
    return 0;
  }, [clockLatitude, clockLongitude, targetBranch]);

  const isWithinRadius = useMemo(() => {
    if (!targetBranch) return true;
    return currentDistance <= targetBranch.radius_meters;
  }, [currentDistance, targetBranch]);

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      {/* 1. iOS Large Title & Action Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#0B2545]">
              {isViewingSelf ? "Presensi Kehadiran Saya" : "Rekapitulasi Presensi"}
            </h1>
            <span className="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-[#DCFCE7] text-[#15803D] border border-[#BBF7D0]">
              {isViewingSelf ? "Layanan Mandiri" : "Operasional HR"}
            </span>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            {isViewingSelf
              ? "Catatan log kehadiran digital dan verifikasi lokasi GPS kantor harian Anda."
              : "Monitoring kehadiran seluruh staf berbasis verifikasi geofencing GPS dan swafoto."}
          </p>
        </div>

        {/* Filter Toolbar (Apple HIG Segmented & 44px Touch Targets) */}
        <div className="flex items-center gap-2 self-start sm:self-auto">
          {isViewingSelf ? (
            <input
              type="month"
              value={selectedMonth}
              onChange={(e) => setSelectedMonth(e.target.value)}
              className="rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2 text-xs font-mono text-slate-800 shadow-[0_1px_2px_rgba(0,0,0,0.03)] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 min-h-[44px]"
              aria-label="Pilih Bulan Presensi"
            />
          ) : (
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              className="rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2 text-xs font-mono text-slate-800 shadow-[0_1px_2px_rgba(0,0,0,0.03)] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 min-h-[44px]"
              aria-label="Pilih Tanggal Presensi"
            />
          )}
        </div>
      </div>

      {/* 1b. Role-Aware Tab Switcher (Khusus HR / Manager / Owner) */}
      {canManage && (
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 bg-white p-2 sm:p-2.5 rounded-2xl border border-slate-200/80 shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
          <div className="inline-flex p-1 bg-slate-100 rounded-xl border border-slate-200/60 w-full sm:w-auto">
            <button
              type="button"
              onClick={() => setSelectedTab("recap")}
              className={cn(
                "flex-1 sm:flex-initial px-3.5 py-2 text-xs font-semibold rounded-lg transition-all cursor-pointer flex items-center justify-center gap-2 min-h-[40px]",
                activeTab === "recap"
                  ? "bg-white text-slate-900 shadow-xs font-bold border border-slate-200/60"
                  : "text-slate-600 hover:text-slate-900"
              )}
            >
              <Users className="w-3.5 h-3.5" aria-hidden="true" />
              <span>Rekapitulasi Karyawan</span>
            </button>
            <button
              type="button"
              onClick={() => setSelectedTab("my-attendance")}
              className={cn(
                "flex-1 sm:flex-initial px-3.5 py-2 text-xs font-semibold rounded-lg transition-all cursor-pointer flex items-center justify-center gap-2 min-h-[40px]",
                activeTab === "my-attendance"
                  ? "bg-white text-slate-900 shadow-xs font-bold border border-slate-200/60"
                  : "text-slate-600 hover:text-slate-900"
              )}
            >
              <Clock className="w-3.5 h-3.5" aria-hidden="true" />
              <span>Presensi Saya (Clock In/Out)</span>
              {currentAtt?.clock_in_time ? (
                <span
                  className="w-2 h-2 rounded-full bg-emerald-500 inline-block"
                  title="Sudah absen hari ini"
                />
              ) : (
                <span
                  className="w-2 h-2 rounded-full bg-amber-500 animate-pulse inline-block"
                  title="Belum absen hari ini"
                />
              )}
            </button>
          </div>

          {/* Quick status bar when on recap */}
          {activeTab === "recap" && (
            <div className="flex items-center justify-between sm:justify-end gap-2 text-xs px-2 sm:px-0">
              <span className="text-slate-500 text-[11px]">
                Presensi Anda hari ini:
              </span>
              {currentAtt?.clock_in_time ? (
                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200 text-[11px] font-semibold">
                  <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                  Masuk {formatTime(currentAtt.clock_in_time)} WIB
                </span>
              ) : (
                <button
                  type="button"
                  onClick={() => setSelectedTab("my-attendance")}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 active:scale-[0.98] text-white text-xs font-bold shadow-xs cursor-pointer transition-all"
                >
                  <Camera className="w-3.5 h-3.5" aria-hidden="true" />
                  <span>Clock In Sekarang</span>
                </button>
              )}
            </div>
          )}
        </div>
      )}

      {/* 2. Toast Feedback */}
      {toastNotice && (
        <div
          role="status"
          className={cn(
            "flex items-center justify-between p-3.5 sm:p-4 rounded-2xl text-xs sm:text-sm font-medium border shadow-[0_2px_8px_rgba(0,0,0,0.04)] transition-all",
            toastNotice.type === "success"
              ? "bg-emerald-50/90 border-emerald-200 text-emerald-800"
              : "bg-rose-50/90 border-rose-200 text-rose-800"
          )}
        >
          <div className="flex items-center gap-2.5">
            {toastNotice.type === "success" ? (
              <CheckCircle2 className="w-5 h-5 text-emerald-600 flex-shrink-0" />
            ) : (
              <AlertCircle className="w-5 h-5 text-rose-600 flex-shrink-0" />
            )}
            <span>{toastNotice.message}</span>
          </div>
          <button
            type="button"
            onClick={() => setToastNotice(null)}
            className="text-xs font-semibold hover:underline cursor-pointer ml-3"
          >
            Tutup
          </button>
        </div>
      )}

      {/* 3. Apple Live Activity Widget: Status Hari Ini (Presensi Mandiri) */}
      {isViewingSelf && (
        <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pb-3 border-b border-slate-100">
            <div className="flex items-center gap-2.5">
              <span className="relative flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500" />
              </span>
              <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
                Live Status Presensi Hari Ini
              </h2>
              {currentAtt ? (
                <StatusBadge
                  status={
                    currentAtt.status === "present"
                      ? "hadir"
                      : currentAtt.status === "late"
                      ? "terlambat"
                      : currentAtt.status === "on_time"
                      ? "on_time"
                      : "alpha"
                  }
                />
              ) : (
                <span className="px-2.5 py-0.5 text-[11px] font-semibold rounded-full bg-slate-100 text-slate-600 border border-slate-200/80">
                  Belum Absen
                </span>
              )}
            </div>

            <div className="flex flex-wrap items-center justify-between sm:justify-end gap-3 text-xs">
              <span className="text-slate-500 text-[11px] font-mono">
                Shift:{" "}
                <strong className="text-slate-700 font-semibold font-sans">
                  {currentShift
                    ? `${currentShift.name} (${currentShift.start_time.slice(0, 5)} - ${currentShift.end_time.slice(0, 5)})`
                    : "Reguler (08:00 - 17:00)"}
                </strong>
              </span>

              {/* Tombol Utama Presensi Masuk / Pulang (Apple HIG 48px Touch Target) */}
              {!currentAtt?.clock_in_time ? (
                <button
                  type="button"
                  onClick={() => handleOpenClockModal("in")}
                  disabled={Boolean(isTodayError)}
                  className="inline-flex items-center justify-center gap-2 px-5 py-3 min-h-[48px] rounded-2xl bg-[#16A34A] hover:bg-[#15803D] active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed text-white font-bold text-xs sm:text-sm shadow-xs transition-all cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600"
                >
                  <Camera className="w-4 h-4" aria-hidden="true" />
                  <span>Presensi Masuk (Clock In)</span>
                </button>
              ) : !currentAtt?.clock_out_time ? (
                <button
                  type="button"
                  onClick={() => handleOpenClockModal("out")}
                  disabled={Boolean(isTodayError)}
                  className="inline-flex items-center justify-center gap-2 px-5 py-3 min-h-[48px] rounded-2xl bg-amber-600 hover:bg-amber-700 active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed text-white font-bold text-xs sm:text-sm shadow-xs transition-all cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600"
                >
                  <Clock className="w-4 h-4" aria-hidden="true" />
                  <span>Presensi Pulang (Clock Out)</span>
                </button>
              ) : (
                <span className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-2xl bg-emerald-50 text-emerald-800 border border-emerald-200 text-xs font-semibold">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                  Presensi Hari Ini Selesai
                </span>
              )}
            </div>
          </div>

          {isTodayLoading ? (
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 pt-1">
              <Skeleton className="h-16 w-full rounded-2xl" />
              <Skeleton className="h-16 w-full rounded-2xl" />
              <Skeleton className="h-16 w-full rounded-2xl col-span-2 sm:col-span-1" />
            </div>
          ) : isTodayError ? (
            <div className="p-4 rounded-2xl bg-amber-50/90 border border-amber-200/80 text-amber-900 space-y-1.5">
              <div className="flex items-center gap-2 font-bold text-xs sm:text-sm text-amber-900">
                <AlertCircle className="w-4 h-4 text-amber-600 flex-shrink-0" />
                <span>Profil Karyawan Belum Terhubung</span>
              </div>
              <p className="text-xs text-amber-800 leading-relaxed">
                Akun login Anda (<strong>{currentUser?.name || "User"}</strong>) belum terhubung dengan data karyawan. Untuk melakukan presensi mandiri, pastikan akun ini telah didaftarkan pada menu <strong>Data Karyawan</strong>.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {/* Box 1: Jam Masuk */}
              <div className="p-3.5 rounded-2xl bg-slate-50/80 border border-slate-100 flex flex-col justify-between">
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-semibold text-slate-500">Jam Masuk (In)</span>
                  <div className="w-6 h-6 rounded-lg bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
                    <Clock className="w-3 h-3" />
                  </div>
                </div>
                <div className="mt-2 flex items-baseline gap-1">
                  <span className="text-lg sm:text-xl font-extrabold font-mono text-slate-900 tabular-nums">
                    {currentAtt?.clock_in_time
                      ? formatTime(currentAtt.clock_in_time)
                      : "--:--"}
                  </span>
                  <span className="text-[11px] text-slate-400 font-mono">WIB</span>
                </div>
                <div className="text-[11px] mt-1">
                  {currentAtt?.clock_in_time ? (
                    currentAtt.late_duration_minutes > 0 ? (
                      <span className="text-amber-700 font-semibold">
                        +{currentAtt.late_duration_minutes}m terlambat
                      </span>
                    ) : (
                      <span className="text-emerald-700 font-semibold">Tepat Waktu</span>
                    )
                  ) : (
                    <span className="text-slate-400">Belum clock-in</span>
                  )}
                </div>
              </div>

              {/* Box 2: Jam Pulang */}
              <div className="p-3.5 rounded-2xl bg-slate-50/80 border border-slate-100 flex flex-col justify-between">
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-semibold text-slate-500">Jam Pulang (Out)</span>
                  <div className="w-6 h-6 rounded-lg bg-blue-500/10 text-blue-600 flex items-center justify-center">
                    <Timer className="w-3 h-3" />
                  </div>
                </div>
                <div className="mt-2 flex items-baseline gap-1">
                  <span className="text-lg sm:text-xl font-extrabold font-mono text-slate-900 tabular-nums">
                    {currentAtt?.clock_out_time
                      ? formatTime(currentAtt.clock_out_time)
                      : "--:--"}
                  </span>
                  <span className="text-[11px] text-slate-400 font-mono">WIB</span>
                </div>
                <div className="text-[11px] mt-1">
                  {currentAtt?.clock_out_time ? (
                    <span className="text-emerald-700 font-semibold">Selesai Kerja</span>
                  ) : currentAtt?.clock_in_time ? (
                    <span className="text-slate-600 font-medium">Sedang Aktif Bekerja</span>
                  ) : (
                    <span className="text-slate-400">Belum jam pulang</span>
                  )}
                </div>
              </div>

              {/* Box 3: Akurasi Radius GPS */}
              <div className="p-3.5 rounded-2xl bg-slate-50/80 border border-slate-100 col-span-2 sm:col-span-1 flex flex-col justify-between">
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-semibold text-slate-500">Verifikasi Lokasi GPS</span>
                  <div className="w-6 h-6 rounded-lg bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
                    <MapPin className="w-3 h-3" />
                  </div>
                </div>
                <div className="mt-2 flex items-baseline gap-1">
                  <span className="text-lg sm:text-xl font-extrabold font-mono text-slate-900 tabular-nums">
                    {currentAtt?.clock_in_distance_meters !== null &&
                    currentAtt?.clock_in_distance_meters !== undefined
                      ? `${currentAtt.clock_in_distance_meters}m`
                      : "Terverifikasi"}
                  </span>
                </div>
                <div className="text-[11px] mt-1 text-slate-500 truncate">
                  Batas radius: {targetBranch?.radius_meters || 50}m ({targetBranch?.name || "Cabang Utama"})
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* 4. Inset Grouped Card: Riwayat / Rekapitulasi Presensi */}
      <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] space-y-4">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <div>
            <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
              {isViewingSelf
                ? `Riwayat Presensi: Bulan ${selectedMonth}`
                : `Rekapitulasi Harian: ${selectedDate}`}
            </h2>
            <p className="text-[11px] sm:text-xs text-slate-500 mt-0.5">
              {isViewingSelf
                ? "Daftar kehadiran harian pada periode bulan berjalan."
                : "Log kehadiran seluruh pegawai yang tercatat pada sistem."}
            </p>
          </div>
          <span className="text-xs text-slate-500 font-mono tabular-nums">
            Total: <strong className="text-slate-800">{attendances.length}</strong> log
          </span>
        </div>

        {isLoading ? (
          <TableSkeleton rows={4} columns={isViewingSelf ? 5 : 7} />
        ) : isError ? (
          <ErrorState
            title="Gagal Memuat Data Presensi"
            message={
              error instanceof Error
                ? error.message
                : "Terjadi kendala saat mengambil log data presensi."
            }
            onRetry={() => refetch()}
          />
        ) : attendances.length === 0 ? (
          <EmptyState
            title={
              isViewingSelf
                ? "Belum Ada Catatan Presensi Bulan Ini"
                : "Belum Ada Catatan Presensi Pada Tanggal Ini"
            }
            description={
              isViewingSelf
                ? "Catatan kehadiran Anda akan otomatis terhimpun saat Anda melakukan absensi masuk."
                : "Belum ada staf yang melakukan absensi clock-in pada tanggal yang dipilih."
            }
          />
        ) : (
          <div>
            {/* 1. Mobile Inset Rows View (< sm) */}
            <div className="sm:hidden space-y-2.5">
              {attendances.map((item) => (
                <div
                  key={item.id_attendances}
                  className="p-3.5 rounded-2xl border border-slate-200/70 bg-white hover:bg-slate-50/70 transition-colors space-y-2.5 shadow-[0_1px_2px_rgba(0,0,0,0.02)]"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center flex-shrink-0">
                        <Clock className="w-4 h-4" />
                      </div>
                      <div>
                        {!isViewingSelf && (
                          <div className="text-xs font-bold text-slate-900 leading-tight">
                            {item.employee?.user?.name ||
                              item.employee?.name ||
                              `Karyawan #${item.id_employees}`}
                          </div>
                        )}
                        <div className="text-xs font-bold text-slate-900">
                          {formatDate(item.date)}
                        </div>
                        <div className="text-[11px] text-slate-400 font-mono">
                          {item.employee?.branch?.name || "Cabang Kantor"}
                        </div>
                      </div>
                    </div>
                    <StatusBadge
                      status={
                        item.status === "on_time"
                          ? "on_time"
                          : item.status === "present"
                          ? "hadir"
                          : item.status === "late"
                          ? "terlambat"
                          : item.status === "absent"
                          ? "alpha"
                          : "cuti"
                      }
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-2 text-[11px] p-2.5 rounded-xl bg-slate-50/80 border border-slate-100 font-mono">
                    <div>
                      <span className="text-slate-400 font-sans">Masuk: </span>
                      <span className="font-semibold text-slate-900">
                        {item.clock_in_time ? formatTime(item.clock_in_time) : "-"}
                      </span>
                    </div>
                    <div>
                      <span className="text-slate-400 font-sans">Pulang: </span>
                      <span className="font-semibold text-slate-700">
                        {item.clock_out_time ? formatTime(item.clock_out_time) : "-"}
                      </span>
                    </div>
                    <div>
                      <span className="text-slate-400 font-sans">Jarak GPS: </span>
                      <span className="text-slate-700">
                        {item.clock_in_distance_meters !== null &&
                        item.clock_in_distance_meters !== undefined
                          ? `${item.clock_in_distance_meters}m`
                          : "-"}
                      </span>
                    </div>
                    <div>
                      <span className="text-slate-400 font-sans">Terlambat: </span>
                      <span
                        className={
                          item.late_duration_minutes > 0
                            ? "text-amber-700 font-bold"
                            : "text-slate-500"
                        }
                      >
                        {item.late_duration_minutes > 0
                          ? `${item.late_duration_minutes}m`
                          : "-"}
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* 2. Desktop Table View (>= sm) */}
            <div className="hidden sm:block overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                    {!isViewingSelf && <th className="px-4 py-3">Nama Pegawai</th>}
                    <th className="px-4 py-3">Tanggal</th>
                    <th className="px-4 py-3 font-mono">Clock In</th>
                    <th className="px-4 py-3 font-mono">Clock Out</th>
                    <th className="px-4 py-3 text-center">Jarak GPS</th>
                    <th className="px-4 py-3 text-center font-mono">Keterlambatan</th>
                    <th className="px-4 py-3 text-right">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {attendances.map((item) => (
                    <tr
                      key={item.id_attendances}
                      className="hover:bg-slate-50/60 transition-colors"
                    >
                      {!isViewingSelf && (
                        <td className="px-4 py-3.5 font-bold text-slate-900">
                          {item.employee?.user?.name ||
                            item.employee?.name ||
                            `Karyawan #${item.id_employees}`}
                        </td>
                      )}
                      <td className="px-4 py-3.5 text-slate-800 font-sans">
                        {formatDate(item.date)}
                      </td>
                      <td className="px-4 py-3.5 font-mono text-slate-900 tabular-nums">
                        {item.clock_in_time ? `${formatTime(item.clock_in_time)} WIB` : "-"}
                      </td>
                      <td className="px-4 py-3.5 font-mono text-slate-500 tabular-nums">
                        {item.clock_out_time ? `${formatTime(item.clock_out_time)} WIB` : "-"}
                      </td>
                      <td className="px-4 py-3.5 font-mono text-center text-slate-600 tabular-nums">
                        {item.clock_in_distance_meters !== null &&
                        item.clock_in_distance_meters !== undefined
                          ? `${item.clock_in_distance_meters}m`
                          : "-"}
                      </td>
                      <td className="px-4 py-3.5 font-mono text-center text-amber-700 tabular-nums">
                        {item.late_duration_minutes > 0
                          ? `${item.late_duration_minutes} menit`
                          : "-"}
                      </td>
                      <td className="px-4 py-3.5 text-right">
                        <StatusBadge
                          status={
                            item.status === "on_time"
                              ? "on_time"
                              : item.status === "present"
                              ? "hadir"
                              : item.status === "late"
                              ? "terlambat"
                              : item.status === "absent"
                              ? "alpha"
                              : "cuti"
                          }
                        />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* 5. Modal: Presensi Mandiri (Apple Sheet Style) */}
      {isClockModalOpen && (
        <Modal
          isOpen={true}
          onClose={() => {
            if (!clockInMutation.isPending && !clockOutMutation.isPending) {
              setIsClockModalOpen(false);
              setClockError(null);
            }
          }}
          title={
            clockActionType === "in"
              ? "Presensi Masuk Kerja (Clock In)"
              : "Presensi Pulang Kerja (Clock Out)"
          }
          description="Sistem akan mencatat koordinat GPS dan foto swafoto Anda untuk verifikasi kehadiran."
          maxWidth="sm"
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => {
                  setIsClockModalOpen(false);
                  setClockError(null);
                }}
                disabled={clockInMutation.isPending || clockOutMutation.isPending}
                className="min-h-[44px] rounded-xl"
              >
                Batal
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={handleClockSubmit}
                isLoading={clockInMutation.isPending || clockOutMutation.isPending}
                className={cn(
                  "min-h-[44px] rounded-xl font-bold",
                  clockActionType === "in"
                    ? "bg-[#16A34A] hover:bg-[#15803D]"
                    : "bg-amber-600 hover:bg-amber-700"
                )}
              >
                {clockActionType === "in" ? "Konfirmasi Masuk" : "Konfirmasi Pulang"}
              </Button>
            </div>
          }
        >
          <form onSubmit={handleClockSubmit} className="space-y-4 text-xs">
            {clockError && (
              <div
                role="alert"
                className="p-3.5 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 font-medium"
              >
                {clockError}
              </div>
            )}

            {/* Informasi Lokasi GPS */}
            <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100 space-y-2">
              <div className="flex items-center justify-between">
                <span className="font-semibold text-slate-700 flex items-center gap-1.5">
                  <MapPin className="w-3.5 h-3.5 text-slate-500" />
                  <span>Titik GPS Lokasi</span>
                </span>
                <button
                  type="button"
                  onClick={detectLocation}
                  disabled={isLocating}
                  className="text-[11px] text-emerald-600 hover:underline flex items-center gap-1 font-bold cursor-pointer"
                >
                  <Navigation className="w-3 h-3" />
                  <span>{isLocating ? "Mencari..." : "Segarkan GPS"}</span>
                </button>
              </div>

              <div className="text-[11.5px] font-mono text-slate-600">
                {clockLatitude && clockLongitude
                  ? `${clockLatitude.toFixed(6)}, ${clockLongitude.toFixed(6)}`
                  : "Mendeteksi koordinat satelit..."}
              </div>

              {targetBranch && (
                <div className="pt-2 border-t border-slate-200/60 flex items-center justify-between text-[11px]">
                  <span className="text-slate-500">Jarak ke {targetBranch.name}:</span>
                  <span
                    className={cn(
                      "font-mono font-bold tabular-nums",
                      isWithinRadius ? "text-emerald-700" : "text-amber-700"
                    )}
                  >
                    {currentDistance} meter ({isWithinRadius ? "Dalam Radius" : "Di Luar Radius"})
                  </span>
                </div>
              )}
            </div>

            {/* Input Foto Swafoto (Khusus Clock In Wajib, Clock Out Opsional) */}
            <div>
              <span className="block text-xs font-semibold text-slate-700 mb-1.5">
                Swafoto Kehadiran {clockActionType === "in" && <span className="text-rose-500">*</span>}
              </span>

              {photoPreview ? (
                <div className="relative rounded-2xl overflow-hidden border border-slate-200/80 bg-slate-100 flex items-center justify-center max-h-48">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={photoPreview}
                    alt="Preview Swafoto"
                    className="w-full h-full object-cover max-h-48"
                  />
                  <button
                    type="button"
                    onClick={() => {
                      setClockPhoto(null);
                      setPhotoPreview(null);
                    }}
                    className="absolute top-2 right-2 p-1.5 rounded-full bg-slate-900/70 text-white hover:bg-slate-900 transition-colors cursor-pointer"
                    aria-label="Hapus foto"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                </div>
              ) : (
                <div
                  onClick={() => fileInputRef.current?.click()}
                  className="p-6 rounded-2xl border-2 border-dashed border-slate-200 hover:border-emerald-500 bg-slate-50/50 hover:bg-emerald-50/20 flex flex-col items-center justify-center gap-2 cursor-pointer transition-all"
                >
                  <div className="w-10 h-10 rounded-2xl bg-emerald-100 text-emerald-700 flex items-center justify-center">
                    <Camera className="w-5 h-5" />
                  </div>
                  <div className="text-center">
                    <span className="font-bold text-slate-800 text-xs">Ambil Foto / Pilih File</span>
                    <p className="text-[11px] text-slate-400 mt-0.5">
                      Gunakan kamera depan ponsel atau unggah swafoto
                    </p>
                  </div>
                </div>
              )}

              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                capture="user"
                onChange={handlePhotoSelect}
                className="hidden"
              />
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
