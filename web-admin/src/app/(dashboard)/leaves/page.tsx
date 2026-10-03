"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Check, X, Plus, FileText, ExternalLink, RotateCcw } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle } from "@/components/ui/Card";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import apiClient from "@/lib/axios";
import type { ApiResponse, LeaveRequest, LeaveType } from "@/types";

export default function LeavesPage() {
  const queryClient = useQueryClient();
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

  // Queries
  const {
    data: leaveRequests = [],
    isLoading: isRequestsLoading,
    isError: isRequestsError,
    error: requestsError,
    refetch: refetchRequests,
  } = useQuery({
    queryKey: ["leave-approvals", statusFilter],
    queryFn: async () => {
      const params: Record<string, string> = {};
      if (statusFilter !== "all") {
        params.status = statusFilter;
      }
      const response = await apiClient.get<
        ApiResponse<LeaveRequest[] | { data: LeaveRequest[] }>
      >("/leave/approvals", {
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
    enabled: activeTab === "approvals",
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
    enabled: activeTab === "types",
  });

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
    },
    onError: (err: { response?: { data?: { message?: string } }; message?: string }) => {
      const msg = err.response?.data?.message || err.message || "Gagal membuat jenis cuti.";
      setCreateTypeError(msg);
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
      notes: rejectionNotes.trim() ? rejectionNotes.trim() : undefined,
    });
  };

  const handleCreateTypeSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTypeName.trim()) {
      setCreateTypeError("Nama jenis cuti wajib diisi.");
      return;
    }
    const quota = parseInt(newTypeQuota, 10);
    if (isNaN(quota) || quota < 0) {
      setCreateTypeError("Kuota hari harus berupa angka positif.");
      return;
    }
    createTypeMutation.mutate({
      name: newTypeName.trim(),
      quota_days: quota,
      is_paid: newTypeIsPaid,
    });
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Manajemen Cuti & Izin
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Persetujuan permohonan izin karyawan dan konfigurasi master kuota cuti tahunan.
          </p>
        </div>
        {activeTab === "types" && (
          <Button
            variant="primary"
            size="md"
            onClick={() => {
              setCreateTypeError(null);
              setIsCreateTypeOpen(true);
            }}
            leftIcon={<Plus className="w-4 h-4" aria-hidden="true" />}
          >
            Tambah Jenis Cuti
          </Button>
        )}
      </div>

      {/* Segmented Control */}
      <div className="flex items-center">
        <div className="inline-flex p-1 bg-slate-200/60 backdrop-blur-md rounded-xl border border-slate-200/80 shadow-2xs">
          <button
            type="button"
            onClick={() => setActiveTab("approvals")}
            className={`px-4 py-1.5 rounded-lg text-xs font-semibold transition-all ${
              activeTab === "approvals"
                ? "bg-white text-slate-900 shadow-xs border border-slate-200/80"
                : "text-slate-600 hover:text-slate-900"
            }`}
          >
            Persetujuan Permohonan
          </button>
          <button
            type="button"
            onClick={() => setActiveTab("types")}
            className={`px-4 py-1.5 rounded-lg text-xs font-semibold transition-all ${
              activeTab === "types"
                ? "bg-white text-slate-900 shadow-xs border border-slate-200/80"
                : "text-slate-600 hover:text-slate-900"
            }`}
          >
            Master Tipe Cuti
          </button>
        </div>
      </div>

      {/* Tab Content 1: Approvals */}
      {activeTab === "approvals" && (
        <Card>
          <CardHeader className="p-5 border-b border-slate-100/80 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
              <CardTitle>Daftar Permohonan Izin</CardTitle>
              <p className="text-xs text-slate-500 mt-1">
                Tinjau tanggal, durasi, dan lampiran sebelum memberikan keputusan.
              </p>
            </div>

            <div className="flex items-center gap-2">
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="rounded-xl border border-slate-200/80 bg-white/95 px-3 py-1.5 text-xs text-slate-800 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
                aria-label="Filter status permohonan"
              >
                <option value="all">Semua Status</option>
                <option value="pending">Menunggu Keputusan</option>
                <option value="approved">Disetujui</option>
                <option value="rejected">Ditolak</option>
              </select>

              <Button
                variant="secondary"
                size="sm"
                onClick={() => refetchRequests()}
                leftIcon={<RotateCcw className="w-4 h-4 text-slate-500" />}
              >
                Segarkan
              </Button>
            </div>
          </CardHeader>

          {isRequestsLoading ? (
            <TableSkeleton rows={4} columns={7} />
          ) : isRequestsError ? (
            <div className="p-6">
              <ErrorState
                title="Gagal Memuat Permohonan"
                message={
                  requestsError instanceof Error
                    ? requestsError.message
                    : "Terjadi kesalahan saat memuat daftar permohonan cuti."
                }
                onRetry={() => refetchRequests()}
              />
            </div>
          ) : leaveRequests.length === 0 ? (
            <div className="p-6">
              <EmptyState
                title="Belum ada permohonan cuti"
                description={
                  statusFilter === "pending"
                    ? "Tidak ada permohonan cuti yang sedang menunggu persetujuan."
                    : "Belum ada riwayat permohonan cuti staf pada kriteria ini."
                }
              />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="bg-slate-50/80 backdrop-blur-xs border-b border-slate-200/70 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                    <th scope="col" className="px-5 py-3">Nama Pegawai</th>
                    <th scope="col" className="px-4 py-3">Jenis Izin</th>
                    <th scope="col" className="px-4 py-3">Rentang Tanggal</th>
                    <th scope="col" className="px-4 py-3 text-center">Durasi</th>
                    <th scope="col" className="px-4 py-3">Alasan & Lampiran</th>
                    <th scope="col" className="px-4 py-3 text-center">Status</th>
                    <th scope="col" className="px-5 py-3 text-right">Tindakan</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {leaveRequests.map((item) => (
                    <tr
                      key={item.id_leave_requests}
                      className="hover:bg-slate-50/60 transition-colors"
                    >
                      <td className="px-5 py-3.5">
                        <div className="font-medium text-slate-900">
                          {item.employee?.user?.name || `Karyawan #${item.id_employees}`}
                        </div>
                        <div className="text-xs text-slate-500 font-mono">
                          {item.employee?.nik || ""}
                        </div>
                      </td>
                      <td className="px-4 py-3.5 text-xs text-slate-900 font-medium">
                        {item.leave_type?.name || "Cuti / Izin"}
                      </td>
                      <td className="px-4 py-3.5 text-xs text-slate-500 font-mono">
                        {item.start_date === item.end_date
                          ? item.start_date
                          : `${item.start_date} s/d ${item.end_date}`}
                      </td>
                      <td className="px-4 py-3.5 text-xs font-mono tabular-nums text-center text-slate-600">
                        {item.total_days} hari
                      </td>
                      <td className="px-4 py-3.5 text-xs text-slate-500 max-w-xs">
                        <div className="truncate">{item.reason}</div>
                        {item.attachment_url && (
                          <a
                            href={item.attachment_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1 text-action-accent hover:underline text-xs mt-0.5"
                          >
                            <FileText className="w-3 h-3" />
                            <span>Lihat Lampiran</span>
                            <ExternalLink className="w-2.5 h-2.5" />
                          </a>
                        )}
                        {item.rejected_reason && (
                          <div className="text-xs text-rose-600 mt-0.5 italic">
                            Catatan: {item.rejected_reason}
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
                      <td className="px-5 py-3.5 text-right">
                        {item.status === "pending" ? (
                          <div className="inline-flex items-center gap-1.5">
                            <Button
                              variant="primary"
                              size="sm"
                              onClick={() => openActionModal(item, "approved")}
                              leftIcon={<Check className="w-3.5 h-3.5" />}
                            >
                              Setujui
                            </Button>
                            <Button
                              variant="danger"
                              size="sm"
                              onClick={() => openActionModal(item, "rejected")}
                              leftIcon={<X className="w-3.5 h-3.5" />}
                            >
                              Tolak
                            </Button>
                          </div>
                        ) : (
                          <span className="text-xs text-slate-500 italic">Selesai diproses</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      )}

      {/* Tab Content 2: Master Leave Types */}
      {activeTab === "types" && (
        <Card>
          <CardHeader className="p-5 border-b border-slate-100/80 flex flex-row items-center justify-between">
            <div>
              <CardTitle>Master Tipe Cuti Perusahaan</CardTitle>
              <p className="text-xs text-slate-500 mt-1">
                Aturan jenis cuti, alokasi kuota tahunan, dan status upah berbayar.
              </p>
            </div>
            <Button
              variant="secondary"
              size="sm"
              onClick={() => refetchTypes()}
              leftIcon={<RotateCcw className="w-4 h-4 text-slate-500" />}
            >
              Segarkan
            </Button>
          </CardHeader>

          {isTypesLoading ? (
            <TableSkeleton rows={3} columns={5} />
          ) : isTypesError ? (
            <div className="p-6">
              <ErrorState
                title="Gagal Memuat Tipe Cuti"
                message={
                  typesError instanceof Error
                    ? typesError.message
                    : "Terjadi kesalahan saat memuat tipe cuti."
                }
                onRetry={() => refetchTypes()}
              />
            </div>
          ) : leaveTypes.length === 0 ? (
            <div className="p-6">
              <EmptyState
                title="Belum ada tipe cuti"
                description="Perusahaan Anda belum mengonfigurasi tipe cuti. Tambahkan tipe cuti seperti Cuti Tahunan atau Izin Sakit."
                actionLabel="Tambah Tipe Cuti"
                onAction={() => {
                  setCreateTypeError(null);
                  setIsCreateTypeOpen(true);
                }}
              />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="bg-slate-50/80 backdrop-blur-xs border-b border-slate-200/70 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                    <th scope="col" className="px-5 py-3">Nama Jenis Cuti</th>
                    <th scope="col" className="px-4 py-3 text-center">Alokasi Kuota</th>
                    <th scope="col" className="px-4 py-3 text-center">Status Upah</th>
                    <th scope="col" className="px-5 py-3 text-right">ID Referensi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {leaveTypes.map((type) => (
                    <tr
                      key={type.id_leave_types}
                      className="hover:bg-slate-50/60 transition-colors"
                    >
                      <td className="px-5 py-3.5 font-medium text-slate-900">
                        {type.name}
                      </td>
                      <td className="px-4 py-3.5 text-xs font-mono tabular-nums text-center text-slate-900 font-semibold">
                        {type.quota_days} hari/tahun
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <span
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold tracking-tight shadow-2xs ${
                            type.is_paid
                              ? "bg-emerald-50 text-emerald-700 border border-emerald-200/80"
                              : "bg-slate-100 text-slate-600 border border-slate-200/80"
                          }`}
                        >
                          {type.is_paid ? "Berbayar (Paid)" : "Tidak Berbayar (Unpaid)"}
                        </span>
                      </td>
                      <td className="px-5 py-3.5 text-right font-mono text-xs text-slate-500">
                        #{type.id_leave_types}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      )}

      {/* Approval / Rejection Confirmation Modal */}
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
              >
                Batal
              </Button>
              <Button
                variant={actionType === "approved" ? "primary" : "danger"}
                size="md"
                onClick={handleConfirmAction}
                isLoading={actionMutation.isPending}
              >
                {actionType === "approved" ? "Setujui Permohonan" : "Tolak Permohonan"}
              </Button>
            </div>
          }
        >
          <div className="space-y-4">
            {actionError && (
              <div
                className="p-3 text-xs rounded-md bg-danger-bg border border-danger-border text-danger-text"
                role="alert"
              >
                {actionError}
              </div>
            )}

            <div className="bg-slate-50/80 border border-slate-200/80 rounded-xl p-3.5 space-y-2 text-xs">
              <div className="flex justify-between">
                <span className="text-slate-500">Rentang Tanggal:</span>
                <span className="font-mono text-slate-900 font-medium">
                  {actionTarget.start_date} s/d {actionTarget.end_date}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Durasi Hari Kerja:</span>
                <span className="font-mono text-slate-900 font-semibold">
                  {actionTarget.total_days} hari
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Alasan:</span>
                <span className="text-slate-900 text-right max-w-xs">{actionTarget.reason}</span>
              </div>
            </div>

            {actionType === "rejected" && (
              <div>
                <label
                  htmlFor="rejectionNotes"
                  className="block text-xs font-semibold text-ink-primary mb-1"
                >
                  Alasan Penolakan <span className="text-danger-text">*</span>
                </label>
                <textarea
                  id="rejectionNotes"
                  rows={3}
                  value={rejectionNotes}
                  onChange={(e) => setRejectionNotes(e.target.value)}
                  placeholder="Tuliskan alasan penolakan permohonan ini secara jelas..."
                  className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-xs text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
                  required
                />
              </div>
            )}
          </div>
        </Modal>
      )}

      {/* Create Leave Type Modal */}
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
          description="Konfigurasikan jenis hak cuti baru untuk seluruh staf perusahaan."
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
              >
                Batal
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={handleCreateTypeSubmit}
                isLoading={createTypeMutation.isPending}
              >
                Simpan Jenis Cuti
              </Button>
            </div>
          }
        >
          <form onSubmit={handleCreateTypeSubmit} className="space-y-4">
            {createTypeError && (
              <div
                className="p-3 text-xs rounded-md bg-danger-bg border border-danger-border text-danger-text"
                role="alert"
              >
                {createTypeError}
              </div>
            )}

            <div>
              <label
                htmlFor="newTypeName"
                className="block text-xs font-semibold text-ink-primary mb-1"
              >
                Nama Jenis Cuti <span className="text-danger-text">*</span>
              </label>
              <input
                id="newTypeName"
                type="text"
                value={newTypeName}
                onChange={(e) => setNewTypeName(e.target.value)}
                placeholder="Contoh: Cuti Tahunan, Izin Melahirkan"
                className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-xs text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
                required
              />
            </div>

            <div>
              <label
                htmlFor="newTypeQuota"
                className="block text-xs font-semibold text-ink-primary mb-1"
              >
                Kuota Hari per Tahun <span className="text-danger-text">*</span>
              </label>
              <input
                id="newTypeQuota"
                type="number"
                min="0"
                max="365"
                value={newTypeQuota}
                onChange={(e) => setNewTypeQuota(e.target.value)}
                className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-xs font-mono text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
                required
              />
            </div>

            <div className="flex items-center gap-2 pt-1">
              <input
                id="newTypeIsPaid"
                type="checkbox"
                checked={newTypeIsPaid}
                onChange={(e) => setNewTypeIsPaid(e.target.checked)}
                className="h-4 w-4 rounded border-border-neutral text-action-accent focus:ring-action-accent"
              />
              <label htmlFor="newTypeIsPaid" className="text-xs text-ink-primary select-none">
                Cuti Berbayar (tidak memotong gaji pokok karyawan)
              </label>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
