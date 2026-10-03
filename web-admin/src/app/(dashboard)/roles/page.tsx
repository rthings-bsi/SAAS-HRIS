"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  ShieldCheck,
  RotateCcw,
  AlertCircle,
  CheckCircle2,
  Briefcase,
  Building,
  Edit2,
  Power,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle } from "@/components/ui/Card";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { apiClient, ApiError } from "@/lib/axios";
import type { ApiResponse, User, UserRole } from "@/types";

interface RoleDefinition {
  key: UserRole;
  label: string;
  badgeClass: string;
  description: string;
  permissions: string[];
}

const ROLE_DEFINITIONS: RoleDefinition[] = [
  {
    key: "owner",
    label: "Owner (Pemilik)",
    badgeClass: "bg-purple-50 text-purple-700 border-purple-200/80",
    description: "Pemilik akun organisasi tenant dengan hak akses mutlak.",
    permissions: [
      "Akses seluruh modul & data perusahaan",
      "Kelola langganan & penagihan",
      "Persetujuan cuti semua karyawan",
      "Ubah dan tetapkan role pengguna",
    ],
  },
  {
    key: "hr",
    label: "HR Administrator",
    badgeClass: "bg-indigo-50 text-indigo-700 border-indigo-200/80",
    description: "Pengelola operasional kepegawaian dan kompensasi.",
    permissions: [
      "Kelola data staf, cabang & departemen",
      "Kelola master shift & jadwal kerja",
      "Kalkulasi & finalisasi payroll (gaji)",
      "Persetujuan cuti dan kelola jenis cuti",
    ],
  },
  {
    key: "manager",
    label: "Manager / Supervisor",
    badgeClass: "bg-amber-50 text-amber-700 border-amber-200/80",
    description: "Atasan operasional atau kepala departemen.",
    permissions: [
      "Persetujuan dan penolakan cuti tim",
      "Melihat rekap presensi tim kerja",
      "Akses operasional mobile & web",
    ],
  },
  {
    key: "employee",
    label: "Karyawan (Staf)",
    badgeClass: "bg-slate-100/90 text-slate-700 border-slate-200/80",
    description: "Staf operasional pelaksana presensi dan tugas harian.",
    permissions: [
      "Presensi GPS & swafoto via mobile",
      "Pengajuan cuti pribadi & lihat kuota",
      "Unduh slip gaji bulanan",
    ],
  },
];

