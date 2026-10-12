"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  ArrowLeft,
  Award,
  Calculator,
  RefreshCw,
  Lock,
  FileText,
  Sliders,
  Users,
  CheckCircle2,
  AlertCircle,
  HelpCircle,
  Info,
  Calendar,
  Sparkles,
  TrendingUp,
  ShieldCheck,
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
import type {
  ApiResponse,
  PerformancePeriod,
  PerformanceCriterion,
  PerformanceEvaluation,
  User,
} from "@/types";

interface PeriodDetailResponse {
  period: PerformancePeriod;
  criteria: PerformanceCriterion[];
  evaluations: PerformanceEvaluation[];
}

export default function PerformanceDetailPage() {
  const params = useParams();
  const periodId = Number(params.id);
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

  const [activeTab, setActiveTab] = useState<
    "ranking" | "scoring" | "criteria" | "my-report"
  >(isEmployee ? "my-report" : "ranking");

  useEffect(() => {
    if (isEmployee) {
      setActiveTab("my-report");
    }
  }, [isEmployee]);

  // Local state for scoring form
  const [localScores, setLocalScores] = useState<Record<string, number>>({});
  const [isDirty, setIsDirty] = useState(false);
  const [notification, setNotification] = useState<{
    type: "success" | "error";
    message: string;
  } | null>(null);

  // Criteria Edit Modal
  const [editingCriterion, setEditingCriterion] =
    useState<PerformanceCriterion | null>(null);
  const [editWeight, setEditWeight] = useState<number>(0);
  const [editCMin, setEditCMin] = useState<number>(0);
  const [editCMax, setEditCMax] = useState<number>(100);

  // Query Detail Periode
  const {
    data,
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["performance-period", periodId],
    queryFn: async () => {
      const response = await apiClient.get<
        ApiResponse<PeriodDetailResponse>
      >(`/performance/periods/${periodId}`);
      if (response.data.success && response.data.data) {
        return response.data.data;
      }
      throw new Error(
        response.data.message || "Gagal mengambil data periode."
      );
    },
    enabled: !!periodId,
  });

  const period = data?.period;
  const criteria = data?.criteria || [];
  const evaluations = data?.evaluations || [];

  // Identify employee's own evaluation record
  const myEvaluation = React.useMemo(() => {
    if (!currentUser || evaluations.length === 0) return null;
    return (
      evaluations.find(
        (e) =>
          e.employee?.id_users === currentUser.id_users ||
          e.employee?.user?.email === currentUser.email
      ) || null
    );
  }, [currentUser, evaluations]);

  // Populate local scores from evaluations
  useEffect(() => {
    if (evaluations.length > 0) {
      const initial: Record<string, number> = {};
      evaluations.forEach((evalItem) => {
        evalItem.details?.forEach((detail) => {
          const key = `${evalItem.id_performance_evaluations}_${detail.id_performance_criteria}`;
          initial[key] = Number(detail.raw_score);
        });
      });
      setLocalScores(initial);
      setIsDirty(false);
    }
  }, [evaluations]);

  // Mutations
  const syncMutation = useMutation({
    mutationFn: async () => {
      const response = await apiClient.post<
        ApiResponse<{ synced_count: number }>
      >(`/performance/periods/${periodId}/sync-employees`);
      return response.data;
    },
    onSuccess: (res) => {
      queryClient.invalidateQueries({
        queryKey: ["performance-period", periodId],
      });
      setNotification({
        type: "success",
        message:
          res.message || "Berhasil mensinkronkan pegawai dan data presensi.",
      });
    },
    onError: (err: {
      response?: { data?: { message?: string } };
      message?: string;
    }) => {
      setNotification({
        type: "error",
        message:
          err.response?.data?.message ||
          err.message ||
          "Gagal sinkronisasi data pegawai.",
      });
    },
  });

  const calculateMutation = useMutation({
    mutationFn: async () => {
      const response = await apiClient.post<ApiResponse<unknown>>(
        `/performance/periods/${periodId}/calculate`
      );
      return response.data;
    },
    onSuccess: (res) => {
      queryClient.invalidateQueries({
        queryKey: ["performance-period", periodId],
      });
      setNotification({
        type: "success",
        message: res.message || "Kalkulasi SMART berhasil diperbarui.",
      });
      setActiveTab("ranking");
    },
    onError: (err: {
      response?: { data?: { message?: string } };
      message?: string;
    }) => {
      setNotification({
        type: "error",
        message:
          err.response?.data?.message ||
          err.message ||
          "Gagal menjalankan kalkulasi SMART.",
      });
    },
  });

  const finalizeMutation = useMutation({
    mutationFn: async () => {
      const response = await apiClient.post<
        ApiResponse<PerformancePeriod>
      >(`/performance/periods/${periodId}/finalize`);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["performance-period", periodId],
      });
      setNotification({
        type: "success",
        message: "Periode evaluasi berhasil difinalisasi dan dikunci.",
      });
    },
    onError: (err: {
      response?: { data?: { message?: string } };
      message?: string;
    }) => {
      setNotification({
        type: "error",
        message:
          err.response?.data?.message ||
          err.message ||
          "Gagal memfinalisasi periode.",
      });
    },
  });

  const saveScoresMutation = useMutation({
    mutationFn: async (
      scoresPayload: {
        id_performance_evaluations: number;
        id_performance_criteria: number;
        raw_score: number;
      }[]
    ) => {
      const response = await apiClient.post<ApiResponse<null>>(
        `/performance/periods/${periodId}/scores`,
        {
          scores: scoresPayload,
        }
      );
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["performance-period", periodId],
      });
      setIsDirty(false);
      setNotification({
        type: "success",
        message:
          "Nilai kinerja berhasil disimpan. Jalankan kalkulasi untuk melihat pembaruan peringkat.",
      });
    },
    onError: (err: {
      response?: { data?: { message?: string } };
      message?: string;
    }) => {
      setNotification({
        type: "error",
        message:
          err.response?.data?.message ||
          err.message ||
          "Gagal menyimpan nilai kinerja.",
      });
    },
  });

  const updateCriterionMutation = useMutation({
    mutationFn: async (payload: {
      id: number;
      weight: number;
      c_min: number;
      c_max: number;
    }) => {
      const response = await apiClient.put<
        ApiResponse<PerformanceCriterion>
      >(`/performance/criteria/${payload.id}`, {
        weight: payload.weight,
        c_min: payload.c_min,
        c_max: payload.c_max,
      });
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["performance-period", periodId],
      });
      setEditingCriterion(null);
      setNotification({
        type: "success",
        message: "Bobot kriteria berhasil diperbarui.",
      });
    },
    onError: (err: {
      response?: { data?: { message?: string } };
      message?: string;
    }) => {
      setNotification({
        type: "error",
        message:
          err.response?.data?.message ||
          err.message ||
          "Gagal memperbarui kriteria.",
      });
    },
  });

  const resetCriteriaMutation = useMutation({
    mutationFn: async () => {
      const response = await apiClient.post<
        ApiResponse<PerformanceCriterion[]>
      >("/performance/criteria/reset-defaults");
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["performance-period", periodId],
      });
      setNotification({
        type: "success",
        message: "Kriteria berhasil direset ke standar default (K1-K4).",
      });
    },
    onError: (err: {
      response?: { data?: { message?: string } };
      message?: string;
    }) => {
      setNotification({
        type: "error",
        message:
          err.response?.data?.message ||
          err.message ||
          "Gagal mereset kriteria default.",
      });
    },
  });

  const handleScoreChange = (
    evalId: number,
    critId: number,
    val: number
  ) => {
    const key = `${evalId}_${critId}`;
    setLocalScores((prev) => ({ ...prev, [key]: val }));
    setIsDirty(true);
  };

  const handleSaveAllScores = () => {
    const payload: {
      id_performance_evaluations: number;
      id_performance_criteria: number;
      raw_score: number;
    }[] = [];

    Object.entries(localScores).forEach(([key, val]) => {
      const [evalIdStr, critIdStr] = key.split("_");
      const evalId = parseInt(evalIdStr, 10);
      const critId = parseInt(critIdStr, 10);
      payload.push({
        id_performance_evaluations: evalId,
        id_performance_criteria: critId,
        raw_score: val,
      });
    });

    saveScoresMutation.mutate(payload);
  };

  const handleDownloadPdf = () => {
    const token =
      typeof window !== "undefined" ? localStorage.getItem("hris_token") : null;
    const url = `${
      process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1"
    }/performance/periods/${periodId}/pdf`;

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
        setNotification({
          type: "error",
          message: err.message || "Terjadi kesalahan saat mengunduh PDF.",
        });
      });
  };

  if (isLoading) return <TableSkeleton rows={8} />;
  if (isError || !period) {
    return (
      <ErrorState
        title="Gagal Memuat Detail Periode"
        message={
          error instanceof Error
            ? error.message
            : "Data periode tidak ditemukan."
        }
        onRetry={() => refetch()}
      />
    );
  }

  const isFinalized = period.status === "finalized";
  const sumWeight = criteria.reduce((acc, c) => acc + Number(c.weight), 0);
  const totalEmployees = evaluations.length;
  const calculatedEmployees = evaluations.filter(
    (e) => e.final_score !== null
  ).length;

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      {/* 1. Header & Navigation (Apple HIG Large Title with Back Pill) */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div className="flex items-center gap-3">
          <Link
            href="/performance"
            className="p-2.5 min-h-[44px] min-w-[44px] flex items-center justify-center rounded-2xl bg-white hover:bg-slate-50 active:scale-[0.96] text-slate-500 hover:text-slate-800 border border-slate-200/80 shadow-[0_1px_2px_rgba(0,0,0,0.03)] transition-all cursor-pointer"
            aria-label="Kembali ke daftar periode"
          >
            <ArrowLeft className="h-4 w-4" />
          </Link>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl sm:text-2xl font-extrabold tracking-tight text-slate-900">
                {period.name}
              </h1>
              <StatusBadge status={period.status} />
            </div>
            <p className="text-xs text-slate-500 mt-0.5 font-mono">
              Rentang: {new Date(period.start_date).toLocaleDateString("id-ID")}{" "}
              - {new Date(period.end_date).toLocaleDateString("id-ID")}
            </p>
          </div>
        </div>

        {/* Global Action Bar */}
        <div className="flex flex-wrap items-center gap-2 self-start sm:self-auto">
          {canManage && !isFinalized && (
            <>
              <button
                type="button"
                onClick={() => syncMutation.mutate()}
                disabled={syncMutation.isPending}
                title="Sinkronkan ulang daftar karyawan dan persentase kehadiran"
                className="inline-flex items-center gap-1.5 px-3 py-2 min-h-[44px] rounded-xl bg-white hover:bg-slate-50 text-slate-700 font-semibold text-xs border border-slate-200 shadow-2xs transition-all cursor-pointer disabled:opacity-50"
              >
                <RefreshCw
                  className={`h-3.5 w-3.5 ${
                    syncMutation.isPending ? "animate-spin" : ""
                  }`}
                />
                <span>Tarik Presensi (K2)</span>
              </button>

              <button
                type="button"
                onClick={() => calculateMutation.mutate()}
                disabled={calculateMutation.isPending || totalEmployees === 0}
                className="inline-flex items-center gap-1.5 px-3 py-2 min-h-[44px] rounded-xl bg-sky-600 hover:bg-sky-700 active:scale-[0.98] text-white font-bold text-xs shadow-2xs transition-all cursor-pointer disabled:opacity-50"
              >
                <Calculator className="h-3.5 w-3.5" />
                <span>
                  {calculateMutation.isPending ? "Menghitung..." : "Jalankan SMART"}
                </span>
              </button>

              {period.status === "calculated" && (
                <button
                  type="button"
                  onClick={() => finalizeMutation.mutate()}
                  disabled={finalizeMutation.isPending}
                  className="inline-flex items-center gap-1.5 px-3 py-2 min-h-[44px] rounded-xl bg-emerald-600 hover:bg-emerald-700 active:scale-[0.98] text-white font-bold text-xs shadow-2xs transition-all cursor-pointer disabled:opacity-50"
                >
                  <Lock className="h-3.5 w-3.5" />
                  <span>Kunci Periode</span>
                </button>
              )}
            </>
          )}

          <button
            type="button"
            onClick={handleDownloadPdf}
            className="inline-flex items-center gap-1.5 px-3 py-2 min-h-[44px] rounded-xl bg-white hover:bg-slate-50 text-slate-700 font-semibold text-xs border border-slate-200 shadow-2xs transition-all cursor-pointer"
          >
            <FileText className="h-3.5 w-3.5 text-slate-500" />
            <span>Cetak PDF</span>
          </button>
        </div>
      </div>

      {/* 2. Notification Alert */}
      {notification && (
        <div
          role="status"
          className={cn(
            "flex items-center justify-between p-3.5 sm:p-4 rounded-2xl text-xs sm:text-sm font-medium border shadow-[0_2px_8px_rgba(0,0,0,0.04)] transition-all",
            notification.type === "success"
              ? "bg-emerald-50/90 border-emerald-200 text-emerald-800"
              : "bg-rose-50/90 border-rose-200 text-rose-800"
          )}
        >
          <div className="flex items-center gap-2.5">
            {notification.type === "success" ? (
              <CheckCircle2 className="h-4 w-4 text-emerald-600 flex-shrink-0" />
            ) : (
              <AlertCircle className="h-4 w-4 text-rose-600 flex-shrink-0" />
            )}
            <span>{notification.message}</span>
          </div>
          <button
            type="button"
            onClick={() => setNotification(null)}
            className="text-xs font-semibold hover:underline cursor-pointer ml-3"
          >
            Tutup
          </button>
        </div>
      )}

      {/* 3. Apple Segmented Control Tabs */}
      <div className="inline-flex p-1 bg-slate-200/60 rounded-2xl border border-slate-200/80 shadow-[0_1px_2px_rgba(0,0,0,0.02)] overflow-x-auto max-w-full">
        {isEmployee && (
          <button
            type="button"
            onClick={() => setActiveTab("my-report")}
            className={cn(
              "px-3.5 py-1.5 text-xs font-semibold rounded-xl transition-all cursor-pointer flex items-center gap-1.5 whitespace-nowrap min-h-[36px]",
              activeTab === "my-report"
                ? "bg-white text-slate-900 shadow-xs font-bold"
                : "text-slate-600 hover:text-slate-900"
            )}
          >
            <Award className="h-3.5 w-3.5" />
            <span>Rapor Kinerja Saya</span>
          </button>
        )}

        <button
          type="button"
          onClick={() => setActiveTab("ranking")}
          className={cn(
            "px-3.5 py-1.5 text-xs font-semibold rounded-xl transition-all cursor-pointer flex items-center gap-1.5 whitespace-nowrap min-h-[36px]",
            activeTab === "ranking"
              ? "bg-white text-slate-900 shadow-xs font-bold"
              : "text-slate-600 hover:text-slate-900"
          )}
        >
          <TrendingUp className="h-3.5 w-3.5" />
          <span>Hasil Ranking & Rekomendasi</span>
          {calculatedEmployees > 0 && (
            <span className="rounded-full bg-sky-100 px-1.5 py-0.5 text-[10px] text-sky-800 font-bold font-mono">
              {calculatedEmployees}
            </span>
          )}
        </button>

        {canManage && (
          <>
            <button
              type="button"
              onClick={() => setActiveTab("scoring")}
              className={cn(
                "px-3.5 py-1.5 text-xs font-semibold rounded-xl transition-all cursor-pointer flex items-center gap-1.5 whitespace-nowrap min-h-[36px]",
                activeTab === "scoring"
                  ? "bg-white text-slate-900 shadow-xs font-bold"
                  : "text-slate-600 hover:text-slate-900"
              )}
            >
              <Users className="h-3.5 w-3.5" />
              <span>Input Nilai Pegawai</span>
              {isDirty && (
                <span
                  className="h-2 w-2 rounded-full bg-amber-500"
                  title="Ada perubahan belum tersimpan"
                />
              )}
            </button>

            <button
              type="button"
              onClick={() => setActiveTab("criteria")}
              className={cn(
                "px-3.5 py-1.5 text-xs font-semibold rounded-xl transition-all cursor-pointer flex items-center gap-1.5 whitespace-nowrap min-h-[36px]",
                activeTab === "criteria"
                  ? "bg-white text-slate-900 shadow-xs font-bold"
                  : "text-slate-600 hover:text-slate-900"
              )}
            >
              <Sliders className="h-3.5 w-3.5" />
              <span>Bobot Kriteria SMART</span>
              <span className="text-[10px] text-slate-400 font-mono">
                ({criteria.length})
              </span>
            </button>
          </>
        )}
      </div>

      {/* ============================================================== */}
      {/* TAB 0: RAPOR KINERJA SAYA (Apple Inset Personal Scorecard) */}
      {/* ============================================================== */}
      {activeTab === "my-report" && (
        <div className="space-y-4">
          {myEvaluation ? (
            <div className="space-y-4">
              {/* Apple HIG Hero Scorecard Banner */}
              <div className="rounded-3xl border border-slate-200/80 bg-gradient-to-br from-white via-white to-sky-50/40 p-5 sm:p-6 shadow-[0_1px_3px_rgba(0,0,0,0.03)] space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pb-4 border-b border-slate-100">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-2xl bg-sky-500/10 text-sky-600 flex items-center justify-center font-bold text-lg flex-shrink-0">
                      #{myEvaluation.rank || "-"}
                    </div>
                    <div>
                      <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                        Hasil Evaluasi Mandiri
                      </span>
                      <h2 className="text-lg sm:text-xl font-extrabold text-slate-900">
                        {myEvaluation.employee?.user?.name || "Karyawan"}
                      </h2>
                      <div className="text-xs text-slate-500 font-mono">
                        NIK: {myEvaluation.employee?.nik || "-"} | Departemen:{" "}
                        {myEvaluation.employee?.department?.name || "-"}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 self-start sm:self-auto">
                    {myEvaluation.grade && (
                      <span
                        className={cn(
                          "px-3 py-1 rounded-xl text-xs font-extrabold",
                          myEvaluation.grade === "Sangat Baik"
                            ? "bg-emerald-100 text-emerald-800"
                            : myEvaluation.grade === "Baik"
                            ? "bg-sky-100 text-sky-800"
                            : myEvaluation.grade === "Cukup"
                            ? "bg-amber-100 text-amber-800"
                            : "bg-rose-100 text-rose-800"
                        )}
                      >
                        Predikat: {myEvaluation.grade}
                      </span>
                    )}
                  </div>
                </div>

                {/* Score & Recommendation Banner */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
                  <div className="p-4 rounded-2xl bg-white border border-slate-200/80 shadow-2xs flex flex-col justify-between">
                    <span className="text-xs font-semibold text-slate-500">
                      Total Skor SMART V(a)
                    </span>
                    <div className="mt-1 flex items-baseline gap-1.5">
                      <span className="text-2xl sm:text-3xl font-extrabold font-mono text-sky-600 tabular-nums">
                        {myEvaluation.final_score !== null
                          ? Number(myEvaluation.final_score).toFixed(2)
                          : "Sedang Dihitung"}
                      </span>
                      <span className="text-xs text-slate-400 font-medium">/ 100</span>
                    </div>
                    <div className="mt-1 text-[11px] text-slate-400">
                      Berdasarkan pembobotan terverifikasi
                    </div>
                  </div>

                  <div className="p-4 rounded-2xl bg-white border border-slate-200/80 shadow-2xs flex flex-col justify-between">
                    <span className="text-xs font-semibold text-slate-500">
                      Rekomendasi Evaluasi
                    </span>
                    <div className="mt-1 text-xs sm:text-sm font-semibold text-slate-800">
                      {myEvaluation.recommendation ||
                        "Rekomendasi resmi akan muncul setelah periode difinalisasi."}
                    </div>
                    <div className="mt-1 text-[11px] text-slate-400">
                      Status periode: {period.status}
                    </div>
                  </div>
                </div>
              </div>

              {/* Rincian Komponen Penilaian SMART */}
              <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] space-y-3">
                <h3 className="text-sm font-bold text-slate-900">
                  Rincian Penilaian per Kriteria
                </h3>

                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                  {criteria.map((c) => {
                    const detail = myEvaluation.details?.find(
                      (d) => d.id_performance_criteria === c.id_performance_criteria
                    );
                    return (
                      <div
                        key={c.id_performance_criteria}
                        className="p-3.5 rounded-2xl border border-slate-200/80 bg-slate-50/50 space-y-2"
                      >
                        <div className="flex items-center justify-between">
                          <span className="text-xs font-bold text-slate-900">
                            {c.code}
                          </span>
                          <span className="text-[10px] uppercase font-semibold text-slate-400">
                            {c.type} ({c.weight}%)
                          </span>
                        </div>
                        <div className="text-xs font-medium text-slate-600 line-clamp-1">
                          {c.name}
                        </div>
                        <div className="pt-2 border-t border-slate-200/60 flex items-center justify-between text-xs">
                          <span className="text-slate-500">Nilai:</span>
                          <span className="font-mono font-bold text-slate-900 tabular-nums">
                            {detail
                              ? Number(detail.raw_score).toFixed(1)
                              : "-"}
                          </span>
                        </div>
                        <div className="flex items-center justify-between text-[11px]">
                          <span className="text-slate-400">Utilitas (u):</span>
                          <span className="font-mono text-sky-600 font-semibold tabular-nums">
                            {detail
                              ? `${Number(detail.utility_score).toFixed(0)}%`
                              : "-"}
                          </span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          ) : (
            <EmptyState
              title="Data Evaluasi Belum Tersedia"
              description="Anda belum terdaftar dalam sesi evaluasi ini atau data kehadiran Anda sedang disinkronkan oleh pihak HR."
            />
          )}
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB 1: HASIL RANKING & REKOMENDASI (EXECUTIVE DASHBOARD) */}
      {/* ============================================================== */}
      {activeTab === "ranking" && (
        <div className="space-y-4">
          {evaluations.length === 0 ? (
            <EmptyState
              title="Belum Ada Pegawai Terdaftar"
              description="Klik tombol 'Tarik Presensi (K2)' di atas untuk mensinkronkan daftar karyawan aktif ke periode ini."
              actionLabel={canManage ? "Tarik Data Pegawai Sekarang" : undefined}
              onAction={canManage ? () => syncMutation.mutate() : undefined}
            />
          ) : calculatedEmployees === 0 ? (
            <div className="p-8 text-center rounded-3xl border-2 border-dashed border-slate-200 bg-white space-y-3">
              <Calculator className="mx-auto h-10 w-10 text-sky-500" />
              <h3 className="text-base font-bold text-slate-900">
                Kalkulasi SMART Belum Dijalankan
              </h3>
              <p className="text-xs text-slate-500 max-w-md mx-auto">
                {canManage
                  ? "Pastikan nilai K1 (KPI), K3 (Attitude), dan K4 (SP) telah diinput di tab 'Input Nilai Pegawai', lalu jalankan kalkulasi."
                  : "Hasil peringkat dan predikat otomatis belum dihitung oleh manajemen."}
              </p>
              {canManage && (
                <button
                  type="button"
                  onClick={() => calculateMutation.mutate()}
                  disabled={calculateMutation.isPending}
                  className="inline-flex items-center gap-2 px-4 py-2.5 min-h-[44px] rounded-2xl bg-sky-600 hover:bg-sky-700 active:scale-[0.98] text-white font-bold text-xs shadow-2xs transition-all cursor-pointer"
                >
                  <Calculator className="h-4 w-4" />
                  <span>Jalankan Kalkulasi SMART Sekarang</span>
                </button>
              )}
            </div>
          ) : (
            <>
              {/* Podium Top 3 Performer */}
              {evaluations.length >= 3 &&
                evaluations[0].final_score !== null && (
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-3 sm:gap-4">
                    {evaluations.slice(0, 3).map((top, idx) => (
                      <div
                        key={top.id_performance_evaluations}
                        className={cn(
                          "rounded-3xl p-4 sm:p-5 border shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between",
                          idx === 0
                            ? "border-amber-300 bg-gradient-to-br from-white to-amber-50/40"
                            : idx === 1
                            ? "border-slate-300 bg-gradient-to-br from-white to-slate-50/50"
                            : "border-orange-200 bg-gradient-to-br from-white to-orange-50/30"
                        )}
                      >
                        <div className="flex items-center justify-between">
                          <span
                            className={cn(
                              "inline-flex items-center justify-center h-7 w-7 rounded-full text-xs font-bold",
                              idx === 0
                                ? "bg-amber-500 text-white"
                                : idx === 1
                                ? "bg-slate-400 text-white"
                                : "bg-orange-400 text-white"
                            )}
                          >
                            #{idx + 1}
                          </span>
                          <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
                            {idx === 0
                              ? "Peringkat 1"
                              : idx === 1
                              ? "Peringkat 2"
                              : "Peringkat 3"}
                          </span>
                        </div>
                        <div className="mt-3">
                          <div className="font-bold text-sm sm:text-base text-slate-900 leading-tight">
                            {top.employee?.user?.name ||
                              `Pegawai #${top.id_employees}`}
                          </div>
                          <div className="text-xs text-slate-500 font-mono mt-0.5">
                            {top.employee?.department?.name || "-"}
                          </div>
                        </div>
                        <div className="mt-4 pt-3 border-t border-slate-200/60 flex items-center justify-between">
                          <div>
                            <div className="text-[11px] text-slate-400">
                              Skor V(a)
                            </div>
                            <div className="text-lg sm:text-xl font-extrabold text-sky-600 font-mono tabular-nums">
                              {Number(top.final_score).toFixed(2)}
                            </div>
                          </div>
                          <span className="px-2.5 py-0.5 rounded-xl text-xs font-bold bg-emerald-100 text-emerald-800">
                            {top.grade}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}

              {/* Inset Grouped Card: Matriks Perangkingan SMART */}
              <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 pb-3 border-b border-slate-100">
                  <div>
                    <h3 className="font-bold text-sm sm:text-base text-slate-900 tracking-tight">
                      Matriks Hasil Perangkingan Akhir & Rekomendasi
                    </h3>
                    <p className="text-[11px] sm:text-xs text-slate-500 mt-0.5">
                      Nilai utilitas (u) dan skor terbobot telah dikalkulasi
                      berdasarkan bobot ternormalisasi.
                    </p>
                  </div>
                  <div className="text-xs text-slate-500 font-mono tabular-nums">
                    Total: <strong className="text-slate-800">{evaluations.length}</strong> Karyawan
                  </div>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead>
                      <tr className="bg-slate-50 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                        <th className="px-3 py-3 text-center w-12">Rank</th>
                        <th className="px-3 py-3">Nama Pegawai</th>
                        <th className="px-3 py-3">Departemen</th>
                        {criteria.map((c) => (
                          <th
                            key={c.id_performance_criteria}
                            className="px-2.5 py-3 text-center"
                          >
                            {c.code}
                            <span className="block text-[10px] lowercase text-slate-400 font-normal">
                              ({c.type})
                            </span>
                          </th>
                        ))}
                        <th className="px-3 py-3 text-center font-bold text-sky-700">
                          Skor V(a)
                        </th>
                        <th className="px-3 py-3 text-center">Predikat</th>
                        <th className="px-3 py-3">Rekomendasi</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium">
                      {evaluations.map((evalItem, index) => {
                        const rankNum = evalItem.rank ?? index + 1;
                        const detailsByCrit = new Map(
                          evalItem.details?.map((d) => [
                            d.id_performance_criteria,
                            d,
                          ]) || []
                        );

                        return (
                          <tr
                            key={evalItem.id_performance_evaluations}
                            className="hover:bg-slate-50/60 transition-colors"
                          >
                            <td className="px-3 py-3.5 text-center">
                              <span
                                className={cn(
                                  "inline-flex items-center justify-center h-6 w-6 rounded-full text-xs font-bold",
                                  rankNum <= 3
                                    ? "bg-sky-600 text-white"
                                    : "bg-slate-100 text-slate-700"
                                )}
                              >
                                {rankNum}
                              </span>
                            </td>
                            <td className="px-3 py-3.5">
                              <div className="font-bold text-slate-900">
                                {evalItem.employee?.user?.name ||
                                  `Pegawai #${evalItem.id_employees}`}
                              </div>
                              <div className="text-[11px] text-slate-400 font-mono">
                                {evalItem.employee?.nik || "-"}
                              </div>
                            </td>
                            <td className="px-3 py-3.5 text-slate-600">
                              {evalItem.employee?.department?.name || "-"}
                            </td>
                            {criteria.map((c) => {
                              const d = detailsByCrit.get(
                                c.id_performance_criteria
                              );
                              return (
                                <td
                                  key={c.id_performance_criteria}
                                  className="px-2.5 py-3.5 text-center"
                                >
                                  {d ? (
                                    <div>
                                      <div className="font-bold text-slate-800 font-mono tabular-nums">
                                        {Number(d.raw_score).toFixed(1)}
                                      </div>
                                      <div className="text-[10px] text-slate-400 font-mono">
                                        u: {Number(d.utility_score).toFixed(0)}%
                                      </div>
                                    </div>
                                  ) : (
                                    <span className="text-slate-300">-</span>
                                  )}
                                </td>
                              );
                            })}
                            <td className="px-3 py-3.5 text-center">
                              <span className="text-sm font-bold text-sky-600 font-mono tabular-nums">
                                {evalItem.final_score !== null
                                  ? Number(evalItem.final_score).toFixed(2)
                                  : "-"}
                              </span>
                            </td>
                            <td className="px-3 py-3.5 text-center">
                              {evalItem.grade ? (
                                <span
                                  className={cn(
                                    "inline-block px-2 py-0.5 rounded-lg text-xs font-bold",
                                    evalItem.grade === "Sangat Baik"
                                      ? "bg-emerald-100 text-emerald-800"
                                      : evalItem.grade === "Baik"
                                      ? "bg-sky-100 text-sky-800"
                                      : evalItem.grade === "Cukup"
                                      ? "bg-amber-100 text-amber-800"
                                      : "bg-rose-100 text-rose-800"
                                  )}
                                >
                                  {evalItem.grade}
                                </span>
                              ) : (
                                <span className="text-slate-400 text-xs">-</span>
                              )}
                            </td>
                            <td className="px-3 py-3.5 text-slate-700 max-w-xs truncate">
                              {evalItem.recommendation || "-"}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          )}
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB 2: INPUT NILAI PEGAWAI (MANAGEMENT ONLY) */}
      {/* ============================================================== */}
      {activeTab === "scoring" && canManage && (
        <div className="space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 bg-sky-50/70 border border-sky-100 p-4 rounded-3xl">
            <div className="flex items-start gap-2.5">
              <Info className="h-4 w-4 text-sky-600 mt-0.5 shrink-0" />
              <div className="text-xs text-sky-900 leading-relaxed">
                <span className="font-bold">Petunjuk Pengisian:</span> K1
                (Pencapaian KPI) & K3 (Attitude): 0-100 | K2 (Kehadiran):
                Auto-presensi | K4 (Pelanggaran/SP): 0 = Aman, 1 = SP1, 2 = SP2,
                3 = SP3.
              </div>
            </div>
            {!isFinalized && (
              <button
                type="button"
                onClick={handleSaveAllScores}
                disabled={saveScoresMutation.isPending || !isDirty}
                className="shrink-0 px-4 py-2 min-h-[44px] rounded-xl bg-orange-600 hover:bg-orange-700 active:scale-[0.98] text-white font-bold text-xs shadow-2xs transition-all cursor-pointer disabled:opacity-50"
              >
                {saveScoresMutation.isPending
                  ? "Menyimpan..."
                  : "Simpan Nilai Kinerja"}
              </button>
            )}
          </div>

          <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                  <th className="px-3 py-3 w-12 text-center">No</th>
                  <th className="px-3 py-3">Nama Pegawai</th>
                  <th className="px-3 py-3">Departemen</th>
                  {criteria.map((c) => (
                    <th
                      key={c.id_performance_criteria}
                      className="px-3 py-3 text-center"
                    >
                      <div className="font-bold text-slate-800">
                        {c.code} - {c.name}
                      </div>
                      <div className="text-[10px] text-slate-400 font-normal">
                        {c.source_type === "attendance"
                          ? "Auto-Presensi"
                          : `Rentang: ${c.c_min} - ${c.c_max}`}
                      </div>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium">
                {evaluations.map((evalItem, idx) => (
                  <tr
                    key={evalItem.id_performance_evaluations}
                    className="hover:bg-slate-50/50"
                  >
                    <td className="px-3 py-3.5 text-center font-mono text-xs text-slate-400">
                      {idx + 1}
                    </td>
                    <td className="px-3 py-3.5">
                      <div className="font-bold text-slate-900">
                        {evalItem.employee?.user?.name ||
                          `Pegawai #${evalItem.id_employees}`}
                      </div>
                      <div className="text-[11px] text-slate-400 font-mono">
                        {evalItem.employee?.nik || "-"}
                      </div>
                    </td>
                    <td className="px-3 py-3.5 text-slate-600">
                      {evalItem.employee?.department?.name || "-"}
                    </td>
                    {criteria.map((c) => {
                      const key = `${evalItem.id_performance_evaluations}_${c.id_performance_criteria}`;
                      const currentVal = localScores[key] ?? 0;
                      const isAuto = c.source_type === "attendance";

                      return (
                        <td
                          key={c.id_performance_criteria}
                          className="px-3 py-3.5 text-center"
                        >
                          {isAuto ? (
                            <span className="inline-flex items-center px-2.5 py-1 rounded-lg bg-slate-100 text-slate-700 font-bold text-xs font-mono">
                              {Number(currentVal).toFixed(1)}%
                            </span>
                          ) : (
                            <input
                              type="number"
                              step="0.1"
                              min={c.c_min}
                              max={c.c_max}
                              disabled={isFinalized}
                              value={currentVal}
                              onChange={(e) =>
                                handleScoreChange(
                                  evalItem.id_performance_evaluations,
                                  c.id_performance_criteria,
                                  parseFloat(e.target.value) || 0
                                )
                              }
                              className="w-20 text-center rounded-xl border border-slate-200/80 bg-white px-2 py-1.5 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-sky-500/20 focus:border-sky-500 disabled:bg-slate-100"
                            />
                          )}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB 3: BOBOT KRITERIA SMART (MANAGEMENT ONLY) */}
      {/* ============================================================== */}
      {activeTab === "criteria" && canManage && (
        <div className="space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
              <h3 className="text-sm font-bold text-slate-900">
                Parameter Kriteria & Pembobotan SMART
              </h3>
              <p className="text-xs text-slate-500">
                Total bobot saat ini:{" "}
                <strong className="text-slate-800">{sumWeight}</strong>. Normalisasi
                dihitung otomatis (w = W / &Sigma;W).
              </p>
            </div>
            {!isFinalized && (
              <button
                type="button"
                onClick={() => resetCriteriaMutation.mutate()}
                disabled={resetCriteriaMutation.isPending}
                className="px-3 py-2 min-h-[44px] rounded-xl bg-white hover:bg-slate-50 text-slate-600 font-semibold text-xs border border-slate-200 transition-colors cursor-pointer"
              >
                Reset ke Standar Default (K1-K4)
              </button>
            )}
          </div>

          <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                  <th className="px-3 py-3 text-center w-16">Kode</th>
                  <th className="px-3 py-3">Nama Kriteria</th>
                  <th className="px-3 py-3 text-center">Tipe</th>
                  <th className="px-3 py-3 text-center">Bobot Awal (W)</th>
                  <th className="px-3 py-3 text-center">Normalisasi (w)</th>
                  <th className="px-3 py-3 text-center">C_min</th>
                  <th className="px-3 py-3 text-center">C_max</th>
                  <th className="px-3 py-3 text-center">Sumber</th>
                  {!isFinalized && <th className="px-3 py-3 text-right">Aksi</th>}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium">
                {criteria.map((c) => {
                  const normWeight = sumWeight > 0 ? c.weight / sumWeight : 0;
                  return (
                    <tr
                      key={c.id_performance_criteria}
                      className="hover:bg-slate-50/50"
                    >
                      <td className="px-3 py-3.5 text-center font-bold text-slate-900">
                        {c.code}
                      </td>
                      <td className="px-3 py-3.5 font-bold text-slate-900">
                        {c.name}
                      </td>
                      <td className="px-3 py-3.5 text-center">
                        <span
                          className={cn(
                            "inline-block px-2 py-0.5 rounded-lg text-xs font-bold",
                            c.type === "benefit"
                              ? "bg-emerald-100 text-emerald-800"
                              : "bg-rose-100 text-rose-800"
                          )}
                        >
                          {c.type.toUpperCase()}
                        </span>
                      </td>
                      <td className="px-3 py-3.5 text-center font-mono font-bold text-slate-800">
                        {Number(c.weight).toFixed(0)}
                      </td>
                      <td className="px-3 py-3.5 text-center font-mono text-sky-700 font-bold">
                        {normWeight.toFixed(4)} ({(normWeight * 100).toFixed(1)}%)
                      </td>
                      <td className="px-3 py-3.5 text-center font-mono">
                        {c.c_min}
                      </td>
                      <td className="px-3 py-3.5 text-center font-mono">
                        {c.c_max}
                      </td>
                      <td className="px-3 py-3.5 text-center text-slate-500">
                        {c.source_type === "attendance"
                          ? "Presensi Otomatis"
                          : "Input Manual"}
                      </td>
                      {!isFinalized && (
                        <td className="px-3 py-3.5 text-right">
                          <button
                            type="button"
                            onClick={() => {
                              setEditingCriterion(c);
                              setEditWeight(Number(c.weight));
                              setEditCMin(Number(c.c_min));
                              setEditCMax(Number(c.c_max));
                            }}
                            className="px-3 py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs transition-colors cursor-pointer"
                          >
                            Edit
                          </button>
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Modal Edit Kriteria (Apple Sheet Style) */}
      {editingCriterion && (
        <Modal
          isOpen={!!editingCriterion}
          onClose={() => setEditingCriterion(null)}
          title={`Edit Parameter Kriteria: ${editingCriterion.code}`}
          description={`Sesuaikan bobot dan rentang penilaian untuk ${editingCriterion.name}`}
          maxWidth="md"
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => setEditingCriterion(null)}
                className="min-h-[44px] rounded-xl"
              >
                Batal
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={() =>
                  updateCriterionMutation.mutate({
                    id: editingCriterion.id_performance_criteria,
                    weight: editWeight,
                    c_min: editCMin,
                    c_max: editCMax,
                  })
                }
                isLoading={updateCriterionMutation.isPending}
                className="min-h-[44px] rounded-xl bg-orange-600 hover:bg-orange-700 font-bold"
              >
                Simpan Perubahan
              </Button>
            </div>
          }
        >
          <div className="space-y-4 text-xs">
            <div>
              <label
                htmlFor="editWeight"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Bobot Nilai (W) <span className="text-rose-500">*</span>
              </label>
              <input
                id="editWeight"
                type="number"
                min="1"
                max="100"
                value={editWeight}
                onChange={(e) => setEditWeight(Number(e.target.value))}
                className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label
                  htmlFor="editCMin"
                  className="block text-xs font-semibold text-slate-700 mb-1.5"
                >
                  C_min (Batas Bawah)
                </label>
                <input
                  id="editCMin"
                  type="number"
                  value={editCMin}
                  onChange={(e) => setEditCMin(Number(e.target.value))}
                  className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
                />
              </div>
              <div>
                <label
                  htmlFor="editCMax"
                  className="block text-xs font-semibold text-slate-700 mb-1.5"
                >
                  C_max (Batas Atas)
                </label>
                <input
                  id="editCMax"
                  type="number"
                  value={editCMax}
                  onChange={(e) => setEditCMax(Number(e.target.value))}
                  className="w-full rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 min-h-[46px]"
                />
              </div>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}
