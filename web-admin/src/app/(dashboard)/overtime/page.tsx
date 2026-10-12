"use client";

import React, { useState, useEffect, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Clock4,
  Plus,
  CheckCircle2,
  AlertCircle,
  Check,
  X,
  Calendar,
  Clock,
  User as UserIcon,
  FileText,
  Filter,
  CheckSquare,
  Timer,
  CheckCheck,
  CalendarDays,
  Sparkles,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import apiClient from "@/lib/axios";
import { cn, formatDate } from "@/lib/utils";
import type { ApiResponse, OvertimeRequest, User } from "@/types";

export default function OvertimePage() {
  const queryClient = useQueryClient();

  // Role & Session State
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
  const canApprove =
    currentUser?.role &&
    ["owner", "hr", "manager", "superadmin", "super_admin"].includes(
      currentUser.role
    );

  // Tab State: Manager/HR can switch between Approval queue and My Requests
  const [selectedTab, setSelectedTab] = useState<"approvals" | "my-requests">(
    "approvals"
  );
  const activeTab = isEmployee ? "my-requests" : selectedTab;

  const [statusFilter, setStatusFilter] = useState<string>("all");

  // Apply Overtime Modal State
  const [isApplyOpen, setIsApplyOpen] = useState(false);
  const [applyDate, setApplyDate] = useState(() =>
    new Date().toISOString().split("T")[0]
  );
  const [applyStartTime, setApplyStartTime] = useState("17:00");
  const [applyEndTime, setApplyEndTime] = useState("20:00");
  const [applyReason, setApplyReason] = useState("");
  const [applyError, setApplyError] = useState<string | null>(null);

  // Approval Action Modal State
  const [actionTarget, setActionTarget] = useState<OvertimeRequest | null>(null);
  const [actionType, setActionType] = useState<"approved" | "rejected" | null>(
    null
  );
  const [actionNotes, setActionNotes] = useState("");
  const [actionError, setActionError] = useState<string | null>(null);

  // Toast Notification
  const [toastNotice, setToastNotice] = useState<{
    type: "success" | "error";
    message: string;
  } | null>(null);

  // Real-time calculated duration
  const calculatedDuration = useMemo(() => {
    if (!applyStartTime || !applyEndTime) return null;
    const [startH, startM] = applyStartTime.split(":").map(Number);
    const [endH, endM] = applyEndTime.split(":").map(Number);
    if (
      isNaN(startH) ||
      isNaN(startM) ||
      isNaN(endH) ||
      isNaN(endM)
    ) {
      return null;
    }
    const startMinutes = startH * 60 + startM;
    const endMinutes = endH * 60 + endM;
    const diff = endMinutes - startMinutes;
    if (diff <= 0) return 0;
    return Math.round((diff / 60) * 100) / 100;
  }, [applyStartTime, applyEndTime]);

  // Query: Data Lembur
  const {
    data: overtimeList = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: [
      activeTab === "approvals" ? "overtime-approvals" : "overtime-my-requests",
      statusFilter,
    ],
    queryFn: async () => {
      const endpoint =
        activeTab === "approvals"
          ? "/overtime/approvals"
          : "/overtime/my-requests";
      const params: Record<string, string> = {};
      if (statusFilter !== "all") {
        params.status = statusFilter;
      }

      const response = await apiClient.get<
        ApiResponse<OvertimeRequest[] | { data: OvertimeRequest[] }>
      >(endpoint, { params });

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
    },
  });

  // Mutasi: Ajukan Lembur Baru
  const applyMutation = useMutation({
    mutationFn: async (payload: {
      date: string;
      start_time: string;
      end_time: string;
      reason: string;
    }) => {
      const res = await apiClient.post<ApiResponse<OvertimeRequest>>(
        "/overtime/request",
        payload
      );
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["overtime-my-requests"] });
      queryClient.invalidateQueries({ queryKey: ["overtime-approvals"] });
      setIsApplyOpen(false);
      setApplyReason("");
      setApplyError(null);
      setToastNotice({
        type: "success",
        message: "Pengajuan lembur berhasil dikirim dan menunggu persetujuan atasan.",
      });
      setTimeout(() => setToastNotice(null), 4000);
    },
    onError: (err: {
      response?: { data?: { message?: string } };
      message?: string;
    }) => {
      setApplyError(
        err.response?.data?.message ||
          err.message ||
          "Gagal mengirimkan pengajuan lembur."
      );
    },
  });

  // Mutasi: Persetujuan / Penolakan Lembur
  const actionMutation = useMutation({
    mutationFn: async ({
      id,
      action,
      notes,
    }: {
      id: number;
      action: "approved" | "rejected";
      notes?: string;
    }) => {
      const res = await apiClient.post<ApiResponse<OvertimeRequest>>(
        `/overtime/approvals/${id}/action`,
        {
          action,
          notes: notes?.trim() || null,
        }
      );
      return res.data;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["overtime-approvals"] });
      queryClient.invalidateQueries({ queryKey: ["overtime-my-requests"] });
      setActionTarget(null);
      setActionType(null);
      setActionNotes("");
      setActionError(null);
      setToastNotice({
        type: "success",
        message:
          variables.action === "approved"
            ? "Pengajuan lembur berhasil disetujui."
            : "Pengajuan lembur telah ditolak.",
      });
      setTimeout(() => setToastNotice(null), 4000);
    },
    onError: (err: {
      response?: { data?: { message?: string } };
      message?: string;
    }) => {
      setActionError(
        err.response?.data?.message ||
          err.message ||
          "Gagal memproses aksi persetujuan lembur."
      );
    },
  });

  const handleApplySubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setApplyError(null);

    if (!applyDate || !applyStartTime || !applyEndTime || !applyReason.trim()) {
      setApplyError("Harap lengkapi seluruh kolom formulir lembur.");
      return;
    }

    if (calculatedDuration === null || calculatedDuration <= 0) {
      setApplyError("Jam selesai lembur harus lebih besar dari jam mulai.");
      return;
    }

    applyMutation.mutate({
      date: applyDate,
      start_time: applyStartTime,
      end_time: applyEndTime,
      reason: applyReason.trim(),
    });
  };

  const handleActionConfirm = () => {
    if (!actionTarget || !actionType) return;
    setActionError(null);

    if (actionType === "rejected" && !actionNotes.trim()) {
      setActionError("Alasan penolakan wajib diisi untuk penolakan lembur.");
      return;
    }

    actionMutation.mutate({
      id: actionTarget.id_overtime_requests,
      action: actionType,
      notes: actionNotes,
    });
  };

  // Metrik Ringkasan
  const stats = useMemo(() => {
    const totalApprovedHours = overtimeList
      .filter((item) => item.status === "approved")
      .reduce((acc, curr) => acc + (Number(curr.duration_hours) || 0), 0);
    const pendingCount = overtimeList.filter(
      (item) => item.status === "pending"
    ).length;
    const approvedCount = overtimeList.filter(
      (item) => item.status === "approved"
    ).length;
    const rejectedCount = overtimeList.filter(
      (item) => item.status === "rejected"
    ).length;

    return {
      totalApprovedHours: Math.round(totalApprovedHours * 100) / 100,
      pendingCount,
      approvedCount,
      rejectedCount,
    };
  }, [overtimeList]);

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      {/* 1. iOS Large Title & Action Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-slate-900">
              Pengajuan Lembur
            </h1>
            <span className="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-orange-50 text-orange-700 border border-orange-200/80">
              {activeTab === "approvals" ? "Persetujuan Tim" : "Layanan Mandiri"}
            </span>
          </div>
          {canApprove && (
            <p className="text-xs sm:text-sm text-slate-500 mt-1">
              Tinjau dan proses persetujuan lembur staf untuk akumulasi otomatis upah lembur ke slip gaji.
            </p>
          )}
        </div>

        <div className="hidden sm:flex items-center gap-2 self-start sm:self-auto">
          {/* Apple HIG 48px touch target */}
          <button
            type="button"
            onClick={() => {
              setApplyError(null);
              setIsApplyOpen(true);
            }}
            className="inline-flex items-center justify-center gap-2 px-4 py-2.5 min-h-[44px] rounded-2xl bg-orange-600 hover:bg-orange-700 active:scale-[0.98] text-white font-bold text-xs sm:text-sm shadow-[0_2px_8px_rgba(234,88,12,0.25)] transition-all cursor-pointer"
          >
            <Plus className="w-4 h-4" aria-hidden="true" />
            <span>Ajukan Lembur</span>
          </button>
        </div>
      </div>

      {/* 2. Toast Notice */}
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

      {/* 3. Apple Fitness / Health Style KPI Metric Cards (Sembunyikan saat mode mobile) */}
      <div className="hidden sm:grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        {/* Card 1: Total Jam Disetujui */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-slate-500">
              Jam Disetujui
            </span>
            <div className="w-7 h-7 rounded-xl bg-orange-500/10 text-orange-600 flex items-center justify-center">
              <Clock4 className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-slate-900 tabular-nums">
              {stats.totalApprovedHours}
            </span>
            <span className="text-xs text-slate-500 font-medium">Jam</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Masuk perhitungan payroll
          </div>
        </div>

        {/* Card 2: Menunggu Persetujuan */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-amber-600">
              Menunggu Keputusan
            </span>
            <div className="w-7 h-7 rounded-xl bg-amber-500/10 text-amber-600 flex items-center justify-center">
              <Timer className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-amber-700 tabular-nums">
              {stats.pendingCount}
            </span>
            <span className="text-xs text-slate-500 font-medium">Pengajuan</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Dalam proses verifikasi
          </div>
        </div>

        {/* Card 3: Disetujui */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-emerald-600">
              Lembur Disetujui
            </span>
            <div className="w-7 h-7 rounded-xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
              <CheckCircle2 className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-emerald-700 tabular-nums">
              {stats.approvedCount}
            </span>
            <span className="text-xs text-slate-500 font-medium">Selesai</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Telah tervalidasi
          </div>
        </div>

        {/* Card 4: Ditolak */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-rose-600">
              Lembur Ditolak
            </span>
            <div className="w-7 h-7 rounded-xl bg-rose-500/10 text-rose-600 flex items-center justify-center">
              <X className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-rose-700 tabular-nums">
              {stats.rejectedCount}
            </span>
            <span className="text-xs text-slate-500 font-medium">Pengajuan</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Tidak disetujui
          </div>
        </div>
      </div>

      {/* 4. Controls: Role-aware Tabs & iOS Filter Pills */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        {canApprove ? (
          <div className="inline-flex p-1 bg-slate-200/60 rounded-2xl border border-slate-200/80 shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
            <button
              type="button"
              onClick={() => setSelectedTab("approvals")}
              className={cn(
                "px-3.5 py-1.5 text-xs font-semibold rounded-xl transition-all cursor-pointer flex items-center gap-1.5",
                activeTab === "approvals"
                  ? "bg-white text-slate-900 shadow-xs font-bold"
                  : "text-slate-600 hover:text-slate-900"
              )}
            >
              <CheckSquare className="w-3.5 h-3.5" />
              <span>Daftar Persetujuan</span>
            </button>
            <button
              type="button"
              onClick={() => setSelectedTab("my-requests")}
              className={cn(
                "px-3.5 py-1.5 text-xs font-semibold rounded-xl transition-all cursor-pointer flex items-center gap-1.5",
                activeTab === "my-requests"
                  ? "bg-white text-slate-900 shadow-xs font-bold"
                  : "text-slate-600 hover:text-slate-900"
              )}
            >
              <UserIcon className="w-3.5 h-3.5" />
              <span>Pengajuan Saya</span>
            </button>
          </div>
        ) : null}

        {/* Filter Pills (iOS Segmented style) */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0">
          {[
            { id: "all", label: "Semua" },
            { id: "pending", label: "Menunggu" },
            { id: "approved", label: "Disetujui" },
            { id: "rejected", label: "Ditolak" },
          ].map((chip) => (
            <button
              key={chip.id}
              type="button"
              onClick={() => setStatusFilter(chip.id)}
              className={cn(
                "px-3 py-1.5 rounded-full text-xs font-semibold transition-all cursor-pointer whitespace-nowrap min-h-[36px]",
                statusFilter === chip.id
                  ? "bg-slate-900 text-white shadow-xs"
                  : "bg-white text-slate-600 hover:bg-slate-100 border border-slate-200/80"
              )}
            >
              {chip.label}
            </button>
          ))}
        </div>
      </div>

      {/* 5. Inset Grouped Card: Riwayat / Daftar Pengajuan Lembur */}
      <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] space-y-4">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <div>
            <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
              {activeTab === "approvals"
                ? "Daftar Persetujuan Lembur Staf"
                : "Riwayat Pengajuan Lembur Saya"}
            </h2>
            <p className="text-[11px] sm:text-xs text-slate-500 mt-0.5">
              {activeTab === "approvals"
                ? "Daftar pengajuan lembur yang perlu ditinjau sebelum dikonfirmasi."
                : "Daftar jam lembur yang telah Anda ajukan beserta status atasan."}
            </p>
          </div>
          <span className="text-xs text-slate-500 font-mono tabular-nums">
            Total: <strong className="text-slate-800">{overtimeList.length}</strong> data
          </span>
        </div>

        {isLoading ? (
          <TableSkeleton rows={4} columns={6} />
        ) : isError ? (
          <ErrorState
            title="Gagal Memuat Data Lembur"
            message={
              (error as Error)?.message ||
              "Terjadi gangguan saat mengambil data permohonan lembur."
            }
            onRetry={() => refetch()}
          />
        ) : overtimeList.length === 0 ? (
          <EmptyState
            title="Tidak Ada Data Lembur"
            description={
              statusFilter !== "all"
                ? `Tidak ditemukan permohonan lembur dengan status "${statusFilter}".`
                : activeTab === "approvals"
                ? "Saat ini belum ada pengajuan lembur yang perlu ditinjau."
                : "Anda belum pernah mengajukan permohonan lembur."
            }
            actionLabel={activeTab === "my-requests" ? "Ajukan Lembur Baru" : undefined}
            onAction={
              activeTab === "my-requests"
                ? () => {
                    setApplyError(null);
                    setIsApplyOpen(true);
                  }
                : undefined
            }
          />
        ) : (
          <div>
            {/* 1. Mobile Inset Rows View (< sm) */}
            <div className="sm:hidden space-y-2.5">
              {overtimeList.map((item) => (
                <div
                  key={item.id_overtime_requests}
                  className="p-3.5 rounded-2xl border border-slate-200/70 bg-white hover:bg-slate-50/70 transition-colors space-y-2.5 shadow-[0_1px_2px_rgba(0,0,0,0.02)]"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-xl bg-orange-500/10 text-orange-600 flex items-center justify-center flex-shrink-0">
                        <Clock4 className="w-4 h-4" />
                      </div>
                      <div>
                        {activeTab === "approvals" && item.employee && (
                          <div className="text-xs font-bold text-slate-900 leading-tight">
                            {item.employee.user?.name || item.employee.nik}
                          </div>
                        )}
                        <div className="text-xs font-bold text-slate-900">
                          {formatDate(item.date)}
                        </div>
                        <div className="text-[11px] text-slate-500 font-mono tabular-nums">
                          {item.start_time.slice(0, 5)} - {item.end_time.slice(0, 5)} WIB
                        </div>
                      </div>
                    </div>
                    <StatusBadge status={item.status} />
                  </div>

                  {/* Durasi & Alasan */}
                  <div className="p-2.5 rounded-xl bg-slate-50/80 border border-slate-100 text-[11.5px] space-y-1.5 font-sans">
                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">Durasi Lembur:</span>
                      <span className="font-mono font-bold text-slate-900 tabular-nums">
                        {item.duration_hours} Jam
                      </span>
                    </div>
                    <div className="text-slate-700">
                      <span className="text-slate-400">Tugas: </span>
                      <span>{item.reason}</span>
                    </div>
                    {item.rejected_reason && (
                      <div className="text-rose-600 text-[11px] italic pt-1 border-t border-rose-100">
                        Alasan Penolakan: {item.rejected_reason}
                      </div>
                    )}
                  </div>

                  {/* Tombol Aksi Persetujuan pada Mobile */}
                  {activeTab === "approvals" &&
                    item.status === "pending" &&
                    canApprove && (
                      <div className="grid grid-cols-2 gap-2 pt-1">
                        <button
                          type="button"
                          onClick={() => {
                            setActionTarget(item);
                            setActionType("approved");
                            setActionNotes("");
                            setActionError(null);
                          }}
                          className="min-h-[40px] rounded-xl bg-emerald-600 hover:bg-emerald-700 active:scale-[0.98] text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-2xs transition-all cursor-pointer"
                        >
                          <Check className="w-3.5 h-3.5" />
                          <span>Setujui</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setActionTarget(item);
                            setActionType("rejected");
                            setActionNotes("");
                            setActionError(null);
                          }}
                          className="min-h-[40px] rounded-xl bg-rose-600 hover:bg-rose-700 active:scale-[0.98] text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-2xs transition-all cursor-pointer"
                        >
                          <X className="w-3.5 h-3.5" />
                          <span>Tolak</span>
                        </button>
                      </div>
                    )}
                </div>
              ))}
            </div>

            {/* 2. Desktop Table View (>= sm) */}
            <div className="hidden sm:block overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                    {activeTab === "approvals" && <th className="px-4 py-3">Karyawan</th>}
                    <th className="px-4 py-3">Tanggal Lembur</th>
                    <th className="px-4 py-3 font-mono">Waktu Mulai - Selesai</th>
                    <th className="px-4 py-3 text-center font-mono">Durasi</th>
                    <th className="px-4 py-3">Uraian Tugas Lembur</th>
                    <th className="px-4 py-3 text-center">Status</th>
                    {activeTab === "approvals" && (
                      <th className="px-4 py-3 text-right">Aksi Persetujuan</th>
                    )}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {overtimeList.map((item) => (
                    <tr
                      key={item.id_overtime_requests}
                      className="hover:bg-slate-50/60 transition-colors"
                    >
                      {activeTab === "approvals" && (
                        <td className="px-4 py-3.5">
                          <div className="font-bold text-slate-900">
                            {item.employee?.user?.name || item.employee?.nik || "-"}
                          </div>
                          <div className="text-[11px] text-slate-400 font-mono">
                            {item.employee?.department?.name || "Karyawan"}
                          </div>
                        </td>
                      )}
                      <td className="px-4 py-3.5 font-bold text-slate-900">
                        {formatDate(item.date)}
                      </td>
                      <td className="px-4 py-3.5 text-slate-600 font-mono tabular-nums">
                        {item.start_time.slice(0, 5)} - {item.end_time.slice(0, 5)} WIB
                      </td>
                      <td className="px-4 py-3.5 text-center font-mono font-bold text-slate-900 tabular-nums">
                        {item.duration_hours} Jam
                      </td>
                      <td className="px-4 py-3.5 text-slate-600 max-w-xs">
                        <div className="truncate">{item.reason}</div>
                        {item.rejected_reason && (
                          <div className="text-[11px] text-rose-600 mt-0.5 italic">
                            Catatan: {item.rejected_reason}
                          </div>
                        )}
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <StatusBadge status={item.status} />
                      </td>
                      {activeTab === "approvals" && (
                        <td className="px-4 py-3.5 text-right">
                          {item.status === "pending" && canApprove ? (
                            <div className="inline-flex items-center gap-1.5">
                              <button
                                type="button"
                                onClick={() => {
                                  setActionTarget(item);
                                  setActionType("approved");
                                  setActionNotes("");
                                  setActionError(null);
                                }}
                                className="px-2.5 py-1.5 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 font-bold text-xs flex items-center gap-1 border border-emerald-200 transition-colors cursor-pointer"
                              >
                                <Check className="w-3 h-3" />
                                <span>Setujui</span>
                              </button>
                              <button
                                type="button"
                                onClick={() => {
                                  setActionTarget(item);
                                  setActionType("rejected");
                                  setActionNotes("");
                                  setActionError(null);
                                }}
                                className="px-2.5 py-1.5 rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-700 font-bold text-xs flex items-center gap-1 border border-rose-200 transition-colors cursor-pointer"
                              >
                                <X className="w-3 h-3" />
                                <span>Tolak</span>
                              </button>
                            </div>
                          ) : (
                            <span className="text-xs text-slate-400 italic">
                              {item.approver?.name
                                ? `Oleh ${item.approver.name}`
                                : "Selesai"}
                            </span>
                          )}
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* 6. Modal Ajukan Lembur Baru (Apple HIG Sheet Style) */}
      {isApplyOpen && (
        <Modal
          isOpen={true}
          onClose={() => {
            if (!applyMutation.isPending) {
              setIsApplyOpen(false);
              setApplyError(null);
            }
          }}
          title="Ajukan Permohonan Lembur"
          description="Pastikan jadwal lembur yang diajukan tidak bertabrakan dengan jadwal lainnya."
          maxWidth="md"
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => {
                  setIsApplyOpen(false);
                  setApplyError(null);
                }}
                disabled={applyMutation.isPending}
                className="min-h-[44px] rounded-xl"
              >
                Batal
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={handleApplySubmit}
                isLoading={applyMutation.isPending}
                className="min-h-[44px] rounded-xl bg-orange-600 hover:bg-orange-700 font-bold"
              >
                Kirim Pengajuan
              </Button>
            </div>
          }
        >
          <form onSubmit={handleApplySubmit} className="space-y-4 text-xs">
            {applyError && (
              <div
                role="alert"
                className="p-3.5 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 font-medium"
              >
                {applyError}
              </div>
            )}

            <div>
              <label
                htmlFor="overtime_date"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Tanggal Lembur <span className="text-rose-500">*</span>
              </label>
              <input
                id="overtime_date"
                type="date"
                value={applyDate}
                onChange={(e) => setApplyDate(e.target.value)}
                className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
                required
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label
                  htmlFor="overtime_start_time"
                  className="block text-xs font-semibold text-slate-700 mb-1.5"
                >
                  Jam Mulai <span className="text-rose-500">*</span>
                </label>
                <input
                  id="overtime_start_time"
                  type="time"
                  value={applyStartTime}
                  onChange={(e) => setApplyStartTime(e.target.value)}
                  className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
                  required
                />
              </div>

              <div>
                <label
                  htmlFor="overtime_end_time"
                  className="block text-xs font-semibold text-slate-700 mb-1.5"
                >
                  Jam Selesai <span className="text-rose-500">*</span>
                </label>
                <input
                  id="overtime_end_time"
                  type="time"
                  value={applyEndTime}
                  onChange={(e) => setApplyEndTime(e.target.value)}
                  className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
                  required
                />
              </div>
            </div>

            {/* Durasi Terkalkulasi Otomatis */}
            <div className="p-3.5 rounded-2xl bg-orange-50/70 border border-orange-200/80 flex items-center justify-between text-xs">
              <span className="text-slate-700 font-semibold">Estimasi Durasi Lembur:</span>
              <span
                className={cn(
                  "font-mono font-extrabold tabular-nums",
                  calculatedDuration && calculatedDuration > 0
                    ? "text-orange-700 text-sm"
                    : "text-rose-600"
                )}
              >
                {calculatedDuration !== null && calculatedDuration > 0
                  ? `${calculatedDuration} Jam (${Math.round(calculatedDuration * 60)} menit)`
                  : "Format jam tidak valid"}
              </span>
            </div>

            <div>
              <label
                htmlFor="overtime_reason"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Uraian Alasan / Tugas Lembur <span className="text-rose-500">*</span>
              </label>
              <textarea
                id="overtime_reason"
                value={applyReason}
                onChange={(e) => setApplyReason(e.target.value)}
                placeholder="Tuliskan rincian tugas lembur yang dikerjakan secara spesifik..."
                rows={3}
                className="w-full rounded-2xl border border-slate-200/80 bg-white p-3.5 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500"
                required
              />
            </div>
          </form>
        </Modal>
      )}

      {/* 7. Modal Konfirmasi Persetujuan / Penolakan (Admin / HR) */}
      {actionTarget && actionType && (
        <Modal
          isOpen={true}
          onClose={() => {
            if (!actionMutation.isPending) {
              setActionTarget(null);
              setActionType(null);
              setActionNotes("");
              setActionError(null);
            }
          }}
          title={
            actionType === "approved"
              ? "Konfirmasi Persetujuan Lembur"
              : "Konfirmasi Penolakan Lembur"
          }
          description={`Pengajuan dari ${
            actionTarget.employee?.user?.name || "Karyawan"
          } untuk lembur selama ${actionTarget.duration_hours} jam.`}
          maxWidth="md"
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => {
                  setActionTarget(null);
                  setActionType(null);
                  setActionNotes("");
                  setActionError(null);
                }}
                disabled={actionMutation.isPending}
                className="min-h-[44px] rounded-xl"
              >
                Batal
              </Button>
              <Button
                variant={actionType === "approved" ? "primary" : "danger"}
                size="md"
                onClick={handleActionConfirm}
                isLoading={actionMutation.isPending}
                className="min-h-[44px] rounded-xl font-bold"
              >
                {actionType === "approved" ? "Setujui Lembur" : "Tolak Lembur"}
              </Button>
            </div>
          }
        >
          <div className="space-y-4 text-xs">
            {actionError && (
              <div
                role="alert"
                className="p-3.5 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 font-medium"
              >
                {actionError}
              </div>
            )}

            <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100 space-y-1.5 font-sans">
              <div className="flex justify-between">
                <span className="text-slate-500">Tanggal:</span>
                <span className="font-bold text-slate-900">
                  {formatDate(actionTarget.date)}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Waktu:</span>
                <span className="font-mono font-bold text-slate-900">
                  {actionTarget.start_time.slice(0, 5)} - {actionTarget.end_time.slice(0, 5)} WIB ({actionTarget.duration_hours} Jam)
                </span>
              </div>
              <div className="text-slate-600 pt-1 border-t border-slate-200/60">
                <span className="text-slate-400">Tugas: </span>
                <span>{actionTarget.reason}</span>
              </div>
            </div>

            {actionType === "rejected" && (
              <div>
                <label
                  htmlFor="actionNotesInput"
                  className="block text-xs font-semibold text-slate-700 mb-1.5"
                >
                  Alasan Penolakan <span className="text-rose-500">*</span>
                </label>
                <textarea
                  id="actionNotesInput"
                  rows={3}
                  value={actionNotes}
                  onChange={(e) => setActionNotes(e.target.value)}
                  placeholder="Tuliskan catatan alasan penolakan..."
                  className="w-full rounded-2xl border border-slate-200/80 bg-white p-3.5 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
                  required
                />
              </div>
            )}
          </div>
        </Modal>
      )}

      {/* Floating Action Button (FAB) + Mobile */}
      <button
        type="button"
        onClick={() => {
          setApplyError(null);
          setIsApplyOpen(true);
        }}
        aria-label="Ajukan Lembur"
        className="sm:hidden fixed bottom-20 right-4 z-40 w-14 h-14 rounded-full bg-orange-600 hover:bg-orange-700 active:scale-90 text-white shadow-[0_8px_24px_rgba(234,88,12,0.45)] flex items-center justify-center transition-transform cursor-pointer focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-orange-500/30"
      >
        <Plus className="w-7 h-7 stroke-[2.5]" aria-hidden="true" />
      </button>
    </div>
  );
}