export default function RolesPage() {
  const queryClient = useQueryClient();

  // Filter State
  const [selectedRoleFilter, setSelectedRoleFilter] = useState<string>("all");

  // Edit Role Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [newRole, setNewRole] = useState<UserRole>("employee");
  const [modalError, setModalError] = useState<string | null>(null);

  // Status feedback toast/notice
  const [actionNotice, setActionNotice] = useState<string | null>(null);

  // Query Users List
  const {
    data: users = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["users-roles"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<User[]>>("/users");
      if (response.data.success && Array.isArray(response.data.data)) {
        return response.data.data;
      }
      return [];
    },
  });

  // Mutation: Update Role
  const updateRoleMutation = useMutation({
    mutationFn: async ({ userId, role }: { userId: number; role: UserRole }) => {
      const response = await apiClient.put<ApiResponse<User>>(`/users/${userId}/role`, {
        role,
      });
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setIsModalOpen(false);
        setSelectedUser(null);
        setModalError(null);
        setActionNotice(data.message || "Role pengguna berhasil diperbarui.");
        queryClient.invalidateQueries({ queryKey: ["users-roles"] });
        setTimeout(() => setActionNotice(null), 4000);
      } else {
        setModalError(data.message || "Gagal memperbarui role.");
      }
    },
    onError: (err: unknown) => {
      if (err instanceof ApiError) {
        setModalError(err.message || "Gagal memperbarui role.");
      } else if (err instanceof Error) {
        setModalError(err.message || "Terjadi kesalahan pada server.");
      } else {
        setModalError("Terjadi kendala saat mengubah role.");
      }
    },
  });

  // Mutation: Toggle Active Status
  const toggleStatusMutation = useMutation({
    mutationFn: async (userId: number) => {
      const response = await apiClient.put<ApiResponse<User>>(`/users/${userId}/status`);
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setActionNotice(data.message || "Status pengguna berhasil diperbarui.");
        queryClient.invalidateQueries({ queryKey: ["users-roles"] });
        setTimeout(() => setActionNotice(null), 4000);
      }
    },
    onError: (err: unknown) => {
      const msg = err instanceof Error ? err.message : "Gagal mengubah status akun.";
      alert(msg);
    },
  });

  const handleOpenEditModal = (user: User) => {
    setSelectedUser(user);
    setNewRole(user.role);
    setModalError(null);
    setIsModalOpen(true);
  };

  const handleSaveRole = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser) return;
    setModalError(null);
    updateRoleMutation.mutate({
      userId: selectedUser.id_users,
      role: newRole,
    });
  };

  const handleToggleStatus = (user: User) => {
    const action = user.is_active ? "menonaktifkan" : "mengaktifkan";
    if (!window.confirm(`Yakin ingin ${action} akun "${user.name}"?`)) return;
    toggleStatusMutation.mutate(user.id_users);
  };

  // Filtered Users
  const filteredUsers = users.filter((u) => {
    if (selectedRoleFilter === "all") return true;
    return u.role === selectedRoleFilter;
  });

  // Count per role
  const roleCounts: Record<string, number> = {
    owner: users.filter((u) => u.role === "owner").length,
    hr: users.filter((u) => u.role === "hr").length,
    manager: users.filter((u) => u.role === "manager").length,
    employee: users.filter((u) => u.role === "employee").length,
  };

  const getRoleBadge = (role: UserRole) => {
    const found = ROLE_DEFINITIONS.find((r) => r.key === role);
    return (
      <span
        className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold border tracking-tight shadow-2xs ${
          found?.badgeClass || "bg-slate-100 text-slate-700 border-slate-200"
        }`}
      >
        {found?.label || role}
      </span>
    );
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Hak Akses & Role Pengguna
          </h1>
          <p className="text-sm text-slate-500 mt-0.5 font-normal">
            Atur wewenang persetujuan cuti, kelola operasional HR, dan hak administrasi sistem.
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
        </div>
      </div>

      {/* Success Notification Banner */}
      {actionNotice && (
        <div
          role="status"
          className="rounded-2xl border border-emerald-200/80 bg-emerald-50/80 backdrop-blur-sm p-4 text-xs text-emerald-800 flex items-center gap-2.5 shadow-2xs"
        >
          <CheckCircle2 className="w-4 h-4 text-emerald-600 flex-shrink-0" aria-hidden="true" />
          <p className="font-semibold">{actionNotice}</p>
        </div>
      )}

      {/* Role Cards Definition Overview */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {ROLE_DEFINITIONS.map((def) => {
          const count = roleCounts[def.key] || 0;
          return (
            <div
              key={def.key}
              onClick={() => setSelectedRoleFilter(def.key)}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => e.key === "Enter" && setSelectedRoleFilter(def.key)}
              className={`p-4.5 rounded-2xl transition-all cursor-pointer backdrop-blur-md active:scale-[0.98] ${
                selectedRoleFilter === def.key
                  ? "border border-orange-500/80 bg-white/95 ring-2 ring-orange-500/20 shadow-sm"
                  : "border border-slate-200/80 bg-white/90 hover:border-slate-300 shadow-[0_1px_3px_rgba(0,0,0,0.03)]"
              }`}
            >
              <div className="flex items-center justify-between mb-2.5">
                <span
                  className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold border tracking-tight shadow-2xs ${def.badgeClass}`}
                >
                  {def.label.split(" ")[0]}
                </span>
                <span className="text-[11px] font-semibold tabular-nums text-slate-600 bg-slate-100/90 px-2 py-0.5 rounded-full">
                  {count} akun
                </span>
              </div>
              <p className="text-xs text-slate-600 font-normal mb-3 line-clamp-2 leading-relaxed">
                {def.description}
              </p>
              <div className="space-y-1.5 pt-2.5 border-t border-slate-100 text-[11px] text-slate-500">
                {def.permissions.slice(0, 2).map((perm, idx) => (
                  <div key={idx} className="flex items-center gap-1.5 truncate">
                    <ShieldCheck className="w-3.5 h-3.5 text-orange-600 flex-shrink-0" aria-hidden="true" />
                    <span className="truncate">{perm}</span>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      {/* Table Card */}
      <Card>
        <CardHeader className="p-5 border-b border-slate-100/80 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div>
            <CardTitle>Daftar Pengguna & Hak Akses</CardTitle>
            <p className="text-xs text-slate-500 mt-1 font-normal">
              Akun dengan role Manager, HR, dan Owner memiliki hak menyetujui pengajuan cuti staf.
            </p>
          </div>

          {/* Filter Segmented Control */}
          <div className="inline-flex p-1 rounded-xl bg-slate-100/80 border border-slate-200/60 backdrop-blur-sm gap-1 flex-wrap">
            <button
              type="button"
              onClick={() => setSelectedRoleFilter("all")}
              className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all cursor-pointer active:scale-[0.97] ${
                selectedRoleFilter === "all"
                  ? "bg-white text-slate-900 shadow-2xs border border-slate-200/50"
                  : "text-slate-600 hover:text-slate-900 hover:bg-white/50"
              }`}
            >
              Semua ({users.length})
            </button>
            {ROLE_DEFINITIONS.map((def) => (
              <button
                key={def.key}
                type="button"
                onClick={() => setSelectedRoleFilter(def.key)}
                className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all cursor-pointer active:scale-[0.97] ${
                  selectedRoleFilter === def.key
                    ? "bg-white text-slate-900 shadow-2xs border border-slate-200/50"
                    : "text-slate-600 hover:text-slate-900 hover:bg-white/50"
                }`}
              >
                {def.label.split(" ")[0]} ({roleCounts[def.key] || 0})
              </button>
            ))}
          </div>
        </CardHeader>

        {isLoading ? (
          <TableSkeleton rows={4} columns={5} />
        ) : isError ? (
          <div className="p-6">
            <ErrorState
              title="Gagal Memuat Daftar Pengguna"
              message={error instanceof Error ? error.message : "Terjadi kendala pada server."}
              onRetry={() => refetch()}
            />
          </div>
        ) : filteredUsers.length === 0 ? (
          <div className="p-6">
            <EmptyState
              title="Tidak ada pengguna ditemukan"
              description={
                selectedRoleFilter === "all"
                  ? "Belum ada akun pengguna yang terdaftar."
                  : `Tidak ada akun dengan role ${selectedRoleFilter}.`
              }
              actionLabel="Tampilkan Semua"
              onAction={() => setSelectedRoleFilter("all")}
            />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="bg-slate-50/80 backdrop-blur-xs border-b border-slate-200/70 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  <th scope="col" className="px-5 py-3">Nama Pengguna & Email</th>
                  <th scope="col" className="px-5 py-3">Profil Pegawai</th>
                  <th scope="col" className="px-5 py-3">Role Saat Ini</th>
                  <th scope="col" className="px-5 py-3 text-center">Status Akun</th>
                  <th scope="col" className="px-5 py-3 text-right">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredUsers.map((user) => (
                  <tr key={user.id_users} className="hover:bg-slate-50/60 transition-colors">
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-xl bg-orange-50/90 border border-orange-200/80 text-orange-700 flex items-center justify-center font-bold text-xs flex-shrink-0 shadow-2xs">
                          {user.name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <div className="font-semibold text-slate-900">{user.name}</div>
                          <div className="text-xs text-slate-500 font-normal">{user.email}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-3.5 text-xs text-slate-600">
                      {user.employee ? (
                        <div className="space-y-0.5">
                          <div className="font-medium text-slate-800 flex items-center gap-1.5">
                            <Briefcase className="w-3.5 h-3.5 text-slate-400" aria-hidden="true" />
                            <span>{user.employee.job_position?.name || "Staf"}</span>
                            <span className="text-slate-400 font-mono">({user.employee.nik})</span>
                          </div>
                          <div className="text-slate-500 flex items-center gap-1.5">
                            <Building className="w-3.5 h-3.5 text-slate-400" aria-hidden="true" />
                            <span>{user.employee.branch?.name || "Cabang Utama"}</span>
                          </div>
                        </div>
                      ) : (
                        <span className="text-slate-400 italic">Akun Sistem / Non-staf</span>
                      )}
                    </td>
                    <td className="px-5 py-3.5">
                      {getRoleBadge(user.role)}
                    </td>
                    <td className="px-5 py-3.5 text-center">
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold border tracking-tight shadow-2xs ${
                          user.is_active
                            ? "bg-emerald-50 text-emerald-700 border-emerald-200/70"
                            : "bg-rose-50 text-rose-700 border-rose-200/70"
                        }`}
                      >
                        {user.is_active ? "Aktif" : "Nonaktif"}
                      </span>
                    </td>
                    <td className="px-5 py-3.5 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          type="button"
                          onClick={() => handleOpenEditModal(user)}
                          aria-label={`Ubah role ${user.name}`}
                          className="inline-flex items-center gap-1.5 px-2.5 py-1.5 text-xs font-semibold rounded-xl text-slate-700 bg-slate-100/80 hover:bg-orange-50 hover:text-orange-700 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 cursor-pointer"
                        >
                          <Edit2 className="w-3.5 h-3.5" aria-hidden="true" />
                          <span>Ubah Role</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => handleToggleStatus(user)}
                          title={user.is_active ? "Nonaktifkan Akun" : "Aktifkan Akun"}
                          aria-label={user.is_active ? `Nonaktifkan akun ${user.name}` : `Aktifkan akun ${user.name}`}
                          className={`p-1.5 rounded-xl transition-all active:scale-95 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600 ${
                            user.is_active
                              ? "text-slate-400 hover:text-rose-600 hover:bg-rose-50"
                              : "text-emerald-600 hover:bg-emerald-50"
                          }`}
                        >
                          <Power className="w-4 h-4" aria-hidden="true" />
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

      {/* Modal Ubah Role Pengguna */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Ubah Hak Akses & Role"
        description={
          selectedUser
            ? `Atur peran wewenang untuk ${selectedUser.name} (${selectedUser.email}).`
            : "Pilih peran baru untuk akun ini."
        }
        maxWidth="lg"
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
              form="change-role-form"
              type="submit"
              variant="primary"
              size="sm"
              isLoading={updateRoleMutation.isPending}
            >
              Simpan Role Baru
            </Button>
          </div>
        }
      >
        <form id="change-role-form" onSubmit={handleSaveRole} className="space-y-4">
          {modalError && (
            <div
              role="alert"
              className="rounded-2xl border border-rose-200/80 bg-rose-50/80 p-3.5 text-xs text-rose-700"
            >
              <div className="flex items-start gap-2">
                <AlertCircle className="w-4 h-4 text-rose-600 flex-shrink-0 mt-0.5" aria-hidden="true" />
                <p className="font-semibold">{modalError}</p>
              </div>
            </div>
          )}
          <div className="space-y-3">
            <label className="block text-xs font-semibold text-slate-700">
              Pilih Role Wewenang <span className="text-rose-500">*</span>
            </label>

            <div className="grid grid-cols-1 gap-2.5">
              {ROLE_DEFINITIONS.map((def) => {
                const isSelected = newRole === def.key;
                return (
                  <label
                    key={def.key}
                    className={`flex items-start gap-3 p-3.5 rounded-2xl border transition-all cursor-pointer ${
                      isSelected
                        ? "border-orange-500/80 bg-orange-50/40 ring-2 ring-orange-500/20 shadow-2xs"
                        : "border-slate-200/80 hover:border-slate-300/80 bg-white/95"
                    }`}
                  >
                    <input
                      type="radio"
                      name="user-role"
                      value={def.key}
                      checked={isSelected}
                      onChange={() => setNewRole(def.key)}
                      className="mt-1 text-orange-600 accent-orange-600 focus:ring-orange-500"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold text-slate-900">{def.label}</span>
                        {def.key === "manager" && (
                          <span className="text-[10px] bg-amber-50 text-amber-800 border border-amber-200/60 font-semibold px-2 py-0.5 rounded-full shadow-2xs">
                            Bisa Approve Cuti
                          </span>
                        )}
                        {def.key === "hr" && (
                          <span className="text-[10px] bg-indigo-50 text-indigo-800 border border-indigo-200/60 font-semibold px-2 py-0.5 rounded-full shadow-2xs">
                            Approve Cuti & Payroll
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-slate-500 mt-0.5">{def.description}</p>
                    </div>
                  </label>
                );
              })}
            </div>
          </div>
        </form>
      </Modal>
    </div>
  );
}
