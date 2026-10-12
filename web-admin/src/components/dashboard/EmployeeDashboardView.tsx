"use client";

import React, { useState, useEffect, useMemo } from "react";
import Link from "next/link";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Clock,
  CalendarCheck,
  CreditCard,
  Award,
  ChevronRight,
  Download,
  AlertCircle,
  MapPin,
  Calendar,
  CheckCircle2,
  ArrowUpRight,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { TableSkeleton, Skeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { Modal } from "@/components/ui/Modal";
import apiClient from "@/lib/axios";
import { cn, formatRupiah, formatDate, formatTime, getLocalDateIso, getLocalMonthIso } from "@/lib/utils";
import type {
  ApiResponse,
  Attendance,
  LeaveBalance,
  LeaveRequest,
  LeaveType,
  PayrollSlip,
  PerformancePeriod,
  PerformanceEvaluation,
  TodayAttendance,
  User,
} from "@/types";

interface EmployeeDashboardViewProps {
  user: User | null;
}

interface PeriodDetailResponse {
  period: PerformancePeriod;
  evaluations: PerformanceEvaluation[];
}

export function EmployeeDashboardView({ user }: EmployeeDashboardViewProps) {
  const queryClient = useQueryClient();

  // State untuk jam digital lokal (Live Clock Ticker)
  const [currentTime, setCurrentTime] = useState("");
  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setCurrentTime(
        now.toLocaleTimeString("id-ID", {
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
        }) + " WIB"
      );
    };
    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  const todayIso = useMemo(() => getLocalDateIso(), []);
  const currentMonth = useMemo(() => getLocalMonthIso(), []);

  // Modal State
  const [selectedSlip, setSelectedSlip] = useState<PayrollSlip | null>(null);
  const [isApplyLeaveOpen, setIsApplyLeaveOpen] = useState(false);
  const [downloadingSlipId, setDownloadingSlipId] = useState<number | null>(null);

  // Form State Ajukan Cuti
  const [leaveTypeId, setLeaveTypeId] = useState<string>("");
  const [startDate, setStartDate] = useState<string>("");
  const [endDate, setEndDate] = useState<string>("");
  const [leaveReason, setLeaveReason] = useState<string>("");
  const [leaveAttachment, setLeaveAttachment] = useState<File | null>(null);
  const [applyLeaveError, setApplyLeaveError] = useState<string | null>(null);
  const [feedbackToast, setFeedbackToast] = useState<{
    type: "success" | "error";
    message: string;
  } | null>(null);

  // 1. Query: Profil Pengguna & Data Karyawan
  const { data: userProfile } = useQuery({
    queryKey: ["auth-me"],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<User>>("/auth/me");
      if (res.data.success && res.data.data) {
        return res.data.data;
      }
      return null;
    },
    initialData: user || undefined,
  });

  const activeEmployee = userProfile?.employee ?? user?.employee;
  const employeeName = userProfile?.name ?? user?.name ?? "Karyawan";
  const employeeNik = activeEmployee?.nik ?? "-";
  const departmentName = activeEmployee?.department?.name ?? "Operasional";
  const jobPositionName = activeEmployee?.job_position?.name ?? "Staf Karyawan";
  const branchName = activeEmployee?.branch?.name ?? "Kantor Pusat";

  // 2. Query: Presensi Hari Ini
  const {
    data: todayAttendance,
    isLoading: isTodayLoading,
    isError: isTodayError,
    error: todayError,
    refetch: refetchToday,
  } = useQuery({
    queryKey: ["employee-today-attendance", todayIso],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<TodayAttendance>>("/attendance/today", {
        params: { date: todayIso },
      });
      if (res.data.success && res.data.data) {
        return res.data.data;
      }
      return null;
    },
  });

  // 3. Query: Rekap Kehadiran Bulan Ini (Untuk Kartu Metrik)
  const {
    data: monthAttendances = [],
    isLoading: isMonthAttendancesLoading,
  } = useQuery({
    queryKey: ["employee-attendance-history-month", currentMonth],
    queryFn: async () => {
      const res = await apiClient.get<
        ApiResponse<{ data?: Attendance[] } | Attendance[]>
      >("/attendance/history", {
        params: { month: currentMonth, per_page: 31 },
      });
      if (res.data.success && res.data.data) {
        if (Array.isArray(res.data.data)) {
          return res.data.data;
        }
        if (
          typeof res.data.data === "object" &&
          "data" in res.data.data &&
          Array.isArray(res.data.data.data)
        ) {
          return res.data.data.data;
        }
      }
      return [];
    },
  });

  // 4. Query: Riwayat Presensi Terbaru (5 item)
  const {
    data: recentAttendances = [],
    isLoading: isRecentAttendancesLoading,
    isError: isRecentAttendancesError,
    error: recentAttendancesError,
    refetch: refetchRecentAttendances,
  } = useQuery({
    queryKey: ["employee-attendance-history-recent"],
    queryFn: async () => {
      const res = await apiClient.get<
        ApiResponse<{ data?: Attendance[] } | Attendance[]>
      >("/attendance/history", {
        params: { per_page: 5 },
      });
      if (res.data.success && res.data.data) {
        if (Array.isArray(res.data.data)) {
          return res.data.data;
        }
        if (
          typeof res.data.data === "object" &&
          "data" in res.data.data &&
          Array.isArray(res.data.data.data)
        ) {
          return res.data.data.data;
        }
      }
      return [];
    },
  });

  // 5. Query: Sisa Saldo Kuota Cuti Karyawan
  const { data: leaveBalances = [] } = useQuery({
    queryKey: ["employee-leave-balance"],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<LeaveBalance[]>>("/leave/balance");
      if (res.data.success && Array.isArray(res.data.data)) {
        return res.data.data;
      }
      return [];
    },
  });

  // 6. Query: Permohonan Cuti Aktif Karyawan
  const {
    data: myLeaveRequests = [],
    isLoading: isMyLeavesLoading,
    isError: isMyLeavesError,
    error: myLeavesError,
    refetch: refetchMyLeaves,
  } = useQuery({
    queryKey: ["employee-leave-requests"],
    queryFn: async () => {
      const res = await apiClient.get<
        ApiResponse<LeaveRequest[] | { data: LeaveRequest[] }>
      >("/leave/my-requests");
      if (res.data.success && res.data.data) {
        if (Array.isArray(res.data.data)) {
          return res.data.data;
        }
        if (
          typeof res.data.data === "object" &&
          "data" in res.data.data &&
          Array.isArray(res.data.data.data)
        ) {
          return res.data.data.data;
        }
      }
      return [];
    },
  });

  // 7. Query: Master Tipe Cuti untuk Formulir
  const { data: leaveTypes = [] } = useQuery({
    queryKey: ["employee-leave-types"],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<LeaveType[]>>("/leave/types");
      if (res.data.success && Array.isArray(res.data.data)) {
        return res.data.data;
      }
      return [];
    },
  });

  // 8. Query: Slip Gaji Personal Karyawan
  const {
    data: mySlips = [],
    isLoading: isMySlipsLoading,
  } = useQuery({
    queryKey: ["employee-my-slips"],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<PayrollSlip[]>>("/payroll/my-slips");
      if (res.data.success && Array.isArray(res.data.data)) {
        return res.data.data;
      }
      return [];
    },
  });

  // 9. Query: Evaluasi Penilaian SMART Karyawan Terakhir
  const {
    data: performanceEvaluation,
    isLoading: isPerformanceLoading,
  } = useQuery({
    queryKey: ["employee-performance-evaluation", activeEmployee?.id_employees],
    queryFn: async () => {
      const periodsRes = await apiClient.get<ApiResponse<PerformancePeriod[]>>(
        "/performance/periods"
      );
      if (!periodsRes.data.success || !Array.isArray(periodsRes.data.data) || periodsRes.data.data.length === 0) {
        return null;
      }
      const latestPeriod = periodsRes.data.data[0];
      const detailRes = await apiClient.get<ApiResponse<PeriodDetailResponse>>(
        `/performance/periods/${latestPeriod.id_performance_periods}`
      );
      if (detailRes.data.success && detailRes.data.data?.evaluations) {
        const empEval = detailRes.data.data.evaluations.find(
          (ev) => ev.id_employees === activeEmployee?.id_employees
        );
        return {
          period: latestPeriod,
          evaluation: empEval ?? null,
        };
      }
      return null;
    },
    enabled: !!activeEmployee?.id_employees,
  });

  // Mutasi: Ajukan Cuti Baru
  const applyLeaveMutation = useMutation({
    mutationFn: async (formData: FormData) => {
      const response = await apiClient.post<ApiResponse<LeaveRequest>>(
        "/leave/request",
        formData,
        {
          headers: {
            "Content-Type": "multipart/form-data",
          },
        }
      );
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["employee-leave-requests"] });
      queryClient.invalidateQueries({ queryKey: ["employee-leave-balance"] });
      setIsApplyLeaveOpen(false);
      setLeaveTypeId("");
      setStartDate("");
      setEndDate("");
      setLeaveReason("");
      setLeaveAttachment(null);
      setApplyLeaveError(null);
      setFeedbackToast({
        type: "success",
        message: "Pengajuan izin cuti Anda berhasil dikirim dan menunggu persetujuan atasan.",
      });
      setTimeout(() => setFeedbackToast(null), 4000);
    },
    onError: (err: { response?: { data?: { message?: string } }; message?: string }) => {
      setApplyLeaveError(
        err.response?.data?.message || err.message || "Gagal mengajukan permohonan cuti."
      );
    },
  });

  const handleApplyLeaveSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setApplyLeaveError(null);

    if (!leaveTypeId || !startDate || !endDate || !leaveReason.trim()) {
      setApplyLeaveError("Harap lengkapi semua kolom wajib formulir cuti.");
      return;
    }

    if (new Date(startDate) > new Date(endDate)) {
      setApplyLeaveError("Tanggal selesai cuti tidak boleh lebih awal dari tanggal mulai.");
      return;
    }

    const formData = new FormData();
    formData.append("id_leave_types", leaveTypeId);
    formData.append("start_date", startDate);
    formData.append("end_date", endDate);
    formData.append("reason", leaveReason.trim());
    if (leaveAttachment) {
      formData.append("attachment", leaveAttachment);
    }

    applyLeaveMutation.mutate(formData);
  };

  // Unduh Slip Gaji PDF
  const handleDownloadSlip = async (idSlip: number) => {
    try {
      setDownloadingSlipId(idSlip);
      const response = await apiClient.get(`/payroll/my-slips/${idSlip}/download`, {
        responseType: "blob",
      });

      const blob = new Blob([response.data], { type: "application/pdf" });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute("download", `Slip-Gaji-${employeeNik}-${idSlip}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
    } catch {
      setFeedbackToast({
        type: "error",
        message: "Gagal mengunduh berkas slip gaji. Silakan coba kembali.",
      });
      setTimeout(() => setFeedbackToast(null), 4000);
    } finally {
      setDownloadingSlipId(null);
    }
  };

  // Kalkulasi Metrik Kartu Personal
  const totalPresentThisMonth = useMemo(() => {
    return monthAttendances.filter(
      (a) => a.status === "present" || a.status === "late" || a.status === "on_time"
    ).length;
  }, [monthAttendances]);

  const totalRemainingQuota = useMemo(() => {
    if (leaveBalances.length === 0) return 12;
    return leaveBalances.reduce(
      (acc, curr) => acc + (Number(curr.remaining_days) || 0),
      0
    );
  }, [leaveBalances]);

  const latestSlip = mySlips.length > 0 ? mySlips[0] : null;

  const currentAtt = todayAttendance?.attendance;
  const currentShift = todayAttendance?.shift;

  return (
    <div className="space-y-4 sm:space-y-5 max-w-7xl mx-auto">
      {/* 1. Header Minimalis (Apple iOS Large Title & Jabatan Saja) */}
      <div className="pb-1">
        <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-slate-900">
          Halo, {employeeName}
        </h1>
        <p className="mt-1 text-sm font-medium text-slate-500">
          {jobPositionName || "Karyawan"}
        </p>
      </div>

      {/* Toast Feedback */}
      {feedbackToast && (
        <div
          role="status"
          className={cn(
            "flex items-center justify-between p-3.5 sm:p-4 rounded-2xl text-xs sm:text-sm font-medium border shadow-2xs transition-all",
            feedbackToast.type === "success"
              ? "bg-emerald-50 border-emerald-200 text-emerald-800"
              : "bg-rose-50 border-rose-200 text-rose-800"
          )}
        >
          <div className="flex items-center gap-2">
            {feedbackToast.type === "success" ? (
              <CheckCircle2 className="w-4 h-4 text-emerald-600 flex-shrink-0" />
            ) : (
              <AlertCircle className="w-4 h-4 text-rose-600 flex-shrink-0" />
            )}
            <span>{feedbackToast.message}</span>
          </div>
          <button
            type="button"
            onClick={() => setFeedbackToast(null)}
            className="text-xs font-semibold hover:underline cursor-pointer ml-3"
          >
            Tutup
          </button>
        </div>
      )}

      {/* 2. Card Status Presensi Hari Ini (iOS Live Activity & Inset Widget) */}
      <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)]">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pb-3.5 border-b border-slate-100">
          <div className="flex items-center justify-between sm:justify-start gap-2.5">
            <div className="flex items-center gap-2">
              <span
                className={cn(
                  "w-2.5 h-2.5 rounded-full flex-shrink-0",
                  currentAtt ? "bg-emerald-500 animate-pulse" : "bg-amber-500"
                )}
                aria-hidden="true"
              />
              <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
                Presensi Hari Ini
              </h2>
            </div>
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
                Belum Hadir
              </span>
            )}
          </div>

          <div className="flex items-center justify-between sm:justify-end gap-2 text-xs flex-wrap">
            {currentTime && (
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-slate-100/80 text-slate-700 text-[11px] font-mono tabular-nums border border-slate-200/60">
                <Clock className="w-3 h-3 text-orange-600 flex-shrink-0" aria-hidden="true" />
                <span>{currentTime}</span>
              </span>
            )}
            <span className="px-2.5 py-1 rounded-full bg-slate-100/80 text-slate-600 text-[11px] font-medium border border-slate-200/60">
              Shift:{" "}
              <strong className="text-slate-800 font-semibold">
                {currentShift
                  ? `${currentShift.name} (${currentShift.start_time.slice(0, 5)} - ${currentShift.end_time.slice(0, 5)})`
                  : "Reguler (08:00 - 17:00)"}
              </strong>
            </span>
          </div>
        </div>

        {isTodayLoading ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 pt-4">
            <Skeleton className="h-20 w-full rounded-2xl" />
            <Skeleton className="h-20 w-full rounded-2xl" />
            <Skeleton className="h-20 w-full rounded-2xl col-span-2 sm:col-span-1" />
          </div>
        ) : isTodayError ? (
          <div className="pt-3">
            <ErrorState
              title="Gagal Memuat Status Presensi"
              message={
                todayError instanceof Error
                  ? todayError.message
                  : "Terjadi gangguan saat mengambil data presensi terkini."
              }
              onRetry={() => refetchToday()}
            />
          </div>
        ) : (
          <div className="pt-4 space-y-4">
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {/* Jam Masuk */}
              <div className="p-3.5 rounded-2xl bg-slate-50/70 border border-slate-100 flex flex-col justify-between">
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Clock In</span>
                  <div className="w-5 h-5 rounded-md bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
                    <Clock className="w-3 h-3" />
                  </div>
                </div>
                <div className="mt-2 flex items-baseline gap-1">
                  <span className="text-xl sm:text-2xl font-bold font-mono text-slate-900 tabular-nums">
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
                    <span className="text-slate-400">Belum absen masuk</span>
                  )}
                </div>
              </div>

              {/* Jam Pulang */}
              <div className="p-3.5 rounded-2xl bg-slate-50/70 border border-slate-100 flex flex-col justify-between">
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Clock Out</span>
                  <div className="w-5 h-5 rounded-md bg-orange-500/10 text-orange-600 flex items-center justify-center">
                    <Clock className="w-3 h-3" />
                  </div>
                </div>
                <div className="mt-2 flex items-baseline gap-1">
                  <span className="text-xl sm:text-2xl font-bold font-mono text-slate-900 tabular-nums">
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
                    <span className="text-slate-600 font-medium">Sedang Bekerja</span>
                  ) : (
                    <span className="text-slate-400">Belum jam pulang</span>
                  )}
                </div>
              </div>

              {/* Jarak GPS (Full-width di mobile) */}
              <div className="p-3.5 rounded-2xl bg-slate-50/70 border border-slate-100 col-span-2 sm:col-span-1 flex flex-col justify-between">
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Radius GPS</span>
                  <div className="w-5 h-5 rounded-md bg-blue-500/10 text-blue-600 flex items-center justify-center">
                    <MapPin className="w-3 h-3" />
                  </div>
                </div>
                <div className="mt-2 flex items-baseline gap-1">
                  <span className="text-xl sm:text-2xl font-bold font-mono text-slate-900 tabular-nums">
                    {currentAtt?.clock_in_distance_meters !== null &&
                    currentAtt?.clock_in_distance_meters !== undefined
                      ? `${currentAtt.clock_in_distance_meters}m`
                      : "Dalam radius"}
                  </span>
                </div>
                <div className="text-[11px] mt-1 text-slate-500 truncate font-medium">
                  {branchName} (Maks 50m)
                </div>
              </div>
            </div>

            {/* iOS Primary Action Touch Targets (>= 48px) */}
            <div>
              {!currentAtt?.clock_in_time ? (
                <Link
                  href="/attendance"
                  className="w-full min-h-[48px] rounded-2xl bg-orange-600 hover:bg-orange-700 active:scale-[0.99] text-white font-bold text-sm flex items-center justify-center gap-2 shadow-[0_2px_8px_rgba(234,88,12,0.25)] transition-all"
                >
                  <span>Clock In Sekarang</span>
                  <ArrowUpRight className="w-4 h-4" />
                </Link>
              ) : !currentAtt?.clock_out_time ? (
                <Link
                  href="/attendance"
                  className="w-full min-h-[48px] rounded-2xl bg-amber-600 hover:bg-amber-700 active:scale-[0.99] text-white font-bold text-sm flex items-center justify-center gap-2 shadow-[0_2px_8px_rgba(217,119,6,0.25)] transition-all"
                >
                  <span>Clock Out Sekarang</span>
                  <ArrowUpRight className="w-4 h-4" />
                </Link>
              ) : (
                <Link
                  href="/attendance"
                  className="w-full min-h-[44px] rounded-2xl bg-slate-100 hover:bg-slate-200/80 active:scale-[0.99] text-slate-700 font-semibold text-sm flex items-center justify-center gap-2 border border-slate-200/80 transition-all"
                >
                  <span>Buka Halaman Presensi</span>
                  <ArrowUpRight className="w-4 h-4 text-slate-500" />
                </Link>
              )}
            </div>
          </div>
        )}
      </div>

      {/* 3. Kartu Metrik Mandiri (iOS Health/Fitness Style Insets) */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        {/* Card 1: Kehadiran Bulan Ini */}
        <Link
          href="/attendance"
          className="group rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 hover:border-slate-300 transition-all flex flex-col justify-between focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 shadow-[0_1px_3px_rgba(0,0,0,0.02)] active:scale-[0.98]"
        >
          <div className="flex items-start justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-slate-500 uppercase tracking-wider">Hadir Bulan Ini</span>
            <div className="w-8 h-8 sm:w-9 sm:h-9 rounded-2xl bg-blue-500/10 text-blue-600 flex items-center justify-center flex-shrink-0 transition-transform group-hover:scale-105">
              <Clock className="w-4 h-4" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-extrabold tracking-tight text-slate-900 tabular-nums">
              {isMonthAttendancesLoading ? "..." : totalPresentThisMonth}
            </div>
            <div className="text-[11px] text-slate-500 mt-1 flex items-center gap-1 font-medium">
              <span>Hari Kerja</span>
              <ArrowUpRight className="w-3.5 h-3.5 text-slate-400 group-hover:text-orange-600 ml-auto transition-colors" />
            </div>
          </div>
        </Link>

        {/* Card 2: Sisa Kuota Cuti */}
        <Link
          href="/leaves"
          className="group rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 hover:border-slate-300 transition-all flex flex-col justify-between focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 shadow-[0_1px_3px_rgba(0,0,0,0.02)] active:scale-[0.98]"
        >
          <div className="flex items-start justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-slate-500 uppercase tracking-wider">Sisa Cuti</span>
            <div className="w-8 h-8 sm:w-9 sm:h-9 rounded-2xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center flex-shrink-0 transition-transform group-hover:scale-105">
              <CalendarCheck className="w-4 h-4" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-extrabold tracking-tight text-slate-900 tabular-nums">
              {totalRemainingQuota}
            </div>
            <div className="text-[11px] text-slate-500 mt-1 flex items-center gap-1 font-medium">
              <span>Hari Tersisa</span>
              <ArrowUpRight className="w-3.5 h-3.5 text-slate-400 group-hover:text-orange-600 ml-auto transition-colors" />
            </div>
          </div>
        </Link>

        {/* Card 3: Slip Gaji Terakhir */}
        <Link
          href="/payroll"
          className="group rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 hover:border-slate-300 transition-all flex flex-col justify-between focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 shadow-[0_1px_3px_rgba(0,0,0,0.02)] active:scale-[0.98]"
        >
          <div className="flex items-start justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-slate-500 uppercase tracking-wider">Slip Terakhir</span>
            <div className="w-8 h-8 sm:w-9 sm:h-9 rounded-2xl bg-orange-500/10 text-orange-600 flex items-center justify-center flex-shrink-0 transition-transform group-hover:scale-105">
              <CreditCard className="w-4 h-4" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-base sm:text-xl font-extrabold tracking-tight text-slate-900 truncate tabular-nums">
              {isMySlipsLoading ? (
                "..."
              ) : latestSlip ? (
                formatRupiah(Number(latestSlip.net_salary))
              ) : (
                "Rp 0"
              )}
            </div>
            <div className="text-[11px] text-slate-500 mt-1 flex items-center gap-1 font-medium truncate">
              <span className="truncate">{latestSlip?.period_name || "Belum terbit"}</span>
              <ArrowUpRight className="w-3.5 h-3.5 text-slate-400 group-hover:text-orange-600 ml-auto flex-shrink-0 transition-colors" />
            </div>
          </div>
        </Link>

        {/* Card 4: Skor SMART */}
        <Link
          href="/performance"
          className="group rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 hover:border-slate-300 transition-all flex flex-col justify-between focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 shadow-[0_1px_3px_rgba(0,0,0,0.02)] active:scale-[0.98]"
        >
          <div className="flex items-start justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-slate-500 uppercase tracking-wider">Nilai SMART</span>
            <div className="w-8 h-8 sm:w-9 sm:h-9 rounded-2xl bg-purple-500/10 text-purple-600 flex items-center justify-center flex-shrink-0 transition-transform group-hover:scale-105">
              <Award className="w-4 h-4" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-extrabold tracking-tight text-slate-900 tabular-nums">
              {isPerformanceLoading ? (
                "..."
              ) : performanceEvaluation?.evaluation?.final_score !== null &&
                performanceEvaluation?.evaluation?.final_score !== undefined ? (
                `${Number(performanceEvaluation.evaluation.final_score).toFixed(1)}`
              ) : (
                "-"
              )}
            </div>
            <div className="text-[11px] text-purple-700 mt-1 flex items-center gap-1 font-semibold truncate">
              <span>
                {performanceEvaluation?.evaluation?.grade
                  ? `Grade ${performanceEvaluation.evaluation.grade}`
                  : "Evaluasi SMART"}
              </span>
              <ArrowUpRight className="w-3.5 h-3.5 text-slate-400 group-hover:text-orange-600 ml-auto flex-shrink-0 transition-colors" />
            </div>
          </div>
        </Link>
      </div>

      {/* 4. Riwayat Presensi & Permohonan Cuti (iOS Inset Group Lists) */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-5">
        {/* Kolom Kiri: Riwayat Presensi Terbaru */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)]">
          <div className="flex items-center justify-between pb-3.5 border-b border-slate-100">
            <div>
              <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
                Riwayat Presensi
              </h2>
              <p className="text-[11px] text-slate-500">5 kehadiran terakhir</p>
            </div>
            <Link
              href="/attendance"
              className="inline-flex items-center gap-1 text-xs font-semibold text-orange-600 hover:text-orange-700 active:scale-95 transition-all"
            >
              <span>Lihat Semua</span>
              <ChevronRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="mt-3.5">
            {isRecentAttendancesLoading ? (
              <TableSkeleton rows={3} columns={3} />
            ) : isRecentAttendancesError ? (
              <ErrorState
                title="Gagal Memuat Riwayat Presensi"
                message={
                  recentAttendancesError instanceof Error
                    ? recentAttendancesError.message
                    : "Kesalahan koneksi saat memuat riwayat kehadiran."
                }
                onRetry={() => refetchRecentAttendances()}
              />
            ) : recentAttendances.length === 0 ? (
              <EmptyState
                title="Belum ada riwayat presensi"
                description="Catatan kehadiran Anda akan otomatis tampil setelah melakukan clock-in."
              />
            ) : (
              <div>
                {/* Mobile Card List View (< sm) - iOS Inset Grouped Rows */}
                <div className="sm:hidden space-y-2">
                  {recentAttendances.map((att) => (
                    <div
                      key={att.id_attendances}
                      className="p-3.5 rounded-2xl border border-slate-100 bg-slate-50/70 flex items-center justify-between transition-colors hover:bg-slate-50"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-xl bg-orange-500/10 text-orange-600 flex items-center justify-center flex-shrink-0">
                          <Clock className="w-4 h-4" />
                        </div>
                        <div>
                          <div className="text-xs font-semibold text-slate-900 font-sans">
                            {formatDate(att.date)}
                          </div>
                          <div className="text-[11px] text-slate-500 font-mono mt-0.5">
                            In: {att.clock_in_time ? formatTime(att.clock_in_time) : "--:--"} • Out:{" "}
                            {att.clock_out_time ? formatTime(att.clock_out_time) : "--:--"}
                          </div>
                        </div>
                      </div>
                      <StatusBadge
                        status={
                          att.status === "present"
                            ? "hadir"
                            : att.status === "late"
                            ? "terlambat"
                            : att.status === "on_time"
                            ? "on_time"
                            : "alpha"
                        }
                      />
                    </div>
                  ))}
                </div>

                {/* Desktop Table View (>= sm) */}
                <div className="hidden sm:block overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead>
                      <tr className="bg-slate-50/80 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                        <th className="px-3.5 py-2.5 rounded-l-xl">Tanggal</th>
                        <th className="px-3.5 py-2.5 font-mono">Masuk</th>
                        <th className="px-3.5 py-2.5 font-mono">Pulang</th>
                        <th className="px-3.5 py-2.5 text-right rounded-r-xl">Status</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium">
                      {recentAttendances.map((att) => (
                        <tr key={att.id_attendances} className="hover:bg-slate-50/60 transition-colors">
                          <td className="px-3.5 py-3 text-slate-900 font-sans">
                            {formatDate(att.date)}
                          </td>
                          <td className="px-3.5 py-3 font-mono text-slate-700">
                            {att.clock_in_time ? formatTime(att.clock_in_time) : "-"}
                          </td>
                          <td className="px-3.5 py-3 font-mono text-slate-500">
                            {att.clock_out_time ? formatTime(att.clock_out_time) : "-"}
                          </td>
                          <td className="px-3.5 py-3 text-right">
                            <StatusBadge
                              status={
                                att.status === "present"
                                  ? "hadir"
                                  : att.status === "late"
                                  ? "terlambat"
                                  : att.status === "on_time"
                                  ? "on_time"
                                  : "alpha"
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
        </div>

        {/* Kolom Kanan: Pengajuan Cuti Aktif (iOS Grouped Inset List) */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)]">
          <div className="flex items-center justify-between pb-3.5 border-b border-slate-100">
            <div>
              <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
                Pengajuan Cuti
              </h2>
              <p className="text-[11px] text-slate-500">Status cuti & izin aktif</p>
            </div>
            <Link
              href="/leaves"
              className="inline-flex items-center gap-1 text-xs font-semibold text-orange-600 hover:text-orange-700 active:scale-95 transition-all"
            >
              <span>Kelola</span>
              <ChevronRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="mt-3.5">
            {isMyLeavesLoading ? (
              <TableSkeleton rows={3} columns={3} />
            ) : isMyLeavesError ? (
              <ErrorState
                title="Gagal Memuat Pengajuan Cuti"
                message={
                  myLeavesError instanceof Error
                    ? myLeavesError.message
                    : "Terjadi kesalahan saat memuat data cuti."
                }
                onRetry={() => refetchMyLeaves()}
              />
            ) : myLeaveRequests.length === 0 ? (
              <EmptyState
                title="Belum ada permohonan cuti"
                description="Anda tidak memiliki izin cuti aktif saat ini."
                actionLabel="Ajukan Cuti Baru"
                onAction={() => {
                  setApplyLeaveError(null);
                  setIsApplyLeaveOpen(true);
                }}
              />
            ) : (
              <div>
                {/* Mobile Card List View (< sm) - iOS Inset Grouped Rows */}
                <div className="sm:hidden space-y-2">
                  {myLeaveRequests.slice(0, 4).map((req) => (
                    <div
                      key={req.id_leave_requests}
                      className="p-3.5 rounded-2xl border border-slate-100 bg-slate-50/70 flex items-center justify-between transition-colors hover:bg-slate-50"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center flex-shrink-0">
                          <CalendarCheck className="w-4 h-4" />
                        </div>
                        <div>
                          <div className="text-xs font-semibold text-slate-900">
                            {req.leave_type?.name || "Cuti Tahunan"}
                          </div>
                          <div className="text-[11px] text-slate-500 font-mono mt-0.5">
                            {formatDate(req.start_date)} s/d {formatDate(req.end_date)}
                          </div>
                        </div>
                      </div>
                      <StatusBadge
                        status={
                          req.status === "approved"
                            ? "disetujui"
                            : req.status === "rejected"
                            ? "ditolak"
                            : "menunggu"
                        }
                      />
                    </div>
                  ))}
                </div>

                {/* Desktop Table View (>= sm) */}
                <div className="hidden sm:block overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead>
                      <tr className="bg-slate-50/80 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                        <th className="px-3.5 py-2.5 rounded-l-xl">Jenis Cuti</th>
                        <th className="px-3.5 py-2.5">Durasi</th>
                        <th className="px-3.5 py-2.5 text-right rounded-r-xl">Status</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium">
                      {myLeaveRequests.slice(0, 4).map((req) => (
                        <tr key={req.id_leave_requests} className="hover:bg-slate-50/60 transition-colors">
                          <td className="px-3.5 py-3 text-slate-900">
                            {req.leave_type?.name || "Cuti"}
                          </td>
                          <td className="px-3.5 py-3 text-slate-500 font-mono">
                            {formatDate(req.start_date)} - {formatDate(req.end_date)}
                          </td>
                          <td className="px-3.5 py-3 text-right">
                            <StatusBadge
                              status={
                                req.status === "approved"
                                  ? "disetujui"
                                  : req.status === "rejected"
                                  ? "ditolak"
                                  : "menunggu"
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
        </div>
      </div>

      {/* 5. Modal Ajukan Cuti Karyawan (Touch-friendly & Responsive) */}
      {isApplyLeaveOpen && (
        <Modal
          isOpen={true}
          onClose={() => setIsApplyLeaveOpen(false)}
          title="Ajukan Permohonan Cuti"
          description="Formulir pengajuan izin atau cuti mandiri untuk persetujuan atasan."
          maxWidth="lg"
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => setIsApplyLeaveOpen(false)}
                disabled={applyLeaveMutation.isPending}
                className="min-h-[44px] rounded-xl active:scale-95"
              >
                Batal
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={handleApplyLeaveSubmit}
                isLoading={applyLeaveMutation.isPending}
                className="min-h-[44px] rounded-xl active:scale-95"
              >
                Kirim Pengajuan
              </Button>
            </div>
          }
        >
          <form onSubmit={handleApplyLeaveSubmit} className="space-y-3.5 text-xs">
            {applyLeaveError && (
              <div
                role="alert"
                className="p-3.5 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 font-medium"
              >
                {applyLeaveError}
              </div>
            )}

            <div>
              <label
                htmlFor="leaveTypeSelect"
                className="block text-xs font-semibold text-slate-700 mb-1"
              >
                Jenis Cuti <span className="text-rose-500">*</span>
              </label>
              <select
                id="leaveTypeSelect"
                value={leaveTypeId}
                onChange={(e) => setLeaveTypeId(e.target.value)}
                className="w-full rounded-xl border border-slate-200/90 bg-slate-50/60 focus:bg-white px-3.5 py-2.5 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[44px] transition-colors"
                required
              >
                <option value="">-- Pilih Jenis Cuti --</option>
                {leaveTypes.map((t) => (
                  <option key={t.id_leave_types} value={t.id_leave_types}>
                    {t.name} (Kuota: {t.quota_days} hari/thn - {t.is_paid ? "Berbayar" : "Unpaid"})
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label
                  htmlFor="leaveStartDate"
                  className="block text-xs font-semibold text-slate-700 mb-1"
                >
                  Tanggal Mulai <span className="text-rose-500">*</span>
                </label>
                <input
                  id="leaveStartDate"
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="w-full rounded-xl border border-slate-200/90 bg-slate-50/60 focus:bg-white px-3.5 py-2.5 text-xs font-mono text-slate-800 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[44px] transition-colors"
                  required
                />
              </div>

              <div>
                <label
                  htmlFor="leaveEndDate"
                  className="block text-xs font-semibold text-slate-700 mb-1"
                >
                  Tanggal Selesai <span className="text-rose-500">*</span>
                </label>
                <input
                  id="leaveEndDate"
                  type="date"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  className="w-full rounded-xl border border-slate-200/90 bg-slate-50/60 focus:bg-white px-3.5 py-2.5 text-xs font-mono text-slate-800 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[44px] transition-colors"
                  required
                />
              </div>
            </div>

            <div>
              <label
                htmlFor="leaveReasonText"
                className="block text-xs font-semibold text-slate-700 mb-1"
              >
                Alasan Pengajuan <span className="text-rose-500">*</span>
              </label>
              <textarea
                id="leaveReasonText"
                rows={3}
                value={leaveReason}
                onChange={(e) => setLeaveReason(e.target.value)}
                placeholder="Tuliskan keterangan keperluan izin atau cuti Anda secara jelas..."
                className="w-full rounded-xl border border-slate-200/90 bg-slate-50/60 focus:bg-white px-3.5 py-2.5 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-colors"
                required
              />
            </div>

            <div>
              <label
                htmlFor="leaveAttachmentFile"
                className="block text-xs font-semibold text-slate-700 mb-1"
              >
                Lampiran Dokumen (Opsional)
              </label>
              <input
                id="leaveAttachmentFile"
                type="file"
                accept=".pdf,.jpg,.jpeg,.png"
                onChange={(e) => {
                  if (e.target.files && e.target.files[0]) {
                    setLeaveAttachment(e.target.files[0]);
                  }
                }}
                className="w-full rounded-xl border border-slate-200/90 bg-slate-50/60 focus:bg-white px-3 py-2 text-xs text-slate-600 file:mr-3 file:py-1 file:px-2.5 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-orange-50 file:text-orange-700 hover:file:bg-orange-100 cursor-pointer min-h-[44px] transition-colors"
              />
              <p className="text-[11px] text-slate-400 mt-1">
                Format: PDF, JPG, PNG (maksimal 4MB). Surat dokter atau berkas pendukung.
              </p>
            </div>
          </form>
        </Modal>
      )}

      {/* 6. Modal Rincian Slip Gaji Karyawan */}
      {selectedSlip && (
        <Modal
          isOpen={true}
          onClose={() => setSelectedSlip(null)}
          title={`Rincian Slip Gaji: ${selectedSlip.period_name || "Periode Berjalan"}`}
          description={`Tanggal Pembayaran: ${selectedSlip.payment_date || "-"}`}
          maxWidth="md"
          footer={
            <div className="flex items-center justify-between w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => setSelectedSlip(null)}
              >
                Tutup
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={() => handleDownloadSlip(selectedSlip.id_payroll_slips)}
                isLoading={downloadingSlipId === selectedSlip.id_payroll_slips}
                leftIcon={<Download className="w-4 h-4" />}
                className="min-h-[44px]"
              >
                Unduh PDF
              </Button>
            </div>
          }
        >
          <div className="space-y-3.5 text-xs">
            {/* Header Profil Penerima */}
            <div className="p-3 rounded-lg bg-slate-50 border border-slate-200/80 space-y-1">
              <div className="flex justify-between">
                <span className="text-slate-500">Nama:</span>
                <span className="font-semibold text-slate-900">{employeeName}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">NIK:</span>
                <span className="font-mono text-slate-800">{employeeNik}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Departemen:</span>
                <span className="text-slate-800">{departmentName}</span>
              </div>
            </div>

            {/* Komponen Pendapatan */}
            <div className="space-y-1.5">
              <div className="text-[11px] font-bold text-slate-900 uppercase tracking-wider">
                Komponen Pendapatan
              </div>
              <div className="space-y-1 pl-2 border-l-2 border-emerald-500">
                <div className="flex justify-between">
                  <span className="text-slate-600">Gaji Pokok:</span>
                  <span className="font-mono font-medium text-slate-900">
                    {formatRupiah(Number(selectedSlip.basic_salary))}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-600">Tunjangan Tetap:</span>
                  <span className="font-mono font-medium text-emerald-700">
                    +{formatRupiah(Number(selectedSlip.allowance_fixed))}
                  </span>
                </div>
                {Number(selectedSlip.overtime_pay || 0) > 0 && (
                  <div className="flex justify-between">
                    <span className="text-slate-600">Upah Lembur:</span>
                    <span className="font-mono font-medium text-emerald-700">
                      +{formatRupiah(Number(selectedSlip.overtime_pay))}
                    </span>
                  </div>
                )}
              </div>
            </div>

            {/* Komponen Potongan */}
            <div className="space-y-1.5">
              <div className="text-[11px] font-bold text-slate-900 uppercase tracking-wider">
                Komponen Potongan
              </div>
              <div className="space-y-1 pl-2 border-l-2 border-rose-500">
                <div className="flex justify-between">
                  <span className="text-slate-600">Potongan Keterlambatan:</span>
                  <span className="font-mono font-medium text-rose-600">
                    -{formatRupiah(Number(selectedSlip.deduction_late ?? selectedSlip.deductions_late ?? 0))}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-600">Potongan Absensi / Alpha:</span>
                  <span className="font-mono font-medium text-rose-600">
                    -{formatRupiah(Number(selectedSlip.deduction_absence ?? selectedSlip.deductions_absence ?? 0))}
                  </span>
                </div>
              </div>
            </div>

            {/* Total Gaji Bersih */}
            <div className="pt-2.5 border-t border-slate-200 flex items-center justify-between bg-orange-50/70 p-3 rounded-lg border border-orange-200">
              <span className="text-xs font-bold text-slate-900">Gaji Bersih (THP):</span>
              <span className="text-sm font-bold font-mono text-orange-700">
                {formatRupiah(Number(selectedSlip.net_salary))}
              </span>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}
