"use client";

import React, { useState, useEffect, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Check,
  X,
  Plus,
  FileText,
  ExternalLink,
  CheckCircle2,
  AlertCircle,
  CalendarCheck,
  CalendarDays,
  Clock,
  Sparkles,
  ArrowUpRight,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton, Skeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { SingleDateRangePicker } from "@/components/ui/SingleDateRangePicker";
import apiClient from "@/lib/axios";
import { cn, formatDate } from "@/lib/utils";
import type { ApiResponse, LeaveRequest, LeaveType, LeaveBalance, User } from "@/types";

export default function LeavesPage() {
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

  const [activeTab, setActiveTab] = useState<"approvals" | "types">("approvals");
  const [statusFilter, setStatusFilter] = useState<string>("all");

  // Approval / Rejection Modal State
  const [actionTarget, setActionTarget] = useState<LeaveRequest | null>(null);
  const [actionType, setActionType] = useState<"approved" | "rejected" | null>(null);
  const [rejectionNotes, setRejectionNotes] = useState("");
  const [actionError, setActionError] = useState<string | null>(null);

  // Create Leave Type Modal State
  const [isCreateTypeOpen, setIsCreateTypeOpen] = useState(false);
  const [newTypeName, setNewTypeName] = useState("");
  const [newTypeQuota, setNewTypeQuota] = useState("12");
  const [newTypeIsPaid, setNewTypeIsPaid] = useState(true);
  const [createTypeError, setCreateTypeError] = useState<string | null>(null);

  // Apply Leave Modal State (Employee self-service)
  const [isApplyLeaveOpen, setIsApplyLeaveOpen] = useState(false);
  const [applyLeaveTypeId, setApplyLeaveTypeId] = useState("");
  const [applyStartDate, setApplyStartDate] = useState("");
  const [applyEndDate, setApplyEndDate] = useState("");
  const [applyReason, setApplyReason] = useState("");
  const [applyAttachment, setApplyAttachment] = useState<File | null>(null);
  const [applyError, setApplyError] = useState<string | null>(null);
  const [toastNotice, setToastNotice] = useState<{ type: "success" | "error"; message: string } | null>(null);

  // Queries
  const {
    data: leaveRequests = [],
    isLoading: isRequestsLoading,
    isError: isRequestsError,
    error: requestsError,
    refetch: refetchRequests,
  } = useQuery({
    queryKey: isEmployee ? ["my-leave-requests", statusFilter] : ["leave-approvals", statusFilter],
    queryFn: async () => {
      const endpoint = isEmployee ? "/leave/my-requests" : "/leave/approvals";
      const params: Record<string, string> = {};
      if (statusFilter !== "all") {
        params.status = statusFilter;
      }
      const response = await apiClient.get<
        ApiResponse<LeaveRequest[] | { data: LeaveRequest[] }>
      >(endpoint, {
        params,
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
    },
    enabled: activeTab === "approvals" || isEmployee,
  });

  const {
    data: leaveTypes = [],
    isLoading: isTypesLoading,
    isError: isTypesError,
    error: typesError,
    refetch: refetchTypes,
  } = useQuery({
    queryKey: ["leave-types"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<LeaveType[]>>("/leave/types");
      if (response.data.success && Array.isArray(response.data.data)) {
        return response.data.data;
      }
      return [];
    },
    enabled: activeTab === "types" || isApplyLeaveOpen,
  });

  // Leave Balances (untuk kalkulasi kuota cuti karyawan)
  const {
    data: leaveBalances = [],
    isLoading: isBalancesLoading,
    refetch: refetchBalances,
  } = useQuery({
    queryKey: ["employee-leave-balances"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<LeaveBalance[]>>("/leave/balance");
      if (response.data.success && Array.isArray(response.data.data)) {
        return response.data.data;
      }
      return [];
    },
    enabled: isEmployee,
  });

  // Stats calculation
  const stats = useMemo(() => {
    const totalQuota = leaveBalances.reduce((acc, b) => acc + (b.quota_days || 0), 0);
    const totalUsed = leaveBalances.reduce((acc, b) => acc + (b.used_days || 0), 0);
    const totalAvailable = leaveBalances.reduce((acc, b) => acc + (b.available_days || 0), 0);
    const pendingCount = leaveRequests.filter((r) => r.status === "pending").length;
    const approvedCount = leaveRequests.filter((r) => r.status === "approved").length;

    return {
      totalQuota: totalQuota > 0 ? totalQuota : 12,
      totalUsed,
      totalAvailable: totalQuota > 0 ? totalAvailable : Math.max(0, 12 - totalUsed),
      pendingCount,
      approvedCount,
    };
  }, [leaveBalances, leaveRequests]);

  // Mutations
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
      const response = await apiClient.post<ApiResponse<LeaveRequest>>(
        `/leave/approvals/${id}/action`,
        {
          action,
          notes,
        }
      );
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["leave-approvals"] });
      setActionTarget(null);
      setActionType(null);
      setRejectionNotes("");
      setActionError(null);
      setToastNotice({
        type: "success",
        message: "Status permohonan cuti berhasil diperbarui.",
      });
      setTimeout(() => setToastNotice(null), 4000);
    },
    onError: (err: { response?: { data?: { message?: string } }; message?: string }) => {
      const msg = err.response?.data?.message || err.message || "Gagal memproses permohonan.";
      setActionError(msg);
    },
  });

  const createTypeMutation = useMutation({
    mutationFn: async (data: { name: string; quota_days: number; is_paid: boolean }) => {
      const response = await apiClient.post<ApiResponse<LeaveType>>("/leave/types", data);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["leave-types"] });
      setIsCreateTypeOpen(false);
      setNewTypeName("");
      setNewTypeQuota("12");
      setNewTypeIsPaid(true);
      setCreateTypeError(null);
      setToastNotice({
        type: "success",
        message: "Tipe cuti baru berhasil ditambahkan.",
      });
      setTimeout(() => setToastNotice(null), 4000);
    },
    onError: (err: { response?: { data?: { message?: string } }; message?: string }) => {
      const msg = err.response?.data?.message || err.message || "Gagal membuat jenis cuti.";
      setCreateTypeError(msg);
    },
  });

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
      queryClient.invalidateQueries({ queryKey: ["my-leave-requests"] });
      queryClient.invalidateQueries({ queryKey: ["employee-leave-balances"] });
      setIsApplyLeaveOpen(false);
      setApplyLeaveTypeId("");
      setApplyStartDate("");
      setApplyEndDate("");
      setApplyReason("");
      setApplyAttachment(null);
      setApplyError(null);
      setToastNotice({
        type: "success",
        message: "Permohonan izin cuti berhasil diajukan dan sedang menunggu persetujuan atasan.",
      });
      setTimeout(() => setToastNotice(null), 4000);
    },
    onError: (err: { response?: { data?: { message?: string } }; message?: string }) => {
      setApplyError(
        err.response?.data?.message || err.message || "Gagal mengajukan permohonan cuti."
      );
    },
  });

  const openActionModal = (request: LeaveRequest, action: "approved" | "rejected") => {
    setActionTarget(request);
    setActionType(action);
    setRejectionNotes("");
    setActionError(null);
  };

  const handleConfirmAction = () => {
    if (!actionTarget || !actionType) return;
    if (actionType === "rejected" && !rejectionNotes.trim()) {
      setActionError("Alasan penolakan wajib diisi.");
      return;
    }
    actionMutation.mutate({
      id: actionTarget.id_leave_requests,
      action: actionType,
      notes: actionType === "rejected" ? rejectionNotes.trim() : undefined,
    });
  };

  const handleApplyLeaveSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setApplyError(null);

    if (!applyLeaveTypeId) {
      setApplyError("Silakan pilih jenis cuti terlebih dahulu.");
      return;
    }

    if (!applyStartDate || !applyEndDate) {
      setApplyError("Silakan tentukan rentang tanggal cuti pada kalender (mulai dan selesai).");
      return;
    }

    if (new Date(applyStartDate) > new Date(applyEndDate)) {
      setApplyError("Tanggal selesai cuti tidak boleh lebih awal dari tanggal mulai.");
      return;
    }

    if (!applyReason.trim()) {
      setApplyError("Alasan keperluan pengajuan cuti wajib diisi.");
      return;
    }

    const formData = new FormData();
    formData.append("id_leave_types", applyLeaveTypeId);
    formData.append("start_date", applyStartDate);
    formData.append("end_date", applyEndDate);
    formData.append("reason", applyReason.trim());
    if (applyAttachment) {
      formData.append("attachment", applyAttachment);
    }

    applyLeaveMutation.mutate(formData);
  };

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      {/* 1. iOS Large Title & Action Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#0B2545]">
              {isEmployee ? "Pengajuan Cuti & Izin" : "Manajemen Cuti & Izin"}
            </h1>
            <span className="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-[#DCFCE7] text-[#15803D] border border-[#BBF7D0]">
              {isEmployee ? "Layanan Mandiri" : "Operasional HR"}
            </span>
          </div>
          {!isEmployee && (
            <p className="text-xs sm:text-sm text-slate-500 mt-1">
              Persetujuan permohonan cuti staf dan konfigurasi kuota hak cuti perusahaan.
            </p>
          )}
        </div>

        <div className="hidden sm:flex items-center gap-2 self-start sm:self-auto">
          {/* Tombol Utama Ajukan Cuti (Apple HIG 48px touch target) */}
          <button
            type="button"
            onClick={() => {
              setApplyError(null);
              setIsApplyLeaveOpen(true);
            }}
            className="inline-flex items-center justify-center gap-2 px-4 py-2.5 min-h-[44px] rounded-2xl bg-[#16A34A] hover:bg-[#15803D] active:scale-[0.98] text-white font-bold text-xs sm:text-sm shadow-xs transition-all cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600"
          >
            <Plus className="w-4 h-4" aria-hidden="true" />
            <span>Ajukan Cuti Baru</span>
          </button>

          {!isEmployee && activeTab === "types" && (
            <button
              type="button"
              onClick={() => {
                setCreateTypeError(null);
                setIsCreateTypeOpen(true);
              }}
              className="inline-flex items-center justify-center gap-2 px-3.5 py-2.5 min-h-[44px] rounded-2xl bg-white hover:bg-slate-50 active:scale-[0.98] text-slate-700 font-semibold text-xs border border-slate-200/80 shadow-[0_1px_2px_rgba(0,0,0,0.03)] transition-all cursor-pointer"
            >
              <Plus className="w-4 h-4 text-slate-500" aria-hidden="true" />
              <span>Tambah Jenis</span>
            </button>
          )}
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

      {/* 3. Summary Metric Cards (Sembunyikan saat mode mobile) */}
      <div className="hidden sm:grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        {/* Card 1: Kuota Tersedia */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-slate-500">
              Sisa Kuota Cuti
            </span>
            <div className="w-7 h-7 rounded-xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
              <CalendarCheck className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-slate-900 tabular-nums">
              {stats.totalAvailable}
            </span>
            <span className="text-xs text-slate-500 font-medium">Hari</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Dari total {stats.totalQuota} hari kuota
          </div>
        </div>

        {/* Card 2: Cuti Terpakai */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-slate-500">
              Cuti Terpakai
            </span>
            <div className="w-7 h-7 rounded-xl bg-blue-500/10 text-blue-600 flex items-center justify-center">
              <CalendarDays className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-blue-700 tabular-nums">
              {stats.totalUsed}
            </span>
            <span className="text-xs text-slate-500 font-medium">Hari</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Telah disetujui atasan
          </div>
        </div>

        {/* Card 3: Menunggu Keputusan */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-amber-600">
              Menunggu Keputusan
            </span>
            <div className="w-7 h-7 rounded-xl bg-amber-500/10 text-amber-600 flex items-center justify-center">
              <Clock className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-amber-700 tabular-nums">
              {stats.pendingCount}
            </span>
            <span className="text-xs text-slate-500 font-medium">Pengajuan</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Dalam tahap peninjauan
          </div>
        </div>

        {/* Card 4: Pengajuan Disetujui */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-emerald-600">
              Total Disetujui
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
            Riwayat cuti sukses
          </div>
        </div>
      </div>

      {/* 4. Controls: Role-aware Tabs & iOS Filter Pills */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        {/* Tab Switcher untuk Manager/HR */}
        {!isEmployee ? (
          <div className="inline-flex p-1 bg-slate-200/60 rounded-2xl border border-slate-200/80 shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
            <button
              type="button"
              onClick={() => setActiveTab("approvals")}
              className={cn(
                "px-3.5 py-1.5 text-xs font-semibold rounded-xl transition-all cursor-pointer flex items-center gap-1.5",
                activeTab === "approvals"
                  ? "bg-white text-slate-900 shadow-xs font-bold"
                  : "text-slate-600 hover:text-slate-900"
              )}
            >
              <CalendarCheck className="w-3.5 h-3.5" />
              <span>Persetujuan Permohonan</span>
            </button>
            <button
              type="button"
              onClick={() => setActiveTab("types")}
              className={cn(
                "px-3.5 py-1.5 text-xs font-semibold rounded-xl transition-all cursor-pointer flex items-center gap-1.5",
                activeTab === "types"
                  ? "bg-white text-slate-900 shadow-xs font-bold"
                  : "text-slate-600 hover:text-slate-900"
              )}
            >
              <FileText className="w-3.5 h-3.5" />
              <span>Master Tipe Cuti</span>
            </button>
          </div>
        ) : null}

        {/* Filter Pills (iOS Segmented style) */}
        {(activeTab === "approvals" || isEmployee) && (
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0">
            {[
              { key: "all", label: "Semua" },
              { key: "pending", label: "Menunggu" },
              { key: "approved", label: "Disetujui" },
              { key: "rejected", label: "Ditolak" },
            ].map((f) => (
              <button
                key={f.key}
                type="button"
                onClick={() => setStatusFilter(f.key)}
                className={cn(
                  "px-3 py-1.5 rounded-full text-xs font-semibold transition-all cursor-pointer whitespace-nowrap min-h-[36px]",
                  statusFilter === f.key
                    ? "bg-slate-900 text-white shadow-xs"
                    : "bg-white text-slate-600 hover:bg-slate-100 border border-slate-200/80"
                )}
              >
                {f.label}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* 5. Inset Grouped Card: Riwayat / Daftar Permohonan Cuti */}
      {(activeTab === "approvals" || isEmployee) && (
        <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div>
              <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
                {isEmployee ? "Riwayat Permohonan Cuti Saya" : "Daftar Permohonan Izin Staf"}
              </h2>
              <p className="text-[11px] sm:text-xs text-slate-500 mt-0.5">
                {isEmployee
                  ? "Daftar permohonan yang telah Anda ajukan beserta status persetujuannya."
                  : "Daftar permohonan staf yang perlu ditinjau sebelum memberikan keputusan."}
              </p>
            </div>
            <span className="text-xs text-slate-500 font-mono tabular-nums">
              Total: <strong className="text-slate-800">{leaveRequests.length}</strong>
            </span>
          </div>

          {isRequestsLoading ? (
            <TableSkeleton rows={4} columns={6} />
          ) : isRequestsError ? (
            <ErrorState
              title="Gagal Memuat Permohonan"
              message={
                requestsError instanceof Error
                  ? requestsError.message
                  : "Terjadi kesalahan saat memuat daftar permohonan cuti."
              }
              onRetry={() => refetchRequests()}
            />
          ) : leaveRequests.length === 0 ? (
            <EmptyState
              title="Belum Ada Permohonan Cuti"
              description={
                isEmployee
                  ? "Anda belum memiliki riwayat pengajuan cuti. Klik tombol di bawah untuk membuat pengajuan baru."
                  : statusFilter === "pending"
                  ? "Tidak ada permohonan cuti yang sedang menunggu persetujuan."
                  : "Belum ada riwayat permohonan cuti staf pada kriteria ini."
              }
              actionLabel={isEmployee ? "Ajukan Cuti Baru" : undefined}
              onAction={
                isEmployee
                  ? () => {
                      setApplyError(null);
                      setIsApplyLeaveOpen(true);
                    }
                  : undefined
              }
            />
          ) : (
            <div>
              {/* 1. Mobile Inset Rows View (< sm) */}
              <div className="sm:hidden space-y-2.5">
                {leaveRequests.map((item) => (
                  <div
                    key={item.id_leave_requests}
                    className="p-3.5 rounded-2xl border border-slate-200/70 bg-white hover:bg-slate-50/70 transition-colors space-y-2.5 shadow-[0_1px_2px_rgba(0,0,0,0.02)]"
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center flex-shrink-0">
                          <CalendarCheck className="w-4 h-4" />
                        </div>
                        <div>
                          {!isEmployee && (
                            <div className="text-xs font-bold text-slate-900 leading-tight">
                              {item.employee?.user?.name || `Karyawan #${item.id_employees}`}
                            </div>
                          )}
                          <div className="text-xs font-bold text-slate-900">
                            {item.leave_type?.name || "Cuti / Izin"}
                          </div>
                          <div className="text-[11px] text-slate-500 font-mono tabular-nums">
                            {item.start_date === item.end_date
                              ? formatDate(item.start_date)
                              : `${formatDate(item.start_date)} - ${formatDate(item.end_date)}`}
                          </div>
                        </div>
                      </div>
                      <StatusBadge
                        status={
                          item.status === "approved"
                            ? "disetujui"
                            : item.status === "rejected"
                            ? "ditolak"
                            : "menunggu"
                        }
                      />
                    </div>

                    {/* Durasi & Alasan */}
                    <div className="p-2.5 rounded-xl bg-slate-50/80 border border-slate-100 text-[11.5px] space-y-1.5">
                      <div className="flex items-center justify-between">
                        <span className="text-slate-500">Durasi:</span>
                        <span className="font-mono font-bold text-slate-900 tabular-nums">
                          {item.total_days} hari
                        </span>
                      </div>
                      <div className="text-slate-700">
                        <span className="text-slate-400">Alasan: </span>
                        <span>{item.reason}</span>
                      </div>
                      {item.attachment_url && (
                        <div className="pt-1 border-t border-slate-200/60">
                          <a
                            href={item.attachment_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1 text-emerald-600 font-semibold text-[11px] hover:underline"
                          >
                            <FileText className="w-3.5 h-3.5" />
                            <span>Lihat Lampiran Bukti</span>
                            <ExternalLink className="w-3 h-3" />
                          </a>
                        </div>
                      )}
                      {item.rejected_reason && (
                        <div className="text-rose-600 text-[11px] italic pt-1 border-t border-rose-100">
                          Catatan: {item.rejected_reason}
                        </div>
                      )}
                    </div>

                    {/* Tombol Aksi Persetujuan untuk Manager / HR pada Mobile */}
                    {!isEmployee && item.status === "pending" && (
                      <div className="grid grid-cols-2 gap-2 pt-1">
                        <button
                          type="button"
                          onClick={() => openActionModal(item, "approved")}
                          className="min-h-[40px] rounded-xl bg-emerald-600 hover:bg-emerald-700 active:scale-[0.98] text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-2xs transition-all cursor-pointer"
                        >
                          <Check className="w-3.5 h-3.5" />
                          <span>Setujui</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => openActionModal(item, "rejected")}
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
                      {!isEmployee && <th className="px-4 py-3">Nama Pegawai</th>}
                      <th className="px-4 py-3">Jenis Izin</th>
                      <th className="px-4 py-3 font-mono">Rentang Tanggal</th>
                      <th className="px-4 py-3 text-center font-mono">Durasi</th>
                      <th className="px-4 py-3">Alasan & Lampiran</th>
                      <th className="px-4 py-3 text-center">Status</th>
                      <th className="px-4 py-3 text-right">
                        {isEmployee ? "Catatan Atasan" : "Tindakan"}
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium">
                    {leaveRequests.map((item) => (
                      <tr
                        key={item.id_leave_requests}
                        className="hover:bg-slate-50/60 transition-colors"
                      >
                        {!isEmployee && (
                          <td className="px-4 py-3.5">
                            <div className="font-bold text-slate-900">
                              {item.employee?.user?.name || `Karyawan #${item.id_employees}`}
                            </div>
                            <div className="text-[11px] text-slate-400 font-mono">
                              {item.employee?.nik || ""}
                            </div>
                          </td>
                        )}
                        <td className="px-4 py-3.5 font-bold text-slate-900">
                          {item.leave_type?.name || "Cuti / Izin"}
                        </td>
                        <td className="px-4 py-3.5 text-slate-600 font-mono tabular-nums">
                          {item.start_date === item.end_date
                            ? formatDate(item.start_date)
                            : `${formatDate(item.start_date)} - ${formatDate(item.end_date)}`}
                        </td>
                        <td className="px-4 py-3.5 text-center font-mono font-bold text-slate-900 tabular-nums">
                          {item.total_days} hari
                        </td>
                        <td className="px-4 py-3.5 text-slate-600 max-w-xs">
                          <div className="truncate">{item.reason}</div>
                          {item.attachment_url && (
                            <a
                              href={item.attachment_url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="inline-flex items-center gap-1 text-emerald-600 hover:underline text-[11px] mt-0.5 font-semibold"
                            >
                              <FileText className="w-3 h-3" />
                              <span>Lampiran</span>
                              <ExternalLink className="w-2.5 h-2.5" />
                            </a>
                          )}
                          {item.rejected_reason && (
                            <div className="text-[11px] text-rose-600 mt-0.5 italic">
                              Alasan: {item.rejected_reason}
                            </div>
                          )}
                        </td>
                        <td className="px-4 py-3.5 text-center">
                          <StatusBadge
                            status={
                              item.status === "approved"
                                ? "disetujui"
                                : item.status === "rejected"
                                ? "ditolak"
                                : "menunggu"
                            }
                          />
                        </td>
                        <td className="px-4 py-3.5 text-right">
                          {isEmployee ? (
                            <div className="text-xs">
                              {item.status === "pending" ? (
                                <span className="text-amber-600 font-medium">
                                  Menunggu Atasan
                                </span>
                              ) : item.status === "approved" ? (
                                <span className="text-emerald-600 font-semibold">
                                  Disetujui
                                </span>
                              ) : (
                                <span className="text-rose-600 font-semibold">
                                  Ditolak
                                </span>
                              )}
                            </div>
                          ) : item.status === "pending" ? (
                            <div className="inline-flex items-center gap-1.5">
                              <button
                                type="button"
                                onClick={() => openActionModal(item, "approved")}
                                className="px-2.5 py-1.5 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 font-bold text-xs flex items-center gap-1 border border-emerald-200 transition-colors cursor-pointer"
                              >
                                <Check className="w-3 h-3" />
                                <span>Setujui</span>
                              </button>
                              <button
                                type="button"
                                onClick={() => openActionModal(item, "rejected")}
                                className="px-2.5 py-1.5 rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-700 font-bold text-xs flex items-center gap-1 border border-rose-200 transition-colors cursor-pointer"
                              >
                                <X className="w-3 h-3" />
                                <span>Tolak</span>
                              </button>
                            </div>
                          ) : (
                            <span className="text-xs text-slate-400 italic">Selesai</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}

      {/* 6. Tab Content 2: Master Leave Types (Admin / HR) */}
      {!isEmployee && activeTab === "types" && (
        <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div>
              <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
                Master Tipe Cuti Perusahaan
              </h2>
              <p className="text-[11px] sm:text-xs text-slate-500 mt-0.5">
                Konfigurasi kuota tahunan dan status gaji (paid/unpaid).
              </p>
            </div>
          </div>

          {isTypesLoading ? (
            <TableSkeleton rows={3} columns={4} />
          ) : isTypesError ? (
            <ErrorState
              title="Gagal Memuat Tipe Cuti"
              message={
                typesError instanceof Error
                  ? typesError.message
                  : "Terjadi kesalahan saat memuat tipe cuti."
              }
              onRetry={() => refetchTypes()}
            />
          ) : leaveTypes.length === 0 ? (
            <EmptyState
              title="Belum Ada Tipe Cuti"
              description="Perusahaan Anda belum mengonfigurasi tipe cuti. Tambahkan tipe cuti baru seperti Cuti Tahunan atau Izin Sakit."
              actionLabel="Tambah Tipe Cuti"
              onAction={() => {
                setCreateTypeError(null);
                setIsCreateTypeOpen(true);
              }}
            />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                    <th className="px-4 py-3">Nama Jenis Cuti</th>
                    <th className="px-4 py-3 text-center font-mono">Alokasi Kuota</th>
                    <th className="px-4 py-3 text-center">Status Upah</th>
                    <th className="px-4 py-3 text-right font-mono">ID Referensi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {leaveTypes.map((type) => (
                    <tr
                      key={type.id_leave_types}
                      className="hover:bg-slate-50/60 transition-colors"
                    >
                      <td className="px-4 py-3.5 font-bold text-slate-900">
                        {type.name}
                      </td>
                      <td className="px-4 py-3.5 text-center font-mono font-bold text-slate-900 tabular-nums">
                        {type.quota_days} hari/tahun
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <span
                          className={cn(
                            "inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold tracking-tight",
                            type.is_paid
                              ? "bg-emerald-50 text-emerald-700 border border-emerald-200/80"
                              : "bg-slate-100 text-slate-600 border border-slate-200/80"
                          )}
                        >
                          {type.is_paid ? "Berbayar (Paid)" : "Tidak Berbayar (Unpaid)"}
                        </span>
                      </td>
                      <td className="px-4 py-3.5 text-right font-mono text-slate-400">
                        #{type.id_leave_types}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* 7. Modal: Ajukan Cuti Mandiri (Apple HIG Sheet Style) */}
      {isApplyLeaveOpen && (
        <Modal
          isOpen={true}
          onClose={() => {
            if (!applyLeaveMutation.isPending) {
              setIsApplyLeaveOpen(false);
              setApplyError(null);
            }
          }}
          title="Ajukan Permohonan Cuti & Izin"
          description="Pilih jenis izin cuti, tentukan rentang tanggal, dan lampirkan alasan keperluan."
          maxWidth="md"
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => {
                  setIsApplyLeaveOpen(false);
                  setApplyError(null);
                }}
                disabled={applyLeaveMutation.isPending}
                className="min-h-[44px] rounded-xl"
              >
                Batal
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={handleApplyLeaveSubmit}
                isLoading={applyLeaveMutation.isPending}
                className="min-h-[44px] rounded-xl bg-[#16A34A] hover:bg-[#15803D] font-bold"
              >
                Kirim Permohonan
              </Button>
            </div>
          }
        >
          <form onSubmit={handleApplyLeaveSubmit} className="space-y-4 text-xs">
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
                htmlFor="applyLeaveTypeSelect"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Jenis Cuti <span className="text-rose-500">*</span>
              </label>
              <select
                id="applyLeaveTypeSelect"
                value={applyLeaveTypeId}
                onChange={(e) => setApplyLeaveTypeId(e.target.value)}
                className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 min-h-[46px]"
                required
              >
                <option value="">-- Pilih Jenis Cuti --</option>
                {leaveTypes.map((t) => (
                  <option key={t.id_leave_types} value={t.id_leave_types}>
                    {t.name} (Kuota: {t.quota_days} hari - {t.is_paid ? "Berbayar" : "Unpaid"})
                  </option>
                ))}
              </select>
            </div>

            <div>
              <SingleDateRangePicker
                startDate={applyStartDate}
                endDate={applyEndDate}
                onChange={({ startDate, endDate }) => {
                  setApplyStartDate(startDate);
                  setApplyEndDate(endDate);
                  if (applyError) setApplyError(null);
                }}
                label="Rentang Tanggal Cuti"
                required
                defaultExpanded={true}
              />
              <input type="hidden" name="start_date" value={applyStartDate} />
              <input type="hidden" name="end_date" value={applyEndDate} />
            </div>

            <div>
              <label
                htmlFor="applyReasonInput"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Alasan Pengajuan <span className="text-rose-500">*</span>
              </label>
              <textarea
                id="applyReasonInput"
                rows={3}
                value={applyReason}
                onChange={(e) => setApplyReason(e.target.value)}
                placeholder="Tuliskan keterangan keperluan cuti atau izin secara jelas..."
                className="w-full rounded-2xl border border-slate-200/80 bg-white p-3.5 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600"
                required
              />
            </div>

            <div>
              <label
                htmlFor="applyAttachmentInput"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Lampiran Pendukung (Opsional)
              </label>
              <input
                id="applyAttachmentInput"
                type="file"
                accept=".pdf,.jpg,.jpeg,.png"
                onChange={(e) => {
                  if (e.target.files && e.target.files[0]) {
                    setApplyAttachment(e.target.files[0]);
                  }
                }}
                className="w-full rounded-2xl border border-slate-200/80 bg-white p-2 text-xs text-slate-600 file:mr-3 file:py-1.5 file:px-3 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-emerald-50 file:text-emerald-700 hover:file:bg-emerald-100 cursor-pointer min-h-[46px]"
              />
              <p className="text-[11px] text-slate-400 mt-1">
                Format: PDF, JPG, PNG (maksimal 4MB). Surat dokter atau bukti pendukung.
              </p>
            </div>
          </form>
        </Modal>
      )}

      {/* 8. Modal: Approval Confirmation (Admin / HR) */}
      {actionTarget && actionType && (
        <Modal
          isOpen={true}
          onClose={() => {
            if (!actionMutation.isPending) {
              setActionTarget(null);
              setActionType(null);
              setActionError(null);
            }
          }}
          title={
            actionType === "approved"
              ? "Konfirmasi Persetujuan Cuti"
              : "Konfirmasi Penolakan Cuti"
          }
          description={`Permohonan dari ${
            actionTarget.employee?.user?.name || "Karyawan"
          } untuk ${actionTarget.leave_type?.name || "Cuti"} selama ${actionTarget.total_days} hari.`}
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => {
                  setActionTarget(null);
                  setActionType(null);
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
                onClick={handleConfirmAction}
                isLoading={actionMutation.isPending}
                className="min-h-[44px] rounded-xl font-bold"
              >
                {actionType === "approved" ? "Setujui Permohonan" : "Tolak Permohonan"}
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

            <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100 space-y-1.5">
              <div className="flex justify-between">
                <span className="text-slate-500">Rentang Tanggal:</span>
                <span className="font-mono font-bold text-slate-900">
                  {actionTarget.start_date} s/d {actionTarget.end_date}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Total Durasi:</span>
                <span className="font-mono font-bold text-slate-900">
                  {actionTarget.total_days} hari
                </span>
              </div>
              <div className="text-slate-600 pt-1 border-t border-slate-200/60">
                <span className="text-slate-400">Alasan: </span>
                <span>{actionTarget.reason}</span>
              </div>
            </div>

            {actionType === "rejected" && (
              <div>
                <label
                  htmlFor="rejectionNotesInput"
                  className="block text-xs font-semibold text-slate-700 mb-1.5"
                >
                  Alasan Penolakan <span className="text-rose-500">*</span>
                </label>
                <textarea
                  id="rejectionNotesInput"
                  rows={3}
                  value={rejectionNotes}
                  onChange={(e) => setRejectionNotes(e.target.value)}
                  placeholder="Tuliskan alasan penolakan permohonan cuti..."
                  className="w-full rounded-2xl border border-slate-200/80 bg-white p-3.5 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
                  required
                />
              </div>
            )}
          </div>
        </Modal>
      )}

      {/* 9. Modal: Create Leave Type (Admin / HR) */}
      {isCreateTypeOpen && (
        <Modal
          isOpen={true}
          onClose={() => {
            if (!createTypeMutation.isPending) {
              setIsCreateTypeOpen(false);
              setCreateTypeError(null);
            }
          }}
          title="Tambah Jenis Cuti Baru"
          description="Konfigurasi nama jenis cuti, alokasi kuota per tahun, dan status pembayaran upah."
          maxWidth="sm"
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => {
                  setIsCreateTypeOpen(false);
                  setCreateTypeError(null);
                }}
                disabled={createTypeMutation.isPending}
                className="min-h-[44px] rounded-xl"
              >
                Batal
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={() => {
                  setCreateTypeError(null);
                  if (!newTypeName.trim()) {
                    setCreateTypeError("Nama jenis cuti wajib diisi.");
                    return;
                  }
                  const quota = parseInt(newTypeQuota, 10);
                  if (isNaN(quota) || quota < 1) {
                    setCreateTypeError("Alokasi kuota harus angka positif.");
                    return;
                  }
                  createTypeMutation.mutate({
                    name: newTypeName.trim(),
                    quota_days: quota,
                    is_paid: newTypeIsPaid,
                  });
                }}
                isLoading={createTypeMutation.isPending}
                className="min-h-[44px] rounded-xl font-bold bg-[#16A34A] hover:bg-[#15803D]"
              >
                Simpan Jenis Cuti
              </Button>
            </div>
          }
        >
          <div className="space-y-4 text-xs">
            {createTypeError && (
              <div
                role="alert"
                className="p-3.5 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 font-medium"
              >
                {createTypeError}
              </div>
            )}

            <div>
              <label
                htmlFor="newTypeNameInput"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Nama Jenis Cuti <span className="text-rose-500">*</span>
              </label>
              <input
                id="newTypeNameInput"
                type="text"
                value={newTypeName}
                onChange={(e) => setNewTypeName(e.target.value)}
                placeholder="Contoh: Cuti Tahunan, Izin Khusus, Cuti Menikah"
                className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 min-h-[46px]"
                required
              />
            </div>

            <div>
              <label
                htmlFor="newTypeQuotaInput"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Alokasi Kuota (Hari per Tahun) <span className="text-rose-500">*</span>
              </label>
              <input
                id="newTypeQuotaInput"
                type="number"
                min="1"
                max="365"
                value={newTypeQuota}
                onChange={(e) => setNewTypeQuota(e.target.value)}
                className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs font-mono text-slate-800 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 min-h-[46px]"
                required
              />
            </div>

            <div>
              <span className="block text-xs font-semibold text-slate-700 mb-1.5">
                Status Pembayaran Upah
              </span>
              <div className="flex items-center gap-4 pt-1">
                <label className="flex items-center gap-2 cursor-pointer text-xs font-medium text-slate-800">
                  <input
                    type="radio"
                    name="isPaidRadio"
                    checked={newTypeIsPaid === true}
                    onChange={() => setNewTypeIsPaid(true)}
                    className="text-emerald-600 focus:ring-emerald-500"
                  />
                  <span>Berbayar (Paid Leave)</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer text-xs font-medium text-slate-800">
                  <input
                    type="radio"
                    name="isPaidRadio"
                    checked={newTypeIsPaid === false}
                    onChange={() => setNewTypeIsPaid(false)}
                    className="text-emerald-600 focus:ring-emerald-500"
                  />
                  <span>Unpaid (Potong Gaji)</span>
                </label>
              </div>
            </div>
          </div>
        </Modal>
      )}

      {/* Floating Action Button (FAB) + Mobile */}
      <button
        type="button"
        onClick={() => {
          setApplyError(null);
          setIsApplyLeaveOpen(true);
        }}
        aria-label="Ajukan Cuti Baru"
        className="sm:hidden fixed bottom-20 right-4 z-40 w-14 h-14 rounded-full bg-[#16A34A] hover:bg-[#15803D] active:scale-90 text-white shadow-[0_8px_24px_rgba(22,163,74,0.35)] flex items-center justify-center transition-transform cursor-pointer focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-emerald-500/30"
      >
        <Plus className="w-7 h-7 stroke-[2.5]" aria-hidden="true" />
      </button>
    </div>
  );
}
