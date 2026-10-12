"use client";

import React, { useState, useEffect, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Plus,
  FileText,
  Calculator,
  Lock,
  Eye,
  AlertTriangle,
  Download,
  AlertCircle,
  CreditCard,
  Wallet,
  TrendingUp,
  ArrowDownRight,
  CheckCircle2,
  Calendar,
  Building,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { formatRupiah, formatDate, cn } from "@/lib/utils";
import apiClient from "@/lib/axios";
import type { ApiResponse, PayrollPeriod, PayrollSlip, User } from "@/types";

interface PayrollPeriodDetail extends PayrollPeriod {
  payroll_slips?: PayrollSlip[];
  total_employees?: number;
  total_amount?: number;
}

export default function PayrollPage() {
  const queryClient = useQueryClient();

  // Role Detection
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

  // Create Period Modal (Admin / HR)
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [periodName, setPeriodName] = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [paymentDate, setPaymentDate] = useState("");
  const [createError, setCreateError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  // Slips Detail Modal (Admin / HR)
  const [selectedPeriod, setSelectedPeriod] = useState<PayrollPeriod | null>(null);

  // Personal Slip Detail Modal (Employee)
  const [selectedPersonalSlip, setSelectedPersonalSlip] = useState<PayrollSlip | null>(null);
  const [downloadingSlipId, setDownloadingSlipId] = useState<number | null>(null);
  const [downloadNotice, setDownloadNotice] = useState<string | null>(null);

  // Query 1: Admin / HR - Periode Penggajian Perusahaan
  const {
    data: periods = [],
    isLoading: isPeriodsLoading,
    isError: isPeriodsError,
    error: periodsError,
    refetch: refetchPeriods,
  } = useQuery({
    queryKey: ["payroll-periods"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<PayrollPeriodDetail[]>>("/payroll/periods");
      if (response.data.success && Array.isArray(response.data.data)) {
        return response.data.data;
      }
      return [];
    },
    enabled: !isEmployee,
  });

  // Query 2: Admin / HR - Slip Per Periode
  const {
    data: selectedSlips = [],
    isLoading: isSlipsLoading,
  } = useQuery({
    queryKey: ["payroll-slips", selectedPeriod?.id_payroll_periods],
    queryFn: async () => {
      if (!selectedPeriod) return [];
      const response = await apiClient.get<ApiResponse<PayrollSlip[]>>(
        `/payroll/periods/${selectedPeriod.id_payroll_periods}/slips`
      );
      if (response.data.success && Array.isArray(response.data.data)) {
        return response.data.data;
      }
      return [];
    },
    enabled: !!selectedPeriod && !isEmployee,
  });

  // Query 3: Employee - Slip Gaji Personal Mandiri
  const {
    data: mySlips = [],
    isLoading: isMySlipsLoading,
    isError: isMySlipsError,
    error: mySlipsError,
    refetch: refetchMySlips,
  } = useQuery({
    queryKey: ["employee-my-slips"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<PayrollSlip[]>>("/payroll/my-slips");
      if (response.data.success && Array.isArray(response.data.data)) {
        return response.data.data;
      }
      return [];
    },
    enabled: isEmployee,
  });

  // Kalkulasi statistik untuk kartu dompet karyawan
  const latestSlip = useMemo(() => {
    return mySlips.length > 0 ? mySlips[0] : null;
  }, [mySlips]);

  const latestDeductions = useMemo(() => {
    if (!latestSlip) return 0;
    return (
      Number(latestSlip.deduction_late ?? latestSlip.deductions_late ?? 0) +
      Number(latestSlip.deduction_absence ?? latestSlip.deductions_absence ?? 0)
    );
  }, [latestSlip]);

  // Mutations (Admin / HR)
  const createMutation = useMutation({
    mutationFn: async (data: {
      name: string;
      start_date: string;
      end_date: string;
      payment_date: string;
    }) => {
      const response = await apiClient.post<ApiResponse<PayrollPeriod>>("/payroll/periods", data);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["payroll-periods"] });
      setIsCreateOpen(false);
      setPeriodName("");
      setStartDate("");
      setEndDate("");
      setPaymentDate("");
      setCreateError(null);
    },
    onError: (err: { response?: { data?: { message?: string } }; message?: string }) => {
      setCreateError(err.response?.data?.message || err.message || "Gagal membuat periode gaji.");
    },
  });

  const calculateMutation = useMutation({
    mutationFn: async (id: number) => {
      const response = await apiClient.post<ApiResponse<Record<string, unknown>>>(
        `/payroll/periods/${id}/calculate`
      );
      return response.data;
    },
    onSuccess: () => {
      setActionError(null);
      queryClient.invalidateQueries({ queryKey: ["payroll-periods"] });
      if (selectedPeriod) {
        queryClient.invalidateQueries({
          queryKey: ["payroll-slips", selectedPeriod.id_payroll_periods],
        });
      }
    },
    onError: (err: { response?: { data?: { message?: string } }; message?: string }) => {
      setActionError(err.response?.data?.message || err.message || "Gagal menjalankan kalkulasi gaji.");
    },
  });

  const finalizeMutation = useMutation({
    mutationFn: async (id: number) => {
      const response = await apiClient.post<ApiResponse<Record<string, unknown>>>(
        `/payroll/periods/${id}/finalize`
      );
      return response.data;
    },
    onSuccess: () => {
      setActionError(null);
      queryClient.invalidateQueries({ queryKey: ["payroll-periods"] });
      if (selectedPeriod) {
        setSelectedPeriod(null);
      }
    },
    onError: (err: { response?: { data?: { message?: string } }; message?: string }) => {
      setActionError(err.response?.data?.message || err.message || "Gagal memfinalisasi periode gaji.");
    },
  });

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!periodName.trim() || !startDate || !endDate || !paymentDate) {
      setCreateError("Semua bidang formulir wajib diisi.");
      return;
    }
    createMutation.mutate({
      name: periodName.trim(),
      start_date: startDate,
      end_date: endDate,
      payment_date: paymentDate,
    });
  };

  // Unduh Slip Gaji PDF dengan autentikasi token
  const handleDownloadSlip = async (slipId: number) => {
    try {
      setDownloadingSlipId(slipId);
      const res = await apiClient.get(`/payroll/my-slips/${slipId}/download`, {
        responseType: "blob",
      });
      const blob = new Blob([res.data], { type: "application/pdf" });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = `Slip_Gaji_${slipId}.pdf`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
    } catch {
      setDownloadNotice("Gagal mengunduh berkas slip gaji. Silakan coba kembali.");
      setTimeout(() => setDownloadNotice(null), 4000);
    } finally {
      setDownloadingSlipId(null);
    }
  };

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      {/* 1. iOS Large Title & Action Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-slate-900">
              {isEmployee ? "Slip Gaji Saya" : "Penggajian (Payroll)"}
            </h1>
            <span className="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-orange-50 text-orange-700 border border-orange-200/80">
              {isEmployee ? "Layanan Mandiri" : "Operasional HR"}
            </span>
          </div>
          {!isEmployee && (
            <p className="text-xs sm:text-sm text-slate-500 mt-1">
              Kelola periode cut-off gaji, kalkulasi kehadiran otomatis, dan penerbitan slip digital.
            </p>
          )}
        </div>

        {!isEmployee && (
          <div className="hidden sm:flex items-center gap-2 self-start sm:self-auto">
            <button
              type="button"
              onClick={() => {
                setCreateError(null);
                setIsCreateOpen(true);
              }}
              className="inline-flex items-center justify-center gap-2 px-4 py-2.5 min-h-[44px] rounded-2xl bg-orange-600 hover:bg-orange-700 active:scale-[0.98] text-white font-bold text-xs sm:text-sm shadow-[0_2px_8px_rgba(234,88,12,0.25)] transition-all cursor-pointer"
            >
              <Plus className="w-4 h-4" aria-hidden="true" />
              <span>Buka Periode Baru</span>
            </button>
          </div>
        )}
      </div>

      {/* 2. Error & Toast Feedback */}
      {actionError && (
        <div
          role="alert"
          className="flex items-center justify-between p-3.5 sm:p-4 rounded-2xl bg-rose-50 border border-rose-200 text-xs sm:text-sm text-rose-800 font-medium shadow-[0_2px_8px_rgba(0,0,0,0.04)]"
        >
          <div className="flex items-center gap-2.5">
            <AlertTriangle className="w-5 h-5 text-rose-600 flex-shrink-0" />
            <span>{actionError}</span>
          </div>
          <button
            type="button"
            onClick={() => setActionError(null)}
            className="text-xs font-semibold hover:underline cursor-pointer ml-3"
          >
            Tutup
          </button>
        </div>
      )}

      {downloadNotice && (
        <div
          role="status"
          className="flex items-center justify-between p-3.5 sm:p-4 rounded-2xl bg-rose-50 border border-rose-200 text-xs sm:text-sm text-rose-800 font-medium shadow-[0_2px_8px_rgba(0,0,0,0.04)]"
        >
          <div className="flex items-center gap-2.5">
            <AlertCircle className="w-5 h-5 text-rose-600 flex-shrink-0" />
            <span>{downloadNotice}</span>
          </div>
          <button
            type="button"
            onClick={() => setDownloadNotice(null)}
            className="text-xs font-semibold hover:underline cursor-pointer ml-3"
          >
            Tutup
          </button>
        </div>
      )}

      {/* 3. Apple Wallet Style KPI Cards (Khusus Karyawan - Sembunyikan saat mode mobile) */}
      {isEmployee && (
        <div className="hidden sm:grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
          {/* Card 1: Gaji Bersih Terakhir (Apple Wallet Primary) */}
          <div className="col-span-2 lg:col-span-1 rounded-3xl border border-slate-200/80 bg-gradient-to-br from-white via-white to-orange-50/40 p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] sm:text-xs font-semibold text-orange-700">
                Gaji Bersih (Terbaru)
              </span>
              <div className="w-7 h-7 rounded-xl bg-orange-500/10 text-orange-600 flex items-center justify-center">
                <Wallet className="w-3.5 h-3.5" />
              </div>
            </div>
            <div className="mt-2.5">
              <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-slate-900 tabular-nums">
                {latestSlip ? formatRupiah(Number(latestSlip.net_salary)) : "Rp 0"}
              </span>
            </div>
            <div className="mt-1.5 text-[11px] text-slate-500 truncate">
              {latestSlip ? (latestSlip.period_name || "Periode terakhir") : "Belum ada slip"}
            </div>
          </div>

          {/* Card 2: Gaji Pokok */}
          <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] sm:text-xs font-semibold text-slate-500">
                Gaji Pokok
              </span>
              <div className="w-7 h-7 rounded-xl bg-slate-500/10 text-slate-600 flex items-center justify-center">
                <Building className="w-3.5 h-3.5" />
              </div>
            </div>
            <div className="mt-2.5">
              <span className="text-base sm:text-lg font-bold font-mono tracking-tight text-slate-900 tabular-nums">
                {latestSlip ? formatRupiah(Number(latestSlip.basic_salary)) : "Rp 0"}
              </span>
            </div>
            <div className="mt-1 text-[11px] text-slate-400">
              Upah pokok kontrak
            </div>
          </div>

          {/* Card 3: Tunjangan Tetap */}
          <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] sm:text-xs font-semibold text-emerald-600">
                Tunjangan Tetap
              </span>
              <div className="w-7 h-7 rounded-xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
                <TrendingUp className="w-3.5 h-3.5" />
              </div>
            </div>
            <div className="mt-2.5">
              <span className="text-base sm:text-lg font-bold font-mono tracking-tight text-emerald-700 tabular-nums">
                +{latestSlip ? formatRupiah(Number(latestSlip.allowance_fixed)) : "Rp 0"}
              </span>
            </div>
            <div className="mt-1 text-[11px] text-slate-400">
              Tunjangan & lembur
            </div>
          </div>

          {/* Card 4: Potongan Terakhir */}
          <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] sm:text-xs font-semibold text-rose-600">
                Potongan Terakhir
              </span>
              <div className="w-7 h-7 rounded-xl bg-rose-500/10 text-rose-600 flex items-center justify-center">
                <ArrowDownRight className="w-3.5 h-3.5" />
              </div>
            </div>
            <div className="mt-2.5">
              <span className="text-base sm:text-lg font-bold font-mono tracking-tight text-rose-600 tabular-nums">
                -{formatRupiah(latestDeductions)}
              </span>
            </div>
            <div className="mt-1 text-[11px] text-slate-400">
              Absensi & keterlambatan
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* TAMPILAN 1: ROLE EMPLOYEE - Personal Slip Inset Grouped  */}
      {/* ========================================================= */}
      {isEmployee && (
        <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div>
              <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
                Riwayat Slip Gaji Digital
              </h2>
              <p className="text-[11px] sm:text-xs text-slate-500 mt-0.5">
                Daftar slip pembayaran gaji yang telah difinalisasi oleh bagian HRD.
              </p>
            </div>
            <span className="text-xs text-slate-500 font-mono tabular-nums">
              Total: <strong className="text-slate-800">{mySlips.length}</strong> slip
            </span>
          </div>

          {isMySlipsLoading ? (
            <TableSkeleton rows={4} columns={6} />
          ) : isMySlipsError ? (
            <ErrorState
              title="Gagal Memuat Slip Gaji"
              message={
                mySlipsError instanceof Error
                  ? mySlipsError.message
                  : "Terjadi kesalahan saat memuat daftar slip gaji Anda."
              }
              onRetry={() => refetchMySlips()}
            />
          ) : mySlips.length === 0 ? (
            <EmptyState
              title="Belum Ada Slip Gaji Diterbitkan"
              description="Slip gaji bulanan Anda akan muncul di sini setelah periode cut-off gaji difinalisasi oleh HRD."
            />
          ) : (
            <div>
              {/* 1. Mobile Inset Rows View (< sm) */}
              <div className="sm:hidden space-y-2.5">
                {mySlips.map((slip) => {
                  const totalDeductions =
                    Number(slip.deduction_late ?? slip.deductions_late ?? 0) +
                    Number(slip.deduction_absence ?? slip.deductions_absence ?? 0);

                  return (
                    <div
                      key={slip.id_payroll_slips}
                      className="p-3.5 rounded-2xl border border-slate-200/70 bg-white hover:bg-slate-50/70 transition-colors space-y-2.5 shadow-[0_1px_2px_rgba(0,0,0,0.02)]"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex items-center gap-2">
                          <div className="w-8 h-8 rounded-xl bg-orange-500/10 text-orange-600 flex items-center justify-center flex-shrink-0">
                            <CreditCard className="w-4 h-4" />
                          </div>
                          <div>
                            <div className="text-xs font-bold text-slate-900">
                              {slip.period_name || `Periode #${slip.id_payroll_periods}`}
                            </div>
                            <div className="text-[11px] text-slate-500 font-mono tabular-nums">
                              {slip.payment_date
                                ? `Dibayar: ${formatDate(slip.payment_date)}`
                                : "Periode berjalan"}
                            </div>
                          </div>
                        </div>

                        {/* Net Salary pill */}
                        <div className="text-right">
                          <div className="text-xs font-mono font-extrabold text-orange-700 tabular-nums">
                            {formatRupiah(Number(slip.net_salary))}
                          </div>
                          <span className="text-[10px] text-slate-400 font-medium">Gaji Bersih</span>
                        </div>
                      </div>

                      {/* Detail komponen upah */}
                      <div className="grid grid-cols-3 gap-2 p-2.5 rounded-xl bg-slate-50/80 border border-slate-100 text-[11px] font-mono">
                        <div>
                          <div className="text-slate-400 font-sans text-[10px]">Pokok</div>
                          <div className="font-semibold text-slate-800 truncate">
                            {formatRupiah(Number(slip.basic_salary))}
                          </div>
                        </div>
                        <div>
                          <div className="text-emerald-600 font-sans text-[10px]">Tunjangan</div>
                          <div className="font-semibold text-emerald-700 truncate">
                            +{formatRupiah(Number(slip.allowance_fixed))}
                          </div>
                        </div>
                        <div>
                          <div className="text-rose-600 font-sans text-[10px]">Potongan</div>
                          <div className="font-semibold text-rose-600 truncate">
                            -{formatRupiah(totalDeductions)}
                          </div>
                        </div>
                      </div>

                      {/* Tombol aksi (44px touch targets) */}
                      <div className="grid grid-cols-2 gap-2 pt-1">
                        <button
                          type="button"
                          onClick={() => setSelectedPersonalSlip(slip)}
                          className="min-h-[40px] rounded-xl bg-white hover:bg-slate-50 active:scale-[0.98] text-slate-700 font-bold text-xs flex items-center justify-center gap-1.5 border border-slate-200/80 shadow-2xs transition-all cursor-pointer"
                        >
                          <Eye className="w-3.5 h-3.5 text-slate-500" />
                          <span>Rincian</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDownloadSlip(slip.id_payroll_slips)}
                          disabled={downloadingSlipId === slip.id_payroll_slips}
                          className="min-h-[40px] rounded-xl bg-orange-600 hover:bg-orange-700 active:scale-[0.98] text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-2xs transition-all cursor-pointer disabled:opacity-50"
                        >
                          <Download className="w-3.5 h-3.5" />
                          <span>
                            {downloadingSlipId === slip.id_payroll_slips ? "Mengunduh..." : "Unduh PDF"}
                          </span>
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* 2. Desktop Table View (>= sm) */}
              <div className="hidden sm:block overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                      <th className="px-4 py-3">Periode Gaji</th>
                      <th className="px-4 py-3 text-right font-mono">Gaji Pokok</th>
                      <th className="px-4 py-3 text-right font-mono">Tunjangan Tetap</th>
                      <th className="px-4 py-3 text-right font-mono">Total Potongan</th>
                      <th className="px-4 py-3 text-right font-mono font-bold text-slate-900">
                        Take Home Pay
                      </th>
                      <th className="px-4 py-3 text-right">Tindakan</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium">
                    {mySlips.map((slip) => {
                      const totalDeductions =
                        Number(slip.deduction_late ?? slip.deductions_late ?? 0) +
                        Number(slip.deduction_absence ?? slip.deductions_absence ?? 0);

                      return (
                        <tr
                          key={slip.id_payroll_slips}
                          className="hover:bg-slate-50/60 transition-colors"
                        >
                          <td className="px-4 py-3.5">
                            <div className="font-bold text-slate-900">
                              {slip.period_name || `Periode #${slip.id_payroll_periods}`}
                            </div>
                            <div className="text-[11px] text-slate-400 font-mono mt-0.5">
                              {slip.payment_date
                                ? `Dibayar: ${formatDate(slip.payment_date)}`
                                : "Periode berjalan"}
                            </div>
                          </td>
                          <td className="px-4 py-3.5 text-right font-mono text-slate-700 tabular-nums">
                            {formatRupiah(Number(slip.basic_salary))}
                          </td>
                          <td className="px-4 py-3.5 text-right font-mono text-emerald-700 tabular-nums">
                            +{formatRupiah(Number(slip.allowance_fixed))}
                          </td>
                          <td className="px-4 py-3.5 text-right font-mono text-rose-600 tabular-nums">
                            -{formatRupiah(totalDeductions)}
                          </td>
                          <td className="px-4 py-3.5 text-right font-mono font-bold text-slate-900 text-sm tabular-nums">
                            {formatRupiah(Number(slip.net_salary))}
                          </td>
                          <td className="px-4 py-3.5 text-right">
                            <div className="inline-flex items-center gap-1.5">
                              <button
                                type="button"
                                onClick={() => setSelectedPersonalSlip(slip)}
                                className="px-2.5 py-1.5 rounded-xl bg-white hover:bg-slate-50 text-slate-700 font-semibold text-xs flex items-center gap-1 border border-slate-200/80 shadow-2xs transition-colors cursor-pointer"
                              >
                                <Eye className="w-3 h-3 text-slate-500" />
                                <span>Rincian</span>
                              </button>
                              <button
                                type="button"
                                onClick={() => handleDownloadSlip(slip.id_payroll_slips)}
                                disabled={downloadingSlipId === slip.id_payroll_slips}
                                className="px-2.5 py-1.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-bold text-xs flex items-center gap-1 shadow-2xs transition-colors cursor-pointer disabled:opacity-50"
                              >
                                <Download className="w-3 h-3" />
                                <span>
                                  {downloadingSlipId === slip.id_payroll_slips
                                    ? "Unduh..."
                                    : "PDF"}
                                </span>
                              </button>
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}

      {/* ========================================================= */}
      {/* TAMPILAN 2: ROLE ADMIN / HR - Periode Penggajian          */}
      {/* ========================================================= */}
      {!isEmployee && (
        <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div>
              <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
                Riwayat Periode Penggajian Perusahaan
              </h2>
              <p className="text-[11px] sm:text-xs text-slate-500 mt-0.5">
                Status pemrosesan upah bulanan staf dan laporan slip gaji digital.
              </p>
            </div>
            <span className="text-xs text-slate-500 font-mono tabular-nums">
              Total: <strong className="text-slate-800">{periods.length}</strong> periode
            </span>
          </div>

          {isPeriodsLoading ? (
            <TableSkeleton rows={3} columns={5} />
          ) : isPeriodsError ? (
            <ErrorState
              title="Gagal Memuat Periode Penggajian"
              message={
                periodsError instanceof Error
                  ? periodsError.message
                  : "Terjadi kesalahan saat memuat data periode penggajian."
              }
              onRetry={() => refetchPeriods()}
            />
          ) : periods.length === 0 ? (
            <EmptyState
              title="Belum Ada Periode Penggajian"
              description="Buka periode penggajian baru untuk memulai perhitungan upah staf berdasarkan log kehadiran."
              actionLabel="Buka Periode Baru"
              onAction={() => {
                setCreateError(null);
                setIsCreateOpen(true);
              }}
            />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                    <th className="px-4 py-3">Nama Periode</th>
                    <th className="px-4 py-3 font-mono">Rentang Cut-Off</th>
                    <th className="px-4 py-3 font-mono">Tanggal Bayar</th>
                    <th className="px-4 py-3 text-center">Status</th>
                    <th className="px-4 py-3 text-right">Tindakan</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {periods.map((item) => (
                    <tr
                      key={item.id_payroll_periods}
                      className="hover:bg-slate-50/60 transition-colors"
                    >
                      <td className="px-4 py-3.5 font-bold text-slate-900">
                        {item.name}
                      </td>
                      <td className="px-4 py-3.5 text-slate-600 font-mono tabular-nums">
                        {item.start_date} s/d {item.end_date}
                      </td>
                      <td className="px-4 py-3.5 text-slate-600 font-mono tabular-nums">
                        {item.payment_date}
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <StatusBadge
                          status={
                            item.status === "finalized"
                              ? "disetujui"
                              : item.status === "calculated"
                              ? "aktif"
                              : "draft"
                          }
                        />
                      </td>
                      <td className="px-4 py-3.5 text-right">
                        <div className="inline-flex items-center gap-1.5">
                          {item.status === "draft" && (
                            <button
                              type="button"
                              onClick={() => calculateMutation.mutate(item.id_payroll_periods)}
                              disabled={calculateMutation.isPending}
                              className="px-2.5 py-1.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-bold text-xs flex items-center gap-1 shadow-2xs transition-colors cursor-pointer disabled:opacity-50"
                            >
                              <Calculator className="w-3.5 h-3.5" />
                              <span>Kalkulasi Gaji</span>
                            </button>
                          )}

                          {item.status === "calculated" && (
                            <>
                              <button
                                type="button"
                                onClick={() => setSelectedPeriod(item)}
                                className="px-2.5 py-1.5 rounded-xl bg-white hover:bg-slate-50 text-slate-700 font-semibold text-xs flex items-center gap-1 border border-slate-200/80 shadow-2xs transition-colors cursor-pointer"
                              >
                                <Eye className="w-3.5 h-3.5 text-slate-500" />
                                <span>Rincian Slip</span>
                              </button>
                              <button
                                type="button"
                                onClick={() => finalizeMutation.mutate(item.id_payroll_periods)}
                                disabled={finalizeMutation.isPending}
                                className="px-2.5 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs flex items-center gap-1 shadow-2xs transition-colors cursor-pointer disabled:opacity-50"
                              >
                                <Lock className="w-3.5 h-3.5" />
                                <span>Finalisasi</span>
                              </button>
                            </>
                          )}

                          {item.status === "finalized" && (
                            <button
                              type="button"
                              onClick={() => setSelectedPeriod(item)}
                              className="px-2.5 py-1.5 rounded-xl bg-white hover:bg-slate-50 text-slate-700 font-semibold text-xs flex items-center gap-1 border border-slate-200/80 shadow-2xs transition-colors cursor-pointer"
                            >
                              <FileText className="w-3.5 h-3.5 text-slate-500" />
                              <span>Lihat Slip Gaji</span>
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Modal: Buka Periode Baru (Admin / HR) */}
      {!isEmployee && isCreateOpen && (
        <Modal
          isOpen={true}
          onClose={() => {
            if (!createMutation.isPending) {
              setIsCreateOpen(false);
              setCreateError(null);
            }
          }}
          title="Buka Periode Penggajian Baru"
          description="Tentukan rentang tanggal cut-off presensi dan tanggal pembayaran upah."
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => {
                  setIsCreateOpen(false);
                  setCreateError(null);
                }}
                disabled={createMutation.isPending}
                className="min-h-[44px] rounded-xl"
              >
                Batal
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={handleCreateSubmit}
                isLoading={createMutation.isPending}
                className="min-h-[44px] rounded-xl font-bold bg-orange-600 hover:bg-orange-700"
              >
                Buka Periode
              </Button>
            </div>
          }
        >
          <form onSubmit={handleCreateSubmit} className="space-y-4 text-xs">
            {createError && (
              <div
                className="p-3.5 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 font-medium"
                role="alert"
              >
                {createError}
              </div>
            )}

            <div>
              <label
                htmlFor="periodName"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Nama Periode <span className="text-rose-500">*</span>
              </label>
              <input
                id="periodName"
                type="text"
                value={periodName}
                onChange={(e) => setPeriodName(e.target.value)}
                placeholder="Contoh: Periode Oktober 2026"
                className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
                required
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label
                  htmlFor="startDate"
                  className="block text-xs font-semibold text-slate-700 mb-1.5"
                >
                  Tanggal Mulai Cut-Off <span className="text-rose-500">*</span>
                </label>
                <input
                  id="startDate"
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
                  required
                />
              </div>

              <div>
                <label
                  htmlFor="endDate"
                  className="block text-xs font-semibold text-slate-700 mb-1.5"
                >
                  Tanggal Selesai Cut-Off <span className="text-rose-500">*</span>
                </label>
                <input
                  id="endDate"
                  type="date"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
                  required
                />
              </div>
            </div>

            <div>
              <label
                htmlFor="paymentDate"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Tanggal Pembayaran Gaji <span className="text-rose-500">*</span>
              </label>
              <input
                id="paymentDate"
                type="date"
                value={paymentDate}
                onChange={(e) => setPaymentDate(e.target.value)}
                className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
                required
              />
            </div>
          </form>
        </Modal>
      )}

      {/* Modal: Slips Detail (Admin / HR) */}
      {!isEmployee && selectedPeriod && (
        <Modal
          isOpen={true}
          onClose={() => setSelectedPeriod(null)}
          title={`Rincian Slip Gaji: ${selectedPeriod.name}`}
          description={`Rentang cut-off: ${selectedPeriod.start_date} s/d ${selectedPeriod.end_date}.`}
          maxWidth="lg"
          footer={
            <div className="flex items-center justify-between w-full">
              <div className="text-xs text-slate-500">
                Total: <span className="font-mono font-bold text-slate-900">{selectedSlips.length} slip</span>
              </div>
              <Button
                variant="secondary"
                size="md"
                onClick={() => setSelectedPeriod(null)}
                className="min-h-[44px] rounded-xl"
              >
                Tutup
              </Button>
            </div>
          }
        >
          {isSlipsLoading ? (
            <TableSkeleton rows={4} columns={6} />
          ) : selectedSlips.length === 0 ? (
            <div className="py-8 text-center text-xs text-slate-500">
              Belum ada slip gaji yang dihasilkan untuk periode ini. Jalankan &quot;Kalkulasi Gaji&quot; terlebih dahulu.
            </div>
          ) : (
            <div className="overflow-x-auto max-h-96">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                    <th className="px-3 py-2.5">Pegawai</th>
                    <th className="px-3 py-2.5 text-right font-mono">Gaji Pokok</th>
                    <th className="px-3 py-2.5 text-right font-mono">Tunjangan</th>
                    <th className="px-3 py-2.5 text-right font-mono">Potongan</th>
                    <th className="px-3 py-2.5 text-right font-mono font-bold">Gaji Bersih</th>
                    <th className="px-3 py-2.5 text-center">Slip PDF</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-mono">
                  {selectedSlips.map((slip) => {
                    const totalDeductions =
                      Number(slip.deduction_late ?? slip.deductions_late ?? 0) +
                      Number(slip.deduction_absence ?? slip.deductions_absence ?? 0);

                    const employeeName =
                      slip.employee?.name ||
                      slip.employee?.user?.name ||
                      `Karyawan #${slip.id_employees}`;

                    const pdfPath = slip.pdf_path || slip.pdf_url;
                    const pdfHref = pdfPath
                      ? (pdfPath.startsWith("http")
                        ? pdfPath
                        : `${process.env.NEXT_PUBLIC_STORAGE_URL || "http://localhost:8000/storage"}/${pdfPath}`)
                      : null;

                    return (
                      <tr key={slip.id_payroll_slips} className="hover:bg-slate-50/60 transition-colors">
                        <td className="px-3 py-2.5 font-sans font-medium text-slate-900">
                          {employeeName}
                        </td>
                        <td className="px-3 py-2.5 text-right text-slate-900 tabular-nums">
                          {formatRupiah(Number(slip.basic_salary))}
                        </td>
                        <td className="px-3 py-2.5 text-right text-emerald-700 tabular-nums">
                          +{formatRupiah(Number(slip.allowance_fixed))}
                        </td>
                        <td className="px-3 py-2.5 text-right text-rose-600 tabular-nums">
                          {"-"}{formatRupiah(totalDeductions)}
                        </td>
                        <td className="px-3 py-2.5 text-right font-bold text-slate-900 tabular-nums">
                          {formatRupiah(Number(slip.net_salary))}
                        </td>
                        <td className="px-3 py-2.5 text-center font-sans">
                          {pdfHref ? (
                            <a
                              href={pdfHref}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="text-orange-600 hover:text-orange-700 active:scale-95 inline-flex items-center gap-1 font-medium transition-all"
                            >
                              <FileText className="w-3.5 h-3.5" />
                              <span>Unduh</span>
                            </a>
                          ) : (
                            <span className="text-slate-400 italic">Belum dibuat</span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </Modal>
      )}

      {/* Modal: Personal Slip Detail (Apple Sheet Style) */}
      {selectedPersonalSlip && (
        <Modal
          isOpen={true}
          onClose={() => setSelectedPersonalSlip(null)}
          title={`Rincian Slip Gaji: ${selectedPersonalSlip.period_name || "Periode Berjalan"}`}
          description={`Tanggal Pembayaran: ${
            selectedPersonalSlip.payment_date ? formatDate(selectedPersonalSlip.payment_date) : "-"
          }`}
          maxWidth="md"
          footer={
            <div className="flex items-center justify-between w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => setSelectedPersonalSlip(null)}
                className="min-h-[44px] rounded-xl"
              >
                Tutup
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={() => handleDownloadSlip(selectedPersonalSlip.id_payroll_slips)}
                isLoading={downloadingSlipId === selectedPersonalSlip.id_payroll_slips}
                leftIcon={<Download className="w-4 h-4" />}
                className="min-h-[44px] rounded-xl font-bold bg-orange-600 hover:bg-orange-700"
              >
                Unduh Slip PDF
              </Button>
            </div>
          }
        >
          <div className="space-y-4 text-xs">
            {/* Header Profil Penerima */}
            <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100 space-y-1.5">
              <div className="flex justify-between">
                <span className="text-slate-500">Nama Penerima:</span>
                <span className="font-bold text-slate-900">{currentUser?.name || "Karyawan"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Periode:</span>
                <span className="text-slate-800 font-semibold">{selectedPersonalSlip.period_name || "-"}</span>
              </div>
            </div>

            {/* Komponen Penerimaan Upah */}
            <div className="space-y-2">
              <div className="text-[11px] font-bold text-slate-900 uppercase tracking-wider">
                Komponen Penerimaan Upah
              </div>
              <div className="p-3 rounded-2xl bg-emerald-50/50 border border-emerald-100 space-y-2">
                <div className="flex justify-between">
                  <span className="text-slate-600">Gaji Pokok:</span>
                  <span className="font-mono font-semibold text-slate-900 tabular-nums">
                    {formatRupiah(Number(selectedPersonalSlip.basic_salary))}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-600">Tunjangan Tetap:</span>
                  <span className="font-mono font-semibold text-emerald-700 tabular-nums">
                    +{formatRupiah(Number(selectedPersonalSlip.allowance_fixed))}
                  </span>
                </div>
                {Number(selectedPersonalSlip.overtime_pay || 0) > 0 && (
                  <div className="flex justify-between">
                    <span className="text-slate-600">Upah Lembur:</span>
                    <span className="font-mono font-semibold text-emerald-700 tabular-nums">
                      +{formatRupiah(Number(selectedPersonalSlip.overtime_pay))}
                    </span>
                  </div>
                )}
              </div>
            </div>

            {/* Komponen Potongan Upah */}
            <div className="space-y-2">
              <div className="text-[11px] font-bold text-slate-900 uppercase tracking-wider">
                Komponen Potongan Upah
              </div>
              <div className="p-3 rounded-2xl bg-rose-50/50 border border-rose-100 space-y-2">
                <div className="flex justify-between">
                  <span className="text-slate-600">Potongan Keterlambatan:</span>
                  <span className="font-mono font-semibold text-rose-600 tabular-nums">
                    -{formatRupiah(
                      Number(
                        selectedPersonalSlip.deduction_late ?? selectedPersonalSlip.deductions_late ?? 0
                      )
                    )}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-600">Potongan Absensi / Alpha:</span>
                  <span className="font-mono font-semibold text-rose-600 tabular-nums">
                    -{formatRupiah(
                      Number(
                        selectedPersonalSlip.deduction_absence ??
                          selectedPersonalSlip.deductions_absence ??
                          0
                      )
                    )}
                  </span>
                </div>
              </div>
            </div>

            {/* Total Gaji Bersih */}
            <div className="p-3.5 rounded-2xl bg-orange-50 border border-orange-200/80 flex items-center justify-between">
              <span className="text-xs font-bold text-slate-900">Gaji Bersih (Take Home Pay):</span>
              <span className="text-base font-extrabold font-mono text-orange-700 tabular-nums">
                {formatRupiah(Number(selectedPersonalSlip.net_salary))}
              </span>
            </div>
          </div>
        </Modal>
      )}

      {/* Floating Action Button (FAB) + Mobile untuk Buka Periode Baru */}
      {!isEmployee && (
        <button
          type="button"
          onClick={() => {
            setCreateError(null);
            setIsCreateOpen(true);
          }}
          aria-label="Buka Periode Penggajian Baru"
          className="sm:hidden fixed bottom-20 right-4 z-40 w-14 h-14 rounded-full bg-orange-600 hover:bg-orange-700 active:scale-90 text-white shadow-[0_8px_24px_rgba(234,88,12,0.45)] flex items-center justify-center transition-transform cursor-pointer focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-orange-500/30"
        >
          <Plus className="w-7 h-7 stroke-[2.5]" aria-hidden="true" />
        </button>
      )}
    </div>
  );
}
