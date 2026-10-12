"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, CalendarClock, Trash2, Edit2, AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle } from "@/components/ui/Card";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import apiClient from "@/lib/axios";
import type { ApiResponse, Shift } from "@/types";

export default function ShiftsPage() {
  const queryClient = useQueryClient();

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingShift, setEditingShift] = useState<Shift | null>(null);
  const [formError, setFormError] = useState<string | null>(null);

  // Delete Confirmation State
  const [deletingShift, setDeletingShift] = useState<Shift | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  // Form Fields
  const [name, setName] = useState("");
  const [startTime, setStartTime] = useState("08:00");
  const [endTime, setEndTime] = useState("17:00");
  const [lateTolerance, setLateTolerance] = useState("15");

  // Query Shifts
  const {
    data: shifts = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["shifts"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<Shift[]>>("/shifts");
      if (response.data.success && Array.isArray(response.data.data)) {
        return response.data.data;
      }
      return [];
    },
  });

  // Create Mutation
  const createMutation = useMutation({
    mutationFn: async (payload: {
      name: string;
      start_time: string;
      end_time: string;
      late_tolerance_minutes: number;
    }) => {
      const response = await apiClient.post<ApiResponse<Shift>>("/shifts", payload);
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setIsModalOpen(false);
        setEditingShift(null);
        queryClient.invalidateQueries({ queryKey: ["shifts"] });
      } else {
        setFormError(data.message || "Gagal menyimpan shift baru.");
      }
    },
    onError: (err: Error) => {
      setFormError(err.message || "Terjadi kendala pada server.");
    },
  });

  // Update Mutation
  const updateMutation = useMutation({
    mutationFn: async ({
      id,
      payload,
    }: {
      id: number;
      payload: {
        name: string;
        start_time: string;
        end_time: string;
        late_tolerance_minutes: number;
      };
    }) => {
      const response = await apiClient.put<ApiResponse<Shift>>(`/shifts/${id}`, payload);
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setIsModalOpen(false);
        setEditingShift(null);
        queryClient.invalidateQueries({ queryKey: ["shifts"] });
      } else {
        setFormError(data.message || "Gagal memperbarui shift.");
      }
    },
    onError: (err: Error) => {
      setFormError(err.message || "Terjadi kendala pada server.");
    },
  });

  // Delete Mutation
  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      await apiClient.delete(`/shifts/${id}`);
    },
    onSuccess: () => {
      setDeletingShift(null);
      setDeleteError(null);
      queryClient.invalidateQueries({ queryKey: ["shifts"] });
    },
    onError: (err: Error) => {
      setDeleteError(err.message || "Gagal menghapus shift.");
    },
  });

  const handleOpenCreateModal = () => {
    setEditingShift(null);
    setName("");
    setStartTime("08:00");
    setEndTime("17:00");
    setLateTolerance("15");
    setFormError(null);
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (shift: Shift) => {
    setEditingShift(shift);
    setName(shift.name);
    setStartTime(shift.start_time.slice(0, 5));
    setEndTime(shift.end_time.slice(0, 5));
    setLateTolerance(String(shift.late_tolerance_minutes));
    setFormError(null);
    setIsModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    const payload = {
      name: name.trim(),
      start_time: startTime.length === 5 ? `${startTime}:00` : startTime,
      end_time: endTime.length === 5 ? `${endTime}:00` : endTime,
      late_tolerance_minutes: parseInt(lateTolerance, 10),
    };

    if (editingShift) {
      updateMutation.mutate({ id: editingShift.id_shifts, payload });
    } else {
      createMutation.mutate(payload);
    }
  };

  const confirmDelete = () => {
    if (deletingShift) {
      deleteMutation.mutate(deletingShift.id_shifts);
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Master Shift Kerja
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Konfigurasi jam masuk, jam pulang, dan toleransi keterlambatan presensi internal.
          </p>
        </div>

        <div className="hidden sm:flex items-center gap-2">
          <Button
            variant="primary"
            size="sm"
            onClick={handleOpenCreateModal}
            leftIcon={<Plus className="w-4 h-4" aria-hidden="true" />}
          >
            Buat Shift Baru
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader className="p-5 border-b border-slate-100/80">
          <CardTitle>Jadwal Kerja Aktif</CardTitle>
          <p className="text-xs text-slate-500 mt-1">
            Ketentuan batas jam kerja harian yang diterapkan pada penugasan staf.
          </p>
        </CardHeader>

        {isLoading ? (
          <TableSkeleton rows={4} columns={5} />
        ) : isError ? (
          <div className="p-6">
            <ErrorState
              title="Gagal Memuat Shift"
              message={error instanceof Error ? error.message : "Terjadi kendala."}
              onRetry={() => refetch()}
            />
          </div>
        ) : shifts.length === 0 ? (
          <div className="p-6">
            <EmptyState
              title="Belum ada shift kerja"
              description="Buat shift reguler atau operasional untuk jadwal harian staf."
              actionLabel="Tambah Shift Baru"
              onAction={handleOpenCreateModal}
            />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="bg-slate-50/80 backdrop-blur-xs border-b border-slate-200/70 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  <th scope="col" className="px-5 py-3">Nama Shift</th>
                  <th scope="col" className="px-4 py-3 font-mono">Jam Mulai</th>
                  <th scope="col" className="px-4 py-3 font-mono">Jam Selesai</th>
                  <th scope="col" className="px-4 py-3 font-mono text-center">Toleransi Terlambat</th>
                  <th scope="col" className="px-5 py-3 text-right">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {shifts.map((item) => (
                  <tr key={item.id_shifts} className="hover:bg-slate-50/60 transition-colors">
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-2.5 font-medium text-slate-900">
                        <div className="w-8 h-8 rounded-xl bg-orange-50/90 border border-orange-200/80 text-orange-600 flex items-center justify-center flex-shrink-0 shadow-2xs">
                          <CalendarClock className="w-4 h-4" />
                        </div>
                        <span className="font-semibold text-slate-900">{item.name}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3.5 text-xs">
                      <span className="inline-flex items-center px-2 py-0.5 rounded-md bg-slate-100/80 text-slate-700 font-mono font-medium">
                        {item.start_time.slice(0, 5)} WIB
                      </span>
                    </td>
                    <td className="px-4 py-3.5 text-xs">
                      <span className="inline-flex items-center px-2 py-0.5 rounded-md bg-slate-100/80 text-slate-700 font-mono font-medium">
                        {item.end_time.slice(0, 5)} WIB
                      </span>
                    </td>
                    <td className="px-4 py-3.5 text-xs text-center">
                      <span className="inline-flex items-center px-2 py-0.5 rounded-full bg-amber-50 text-amber-700 border border-amber-200/60 text-[11px] font-semibold">
                        {item.late_tolerance_minutes} menit
                      </span>
                    </td>
                    <td className="px-5 py-3.5 text-right">
                      <div className="inline-flex items-center gap-1.5 justify-end">
                        <button
                          type="button"
                          onClick={() => handleOpenEditModal(item)}
                          aria-label={`Ubah shift ${item.name}`}
                          className="p-1.5 rounded-xl text-slate-500 hover:text-orange-600 hover:bg-orange-50 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-500 cursor-pointer"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button
                          type="button"
                          onClick={() => setDeletingShift(item)}
                          aria-label={`Hapus shift ${item.name}`}
                          className="p-1.5 rounded-xl text-rose-500 hover:text-rose-700 hover:bg-rose-50 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-500 cursor-pointer"
                        >
                          <Trash2 className="w-4 h-4" />
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

      {/* Modal Buat / Edit Shift */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingShift ? "Ubah Jadwal Shift Kerja" : "Buat Shift Kerja Baru"}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          {formError && (
            <div className="rounded-xl border border-rose-200 bg-rose-50 p-3.5 text-xs text-rose-700 font-medium">
              {formError}
            </div>
          )}

          <div>
            <label htmlFor="shiftName" className="block text-xs font-semibold text-slate-700 mb-1.5">
              Nama Shift
            </label>
            <input
              id="shiftName"
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Contoh: Shift Reguler Kantor"
              className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200/80 bg-white/95 shadow-2xs transition-all outline-none placeholder:text-slate-400 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label htmlFor="startTime" className="block text-xs font-semibold text-slate-700 mb-1.5">
                Jam Masuk (WIB)
              </label>
              <input
                id="startTime"
                type="time"
                required
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
                className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200/80 bg-white/95 shadow-2xs font-mono transition-all outline-none focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
              />
            </div>
            <div>
              <label htmlFor="endTime" className="block text-xs font-semibold text-slate-700 mb-1.5">
                Jam Pulang (WIB)
              </label>
              <input
                id="endTime"
                type="time"
                required
                value={endTime}
                onChange={(e) => setEndTime(e.target.value)}
                className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200/80 bg-white/95 shadow-2xs font-mono transition-all outline-none focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
              />
            </div>
          </div>
          <div>
            <label htmlFor="lateTolerance" className="block text-xs font-semibold text-slate-700 mb-1.5">
              Toleransi Keterlambatan (menit)
            </label>
            <input
              id="lateTolerance"
              type="number"
              min={0}
              max={120}
              required
              value={lateTolerance}
              onChange={(e) => setLateTolerance(e.target.value)}
              className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200/80 bg-white/95 shadow-2xs font-mono transition-all outline-none focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
            />
            <p className="mt-1 text-[11px] text-slate-500">
              Clock-in melebihi jam masuk + toleransi ini akan tercatat status Terlambat.
            </p>
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              onClick={() => setIsModalOpen(false)}
            >
              Batal
            </Button>
            <Button
              type="submit"
              variant="primary"
              size="sm"
              isLoading={createMutation.isPending || updateMutation.isPending}
            >
              {editingShift ? "Simpan Perubahan" : "Simpan Shift"}
            </Button>
          </div>
        </form>
      </Modal>

      {/* Confirmation Modal for Delete */}
      <Modal
        isOpen={!!deletingShift}
        onClose={() => {
          setDeletingShift(null);
          setDeleteError(null);
        }}
        title="Konfirmasi Hapus Shift"
        maxWidth="md"
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              onClick={() => {
                setDeletingShift(null);
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
              Hapus Shift
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
              Apakah Anda yakin ingin menghapus shift{" "}
              <strong className="text-slate-900">{deletingShift?.name}</strong>?
            </p>
            <p className="text-xs text-slate-500 mt-1">
              Tindakan ini tidak dapat dibatalkan. Shift yang masih terhubung dengan jadwal kerja aktif tidak dapat dihapus.
            </p>
          </div>
        </div>
      </Modal>

      {/* Floating Action Button (FAB) + Mobile */}
      <button
        type="button"
        onClick={handleOpenCreateModal}
        aria-label="Buat Shift Baru"
        className="sm:hidden fixed bottom-20 right-4 z-40 w-14 h-14 rounded-full bg-orange-600 hover:bg-orange-700 active:scale-90 text-white shadow-[0_8px_24px_rgba(234,88,12,0.45)] flex items-center justify-center transition-transform cursor-pointer focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-orange-500/30"
      >
        <Plus className="w-7 h-7 stroke-[2.5]" aria-hidden="true" />
      </button>
    </div>
  );
}
