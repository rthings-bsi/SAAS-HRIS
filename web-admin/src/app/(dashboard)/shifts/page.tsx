"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, CalendarClock, Trash2, RotateCcw } from "lucide-react";
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
  const [formError, setFormError] = useState<string | null>(null);

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
        queryClient.invalidateQueries({ queryKey: ["shifts"] });
      } else {
        setFormError(data.message || "Gagal menyimpan shift baru.");
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
      queryClient.invalidateQueries({ queryKey: ["shifts"] });
    },
    onError: (err: Error) => {
      alert(err.message || "Gagal menghapus shift.");
    },
  });

  const handleOpenModal = () => {
    setName("");
    setStartTime("08:00");
    setEndTime("17:00");
    setLateTolerance("15");
    setFormError(null);
    setIsModalOpen(true);
  };

  const handleCreateShift = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    createMutation.mutate({
      name,
      start_time: startTime.length === 5 ? `${startTime}:00` : startTime,
      end_time: endTime.length === 5 ? `${endTime}:00` : endTime,
      late_tolerance_minutes: parseInt(lateTolerance, 10),
    });
  };

  const handleDeleteShift = (id: number) => {
    if (!window.confirm("Yakin ingin menghapus jadwal shift ini?")) return;
    deleteMutation.mutate(id);
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Master Shift Kerja
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Konfigurasi jam masuk, jam pulang, dan toleransi keterlambatan presensi.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="secondary"
            size="sm"
            onClick={() => refetch()}
            leftIcon={<RotateCcw className="w-4 h-4 text-slate-500" />}
          >
            Segarkan
          </Button>
          <Button
            variant="primary"
            size="sm"
            onClick={handleOpenModal}
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
              onAction={handleOpenModal}
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
                      <button
                        type="button"
                        onClick={() => handleDeleteShift(item.id_shifts)}
                        aria-label={`Hapus shift ${item.name}`}
                        className="p-1.5 rounded-xl text-rose-500 hover:text-rose-700 hover:bg-rose-50 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-500 cursor-pointer"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Modal Buat Shift */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Buat Shift Kerja Baru"
      >
        <form onSubmit={handleCreateShift} className="space-y-4">
          {formError && (
            <div
              className="rounded-xl border border-rose-200 bg-rose-50 p-3.5 text-xs text-rose-700 font-medium"
            >
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
              isLoading={createMutation.isPending}
            >
              Simpan Shift
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
