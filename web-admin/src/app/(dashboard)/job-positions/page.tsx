"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Briefcase, Trash2, Edit2, AlertCircle, AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle } from "@/components/ui/Card";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { apiClient, ApiError } from "@/lib/axios";
import type { ApiResponse, JobPosition } from "@/types";

export default function JobPositionsPage() {
  const queryClient = useQueryClient();

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingPosition, setEditingPosition] = useState<JobPosition | null>(null);
  const [deletingPosition, setDeletingPosition] = useState<JobPosition | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string[]>>({});

  // Form Fields
  const [name, setName] = useState("");

  // Query Job Positions
  const {
    data: positions = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["job-positions"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<JobPosition[]>>("/job-positions");
      if (response.data.success && Array.isArray(response.data.data)) {
        return response.data.data;
      }
      return [];
    },
  });

  // Create Mutation
  const createMutation = useMutation({
    mutationFn: async (payload: { name: string }) => {
      const response = await apiClient.post<ApiResponse<JobPosition>>("/job-positions", payload);
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setIsModalOpen(false);
        setEditingPosition(null);
        setName("");
        setFieldErrors({});
        setFormError(null);
        queryClient.invalidateQueries({ queryKey: ["job-positions"] });
      } else {
        setFormError(data.message || "Gagal menyimpan jabatan baru.");
      }
    },
    onError: (err: unknown) => {
      if (err instanceof ApiError) {
        setFormError(err.message || "Validasi gagal.");
        if (err.errors) setFieldErrors(err.errors);
      } else if (err instanceof Error) {
        setFormError(err.message || "Terjadi kendala pada server.");
      } else {
        setFormError("Terjadi kendala saat menyimpan data.");
      }
    },
  });

  // Update Mutation
  const updateMutation = useMutation({
    mutationFn: async ({ id, payload }: { id: number; payload: { name: string } }) => {
      const response = await apiClient.put<ApiResponse<JobPosition>>(`/job-positions/${id}`, payload);
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setIsModalOpen(false);
        setEditingPosition(null);
        setName("");
        setFieldErrors({});
        setFormError(null);
        queryClient.invalidateQueries({ queryKey: ["job-positions"] });
      } else {
        setFormError(data.message || "Gagal memperbarui jabatan.");
      }
    },
    onError: (err: unknown) => {
      if (err instanceof ApiError) {
        setFormError(err.message || "Validasi gagal.");
        if (err.errors) setFieldErrors(err.errors);
      } else if (err instanceof Error) {
        setFormError(err.message || "Terjadi kendala pada server.");
      } else {
        setFormError("Terjadi kendala saat menyimpan data.");
      }
    },
  });

  // Delete Mutation
  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      await apiClient.delete(`/job-positions/${id}`);
    },
    onSuccess: () => {
      setDeletingPosition(null);
      setDeleteError(null);
      queryClient.invalidateQueries({ queryKey: ["job-positions"] });
    },
    onError: (err: Error) => {
      setDeleteError(err.message || "Gagal menghapus jabatan posisi.");
    },
  });

  const clearFieldError = (fieldName: string) => {
    if (fieldErrors[fieldName]) {
      setFieldErrors((prev) => {
        const next = { ...prev };
        delete next[fieldName];
        return next;
      });
    }
  };

  const handleOpenCreateModal = () => {
    setEditingPosition(null);
    setName("");
    setFormError(null);
    setFieldErrors({});
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (pos: JobPosition) => {
    setEditingPosition(pos);
    setName(pos.name);
    setFormError(null);
    setFieldErrors({});
    setIsModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    setFieldErrors({});

    const trimmedName = name.trim();
    if (!trimmedName) {
      setFieldErrors({ name: ["Nama posisi jabatan wajib diisi."] });
      setFormError("Silakan isi nama jabatan posisi.");
      return;
    }

    if (editingPosition) {
      updateMutation.mutate({
        id: editingPosition.id_job_positions,
        payload: { name: trimmedName },
      });
    } else {
      createMutation.mutate({ name: trimmedName });
    }
  };

  const confirmDelete = () => {
    if (deletingPosition) {
      deleteMutation.mutate(deletingPosition.id_job_positions);
    }
  };

  const isPending = createMutation.isPending || updateMutation.isPending;

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Jabatan & Posisi Karyawan
          </h1>
          <p className="text-sm text-slate-500 mt-0.5 font-normal">
            Kelola tingkatan peran, profesi, dan jabatan kerja dalam struktur perusahaan.
          </p>
        </div>

        <div className="hidden sm:flex items-center gap-2">
          <Button
            variant="primary"
            size="sm"
            onClick={handleOpenCreateModal}
            leftIcon={<Plus className="w-4 h-4" aria-hidden="true" />}
          >
            Tambah Jabatan
          </Button>
        </div>
      </div>

      {/* Main Table Card */}
      <Card>
        <CardHeader className="p-5 border-b border-slate-100/80">
          <CardTitle>Daftar Posisi Jabatan</CardTitle>
          <p className="text-xs text-slate-500 mt-1 font-normal">
            Jabatan menentukan hierarki peran staf dan acuan kompensasi penggajian.
          </p>
        </CardHeader>

        {isLoading ? (
          <TableSkeleton rows={4} columns={3} />
        ) : isError ? (
          <div className="p-6">
            <ErrorState
              title="Gagal Memuat Jabatan"
              message={error instanceof Error ? error.message : "Terjadi kendala pada server."}
              onRetry={() => refetch()}
            />
          </div>
        ) : positions.length === 0 ? (
          <div className="p-6">
            <EmptyState
              title="Belum ada data jabatan posisi"
              description="Daftarkan jabatan pertama staf Anda (contoh: Staff Gudang, Kasir, Manager Operasional, Software Engineer)."
              actionLabel="Tambah Jabatan"
              onAction={handleOpenCreateModal}
            />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="bg-slate-50/80 backdrop-blur-xs border-b border-slate-200/70 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  <th scope="col" className="px-5 py-3">Nama Jabatan Posisi</th>
                  <th scope="col" className="px-5 py-3">Kode Jabatan</th>
                  <th scope="col" className="px-5 py-3 text-right">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {positions.map((pos) => (
                  <tr key={pos.id_job_positions} className="hover:bg-slate-50/60 transition-colors">
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-2.5 font-medium text-slate-900">
                        <div className="w-8 h-8 rounded-xl bg-orange-50/90 border border-orange-200/80 text-orange-600 flex items-center justify-center flex-shrink-0 shadow-2xs">
                          <Briefcase className="w-4 h-4" aria-hidden="true" />
                        </div>
                        <span className="font-semibold text-slate-900">{pos.name}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5 text-xs font-mono tabular-nums text-slate-500">
                      POS-{String(pos.id_job_positions).padStart(3, "0")}
                    </td>
                    <td className="px-5 py-3.5 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          type="button"
                          onClick={() => handleOpenEditModal(pos)}
                          aria-label={`Ubah jabatan ${pos.name}`}
                          className="p-1.5 rounded-xl text-slate-500 hover:text-slate-800 hover:bg-slate-100 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 cursor-pointer"
                        >
                          <Edit2 className="w-4 h-4" aria-hidden="true" />
                        </button>
                        <button
                          type="button"
                          onClick={() => setDeletingPosition(pos)}
                          aria-label={`Hapus jabatan ${pos.name}`}
                          className="p-1.5 rounded-xl text-rose-500 hover:text-rose-700 hover:bg-rose-50 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-500 cursor-pointer"
                        >
                          <Trash2 className="w-4 h-4" aria-hidden="true" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Modal Tambah / Edit Jabatan Posisi */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingPosition ? "Ubah Jabatan Posisi" : "Tambah Jabatan Baru"}
        description={
          editingPosition
            ? "Perbarui nama jabatan yang dipilih."
            : "Lengkapi nama posisi atau peran staf baru."
        }
        maxWidth="md"
        footer={
          <div className="flex items-center justify-end gap-2.5 w-full">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              onClick={() => setIsModalOpen(false)}
            >
              Batal
            </Button>
            <Button
              form="job-position-form"
              type="submit"
              variant="primary"
              size="sm"
              isLoading={isPending}
            >
              {editingPosition ? "Simpan Perubahan" : "Simpan Jabatan"}
            </Button>
          </div>
        }
      >
        <form
          id="job-position-form"
          onSubmit={handleSubmit}
          noValidate
          className="space-y-4 text-sm"
        >
          {formError && (
            <div
              role="alert"
              className="rounded-xl border border-rose-200 bg-rose-50 p-3.5 text-xs text-rose-700"
            >
              <div className="flex items-start gap-2">
                <AlertCircle className="w-4 h-4 text-rose-600 flex-shrink-0 mt-0.5" aria-hidden="true" />
                <p className="font-semibold">{formError}</p>
              </div>
            </div>
          )}

          <div>
            <label
              htmlFor="pos-name"
              className="block text-xs font-semibold text-slate-700 mb-1.5"
            >
              Nama Jabatan Posisi <span className="text-rose-500">*</span>
            </label>
            <input
              id="pos-name"
              type="text"
              required
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                clearFieldError("name");
              }}
              placeholder="Contoh: Barista, Staff Gudang, HR Officer"
              aria-invalid={fieldErrors.name ? "true" : undefined}
              aria-describedby={fieldErrors.name ? "pos-name-error" : undefined}
              className={`w-full px-3.5 py-2 text-sm rounded-xl border shadow-2xs transition-all outline-none ${
                fieldErrors.name
                  ? "border-rose-400 bg-rose-50/30 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20"
                  : "border-slate-200/80 bg-white/95 placeholder:text-slate-400 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
              }`}
            />
            {fieldErrors.name && (
              <p id="pos-name-error" className="mt-1 text-xs text-rose-600 font-medium">
                {fieldErrors.name[0]}
              </p>
            )}
          </div>
        </form>
      </Modal>

      {/* Confirmation Modal for Delete */}
      <Modal
        isOpen={!!deletingPosition}
        onClose={() => {
          setDeletingPosition(null);
          setDeleteError(null);
        }}
        title="Konfirmasi Hapus Jabatan Posisi"
        maxWidth="md"
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              onClick={() => {
                setDeletingPosition(null);
                setDeleteError(null);
              }}
            >
              Batal
            </Button>
            <Button
              type="button"
              variant="danger"
              size="sm"
              isLoading={deleteMutation.isPending}
              onClick={confirmDelete}
            >
              Hapus Jabatan
            </Button>
          </div>
        }
      >
        {deleteError && (
          <div role="alert" className="mb-3 rounded-xl border border-rose-200 bg-rose-50 p-3 text-xs text-rose-700">
            {deleteError}
          </div>
        )}
        <div className="flex items-start gap-3 py-2">
          <div className="p-2 rounded-xl bg-rose-50 text-rose-600 flex-shrink-0">
            <AlertTriangle className="w-5 h-5" />
          </div>
          <div>
            <p className="text-sm text-slate-700">
              Apakah Anda yakin ingin menghapus jabatan posisi{" "}
              <strong className="text-slate-900">{deletingPosition?.name}</strong>?
            </p>
            <p className="text-xs text-slate-500 mt-1">
              Tindakan ini tidak dapat dibatalkan. Karyawan dengan posisi ini perlu diperbarui peran jabatannya.
            </p>
          </div>
        </div>
      </Modal>

      {/* Floating Action Button (FAB) + Mobile */}
      <button
        type="button"
        onClick={handleOpenCreateModal}
        aria-label="Tambah Jabatan Baru"
        className="sm:hidden fixed bottom-20 right-4 z-40 w-14 h-14 rounded-full bg-orange-600 hover:bg-orange-700 active:scale-90 text-white shadow-[0_8px_24px_rgba(234,88,12,0.45)] flex items-center justify-center transition-transform cursor-pointer focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-orange-500/30"
      >
        <Plus className="w-7 h-7 stroke-[2.5]" aria-hidden="true" />
      </button>
    </div>
  );
}
