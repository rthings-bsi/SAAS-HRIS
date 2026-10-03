"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, MapPin, Trash2, RotateCcw } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle } from "@/components/ui/Card";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import apiClient from "@/lib/axios";
import type { ApiResponse, Branch } from "@/types";

export default function BranchesPage() {
  const queryClient = useQueryClient();

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  // Form Fields
  const [name, setName] = useState("");
  const [address, setAddress] = useState("");
  const [latitude, setLatitude] = useState("-6.208800");
  const [longitude, setLongitude] = useState("106.845600");
  const [radiusMeters, setRadiusMeters] = useState("50");

  // Query Branches
  const {
    data: branches = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["branches"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<Branch[]>>("/branches");
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
      address: string;
      latitude: number;
      longitude: number;
      radius_meters: number;
    }) => {
      const response = await apiClient.post<ApiResponse<Branch>>("/branches", payload);
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setIsModalOpen(false);
        queryClient.invalidateQueries({ queryKey: ["branches"] });
      } else {
        setFormError(data.message || "Gagal menyimpan cabang baru.");
      }
    },
    onError: (err: Error) => {
      setFormError(err.message || "Terjadi kendala pada server.");
    },
  });

  // Delete Mutation
  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      await apiClient.delete(`/branches/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["branches"] });
    },
    onError: (err: Error) => {
      alert(err.message || "Gagal menghapus cabang.");
    },
  });

  const handleOpenModal = () => {
    setName("");
    setAddress("");
    setLatitude("-6.208800");
    setLongitude("106.845600");
    setRadiusMeters("50");
    setFormError(null);
    setIsModalOpen(true);
  };

  const handleCreateBranch = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    createMutation.mutate({
      name,
      address,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      radius_meters: parseInt(radiusMeters, 10),
    });
  };

  const handleDeleteBranch = (id: number) => {
    if (!window.confirm("Yakin ingin menghapus kantor cabang ini?")) return;
    deleteMutation.mutate(id);
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Kantor Cabang
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Kelola titik lokasi kantor, koordinat GPS, dan radius toleransi presensi karyawan.
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
            Tambah Cabang Baru
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader className="p-5 border-b border-slate-100/80">
          <CardTitle>Daftar Lokasi Kantor</CardTitle>
          <p className="text-xs text-slate-500 mt-1">
            Validasi presensi mobile mengacu pada koordinat dan radius kantor cabang berikut.
          </p>
        </CardHeader>

        {isLoading ? (
          <TableSkeleton rows={4} columns={5} />
        ) : isError ? (
          <div className="p-6">
            <ErrorState
              title="Gagal Memuat Cabang"
              message={error instanceof Error ? error.message : "Terjadi kendala."}
              onRetry={() => refetch()}
            />
          </div>
        ) : branches.length === 0 ? (
          <div className="p-6">
            <EmptyState
              title="Belum ada kantor cabang"
              description="Daftarkan kantor pusat atau cabang operasional pertama Anda."
              actionLabel="Tambah Cabang"
              onAction={handleOpenModal}
            />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="bg-slate-50/80 backdrop-blur-xs border-b border-slate-200/70 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  <th scope="col" className="px-5 py-3">Nama Cabang</th>
                  <th scope="col" className="px-4 py-3">Alamat Lengkap</th>
                  <th scope="col" className="px-4 py-3 font-mono">Titik Koordinat</th>
                  <th scope="col" className="px-4 py-3 font-mono text-center">Radius Toleransi</th>
                  <th scope="col" className="px-5 py-3 text-right">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {branches.map((item) => (
                  <tr key={item.id_branches} className="hover:bg-slate-50/60 transition-colors">
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-2 font-medium text-slate-900">
                        <MapPin className="w-4 h-4 text-orange-600 flex-shrink-0" />
                        <span>{item.name}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3.5 text-xs text-slate-500 max-w-xs">
                      {item.address}
                    </td>
                    <td className="px-4 py-3.5 text-xs font-mono tabular-nums text-slate-900">
                      {Number(item.latitude).toFixed(6)}, {Number(item.longitude).toFixed(6)}
                    </td>
                    <td className="px-4 py-3.5 text-xs font-mono tabular-nums text-center text-slate-900">
                      {item.radius_meters} meter
                    </td>
                    <td className="px-5 py-3.5 text-right">
                      <button
                        type="button"
                        onClick={() => handleDeleteBranch(item.id_branches)}
                        aria-label={`Hapus cabang ${item.name}`}
                        className="inline-flex items-center p-2 rounded-xl text-rose-600 hover:bg-rose-50 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-500"
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

      {/* Modal Tambah Cabang */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Tambah Kantor Cabang Baru"
      >
        <form onSubmit={handleCreateBranch} className="space-y-4">
          {formError && (
            <div
              role="alert"
              className="rounded-xl border border-rose-200 bg-rose-50 p-3 text-xs text-rose-700"
            >
              {formError}
            </div>
          )}

          <div>
            <label htmlFor="branchName" className="block text-xs font-semibold text-slate-700 mb-1.5">
              Nama Kantor Cabang
            </label>
            <input
              id="branchName"
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Contoh: Kantor Operasional Surabaya"
              className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-sm text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
            />
          </div>

          <div>
            <label htmlFor="branchAddress" className="block text-xs font-semibold text-slate-700 mb-1.5">
              Alamat Lengkap
            </label>
            <textarea
              id="branchAddress"
              required
              rows={2}
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              placeholder="Jl. Raya No. 12, Kelurahan, Kecamatan"
              className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-sm text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label htmlFor="branchLat" className="block text-xs font-semibold text-slate-700 mb-1.5 font-mono">
                Latitude
              </label>
              <input
                id="branchLat"
                type="text"
                required
                value={latitude}
                onChange={(e) => setLatitude(e.target.value)}
                placeholder="-6.208800"
                className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-sm font-mono text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
              />
            </div>
            <div>
              <label htmlFor="branchLng" className="block text-xs font-semibold text-slate-700 mb-1.5 font-mono">
                Longitude
              </label>
              <input
                id="branchLng"
                type="text"
                required
                value={longitude}
                onChange={(e) => setLongitude(e.target.value)}
                placeholder="106.845600"
                className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-sm font-mono text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
              />
            </div>
          </div>

          <div>
            <label htmlFor="branchRadius" className="block text-xs font-semibold text-slate-700 mb-1.5">
              Radius Toleransi Presensi (meter)
            </label>
            <input
              id="branchRadius"
              type="number"
              min={10}
              max={1000}
              required
              value={radiusMeters}
              onChange={(e) => setRadiusMeters(e.target.value)}
              className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-sm font-mono text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
            />
            <p className="mt-1.5 text-xs text-slate-500">
              Standar kantor: 50 meter. Perangkat di luar radius ini akan ditolak otomatis.
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
              Simpan Cabang
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
