"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, FileText, Calculator, Lock, RotateCcw, Eye } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle } from "@/components/ui/Card";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { formatRupiah } from "@/lib/utils";
import apiClient from "@/lib/axios";
import type { ApiResponse, PayrollPeriod, PayrollSlip } from "@/types";

interface PayrollPeriodDetail extends PayrollPeriod {
  payroll_slips?: PayrollSlip[];
  total_employees?: number;
  total_amount?: number;
}

export default function PayrollPage() {
  const queryClient = useQueryClient();

  // Create Period Modal
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [periodName, setPeriodName] = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [paymentDate, setPaymentDate] = useState("");
  const [createError, setCreateError] = useState<string | null>(null);

  // Slips Detail Modal
  const [selectedPeriod, setSelectedPeriod] = useState<PayrollPeriod | null>(null);

  // Queries
  const {
    data: periods = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["payroll-periods"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<PayrollPeriodDetail[]>>("/payroll/periods");
      if (response.data.success && Array.isArray(response.data.data)) {
        return response.data.data;
      }
      return [];
    },
  });

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
    enabled: !!selectedPeriod,
  });

  // Mutations
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
      const response = await apiClient.post<ApiResponse<Record<string, unknown>>>(`/payroll/periods/${id}/calculate`);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["payroll-periods"] });
      if (selectedPeriod) {
        queryClient.invalidateQueries({ queryKey: ["payroll-slips", selectedPeriod.id_payroll_periods] });
      }
    },
    onError: (err: { response?: { data?: { message?: string } }; message?: string }) => {
      alert(err.response?.data?.message || "Gagal menjalankan kalkulasi gaji.");
    },
  });

  const finalizeMutation = useMutation({
    mutationFn: async (id: number) => {
      const response = await apiClient.post<ApiResponse<Record<string, unknown>>>(`/payroll/periods/${id}/finalize`);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["payroll-periods"] });
      if (selectedPeriod) {
        setSelectedPeriod(null);
      }
    },
    onError: (err: { response?: { data?: { message?: string } }; message?: string }) => {
      alert(err.response?.data?.message || "Gagal memfinalisasi periode gaji.");
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

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Penggajian (Payroll)
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Kelola periode cut-off gaji, kalkulasi kehadiran otomatis, dan penerbitan slip digital.
          </p>
        </div>

        <Button
          variant="primary"
          size="md"
          onClick={() => {
            setCreateError(null);
            setIsCreateOpen(true);
          }}
          leftIcon={<Plus className="w-4 h-4" aria-hidden="true" />}
        >
          Buka Periode Baru
        </Button>
      </div>

      <Card>
        <CardHeader className="p-5 border-b border-slate-100/80 flex flex-row items-center justify-between">
          <div>
            <CardTitle>Riwayat Periode Penggajian</CardTitle>
            <p className="text-xs text-slate-500 mt-1">
              Status pemrosesan upah bulanan staf dan laporan slip gaji digital.
            </p>
          </div>
          <Button
            variant="secondary"
            size="sm"
            onClick={() => refetch()}
            leftIcon={<RotateCcw className="w-4 h-4 text-slate-500" />}
          >
            Segarkan
          </Button>
        </CardHeader>

        {isLoading ? (
          <TableSkeleton rows={3} columns={7} />
        ) : isError ? (
          <div className="p-6">
            <ErrorState
              title="Gagal Memuat Periode Penggajian"
              message={
                error instanceof Error
                  ? error.message
                  : "Terjadi kesalahan saat memuat data periode penggajian."
              }
              onRetry={() => refetch()}
            />
          </div>
        ) : periods.length === 0 ? (
          <div className="p-6">
            <EmptyState
              title="Belum ada periode penggajian"
              description="Buka periode penggajian baru untuk memulai perhitungan upah staf berdasarkan log kehadiran."
              actionLabel="Buka Periode Baru"
              onAction={() => {
                setCreateError(null);
                setIsCreateOpen(true);
              }}
            />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="bg-slate-50/80 backdrop-blur-xs border-b border-slate-200/70 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  <th scope="col" className="px-5 py-3">Nama Periode</th>
                  <th scope="col" className="px-4 py-3">Rentang Cut-Off</th>
                  <th scope="col" className="px-4 py-3">Tanggal Bayar</th>
                  <th scope="col" className="px-4 py-3 text-center">Status</th>
                  <th scope="col" className="px-5 py-3 text-right">Tindakan</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {periods.map((item) => (
                  <tr key={item.id_payroll_periods} className="hover:bg-slate-50/60 transition-colors">
                    <td className="px-5 py-3.5 font-medium text-slate-900">
                      {item.name}
                    </td>
                    <td className="px-4 py-3.5 text-xs text-slate-500 font-mono">
                      {item.start_date} s/d {item.end_date}
                    </td>
                    <td className="px-4 py-3.5 text-xs text-slate-500 font-mono">
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
                    <td className="px-5 py-3.5 text-right">
                      <div className="inline-flex items-center gap-1.5">
                        {item.status === "draft" && (
                          <Button
                            variant="primary"
                            size="sm"
                            onClick={() => calculateMutation.mutate(item.id_payroll_periods)}
                            isLoading={calculateMutation.isPending}
                            leftIcon={<Calculator className="w-3.5 h-3.5" />}
                          >
                            Kalkulasi Gaji
                          </Button>
                        )}

                        {item.status === "calculated" && (
                          <>
                            <Button
                              variant="secondary"
                              size="sm"
                              onClick={() => setSelectedPeriod(item)}
                              leftIcon={<Eye className="w-3.5 h-3.5" />}
                            >
                              Rincian Slip
                            </Button>
                            <Button
                              variant="primary"
                              size="sm"
                              onClick={() => finalizeMutation.mutate(item.id_payroll_periods)}
                              isLoading={finalizeMutation.isPending}
                              leftIcon={<Lock className="w-3.5 h-3.5" />}
                            >
                              Finalisasi
                            </Button>
                          </>
                        )}

                        {item.status === "finalized" && (
                          <Button
                            variant="secondary"
                            size="sm"
                            onClick={() => setSelectedPeriod(item)}
                            leftIcon={<FileText className="w-3.5 h-3.5" />}
                          >
                            Lihat Slip Gaji
                          </Button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Create Period Modal */}
      {isCreateOpen && (
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
              >
                Batal
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={handleCreateSubmit}
                isLoading={createMutation.isPending}
              >
                Buka Periode
              </Button>
            </div>
          }
        >
          <form onSubmit={handleCreateSubmit} className="space-y-4">
            {createError && (
              <div
                className="p-3 text-xs rounded-xl bg-rose-50 border border-rose-200 text-rose-700"
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
                className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-xs text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
                required
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
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
                  className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-xs font-mono text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
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
                  className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-xs font-mono text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
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
                className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-xs font-mono text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
                required
              />
            </div>
          </form>
        </Modal>
      )}

      {/* Slips Detail Modal */}
      {selectedPeriod && (
        <Modal
          isOpen={true}
          onClose={() => setSelectedPeriod(null)}
          title={`Rincian Slip Gaji: ${selectedPeriod.name}`}
          description={`Rentang cut-off: ${selectedPeriod.start_date} s/d ${selectedPeriod.end_date}.`}
          maxWidth="lg"
          footer={
            <div className="flex items-center justify-between w-full">
              <div className="text-xs text-slate-500">
                Total: <span className="font-mono font-semibold text-slate-900">{selectedSlips.length} slip</span>
              </div>
              <Button variant="secondary" size="md" onClick={() => setSelectedPeriod(null)}>
                Tutup
              </Button>
            </div>
          }
        >
          {isSlipsLoading ? (
            <TableSkeleton rows={4} columns={5} />
          ) : selectedSlips.length === 0 ? (
            <div className="py-8 text-center text-xs text-slate-500">
              Belum ada slip gaji yang dihasilkan untuk periode ini. Jalankan &quot;Kalkulasi Gaji&quot; terlebih dahulu.
            </div>
          ) : (
            <div className="overflow-x-auto max-h-96">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-slate-50/80 backdrop-blur-xs border-b border-slate-200/70 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                    <th className="px-3 py-2">Pegawai</th>
                    <th className="px-3 py-2 text-right">Gaji Pokok</th>
                    <th className="px-3 py-2 text-right">Tunjangan</th>
                    <th className="px-3 py-2 text-right">Potongan</th>
                    <th className="px-3 py-2 text-right">Gaji Bersih</th>
                    <th className="px-3 py-2 text-center">Slip PDF</th>
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
                      ? pdfPath.startsWith("http")
                        ? pdfPath
                        : `${process.env.NEXT_PUBLIC_STORAGE_URL || "http://localhost:8000/storage"}/${pdfPath}`
                      : null;

                    return (
                      <tr key={slip.id_payroll_slips} className="hover:bg-slate-50/60 transition-colors">
                        <td className="px-3 py-2.5 font-sans font-medium text-slate-900">
                          {employeeName}
                        </td>
                        <td className="px-3 py-2.5 text-right text-slate-900">
                          {formatRupiah(Number(slip.basic_salary))}
                        </td>
                        <td className="px-3 py-2.5 text-right text-emerald-700">
                          +{formatRupiah(Number(slip.allowance_fixed))}
                        </td>
                        <td className="px-3 py-2.5 text-right text-rose-600">
                          {"-"}{formatRupiah(totalDeductions)}
                        </td>
                        <td className="px-3 py-2.5 text-right font-bold text-slate-900">
                          {formatRupiah(Number(slip.net_salary))}
                        </td>
                        <td className="px-3 py-2.5 text-center">
                          {pdfHref ? (
                            <a
                              href={pdfHref}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="text-orange-600 hover:text-orange-700 active:scale-95 inline-flex items-center gap-1 font-sans font-medium transition-all"
                            >
                              <FileText className="w-3.5 h-3.5" />
                              <span>Unduh</span>
                            </a>
                          ) : (
                            <span className="text-slate-400 font-sans italic">Belum dibuat</span>
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
    </div>
  );
}
