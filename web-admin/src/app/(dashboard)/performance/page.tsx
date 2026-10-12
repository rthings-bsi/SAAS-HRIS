"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Plus,
  Award,
  Calendar,
  Users,
  FileText,
  ArrowRight,
  BarChart2,
  AlertTriangle,
  CheckCircle2,
  CalendarDays,
  Sparkles,
  UserCheck,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import apiClient from "@/lib/axios";
import { cn } from "@/lib/utils";
import type { ApiResponse, PerformancePeriod, User } from "@/types";

export default function PerformancePage() {
  const queryClient = useQueryClient();

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

  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [periodName, setPeriodName] = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [createError, setCreateError] = useState<string | null>(null);
  const [downloadError, setDownloadError] = useState<string | null>(null);

  const {
    data: periods = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["performance-periods"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<PerformancePeriod[]>>(
        "/performance/periods"
      );
      if (response.data.success && Array.isArray(response.data.data)) {
        return response.data.data;
      }
      return [];
    },
  });

  const createMutation = useMutation({
    mutationFn: async (data: {
      name: string;
      start_date: string;
      end_date: string;
    }) => {
      const response = await apiClient.post<ApiResponse<PerformancePeriod>>(
        "/performance/periods",
        data
      );
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["performance-periods"] });
      setIsCreateOpen(false);
      setPeriodName("");
      setStartDate("");
      setEndDate("");
      setCreateError(null);
    },
    onError: (err: {
      response?: { data?: { message?: string } };
      message?: string;
    }) => {
      setCreateError(
        err.response?.data?.message ||
          err.message ||
          "Gagal membuat periode evaluasi."
      );
    },
  });

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setCreateError(null);

    if (!periodName.trim() || !startDate || !endDate) {
      setCreateError("Semua field wajib diisi.");
      return;
    }

    if (new Date(endDate) < new Date(startDate)) {
      setCreateError("Tanggal akhir tidak boleh mendahului tanggal mulai.");
      return;
    }

    createMutation.mutate({
      name: periodName.trim(),
      start_date: startDate,
      end_date: endDate,
    });
  };

  const handleDownloadPdf = (id: number) => {
    setDownloadError(null);
    const token =
      typeof window !== "undefined" ? localStorage.getItem("hris_token") : null;
    const url = `${
      process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1"
    }/performance/periods/${id}/pdf`;

    fetch(url, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })
      .then((res) => {
        if (!res.ok) throw new Error("Gagal mengunduh dokumen PDF.");
        return res.blob();
      })
      .then((blob) => {
        const fileUrl = window.URL.createObjectURL(blob);
        window.open(fileUrl, "_blank");
      })
      .catch((err) => {
        setDownloadError(
          err.message || "Terjadi kesalahan saat mengunduh PDF."
        );
      });
  };

  const totalPeriods = periods.length;
  const activePeriods = periods.filter(
    (p) => p.status === "active" || p.status === "calculated"
  ).length;
  const finalizedPeriods = periods.filter((p) => p.status === "finalized").length;

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      {/* 1. iOS Large Title & Action Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-slate-900">
              Penilaian Kinerja Pegawai
            </h1>
            <span className="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-sky-50 text-sky-700 border border-sky-200/80">
              Metode SMART
            </span>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            {isEmployee
              ? "Transparansi capaian kinerja, evaluasi kehadiran, dan pemeringkatan berbasis bobot SMART."
              : "Sistem Penunjang Keputusan berbasis Simple Multi-Attribute Rating Technique."}
          </p>
        </div>

        <div className="hidden sm:flex items-center gap-2 self-start sm:self-auto">
          {canManage && (
            <button
              type="button"
              onClick={() => {
                setCreateError(null);
                setIsCreateOpen(true);
              }}
              className="inline-flex items-center justify-center gap-2 px-4 py-2.5 min-h-[44px] rounded-2xl bg-orange-600 hover:bg-orange-700 active:scale-[0.98] text-white font-bold text-xs sm:text-sm shadow-[0_2px_8px_rgba(234,88,12,0.25)] transition-all cursor-pointer"
            >
              <Plus className="w-4 h-4" aria-hidden="true" />
              <span>Buka Periode Penilaian</span>
            </button>
          )}
        </div>
      </div>

      {/* 2. Download / Error Notice */}
      {downloadError && (
        <div
          role="alert"
          className="flex items-center justify-between p-3.5 sm:p-4 rounded-2xl bg-rose-50/90 border border-rose-200 text-xs sm:text-sm text-rose-800 shadow-[0_2px_8px_rgba(0,0,0,0.04)]"
        >
          <div className="flex items-center gap-2.5">
            <AlertTriangle className="w-5 h-5 text-rose-600 flex-shrink-0" />
            <span>{downloadError}</span>
          </div>
          <button
            type="button"
            onClick={() => setDownloadError(null)}
            className="text-xs font-semibold hover:underline cursor-pointer ml-3"
          >
            Tutup
          </button>
        </div>
      )}

      {/* 3. Apple Fitness / Health Style KPI Metric Cards (Sembunyikan saat mode mobile) */}
      <div className="hidden sm:grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        {/* Card 1: Total Sesi */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-slate-500">
              Total Periode
            </span>
            <div className="w-7 h-7 rounded-xl bg-orange-500/10 text-orange-600 flex items-center justify-center">
              <Calendar className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-slate-900 tabular-nums">
              {totalPeriods}
            </span>
            <span className="text-xs text-slate-500 font-medium">Sesi</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Sesi evaluasi yang tercatat
          </div>
        </div>

        {/* Card 2: Periode Berjalan */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-sky-600">
              Periode Berjalan
            </span>
            <div className="w-7 h-7 rounded-xl bg-sky-500/10 text-sky-600 flex items-center justify-center">
              <BarChart2 className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-sky-700 tabular-nums">
              {activePeriods}
            </span>
            <span className="text-xs text-slate-500 font-medium">Aktif</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Proses penilaian / kalkulasi
          </div>
        </div>

        {/* Card 3: Periode Final */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-emerald-600">
              Periode Terkunci
            </span>
            <div className="w-7 h-7 rounded-xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
              <Award className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-emerald-700 tabular-nums">
              {finalizedPeriods}
            </span>
            <span className="text-xs text-slate-500 font-medium">Selesai</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Laporan resmi disahkan
          </div>
        </div>

        {/* Card 4: Transparansi & Metode */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-amber-600">
              Model Keputusan
            </span>
            <div className="w-7 h-7 rounded-xl bg-amber-500/10 text-amber-600 flex items-center justify-center">
              <UserCheck className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-sm sm:text-base font-extrabold tracking-tight text-slate-900">
              SMART SPK
            </span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Kriteria kehadiran & performa
          </div>
        </div>
      </div>

      {/* 4. Inset Grouped Card: Daftar Sesi Penilaian */}
      <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] space-y-4">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <div>
            <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
              {isEmployee
                ? "Daftar Evaluasi Kinerja Saya"
                : "Daftar Periode Penilaian Kinerja"}
            </h2>
            <p className="text-[11px] sm:text-xs text-slate-500 mt-0.5">
              {isEmployee
                ? "Pilih periode untuk melihat detail nilai, pemeringkatan, dan transparansi skor SMART."
                : "Kelola sesi penilaian, sinkronkan pegawai, input nilai, dan cetak laporan resmi."}
            </p>
          </div>
          <span className="text-xs text-slate-500 font-mono tabular-nums">
            Total: <strong className="text-slate-800">{periods.length}</strong> sesi
          </span>
        </div>

        {isLoading ? (
          <TableSkeleton rows={4} columns={5} />
        ) : isError ? (
          <ErrorState
            title="Gagal Memuat Periode Evaluasi"
            message={
              error instanceof Error
                ? error.message
                : "Terjadi kesalahan saat memuat data."
            }
            onRetry={() => refetch()}
          />
        ) : periods.length === 0 ? (
          <EmptyState
            title="Belum Ada Periode Penilaian"
            description="Buka sesi evaluasi berkala untuk memulai proses pembobotan SMART dan penilaian kinerja karyawan."
            actionLabel={canManage ? "Buka Periode Sekarang" : undefined}
            onAction={canManage ? () => setIsCreateOpen(true) : undefined}
          />
        ) : (
          <div>
            {/* 1. Mobile Inset Rows View (< sm) */}
            <div className="sm:hidden space-y-2.5">
              {periods.map((item) => (
                <div
                  key={item.id_performance_periods}
                  className="p-3.5 rounded-2xl border border-slate-200/70 bg-white hover:bg-slate-50/70 transition-colors space-y-2.5 shadow-[0_1px_2px_rgba(0,0,0,0.02)]"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-xl bg-sky-500/10 text-sky-600 flex items-center justify-center font-bold text-xs flex-shrink-0">
                        SPK
                      </div>
                      <div>
                        <div className="text-xs font-bold text-slate-900 leading-tight">
                          {item.name}
                        </div>
                        <div className="text-[11px] text-slate-500 font-mono">
                          {new Date(item.start_date).toLocaleDateString("id-ID", {
                            day: "numeric",
                            month: "short",
                            year: "numeric",
                          })}{" "}
                          -{" "}
                          {new Date(item.end_date).toLocaleDateString("id-ID", {
                            day: "numeric",
                            month: "short",
                            year: "numeric",
                          })}
                        </div>
                      </div>
                    </div>
                    <StatusBadge status={item.status} />
                  </div>

                  <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50/80 border border-slate-100 text-[11.5px]">
                    <span className="text-slate-500">Pegawai Terdaftar:</span>
                    <span className="font-bold text-slate-900 font-mono">
                      {item.evaluations_count ?? 0} Orang
                    </span>
                  </div>

                  <div className="grid grid-cols-2 gap-2 pt-1">
                    {(item.status === "calculated" ||
                      item.status === "finalized") && (
                      <button
                        type="button"
                        onClick={() =>
                          handleDownloadPdf(item.id_performance_periods)
                        }
                        className="min-h-[40px] rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
                      >
                        <FileText className="w-3.5 h-3.5" />
                        <span>PDF</span>
                      </button>
                    )}
                    <Link
                      href={`/performance/${item.id_performance_periods}`}
                      className={cn(
                        "min-h-[40px] rounded-xl bg-orange-600 hover:bg-orange-700 active:scale-[0.98] text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-2xs transition-all",
                        item.status !== "calculated" &&
                          item.status !== "finalized" &&
                          "col-span-2"
                      )}
                    >
                      <span>{isEmployee ? "Lihat Nilai" : "Kelola Evaluasi"}</span>
                      <ArrowRight className="w-3.5 h-3.5" />
                    </Link>
                  </div>
                </div>
              ))}
            </div>

            {/* 2. Desktop Table View (>= sm) */}
            <div className="hidden sm:block overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                    <th scope="col" className="px-4 py-3">Nama Periode</th>
                    <th scope="col" className="px-4 py-3 font-mono">Rentang Waktu</th>
                    <th scope="col" className="px-4 py-3 text-center">Pegawai Terdaftar</th>
                    <th scope="col" className="px-4 py-3 text-center">Status</th>
                    <th scope="col" className="px-4 py-3 text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {periods.map((item) => (
                    <tr
                      key={item.id_performance_periods}
                      className="hover:bg-slate-50/60 transition-colors"
                    >
                      <td className="px-4 py-3.5 font-bold text-slate-900">
                        <div className="flex items-center gap-2.5">
                          <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-sky-50 text-sky-600 font-bold text-xs flex-shrink-0">
                            SPK
                          </div>
                          <div>
                            <div>{item.name}</div>
                            <div className="text-[11px] text-slate-400 font-mono font-normal">
                              ID #{item.id_performance_periods}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3.5 text-slate-600 font-mono">
                        {new Date(item.start_date).toLocaleDateString("id-ID", {
                          day: "numeric",
                          month: "short",
                          year: "numeric",
                        })}{" "}
                        -{" "}
                        {new Date(item.end_date).toLocaleDateString("id-ID", {
                          day: "numeric",
                          month: "short",
                          year: "numeric",
                        })}
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-700 font-mono">
                          <Users className="h-3 w-3 text-slate-500" />
                          {item.evaluations_count ?? 0} Orang
                        </span>
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <StatusBadge status={item.status} />
                      </td>
                      <td className="px-4 py-3.5 text-right">
                        <div className="flex items-center justify-end gap-2">
                          {(item.status === "calculated" ||
                            item.status === "finalized") && (
                            <button
                              type="button"
                              onClick={() =>
                                handleDownloadPdf(item.id_performance_periods)
                              }
                              title="Unduh Laporan PDF"
                              className="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-600 transition-colors cursor-pointer min-h-[36px] min-w-[36px] flex items-center justify-center"
                            >
                              <FileText className="h-3.5 w-3.5" />
                            </button>
                          )}
                          <Link href={`/performance/${item.id_performance_periods}`}>
                            <button
                              type="button"
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-orange-600 hover:bg-orange-700 active:scale-[0.98] text-white font-bold text-xs shadow-2xs transition-all cursor-pointer min-h-[36px]"
                            >
                              <span>{isEmployee ? "Lihat Nilai" : "Kelola Evaluasi"}</span>
                              <ArrowRight className="h-3 w-3" />
                            </button>
                          </Link>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* 5. Modal Buka Periode Baru (Apple Sheet Style) */}
      {isCreateOpen && (
        <Modal
          isOpen={true}
          onClose={() => {
            if (!createMutation.isPending) {
              setIsCreateOpen(false);
              setCreateError(null);
            }
          }}
          title="Buka Periode Penilaian Kinerja Baru"
          description="Sesi evaluasi berkala untuk karyawan. Pegawai aktif dan data kehadiran akan disinkronkan otomatis."
          maxWidth="md"
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
                className="min-h-[44px] rounded-xl bg-orange-600 hover:bg-orange-700 font-bold"
              >
                Buat & Sinkronkan Pegawai
              </Button>
            </div>
          }
        >
          <form onSubmit={handleCreateSubmit} className="space-y-4 text-xs">
            {createError && (
              <div
                role="alert"
                className="p-3.5 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 font-medium"
              >
                {createError}
              </div>
            )}

            <div>
              <label
                htmlFor="period_name"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Nama Periode Penilaian <span className="text-rose-500">*</span>
              </label>
              <input
                id="period_name"
                type="text"
                required
                placeholder="Contoh: Penilaian Kinerja Semester I - 2026"
                value={periodName}
                onChange={(e) => setPeriodName(e.target.value)}
                className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label
                  htmlFor="period_start_date"
                  className="block text-xs font-semibold text-slate-700 mb-1.5"
                >
                  Tanggal Mulai <span className="text-rose-500">*</span>
                </label>
                <input
                  id="period_start_date"
                  type="date"
                  required
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
                />
              </div>

              <div>
                <label
                  htmlFor="period_end_date"
                  className="block text-xs font-semibold text-slate-700 mb-1.5"
                >
                  Tanggal Akhir <span className="text-rose-500">*</span>
                </label>
                <input
                  id="period_end_date"
                  type="date"
                  required
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
                />
              </div>
            </div>
          </form>
        </Modal>
      )}

      {/* Floating Action Button (FAB) + Mobile */}
      {canManage && (
        <button
          type="button"
          onClick={() => {
            setCreateError(null);
            setIsCreateOpen(true);
          }}
          aria-label="Buka Periode Penilaian Baru"
          className="sm:hidden fixed bottom-20 right-4 z-40 w-14 h-14 rounded-full bg-orange-600 hover:bg-orange-700 active:scale-90 text-white shadow-[0_8px_24px_rgba(234,88,12,0.45)] flex items-center justify-center transition-transform cursor-pointer focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-orange-500/30"
        >
          <Plus className="w-7 h-7 stroke-[2.5]" aria-hidden="true" />
        </button>
      )}
    </div>
  );
}
