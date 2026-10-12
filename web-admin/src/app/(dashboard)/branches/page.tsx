"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Plus,
  MapPin,
  Trash2,
  Edit2,
  ExternalLink,
  Navigation,
  AlertCircle,
  AlertTriangle,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle } from "@/components/ui/Card";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { apiClient, ApiError } from "@/lib/axios";
import type { ApiResponse, Branch } from "@/types";

export default function BranchesPage() {
  const queryClient = useQueryClient();

  // Modal & Form State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBranch, setEditingBranch] = useState<Branch | null>(null);
  const [deletingBranch, setDeletingBranch] = useState<Branch | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string[]>>({});
  const [locationNotice, setLocationNotice] = useState<string | null>(null);
  const [isGettingLocation, setIsGettingLocation] = useState(false);

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

  const clearFieldError = (fieldName: string) => {
    if (fieldErrors[fieldName]) {
      setFieldErrors((prev) => {
        const next = { ...prev };
        delete next[fieldName];
        return next;
      });
    }
  };

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
        setEditingBranch(null);
        setFormError(null);
        setFieldErrors({});
        queryClient.invalidateQueries({ queryKey: ["branches"] });
      } else {
        setFormError(data.message || "Gagal menyimpan cabang baru.");
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
    mutationFn: async ({
      id,
      payload,
    }: {
      id: number;
      payload: {
        name: string;
        address: string;
        latitude: number;
        longitude: number;
        radius_meters: number;
      };
    }) => {
      const response = await apiClient.put<ApiResponse<Branch>>(`/branches/${id}`, payload);
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setIsModalOpen(false);
        setEditingBranch(null);
        setFormError(null);
        setFieldErrors({});
        queryClient.invalidateQueries({ queryKey: ["branches"] });
      } else {
        setFormError(data.message || "Gagal memperbarui cabang.");
      }
    },
    onError: (err: unknown) => {
      if (err instanceof ApiError) {
        setFormError(err.message || "Validasi gagal.");
        if (err.errors) setFieldErrors(err.errors);
      } else if (err instanceof Error) {
        setFormError(err.message || "Terjadi kendala pada server.");
      } else {
        setFormError("Terjadi kendala saat memperbarui data.");
      }
    },
  });

  // Delete Mutation
  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      await apiClient.delete(`/branches/${id}`);
    },
    onSuccess: () => {
      setDeletingBranch(null);
      setDeleteError(null);
      queryClient.invalidateQueries({ queryKey: ["branches"] });
    },
    onError: (err: unknown) => {
      if (err instanceof ApiError) {
        setDeleteError(err.message || "Gagal menghapus cabang.");
      } else if (err instanceof Error) {
        setDeleteError(err.message || "Gagal menghapus cabang.");
      } else {
        setDeleteError("Terjadi kendala saat menghapus cabang.");
      }
    },
  });

  const handleOpenCreateModal = () => {
    setEditingBranch(null);
    setName("");
    setAddress("");
    setLatitude("-6.208800");
    setLongitude("106.845600");
    setRadiusMeters("50");
    setFormError(null);
    setFieldErrors({});
    setLocationNotice(null);
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (branch: Branch) => {
    setEditingBranch(branch);
    setName(branch.name);
    setAddress(branch.address || "");
    setLatitude(String(branch.latitude));
    setLongitude(String(branch.longitude));
    setRadiusMeters(String(branch.radius_meters));
    setFormError(null);
    setFieldErrors({});
    setLocationNotice(null);
    setIsModalOpen(true);
  };

  const handleGetCurrentLocation = () => {
    if (typeof window === "undefined" || !navigator.geolocation) {
      setLocationNotice("Browser tidak mendukung deteksi lokasi otomatis.");
      return;
    }
    setIsGettingLocation(true);
    setLocationNotice(null);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setIsGettingLocation(false);
        setLatitude(pos.coords.latitude.toFixed(6));
        setLongitude(pos.coords.longitude.toFixed(6));
        clearFieldError("latitude");
        clearFieldError("longitude");
        setLocationNotice("Koordinat GPS berhasil disesuaikan dengan posisi perangkat.");
      },
      (err) => {
        setIsGettingLocation(false);
        setLocationNotice(`Gagal mendeteksi lokasi: ${err.message}`);
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
    );
  };

  const validateForm = (): boolean => {
    const errs: Record<string, string[]> = {};

    if (!name.trim()) {
      errs.name = ["Nama cabang wajib diisi."];
    } else if (name.trim().length > 100) {
      errs.name = ["Nama cabang maksimal 100 karakter."];
    }

    if (!address.trim()) {
      errs.address = ["Alamat cabang wajib diisi."];
    }

    const lat = parseFloat(latitude);
    if (isNaN(lat)) {
      errs.latitude = ["Latitude harus berupa angka numerik."];
    } else if (lat < -90 || lat > 90) {
      errs.latitude = ["Latitude harus berada dalam rentang -90 hingga 90."];
    }

    const lng = parseFloat(longitude);
    if (isNaN(lng)) {
      errs.longitude = ["Longitude harus berupa angka numerik."];
    } else if (lng < -180 || lng > 180) {
      errs.longitude = ["Longitude harus berada dalam rentang -180 hingga 180."];
    }

    const rad = parseInt(radiusMeters, 10);
    if (isNaN(rad)) {
      errs.radius_meters = ["Radius harus berupa bilangan bulat."];
    } else if (rad < 1) {
      errs.radius_meters = ["Radius minimal bernilai 1 meter."];
    }

    setFieldErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    if (!validateForm()) return;

    const payload = {
      name: name.trim(),
      address: address.trim(),
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      radius_meters: parseInt(radiusMeters, 10),
    };

    if (editingBranch) {
      updateMutation.mutate({ id: editingBranch.id_branches, payload });
    } else {
      createMutation.mutate(payload);
    }
  };

  const confirmDelete = () => {
    if (deletingBranch) {
      deleteMutation.mutate(deletingBranch.id_branches);
    }
  };

  const isSubmitting = createMutation.isPending || updateMutation.isPending;
  const parsedLat = parseFloat(latitude);
  const parsedLng = parseFloat(longitude);
  const hasValidCoords =
    !isNaN(parsedLat) &&
    !isNaN(parsedLng) &&
    parsedLat >= -90 &&
    parsedLat <= 90 &&
    parsedLng >= -180 &&
    parsedLng <= 180;

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

        <div className="hidden sm:flex items-center gap-2">
          <Button
            variant="primary"
            size="sm"
            onClick={handleOpenCreateModal}
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
              onAction={handleOpenCreateModal}
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
                      <div className="inline-flex items-center gap-1.5">
                        <span>
                          {Number(item.latitude).toFixed(6)}, {Number(item.longitude).toFixed(6)}
                        </span>
                        <a
                          href={`https://www.google.com/maps?q=${item.latitude},${item.longitude}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center text-slate-400 hover:text-orange-600 transition-colors"
                          title="Buka di Google Maps"
                          aria-label={`Buka peta lokasi ${item.name}`}
                        >
                          <ExternalLink className="w-3.5 h-3.5" />
                        </a>
                      </div>
                    </td>
                    <td className="px-4 py-3.5 text-xs font-mono tabular-nums text-center text-slate-900">
                      <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
                        {item.radius_meters} meter
                      </span>
                    </td>
                    <td className="px-5 py-3.5 text-right">
                      <div className="inline-flex items-center gap-1">
                        <button
                          type="button"
                          onClick={() => handleOpenEditModal(item)}
                          aria-label={`Ubah cabang ${item.name}`}
                          className="inline-flex items-center justify-center p-2 rounded-xl text-slate-600 hover:text-orange-600 hover:bg-orange-50 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-500"
                          title="Ubah data cabang"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button
                          type="button"
                          onClick={() => setDeletingBranch(item)}
                          aria-label={`Hapus cabang ${item.name}`}
                          className="inline-flex items-center justify-center p-2 rounded-xl text-rose-600 hover:bg-rose-50 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-500"
                          title="Hapus cabang"
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

      {/* Modal Tambah / Ubah Cabang */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingBranch ? "Ubah Data Kantor Cabang" : "Tambah Kantor Cabang Baru"}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          {formError && (
            <div
              role="alert"
              className="flex items-center gap-2 rounded-xl border border-rose-200 bg-rose-50 p-3 text-xs text-rose-700"
            >
              <AlertCircle className="w-4 h-4 flex-shrink-0" />
              <span>{formError}</span>
            </div>
          )}

          {locationNotice && (
            <div
              role="status"
              className="flex items-center gap-2 rounded-xl border border-orange-200 bg-orange-50/80 p-3 text-xs text-orange-800"
            >
              <Navigation className="w-4 h-4 flex-shrink-0 text-orange-600" />
              <span>{locationNotice}</span>
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
              onChange={(e) => {
                setName(e.target.value);
                clearFieldError("name");
              }}
              placeholder="Contoh: Kantor Operasional Surabaya"
              className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-sm text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
              aria-invalid={!!fieldErrors.name}
              aria-describedby={fieldErrors.name ? "branchName-error" : undefined}
            />
            {fieldErrors.name && (
              <p id="branchName-error" role="alert" className="mt-1 text-xs text-rose-600">
                {fieldErrors.name[0]}
              </p>
            )}
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
              onChange={(e) => {
                setAddress(e.target.value);
                clearFieldError("address");
              }}
              placeholder="Jl. Raya No. 12, Kelurahan, Kecamatan"
              className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-sm text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
              aria-invalid={!!fieldErrors.address}
              aria-describedby={fieldErrors.address ? "branchAddress-error" : undefined}
            />
            {fieldErrors.address && (
              <p id="branchAddress-error" role="alert" className="mt-1 text-xs text-rose-600">
                {fieldErrors.address[0]}
              </p>
            )}
          </div>

          <div>
            <div className="flex items-center justify-between mb-1.5">
              <span className="text-xs font-semibold text-slate-700">Titik Koordinat GPS</span>
              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={handleGetCurrentLocation}
                  disabled={isGettingLocation}
                  className="inline-flex items-center gap-1 text-xs font-medium text-orange-600 hover:text-orange-700 disabled:opacity-50 transition-colors"
                >
                  <Navigation className="w-3 h-3" />
                  <span>{isGettingLocation ? "Mendeteksi..." : "Gunakan Lokasi Saat Ini"}</span>
                </button>
                {hasValidCoords && (
                  <a
                    href={`https://www.google.com/maps?q=${parsedLat},${parsedLng}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1 text-xs text-slate-500 hover:text-slate-800 transition-colors"
                    title="Pratinjau titik di peta"
                  >
                    <ExternalLink className="w-3 h-3" />
                    <span>Lihat di Peta</span>
                  </a>
                )}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label htmlFor="branchLat" className="block text-xs text-slate-500 mb-1 font-mono">
                  Latitude (-90 s/d 90)
                </label>
                <input
                  id="branchLat"
                  type="text"
                  required
                  value={latitude}
                  onChange={(e) => {
                    setLatitude(e.target.value);
                    clearFieldError("latitude");
                  }}
                  placeholder="-6.208800"
                  className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-sm font-mono text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
                  aria-invalid={!!fieldErrors.latitude}
                  aria-describedby={fieldErrors.latitude ? "branchLat-error" : undefined}
                />
                {fieldErrors.latitude && (
                  <p id="branchLat-error" role="alert" className="mt-1 text-xs text-rose-600">
                    {fieldErrors.latitude[0]}
                  </p>
                )}
              </div>
              <div>
                <label htmlFor="branchLng" className="block text-xs text-slate-500 mb-1 font-mono">
                  Longitude (-180 s/d 180)
                </label>
                <input
                  id="branchLng"
                  type="text"
                  required
                  value={longitude}
                  onChange={(e) => {
                    setLongitude(e.target.value);
                    clearFieldError("longitude");
                  }}
                  placeholder="106.845600"
                  className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-sm font-mono text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
                  aria-invalid={!!fieldErrors.longitude}
                  aria-describedby={fieldErrors.longitude ? "branchLng-error" : undefined}
                />
                {fieldErrors.longitude && (
                  <p id="branchLng-error" role="alert" className="mt-1 text-xs text-rose-600">
                    {fieldErrors.longitude[0]}
                  </p>
                )}
              </div>
            </div>
          </div>

          <div>
            <label htmlFor="branchRadius" className="block text-xs font-semibold text-slate-700 mb-1.5">
              Radius Toleransi Presensi (meter)
            </label>
            <input
              id="branchRadius"
              type="number"
              min={1}
              max={5000}
              required
              value={radiusMeters}
              onChange={(e) => {
                setRadiusMeters(e.target.value);
                clearFieldError("radius_meters");
              }}
              className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3 py-2 text-sm font-mono text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
              aria-invalid={!!fieldErrors.radius_meters}
              aria-describedby={fieldErrors.radius_meters ? "branchRadius-error" : undefined}
            />
            {fieldErrors.radius_meters ? (
              <p id="branchRadius-error" role="alert" className="mt-1 text-xs text-rose-600">
                {fieldErrors.radius_meters[0]}
              </p>
            ) : (
              <p className="mt-1.5 text-xs text-slate-500">
                Jarak toleransi maksimal pegawai dapat melakukan clock-in (standar kantor: 50 meter).
              </p>
            )}
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
              isLoading={isSubmitting}
            >
              {editingBranch ? "Simpan Perubahan" : "Simpan Cabang"}
            </Button>
          </div>
        </form>
      </Modal>

      {/* Confirmation Modal for Delete */}
      <Modal
        isOpen={!!deletingBranch}
        onClose={() => {
          setDeletingBranch(null);
          setDeleteError(null);
        }}
        title="Konfirmasi Hapus Kantor Cabang"
        maxWidth="md"
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              onClick={() => {
                setDeletingBranch(null);
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
              Hapus Cabang
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
              Apakah Anda yakin ingin menghapus kantor cabang{" "}
              <strong className="text-slate-900">{deletingBranch?.name}</strong>?
            </p>
            <p className="text-xs text-slate-500 mt-1">
              Tindakan ini tidak dapat dibatalkan. Karyawan yang terhubung dengan cabang ini perlu dipindahkan terlebih dahulu.
            </p>
          </div>
        </div>
      </Modal>

      {/* Floating Action Button (FAB) + Mobile */}
      <button
        type="button"
        onClick={handleOpenCreateModal}
        aria-label="Tambah Cabang Baru"
        className="sm:hidden fixed bottom-20 right-4 z-40 w-14 h-14 rounded-full bg-orange-600 hover:bg-orange-700 active:scale-90 text-white shadow-[0_8px_24px_rgba(234,88,12,0.45)] flex items-center justify-center transition-transform cursor-pointer focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-orange-500/30"
      >
        <Plus className="w-7 h-7 stroke-[2.5]" aria-hidden="true" />
      </button>
    </div>
  );
}
