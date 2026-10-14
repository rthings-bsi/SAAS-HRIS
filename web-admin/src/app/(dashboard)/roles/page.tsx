"use client";

import React, { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  ShieldCheck,
  AlertCircle,
  AlertTriangle,
  CheckCircle2,
  Briefcase,
  Building,
  Edit2,
  Power,
  Plus,
  RotateCcw,
  Trash2,
  Users,
  Settings2,
  Lock,
  Check,
  Search,
  Crown,
  UserCheck,
  User,
  Sliders,
  LayoutDashboard,
  Clock,
  Calendar,
  Wallet,
  Award,
  Smartphone,
  KeyRound,
  Sparkles,
  ArrowRight,
  Filter,
  X,
  Shield,
  Layers,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle } from "@/components/ui/Card";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { RoleGuard } from "@/components/auth/RoleGuard";
import { apiClient, ApiError } from "@/lib/axios";
import type {
  ApiResponse,
  User as UserType,
  UserRole,
  RoleItem,
  PermissionCategory,
  RolesApiResponse,
} from "@/types";

const BADGE_COLOR_OPTIONS = [
  { label: "Ungu", value: "bg-purple-50 text-purple-700 border-purple-200/80", dot: "bg-purple-600" },
  { label: "Nila", value: "bg-indigo-50 text-indigo-700 border-indigo-200/80", dot: "bg-indigo-600" },
  { label: "Kuning Kunyit", value: "bg-amber-50 text-amber-700 border-amber-200/80", dot: "bg-amber-600" },
  { label: "Hijau Zamrud", value: "bg-emerald-50 text-emerald-700 border-emerald-200/80", dot: "bg-emerald-600" },
  { label: "Biru", value: "bg-blue-50 text-blue-700 border-blue-200/80", dot: "bg-blue-600" },
  { label: "Sian", value: "bg-cyan-50 text-cyan-700 border-cyan-200/80", dot: "bg-cyan-600" },
  { label: "Merah Mawar", value: "bg-rose-50 text-rose-700 border-rose-200/80", dot: "bg-rose-600" },
  { label: "Abu Netral", value: "bg-slate-100/90 text-slate-700 border-slate-200/80", dot: "bg-slate-600" },
];

// Human-friendly functional module mapping for clean UI representation
const FUNCTIONAL_MODULES = [
  {
    key: "dashboard",
    label: "Dashboard Analitik",
    icon: LayoutDashboard,
    test: (perms: string[]) => perms.includes("dashboard.view"),
  },
  {
    key: "employees",
    label: "Karyawan & Organisasi",
    icon: Users,
    test: (perms: string[]) => perms.some((p) => p.startsWith("employees.")),
  },
  {
    key: "attendance",
    label: "Presensi & Shift",
    icon: Clock,
    test: (perms: string[]) => perms.some((p) => p.startsWith("attendance.")),
  },
  {
    key: "leave_overtime",
    label: "Cuti & Lembur",
    icon: Calendar,
    test: (perms: string[]) => perms.some((p) => p.startsWith("leave.") || p.startsWith("overtime.")),
  },
  {
    key: "payroll",
    label: "Penggajian (Payroll)",
    icon: Wallet,
    test: (perms: string[]) => perms.some((p) => p.startsWith("payroll.")),
  },
  {
    key: "performance",
    label: "Kinerja (SMART)",
    icon: Award,
    test: (perms: string[]) => perms.some((p) => p.startsWith("performance.")),
  },
  {
    key: "roles",
    label: "Konfigurasi Role",
    icon: KeyRound,
    test: (perms: string[]) => perms.includes("roles.manage"),
  },
  {
    key: "self_service",
    label: "Portal Mandiri Mobile",
    icon: Smartphone,
    test: (perms: string[]) => perms.some((p) => p.startsWith("self.") || p.startsWith("self_service.")),
  },
];

export default function RolesPage() {
  return (
    <RoleGuard
      allowedRoles={["superadmin", "super_admin", "owner", "hr"]}
      fallbackTitle="Akses Hak Akses & Role Dibatasi"
      fallbackMessage="Konfigurasi matriks peran dan penugasan role pengguna hanya dapat diakses oleh Super Admin, Owner, dan Tim HRD."
    >
      <RolesContent />
    </RoleGuard>
  );
}

function RolesContent() {
  const queryClient = useQueryClient();

  // Active Tab: "roles" (Konfigurasi & Tambah Role) | "users" (Penugasan Role Pengguna)
  const [activeTab, setActiveTab] = useState<"roles" | "users">("roles");

  // Filter State in Users Tab
  const [selectedRoleFilter, setSelectedRoleFilter] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState<string>("");

  // Status feedback toast/notice
  const [actionNotice, setActionNotice] = useState<string | null>(null);

  // Edit User Role Modal State
  const [isUserRoleModalOpen, setIsUserRoleModalOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<UserType | null>(null);
  const [newRoleForUser, setNewRoleForUser] = useState<UserRole>("employee");
  const [userRoleModalError, setUserRoleModalError] = useState<string | null>(null);

  // Toggle User Active Status State
  const [togglingUser, setTogglingUser] = useState<UserType | null>(null);

  // Create Custom Role Modal State
  const [isAddRoleModalOpen, setIsAddRoleModalOpen] = useState(false);
  const [addRoleName, setAddRoleName] = useState("");
  const [addRoleKey, setAddRoleKey] = useState("");
  const [addRoleDescription, setAddRoleDescription] = useState("");
  const [addRoleBadgeClass, setAddRoleBadgeClass] = useState(BADGE_COLOR_OPTIONS[0].value);
  const [addRolePermissions, setAddRolePermissions] = useState<string[]>([]);
  const [addRoleError, setAddRoleError] = useState<string | null>(null);
  const [addPermSearchQuery, setAddPermSearchQuery] = useState("");

  // Configure / Edit Role Modal State
  const [isEditRoleModalOpen, setIsEditRoleModalOpen] = useState(false);
  const [editingRole, setEditingRole] = useState<RoleItem | null>(null);
  const [editRoleLabel, setEditRoleLabel] = useState("");
  const [editRoleDescription, setEditRoleDescription] = useState("");
  const [editRoleBadgeClass, setEditRoleBadgeClass] = useState("");
  const [editRolePermissions, setEditRolePermissions] = useState<string[]>([]);
  const [editRoleError, setEditRoleError] = useState<string | null>(null);
  const [editPermSearchQuery, setEditPermSearchQuery] = useState("");

  // Delete Custom Role Modal State
  const [deletingRole, setDeletingRole] = useState<RoleItem | null>(null);

  // Reset Roles Confirmation Modal State
  const [isResetConfirmOpen, setIsResetConfirmOpen] = useState(false);

  // 1. Query: Roles Configuration & Available Permissions
  const {
    data: rolesData,
    isLoading: isLoadingRoles,
    isError: isErrorRoles,
    error: rolesError,
    refetch: refetchRoles,
  } = useQuery({
    queryKey: ["roles-configuration"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<RolesApiResponse>>("/roles");
      if (response.data.success && response.data.data) {
        return response.data.data;
      }
      return { roles: [], available_permissions: [] };
    },
  });

  const roles = rolesData?.roles || [];
  const availablePermissions: PermissionCategory[] = rolesData?.available_permissions || [];

  // 2. Query: Users List
  const {
    data: users = [],
    isLoading: isLoadingUsers,
    isError: isErrorUsers,
    error: usersError,
    refetch: refetchUsers,
  } = useQuery({
    queryKey: ["users-roles"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<UserType[]>>("/users");
      if (response.data.success && Array.isArray(response.data.data)) {
        return response.data.data;
      }
      return [];
    },
  });

  // Notice Helper
  const triggerNotice = (msg: string) => {
    setActionNotice(msg);
    setTimeout(() => setActionNotice(null), 4500);
  };

  // 3. Mutation: Update User's Assigned Role
  const updateUserRoleMutation = useMutation({
    mutationFn: async ({ userId, role }: { userId: number; role: UserRole }) => {
      const response = await apiClient.put<ApiResponse<UserType>>(`/users/${userId}/role`, {
        role,
      });
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setIsUserRoleModalOpen(false);
        setSelectedUser(null);
        setUserRoleModalError(null);
        triggerNotice(data.message || "Role pengguna berhasil diperbarui.");
        queryClient.invalidateQueries({ queryKey: ["users-roles"] });
        queryClient.invalidateQueries({ queryKey: ["roles-configuration"] });
      } else {
        setUserRoleModalError(data.message || "Gagal memperbarui role.");
      }
    },
    onError: (err: unknown) => {
      if (err instanceof ApiError) {
        setUserRoleModalError(err.message || "Gagal memperbarui role.");
      } else if (err instanceof Error) {
        setUserRoleModalError(err.message || "Terjadi kesalahan pada server.");
      } else {
        setUserRoleModalError("Terjadi kendala saat mengubah role.");
      }
    },
  });

  // 4. Mutation: Toggle User Status
  const toggleStatusMutation = useMutation({
    mutationFn: async (userId: number) => {
      const response = await apiClient.put<ApiResponse<UserType>>(`/users/${userId}/status`);
      return response.data;
    },
    onSuccess: (data) => {
      setTogglingUser(null);
      if (data.success) {
        triggerNotice(data.message || "Status pengguna berhasil diperbarui.");
        queryClient.invalidateQueries({ queryKey: ["users-roles"] });
      }
    },
    onError: (err: unknown) => {
      const msg = err instanceof Error ? err.message : "Gagal mengubah status akun.";
      setTogglingUser(null);
      triggerNotice(msg);
    },
  });

  // 5. Mutation: Create Custom Role
  const createRoleMutation = useMutation({
    mutationFn: async (payload: {
      name: string;
      key: string;
      description: string;
      badgeClass: string;
      permissions: string[];
    }) => {
      const response = await apiClient.post<ApiResponse<RoleItem>>("/roles", payload);
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setIsAddRoleModalOpen(false);
        setAddRoleName("");
        setAddRoleKey("");
        setAddRoleDescription("");
        setAddRolePermissions([]);
        setAddRoleError(null);
        setAddPermSearchQuery("");
        triggerNotice(data.message || "Role kustom berhasil ditambahkan.");
        queryClient.invalidateQueries({ queryKey: ["roles-configuration"] });
      } else {
        setAddRoleError(data.message || "Gagal menambahkan role.");
      }
    },
    onError: (err: unknown) => {
      if (err instanceof ApiError) {
        setAddRoleError(err.message || "Gagal menambahkan role.");
      } else if (err instanceof Error) {
        setAddRoleError(err.message || "Terjadi kendala saat menyimpan data role.");
      } else {
        setAddRoleError("Terjadi kesalahan sistem saat membuat role.");
      }
    },
  });

  // 6. Mutation: Update Role Configuration & Permissions
  const updateRoleConfigMutation = useMutation({
    mutationFn: async ({
      key,
      payload,
    }: {
      key: string;
      payload: {
        label: string;
        description: string;
        badgeClass: string;
        permissions: string[];
      };
    }) => {
      const response = await apiClient.put<ApiResponse<RoleItem>>(`/roles/${key}`, payload);
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setIsEditRoleModalOpen(false);
        setEditingRole(null);
        setEditRoleError(null);
        setEditPermSearchQuery("");
        triggerNotice(data.message || "Konfigurasi role berhasil diperbarui.");
        queryClient.invalidateQueries({ queryKey: ["roles-configuration"] });
      } else {
        setEditRoleError(data.message || "Gagal menyimpan konfigurasi role.");
      }
    },
    onError: (err: unknown) => {
      if (err instanceof ApiError) {
        setEditRoleError(err.message || "Gagal menyimpan konfigurasi role.");
      } else if (err instanceof Error) {
        setEditRoleError(err.message || "Terjadi kendala pada server.");
      } else {
        setEditRoleError("Terjadi kesalahan sistem saat memperbarui role.");
      }
    },
  });

  // 7. Mutation: Delete Custom Role
  const deleteRoleMutation = useMutation({
    mutationFn: async (key: string) => {
      const response = await apiClient.delete<ApiResponse<null>>(`/roles/${key}`);
      return response.data;
    },
    onSuccess: (data) => {
      setDeletingRole(null);
      if (data.success) {
        triggerNotice(data.message || "Role berhasil dihapus.");
        queryClient.invalidateQueries({ queryKey: ["roles-configuration"] });
      } else {
        triggerNotice(data.message || "Gagal menghapus role.");
      }
    },
    onError: (err: unknown) => {
      setDeletingRole(null);
      const msg = err instanceof Error ? err.message : "Gagal menghapus role.";
      triggerNotice(msg);
    },
  });

  // 8. Mutation: Reset Roles to Factory Default
  const resetRolesMutation = useMutation({
    mutationFn: async () => {
      const response = await apiClient.post<ApiResponse<RoleItem[]>>("/roles/reset");
      return response.data;
    },
    onSuccess: (data) => {
      setIsResetConfirmOpen(false);
      if (data.success) {
        triggerNotice(data.message || "Seluruh konfigurasi role berhasil direset ke standar.");
        queryClient.invalidateQueries({ queryKey: ["roles-configuration"] });
      }
    },
    onError: (err: unknown) => {
      setIsResetConfirmOpen(false);
      const msg = err instanceof Error ? err.message : "Gagal mereset konfigurasi role.";
      triggerNotice(msg);
    },
  });

  // Handlers for User Role Assignment
  const handleOpenUserRoleModal = (user: UserType) => {
    setSelectedUser(user);
    setNewRoleForUser(user.role);
    setUserRoleModalError(null);
    setIsUserRoleModalOpen(true);
  };

  const handleSaveUserRole = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser) return;
    setUserRoleModalError(null);
    updateUserRoleMutation.mutate({
      userId: selectedUser.id_users,
      role: newRoleForUser,
    });
  };

  // Handlers for Role Configuration Modal
  const handleOpenEditRoleModal = (role: RoleItem) => {
    setEditingRole(role);
    setEditRoleLabel(role.label);
    setEditRoleDescription(role.description || "");
    setEditRoleBadgeClass(role.badgeClass || BADGE_COLOR_OPTIONS[0].value);
    setEditRolePermissions([...(role.permissions || [])]);
    setEditRoleError(null);
    setEditPermSearchQuery("");
    setIsEditRoleModalOpen(true);
  };

  const handleSaveRoleConfig = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingRole) return;
    setEditRoleError(null);
    updateRoleConfigMutation.mutate({
      key: editingRole.key,
      payload: {
        label: editRoleLabel,
        description: editRoleDescription,
        badgeClass: editRoleBadgeClass,
        permissions: editRolePermissions,
      },
    });
  };

  // Handlers for Add Role Modal
  const handleOpenAddRoleModal = () => {
    setAddRoleName("");
    setAddRoleKey("");
    setAddRoleDescription("");
    setAddRoleBadgeClass(BADGE_COLOR_OPTIONS[0].value);
    setAddRolePermissions(["dashboard.view"]);
    setAddRoleError(null);
    setAddPermSearchQuery("");
    setIsAddRoleModalOpen(true);
  };

  const handleSaveAddRole = (e: React.FormEvent) => {
    e.preventDefault();
    setAddRoleError(null);
    if (!addRoleName.trim()) {
      setAddRoleError("Nama role wajib diisi.");
      return;
    }
    createRoleMutation.mutate({
      name: addRoleName.trim(),
      key: addRoleKey.trim() || addRoleName.trim().toLowerCase().replace(/\s+/g, "_"),
      description: addRoleDescription.trim(),
      badgeClass: addRoleBadgeClass,
      permissions: addRolePermissions,
    });
  };

  // Permission selection toggle helper
  const togglePermission = (
    currentList: string[],
    setList: React.Dispatch<React.SetStateAction<string[]>>,
    permKey: string
  ) => {
    if (currentList.includes(permKey)) {
      setList(currentList.filter((k) => k !== permKey));
    } else {
      setList([...currentList, permKey]);
    }
  };

  const toggleCategoryPermissions = (
    currentList: string[],
    setList: React.Dispatch<React.SetStateAction<string[]>>,
    catPermissions: { key: string }[]
  ) => {
    const catKeys = catPermissions.map((p) => p.key);
    const allSelected = catKeys.every((k) => currentList.includes(k));

    if (allSelected) {
      setList(currentList.filter((k) => !catKeys.includes(k)));
    } else {
      const merged = Array.from(new Set([...currentList, ...catKeys]));
      setList(merged);
    }
  };

  // Dynamic user count by role
  const roleCounts: Record<string, number> = {};
  roles.forEach((r) => {
    roleCounts[r.key] = r.user_count || 0;
  });

  // Switch to users tab with a preselected filter
  const handleViewUsersForRole = (roleKey: string) => {
    setSelectedRoleFilter(roleKey);
    setActiveTab("users");
  };

  // Filtered Users List
  const filteredUsers = useMemo(() => {
    return users.filter((u) => {
      const matchRole =
        selectedRoleFilter === "all" ||
        u.role === selectedRoleFilter ||
        (selectedRoleFilter === "superadmin" && (u.role === "superadmin" || u.role === "owner"));
      const matchSearch =
        searchQuery === "" ||
        u.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        u.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        u.employee?.nik?.toLowerCase().includes(searchQuery.toLowerCase());
      return matchRole && matchSearch;
    });
  }, [users, selectedRoleFilter, searchQuery]);

  const getRoleDefinition = (roleKey: string) => {
    return (
      roles.find((r) => r.key === roleKey) ||
      (roleKey === "superadmin" || roleKey === "owner"
        ? roles.find((r) => r.key === "superadmin" || r.key === "owner")
        : null) || {
        key: roleKey,
        label:
          roleKey === "superadmin" || roleKey === "owner"
            ? "Super Admin"
            : roleKey.charAt(0).toUpperCase() + roleKey.slice(1),
        badgeClass: "bg-purple-50 text-purple-700 border-purple-200/80",
        description: "Administrator tertinggi dengan hak akses mutlak dan wewenang penuh di seluruh modul sistem.",
        permissions: [],
      }
    );
  };

  // Thematic styling per role
  const getRoleMeta = (roleKey: string) => {
    switch (roleKey) {
      case "superadmin":
      case "super_admin":
      case "owner":
        return {
          icon: Crown,
          iconColor: "text-purple-600",
          iconBg: "bg-purple-50 border-purple-200/80 text-purple-700",
          cardBorderHover: "hover:border-purple-300",
          gradientBar: "from-purple-500 to-indigo-600",
          accentRing: "ring-purple-500/20",
          badgeColor: "bg-purple-50 text-purple-700 border-purple-200/80",
        };
      case "hr":
        return {
          icon: ShieldCheck,
          iconColor: "text-indigo-600",
          iconBg: "bg-indigo-50 border-indigo-200/80 text-indigo-700",
          cardBorderHover: "hover:border-indigo-300",
          gradientBar: "from-indigo-500 to-blue-600",
          accentRing: "ring-indigo-500/20",
          badgeColor: "bg-indigo-50 text-indigo-700 border-indigo-200/80",
        };
      case "manager":
        return {
          icon: UserCheck,
          iconColor: "text-amber-600",
          iconBg: "bg-amber-50 border-amber-200/80 text-amber-700",
          cardBorderHover: "hover:border-amber-300",
          gradientBar: "from-amber-500 to-orange-500",
          accentRing: "ring-amber-500/20",
          badgeColor: "bg-amber-50 text-amber-700 border-amber-200/80",
        };
      case "employee":
        return {
          icon: User,
          iconColor: "text-emerald-600",
          iconBg: "bg-emerald-50 border-emerald-200/80 text-emerald-700",
          cardBorderHover: "hover:border-emerald-300",
          gradientBar: "from-emerald-500 to-teal-600",
          accentRing: "ring-emerald-500/20",
          badgeColor: "bg-emerald-50 text-emerald-700 border-emerald-200/80",
        };
      default:
        return {
          icon: Sliders,
          iconColor: "text-blue-600",
          iconBg: "bg-blue-50 border-blue-200/80 text-blue-700",
          cardBorderHover: "hover:border-blue-300",
          gradientBar: "from-blue-500 to-cyan-600",
          accentRing: "ring-blue-500/20",
          badgeColor: "bg-blue-50 text-blue-700 border-blue-200/80",
        };
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-16">
      {/* 1. TOP PAGE HEADER WITH BREADCRUMB & CONTEXT */}
      <div className="space-y-2">
        <div className="flex items-center gap-2 text-xs font-medium text-slate-500 select-none">
          <span>Pengaturan & Keamanan</span>
          <span className="text-slate-300">/</span>
          <span className="text-emerald-700 font-semibold">Hak Akses & Role</span>
        </div>

        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pt-0.5">
          <div>
            <div className="flex items-center gap-2.5 flex-wrap">
              <h1 className="text-2xl sm:text-[26px] font-extrabold tracking-tight text-[#0B2545] leading-tight">
                Hak Akses & Manajemen Role
              </h1>
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-bold tracking-wide uppercase bg-emerald-50 text-emerald-700 border border-emerald-200/80 shadow-2xs">
                <ShieldCheck className="w-3 h-3 text-emerald-600" aria-hidden="true" />
                Kontrol Akses Terpusat
              </span>
            </div>
            <p className="text-xs sm:text-sm text-slate-500 mt-1.5 font-normal max-w-2xl leading-relaxed">
              Atur hak akses modular, konfigurasi matriks wewenang operasional tiap peran, dan kelola penugasan akun staf PT SPINDO.
            </p>
          </div>

          {/* Global Action Buttons */}
          <div className="flex items-center gap-2.5 flex-wrap sm:flex-nowrap flex-shrink-0">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              leftIcon={<RotateCcw className="w-3.5 h-3.5 text-slate-500" aria-hidden="true" />}
              onClick={() => setIsResetConfirmOpen(true)}
              className="text-xs font-semibold cursor-pointer active:scale-[0.98] border-slate-200/90 hover:bg-slate-50"
            >
              Reset Standar
            </Button>
            <Button
              type="button"
              variant="primary"
              size="sm"
              leftIcon={<Plus className="w-4 h-4" aria-hidden="true" />}
              onClick={handleOpenAddRoleModal}
              className="text-xs font-bold shadow-xs cursor-pointer active:scale-[0.98]"
            >
              Tambah Role Baru
            </Button>
          </div>
        </div>
      </div>

      {/* Global Status Feedback Notice */}
      {actionNotice && (
        <div
          role="status"
          className="rounded-2xl border border-emerald-200/90 bg-emerald-50/90 backdrop-blur-sm p-4 text-xs text-emerald-800 flex items-center justify-between gap-2.5 shadow-2xs animate-fade-in-up"
        >
          <div className="flex items-center gap-2.5 min-w-0">
            <CheckCircle2 className="w-4 h-4 text-emerald-600 flex-shrink-0" aria-hidden="true" />
            <p className="font-semibold truncate">{actionNotice}</p>
          </div>
          <button
            type="button"
            onClick={() => setActionNotice(null)}
            className="p-1 rounded-lg text-emerald-600 hover:bg-emerald-100/70 transition-colors cursor-pointer"
            aria-label="Tutup notifikasi"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* 2. EXECUTIVE METRICS BAR: CLEAN, PURPOSEFUL HIERARCHY */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3.5 sm:gap-4">
        {/* Card 1: Total Role */}
        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-slate-200/80 shadow-[0_1px_3px_rgba(0,0,0,0.02)] hover:border-slate-300 transition-all flex flex-col justify-between group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500">Total Role Terdaftar</span>
            <div className="w-9 h-9 rounded-xl bg-slate-100 border border-slate-200/80 text-slate-700 flex items-center justify-center flex-shrink-0 shadow-2xs group-hover:scale-105 transition-transform">
              <KeyRound className="w-4 h-4 stroke-[2]" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-4">
            <div className="flex items-baseline gap-2">
              <span className="text-2xl sm:text-3xl font-extrabold text-[#0B2545] tracking-tight tabular-nums">
                {roles.length}
              </span>
              <span className="text-[11px] font-bold text-slate-500 bg-slate-100 px-2 py-0.5 rounded-full border border-slate-200/60">
                {roles.filter((r) => r.is_system).length} Bawaan
              </span>
            </div>
            <span className="text-[11px] text-slate-400 font-normal mt-1 block">
              Peran wewenang aktif organisasi
            </span>
          </div>
        </div>

        {/* Card 2: Role Sistem */}
        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-slate-200/80 shadow-[0_1px_3px_rgba(0,0,0,0.02)] hover:border-purple-300 transition-all flex flex-col justify-between group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500">Role Sistem</span>
            <div className="w-9 h-9 rounded-xl bg-purple-50 border border-purple-200/80 text-purple-700 flex items-center justify-center flex-shrink-0 shadow-2xs group-hover:scale-105 transition-transform">
              <Lock className="w-4 h-4 stroke-[2]" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-4">
            <div className="flex items-baseline gap-2">
              <span className="text-2xl sm:text-3xl font-extrabold text-purple-700 tracking-tight tabular-nums">
                {roles.filter((r) => r.is_system).length}
              </span>
              <span className="text-[11px] font-bold text-purple-700 bg-purple-50 px-2 py-0.5 rounded-full border border-purple-200/70">
                Terproteksi
              </span>
            </div>
            <span className="text-[11px] text-slate-400 font-normal mt-1 block">
              Super Admin, HR, Manager, Karyawan
            </span>
          </div>
        </div>

        {/* Card 3: Role Kustom */}
        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-slate-200/80 shadow-[0_1px_3px_rgba(0,0,0,0.02)] hover:border-emerald-300 transition-all flex flex-col justify-between group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500">Role Kustom</span>
            <div className="w-9 h-9 rounded-xl bg-emerald-50 border border-emerald-200/80 text-emerald-700 flex items-center justify-center flex-shrink-0 shadow-2xs group-hover:scale-105 transition-transform">
              <Sliders className="w-4 h-4 stroke-[2]" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-4">
            <div className="flex items-baseline gap-2">
              <span className="text-2xl sm:text-3xl font-extrabold text-emerald-700 tracking-tight tabular-nums">
                {roles.filter((r) => !r.is_system).length}
              </span>
              <span className="text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200/70">
                Kustom Perusahaan
              </span>
            </div>
            <span className="text-[11px] text-slate-400 font-normal mt-1 block">
              Dapat ditambah & dihapus kapan saja
            </span>
          </div>
        </div>

        {/* Card 4: Akun Terhubung */}
        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-slate-200/80 shadow-[0_1px_3px_rgba(0,0,0,0.02)] hover:border-amber-300 transition-all flex flex-col justify-between group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500">Akun Pengguna Terpetakan</span>
            <div className="w-9 h-9 rounded-xl bg-amber-50 border border-amber-200/80 text-amber-700 flex items-center justify-center flex-shrink-0 shadow-2xs group-hover:scale-105 transition-transform">
              <Users className="w-4 h-4 stroke-[2]" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-4">
            <div className="flex items-baseline gap-2">
              <span className="text-2xl sm:text-3xl font-extrabold text-amber-700 tracking-tight tabular-nums">
                {users.length}
              </span>
              <span className="text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200/70">
                {users.filter((u) => u.is_active).length} Aktif
              </span>
            </div>
            <span className="text-[11px] text-slate-400 font-normal mt-1 block">
              Seluruh staf terasosiasi dengan role
            </span>
          </div>
        </div>
      </div>

      {/* 3. SEGMENTED NAVIGATION TABS */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-slate-200/80 gap-3 pb-px">
        <div className="inline-flex p-1 rounded-2xl bg-slate-100/90 border border-slate-200/70 backdrop-blur-sm gap-1 self-start">
          <button
            type="button"
            onClick={() => setActiveTab("roles")}
            className={`flex items-center gap-2.5 px-4 py-2 text-xs font-bold rounded-xl transition-all cursor-pointer active:scale-[0.98] ${
              activeTab === "roles"
                ? "bg-white text-[#0B2545] shadow-2xs border border-slate-200/70"
                : "text-slate-600 hover:text-slate-900 hover:bg-white/40"
            }`}
          >
            <Settings2 className="w-3.5 h-3.5 text-emerald-600" aria-hidden="true" />
            <span>Konfigurasi & Wewenang Role</span>
            <span
              className={`px-2 py-0.2 rounded-full text-[10px] font-extrabold tabular-nums transition-colors ${
                activeTab === "roles"
                  ? "bg-emerald-100/80 text-emerald-800"
                  : "bg-slate-200/70 text-slate-600"
              }`}
            >
              {roles.length}
            </span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab("users")}
            className={`flex items-center gap-2.5 px-4 py-2 text-xs font-bold rounded-xl transition-all cursor-pointer active:scale-[0.98] ${
              activeTab === "users"
                ? "bg-white text-[#0B2545] shadow-2xs border border-slate-200/70"
                : "text-slate-600 hover:text-slate-900 hover:bg-white/40"
            }`}
          >
            <Users className="w-3.5 h-3.5 text-indigo-600" aria-hidden="true" />
            <span>Penugasan Akun Pengguna</span>
            <span
              className={`px-2 py-0.2 rounded-full text-[10px] font-extrabold tabular-nums transition-colors ${
                activeTab === "users"
                  ? "bg-indigo-100/80 text-indigo-800"
                  : "bg-slate-200/70 text-slate-600"
              }`}
            >
              {users.length}
            </span>
          </button>
        </div>

        <div className="hidden md:flex items-center gap-2 text-xs text-slate-500 font-medium">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" aria-hidden="true" />
          <span>Sistem Otoritas PT SPINDO</span>
        </div>
      </div>

      {/* ======================================================== */}
      {/* TAB 1: KONFIGURASI ROLE & HAK AKSES                      */}
      {/* ======================================================== */}
      {activeTab === "roles" && (
        <div className="space-y-6">
          {isLoadingRoles ? (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
              {[1, 2, 3, 4].map((i) => (
                <div
                  key={i}
                  className="p-6 rounded-2xl border border-slate-200 bg-white animate-pulse space-y-4"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-2xl bg-slate-200" />
                    <div className="space-y-1.5 flex-1">
                      <div className="h-4 w-32 bg-slate-200 rounded" />
                      <div className="h-3 w-48 bg-slate-100 rounded" />
                    </div>
                  </div>
                  <div className="h-24 bg-slate-50 rounded-xl" />
                  <div className="h-10 bg-slate-100 rounded-xl" />
                </div>
              ))}
            </div>
          ) : isErrorRoles ? (
            <Card>
              <div className="p-6">
                <ErrorState
                  title="Gagal Memuat Konfigurasi Role"
                  message={
                    rolesError instanceof Error ? rolesError.message : "Terjadi kendala pada server."
                  }
                  onRetry={() => refetchRoles()}
                />
              </div>
            </Card>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
              {roles.map((role) => {
                const isSystem = !!role.is_system;
                const userCount = role.user_count || 0;
                const permissionsList = role.permissions || [];
                const activeModules = FUNCTIONAL_MODULES.filter((m) => m.test(permissionsList));
                const totalModules = FUNCTIONAL_MODULES.length;
                const coveragePercent = Math.round((activeModules.length / totalModules) * 100);
                const roleMeta = getRoleMeta(role.key);
                const IconComponent = roleMeta.icon;

                return (
                  <div
                    key={role.key}
                    className={`p-6 rounded-2xl border border-slate-200/90 bg-white hover:shadow-sm ${roleMeta.cardBorderHover} transition-all duration-200 flex flex-col justify-between group`}
                  >
                    <div>
                      {/* Top Header: Avatar + Title + Badges */}
                      <div className="flex items-start justify-between gap-3 mb-3.5">
                        <div className="flex items-start gap-3.5">
                          <div
                            className={`w-12 h-12 rounded-2xl border flex items-center justify-center flex-shrink-0 shadow-2xs ${roleMeta.iconBg} group-hover:scale-105 transition-transform`}
                          >
                            <IconComponent className="w-6 h-6 stroke-[2]" aria-hidden="true" />
                          </div>
                          <div>
                            <div className="flex items-center gap-2 flex-wrap">
                              <h2 className="text-base sm:text-lg font-bold text-[#0B2545] tracking-tight">
                                {role.label}
                              </h2>
                              <span className="font-mono text-[10px] text-slate-500 bg-slate-100 px-2 py-0.5 rounded-md border border-slate-200/70 font-semibold">
                                {role.key}
                              </span>
                            </div>

                            <div className="flex items-center gap-2 mt-1">
                              {isSystem ? (
                                <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-slate-500 bg-slate-100/80 px-2 py-0.5 rounded-md border border-slate-200/60">
                                  <Lock className="w-3 h-3 text-slate-400" aria-hidden="true" />
                                  Role Bawaan Sistem
                                </span>
                              ) : (
                                <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md border border-emerald-200/70">
                                  <Sliders className="w-3 h-3 text-emerald-600" aria-hidden="true" />
                                  Role Kustom Perusahaan
                                </span>
                              )}
                            </div>
                          </div>
                        </div>

                        {/* Interactive User Pill: Click to jump to filtered users */}
                        <button
                          type="button"
                          onClick={() => handleViewUsersForRole(role.key)}
                          title={`Lihat ${userCount} akun dengan role ${role.label}`}
                          className="inline-flex items-center gap-1.5 text-xs font-bold text-slate-700 hover:text-emerald-700 bg-slate-50 hover:bg-emerald-50 px-3 py-1.5 rounded-xl border border-slate-200/80 hover:border-emerald-200/80 shadow-2xs flex-shrink-0 transition-all cursor-pointer active:scale-95"
                        >
                          <Users className="w-3.5 h-3.5 text-slate-500" aria-hidden="true" />
                          <span className="tabular-nums">{userCount}</span>
                          <span className="text-slate-500 font-normal">akun</span>
                          <ArrowRight className="w-3 h-3 text-slate-400 ml-0.5" />
                        </button>
                      </div>

                      {/* Role Description */}
                      <p className="text-xs sm:text-[13px] text-slate-600 font-normal leading-relaxed mb-4 min-h-[38px]">
                        {role.description || "Tidak ada deskripsi khusus untuk role wewenang ini."}
                      </p>

                      {/* Functional Module Coverage Box */}
                      <div className="p-4 rounded-xl bg-slate-50/80 border border-slate-200/80 mb-5 space-y-3">
                        <div className="flex items-center justify-between text-xs">
                          <div className="flex items-center gap-1.5 font-bold text-slate-800">
                            <Shield className="w-4 h-4 text-emerald-600" aria-hidden="true" />
                            <span>Cakupan Modul Operasional</span>
                          </div>
                          <span className="text-[11px] font-bold text-slate-600 tabular-nums">
                            {activeModules.length} dari {totalModules} modul ({coveragePercent}%)
                          </span>
                        </div>

                        {/* Visual Progress Bar */}
                        <div className="w-full bg-slate-200/80 rounded-full h-1.5 overflow-hidden">
                          <div
                            className={`h-full rounded-full transition-all duration-300 ${
                              coveragePercent >= 80
                                ? "bg-emerald-600"
                                : coveragePercent >= 40
                                ? "bg-indigo-600"
                                : "bg-amber-600"
                            }`}
                            style={{ width: `${coveragePercent}%` }}
                          />
                        </div>

                        {/* Functional Feature Tags (Clean, Readable Pills) */}
                        <div className="flex flex-wrap gap-1.5 pt-1">
                          {activeModules.length > 0 ? (
                            activeModules.map((module) => {
                              const ModuleIcon = module.icon;
                              return (
                                <span
                                  key={module.key}
                                  className="inline-flex items-center gap-1.5 text-[11px] font-medium text-slate-700 bg-white px-2.5 py-1 rounded-lg border border-slate-200/80 shadow-2xs"
                                >
                                  <ModuleIcon className="w-3 h-3 text-slate-500" aria-hidden="true" />
                                  <span>{module.label}</span>
                                </span>
                              );
                            })
                          ) : (
                            <span className="text-xs text-slate-400 italic">
                              Tidak ada hak akses operasional yang aktif
                            </span>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Bottom Action Footer */}
                    <div className="pt-3.5 border-t border-slate-100 flex items-center justify-between gap-2.5">
                      <Button
                        type="button"
                        variant="secondary"
                        size="sm"
                        leftIcon={<Settings2 className="w-3.5 h-3.5 text-slate-600" aria-hidden="true" />}
                        onClick={() => handleOpenEditRoleModal(role)}
                        className="text-xs font-semibold flex-1 justify-center active:scale-[0.98] cursor-pointer"
                      >
                        Atur Hak Akses & Wewenang
                      </Button>

                      {/* Custom roles deletion button */}
                      {!isSystem && (
                        <button
                          type="button"
                          onClick={() => setDeletingRole(role)}
                          aria-label={`Hapus role ${role.label}`}
                          className="p-2 rounded-xl text-slate-400 hover:text-rose-600 hover:bg-rose-50 border border-slate-200/80 hover:border-rose-200 transition-colors cursor-pointer active:scale-95"
                          title="Hapus role kustom"
                        >
                          <Trash2 className="w-4 h-4" aria-hidden="true" />
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* ======================================================== */}
      {/* TAB 2: DAFTAR PENGGUNA & PENUGASAN ROLE                  */}
      {/* ======================================================== */}
      {activeTab === "users" && (
        <Card className="shadow-2xs overflow-hidden">
          <CardHeader className="p-5 sm:p-6 border-b border-slate-100 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
              <CardTitle className="text-base sm:text-lg">Daftar Pengguna & Penugasan Role</CardTitle>
              <p className="text-xs sm:text-sm text-slate-500 mt-1 font-normal">
                Ubah penugasan role akun staf atau atur status akses operasional login.
              </p>
            </div>

            {/* User Search Input */}
            <div className="relative w-full md:w-72">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              <input
                type="search"
                placeholder="Cari nama, email, NIK..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-9 pr-8 py-2 rounded-xl bg-slate-50 border border-slate-200 text-xs text-slate-800 placeholder:text-slate-400 focus:outline-none focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/15 transition-all shadow-2xs"
              />
              {searchQuery && (
                <button
                  type="button"
                  onClick={() => setSearchQuery("")}
                  className="absolute right-2.5 top-1/2 -translate-y-1/2 p-0.5 text-slate-400 hover:text-slate-600"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              )}
            </div>
          </CardHeader>

          {/* Role Filter Chips Bar */}
          <div className="px-5 sm:px-6 py-3 border-b border-slate-100 bg-slate-50/60 flex items-center gap-1.5 overflow-x-auto scrollbar-none">
            <button
              type="button"
              onClick={() => setSelectedRoleFilter("all")}
              className={`px-3 py-1.5 text-xs font-bold rounded-xl transition-all cursor-pointer whitespace-nowrap active:scale-[0.98] ${
                selectedRoleFilter === "all"
                  ? "bg-white text-[#0B2545] shadow-2xs border border-slate-200/90"
                  : "text-slate-600 hover:text-slate-900 hover:bg-white/60"
              }`}
            >
              Semua Akun ({users.length})
            </button>
            {roles.map((r) => {
              const count = roleCounts[r.key] || 0;
              const isSelected = selectedRoleFilter === r.key;
              return (
                <button
                  key={r.key}
                  type="button"
                  onClick={() => setSelectedRoleFilter(r.key)}
                  className={`px-3 py-1.5 text-xs font-bold rounded-xl transition-all cursor-pointer whitespace-nowrap active:scale-[0.98] flex items-center gap-1.5 ${
                    isSelected
                      ? "bg-white text-[#0B2545] shadow-2xs border border-slate-200/90"
                      : "text-slate-600 hover:text-slate-900 hover:bg-white/60"
                  }`}
                >
                  <span>{r.label}</span>
                  <span
                    className={`px-1.5 py-0.2 rounded-md text-[10px] font-extrabold ${
                      isSelected ? "bg-slate-100 text-slate-800" : "bg-slate-200/60 text-slate-600"
                    }`}
                  >
                    {count}
                  </span>
                </button>
              );
            })}
          </div>

          {isLoadingUsers ? (
            <TableSkeleton rows={5} columns={5} />
          ) : isErrorUsers ? (
            <div className="p-6">
              <ErrorState
                title="Gagal Memuat Daftar Pengguna"
                message={
                  usersError instanceof Error ? usersError.message : "Terjadi kendala pada server."
                }
                onRetry={() => refetchUsers()}
              />
            </div>
          ) : filteredUsers.length === 0 ? (
            <div className="p-8">
              <EmptyState
                title="Tidak ada pengguna ditemukan"
                description={
                  searchQuery
                    ? `Tidak ada hasil pencarian untuk "${searchQuery}".`
                    : selectedRoleFilter === "all"
                    ? "Belum ada akun pengguna yang terdaftar."
                    : `Tidak ada akun yang ditugaskan ke role ini.`
                }
                actionLabel={searchQuery || selectedRoleFilter !== "all" ? "Reset Filter" : undefined}
                onAction={() => {
                  setSearchQuery("");
                  setSelectedRoleFilter("all");
                }}
              />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="bg-slate-50/80 border-b border-slate-200/70 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                    <th scope="col" className="px-5 sm:px-6 py-3.5">
                      Pengguna & Email
                    </th>
                    <th scope="col" className="px-5 sm:px-6 py-3.5">
                      Profil Pegawai
                    </th>
                    <th scope="col" className="px-5 sm:px-6 py-3.5">
                      Role Wewenang
                    </th>
                    <th scope="col" className="px-5 sm:px-6 py-3.5 text-center">
                      Status Akun
                    </th>
                    <th scope="col" className="px-5 sm:px-6 py-3.5 text-right">
                      Aksi
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredUsers.map((user) => {
                    const roleDef = getRoleDefinition(user.role);
                    const roleMeta = getRoleMeta(user.role);
                    return (
                      <tr key={user.id_users} className="hover:bg-slate-50/70 transition-colors">
                        <td className="px-5 sm:px-6 py-4">
                          <div className="flex items-center gap-3">
                            <div
                              className={`w-9 h-9 rounded-xl border flex items-center justify-center font-bold text-xs flex-shrink-0 shadow-2xs ${roleMeta.iconBg}`}
                            >
                              {user.name.charAt(0).toUpperCase()}
                            </div>
                            <div className="min-w-0">
                              <div className="font-bold text-slate-900 truncate">{user.name}</div>
                              <div className="text-xs text-slate-500 font-normal truncate">{user.email}</div>
                            </div>
                          </div>
                        </td>
                        <td className="px-5 sm:px-6 py-4 text-xs text-slate-600">
                          {user.employee ? (
                            <div className="space-y-0.5">
                              <div className="font-semibold text-slate-800 flex items-center gap-1.5">
                                <Briefcase className="w-3.5 h-3.5 text-slate-400" aria-hidden="true" />
                                <span>{user.employee.job_position?.name || "Staf Operasional"}</span>
                                <span className="text-slate-400 font-mono text-[11px]">
                                  ({user.employee.nik})
                                </span>
                              </div>
                              <div className="text-slate-500 flex items-center gap-1.5">
                                <Building className="w-3.5 h-3.5 text-slate-400" aria-hidden="true" />
                                <span>{user.employee.branch?.name || "Kantor Pusat"}</span>
                              </div>
                            </div>
                          ) : (
                            <span className="text-slate-400 italic text-xs">Akun Sistem / Non-staf</span>
                          )}
                        </td>
                        <td className="px-5 sm:px-6 py-4">
                          <span
                            className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-bold border tracking-tight shadow-2xs ${
                              roleDef.badgeClass || "bg-slate-100 text-slate-700 border-slate-200"
                            }`}
                          >
                            <span>{roleDef.label}</span>
                          </span>
                        </td>
                        <td className="px-5 sm:px-6 py-4 text-center">
                          <span
                            className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold border tracking-tight shadow-2xs ${
                              user.is_active
                                ? "bg-emerald-50 text-emerald-700 border-emerald-200/80"
                                : "bg-rose-50 text-rose-700 border-rose-200/80"
                            }`}
                          >
                            <span
                              className={`w-1.5 h-1.5 rounded-full ${
                                user.is_active ? "bg-emerald-500" : "bg-rose-500"
                              }`}
                              aria-hidden="true"
                            />
                            <span>{user.is_active ? "Aktif" : "Nonaktif"}</span>
                          </span>
                        </td>
                        <td className="px-5 sm:px-6 py-4 text-right">
                          <div className="flex items-center justify-end gap-1.5">
                            <button
                              type="button"
                              onClick={() => handleOpenUserRoleModal(user)}
                              aria-label={`Ubah role ${user.name}`}
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold rounded-xl text-slate-700 bg-slate-100 hover:bg-emerald-50 hover:text-emerald-700 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 cursor-pointer"
                            >
                              <Edit2 className="w-3.5 h-3.5" aria-hidden="true" />
                              <span>Ubah Role</span>
                            </button>
                            <button
                              type="button"
                              onClick={() => setTogglingUser(user)}
                              title={user.is_active ? "Nonaktifkan Akun" : "Aktifkan Akun"}
                              aria-label={
                                user.is_active
                                  ? `Nonaktifkan akun ${user.name}`
                                  : `Aktifkan akun ${user.name}`
                              }
                              className={`p-2 rounded-xl transition-all active:scale-95 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 ${
                                user.is_active
                                  ? "text-slate-400 hover:text-rose-600 hover:bg-rose-50 border border-transparent hover:border-rose-100"
                                  : "text-emerald-600 hover:bg-emerald-50 border border-transparent hover:border-emerald-100"
                              }`}
                            >
                              <Power className="w-4 h-4" aria-hidden="true" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>

              {/* Table Footer Count Indicator */}
              <div className="px-6 py-3.5 border-t border-slate-100 bg-slate-50/50 flex items-center justify-between text-xs text-slate-500 font-medium">
                <span>
                  Menampilkan <strong className="text-slate-800">{filteredUsers.length}</strong> dari{" "}
                  <strong className="text-slate-800">{users.length}</strong> pengguna
                </span>
                {selectedRoleFilter !== "all" && (
                  <button
                    type="button"
                    onClick={() => setSelectedRoleFilter("all")}
                    className="text-emerald-700 font-semibold hover:underline cursor-pointer"
                  >
                    Tampilkan Semua Role
                  </button>
                )}
              </div>
            </div>
          )}
        </Card>
      )}

      {/* ======================================================== */}
      {/* MODAL: TAMBAH ROLE BARU (UI/UX PRO MAX)                  */}
      {/* ======================================================== */}
      <Modal
        isOpen={isAddRoleModalOpen}
        onClose={() => setIsAddRoleModalOpen(false)}
        title="Tambah Role Kustom Baru"
        description="Buat role wewenang baru dan tetapkan izin modul operasional untuk organisasi Anda."
        maxWidth="2xl"
        footer={
          <div className="flex items-center justify-between w-full">
            <span className="text-xs text-slate-500 font-medium hidden sm:inline-block">
              <strong className="text-slate-800">{addRolePermissions.length}</strong> izin modul dipilih
            </span>
            <div className="flex items-center justify-end gap-2.5">
              <Button
                type="button"
                variant="secondary"
                size="sm"
                onClick={() => setIsAddRoleModalOpen(false)}
              >
                Batal
              </Button>
              <Button
                form="add-role-form"
                type="submit"
                variant="primary"
                size="sm"
                isLoading={createRoleMutation.isPending}
              >
                Simpan Role Baru
              </Button>
            </div>
          </div>
        }
      >
        <form id="add-role-form" onSubmit={handleSaveAddRole} className="space-y-5">
          {addRoleError && (
            <div
              role="alert"
              className="rounded-2xl border border-rose-200/80 bg-rose-50/80 p-3.5 text-xs text-rose-700 flex items-start gap-2 animate-fade-in-up"
            >
              <AlertCircle className="w-4 h-4 text-rose-600 flex-shrink-0 mt-0.5" aria-hidden="true" />
              <p className="font-semibold">{addRoleError}</p>
            </div>
          )}

          {/* Role Identifiers */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">
                Nama Role <span className="text-rose-500">*</span>
              </label>
              <input
                type="text"
                required
                placeholder="Contoh: Finance & Accounting"
                value={addRoleName}
                onChange={(e) => {
                  setAddRoleName(e.target.value);
                  if (!addRoleKey) {
                    setAddRoleKey(e.target.value.toLowerCase().replace(/[^a-z0-9]/g, "_"));
                  }
                }}
                className="w-full px-3.5 py-2.5 text-xs rounded-xl border border-slate-200 bg-slate-50 focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/15 transition-all shadow-2xs"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">
                Kode Identitas Slug (Unik)
              </label>
              <input
                type="text"
                placeholder="Contoh: finance"
                value={addRoleKey}
                onChange={(e) => setAddRoleKey(e.target.value.toLowerCase().replace(/[^a-z0-9_\-]/g, ""))}
                className="w-full px-3.5 py-2.5 text-xs rounded-xl border border-slate-200 bg-slate-50 focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/15 font-mono transition-all shadow-2xs"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">
              Deskripsi Wewenang
            </label>
            <input
              type="text"
              placeholder="Contoh: Pengelola kompensasi gaji dan verifikasi data payroll pegawai."
              value={addRoleDescription}
              onChange={(e) => setAddRoleDescription(e.target.value)}
              className="w-full px-3.5 py-2.5 text-xs rounded-xl border border-slate-200 bg-slate-50 focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/15 transition-all shadow-2xs"
            />
          </div>

          {/* Badge Color Swatches with Live Preview */}
          <div className="p-4 rounded-2xl bg-slate-50/80 border border-slate-200/80 space-y-3">
            <div className="flex items-center justify-between">
              <label className="block text-xs font-bold text-slate-800">
                Pilihan Warna Badge Tampilan
              </label>
              <div className="flex items-center gap-2">
                <span className="text-[11px] text-slate-400">Pratinjau:</span>
                <span className={`px-2.5 py-0.5 rounded-lg border text-xs font-bold ${addRoleBadgeClass}`}>
                  {addRoleName.trim() || "Nama Role"}
                </span>
              </div>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              {BADGE_COLOR_OPTIONS.map((badge) => {
                const isSelected = addRoleBadgeClass === badge.value;
                return (
                  <button
                    key={badge.label}
                    type="button"
                    onClick={() => setAddRoleBadgeClass(badge.value)}
                    className={`flex items-center justify-between px-3 py-2 rounded-xl border text-xs font-semibold transition-all cursor-pointer ${
                      isSelected
                        ? "border-emerald-600 ring-2 ring-emerald-600/20 bg-white shadow-2xs"
                        : "border-slate-200/90 hover:border-slate-300 bg-white"
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      <span className={`w-2.5 h-2.5 rounded-full ${badge.dot}`} />
                      <span className="text-[11px] text-slate-700">{badge.label}</span>
                    </div>
                    {isSelected && <Check className="w-3.5 h-3.5 text-emerald-600" />}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Categorized Permission Matrix */}
          <div>
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2.5">
              <div>
                <label className="block text-xs font-bold text-slate-800">
                  Pilih Hak Akses Modul Operasional
                </label>
                <span className="text-[11px] text-slate-400 font-normal">
                  Pilih wewenang yang diizinkan untuk role ini.
                </span>
              </div>

              <div className="flex items-center gap-2.5 text-xs">
                <button
                  type="button"
                  onClick={() => {
                    const allKeys = availablePermissions.flatMap((c) => c.permissions.map((p) => p.key));
                    setAddRolePermissions(allKeys);
                  }}
                  className="text-emerald-700 hover:underline font-bold cursor-pointer"
                >
                  Pilih Semua
                </button>
                <span className="text-slate-300">•</span>
                <button
                  type="button"
                  onClick={() => setAddRolePermissions([])}
                  className="text-slate-500 hover:underline font-semibold cursor-pointer"
                >
                  Kosongkan
                </button>
              </div>
            </div>

            {/* Quick Search Permissions */}
            <div className="relative mb-3">
              <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              <input
                type="search"
                placeholder="Cari izin modul (contoh: payroll, cuti, shift)..."
                value={addPermSearchQuery}
                onChange={(e) => setAddPermSearchQuery(e.target.value)}
                className="w-full pl-8 pr-3 py-1.5 rounded-xl bg-slate-50 border border-slate-200 text-xs text-slate-800 placeholder:text-slate-400 focus:outline-none focus:bg-white focus:border-emerald-600"
              />
            </div>

            {/* Scrollable Categories List */}
            <div className="max-h-72 overflow-y-auto pr-1.5 space-y-3.5 divide-y divide-slate-100 border border-slate-200/90 rounded-2xl p-3.5 bg-slate-50/50">
              {availablePermissions.map((cat) => {
                const catFilteredPerms = cat.permissions.filter(
                  (p) =>
                    !addPermSearchQuery ||
                    p.label.toLowerCase().includes(addPermSearchQuery.toLowerCase()) ||
                    p.key.toLowerCase().includes(addPermSearchQuery.toLowerCase()) ||
                    p.description.toLowerCase().includes(addPermSearchQuery.toLowerCase())
                );

                if (catFilteredPerms.length === 0) return null;

                const catKeys = cat.permissions.map((p) => p.key);
                const allCatSelected = catKeys.every((k) => addRolePermissions.includes(k));

                return (
                  <div key={cat.category} className="pt-3 first:pt-0">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-bold text-[#0B2545] flex items-center gap-1.5">
                        <Layers className="w-3.5 h-3.5 text-slate-400" />
                        <span>{cat.category}</span>
                      </span>
                      <button
                        type="button"
                        onClick={() =>
                          toggleCategoryPermissions(
                            addRolePermissions,
                            setAddRolePermissions,
                            cat.permissions
                          )
                        }
                        className="text-[11px] font-bold text-emerald-700 hover:text-emerald-800 cursor-pointer"
                      >
                        {allCatSelected ? "Batal Kategori" : "Pilih Kategori"}
                      </button>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                      {catFilteredPerms.map((perm) => {
                        const isChecked = addRolePermissions.includes(perm.key);
                        return (
                          <label
                            key={perm.key}
                            className={`flex items-start gap-2.5 p-2.5 rounded-xl border text-xs cursor-pointer transition-all ${
                              isChecked
                                ? "bg-white border-emerald-500 ring-1 ring-emerald-500/20 shadow-2xs"
                                : "bg-white/70 border-slate-200/80 hover:bg-white hover:border-slate-300"
                            }`}
                          >
                            <input
                              type="checkbox"
                              checked={isChecked}
                              onChange={() =>
                                togglePermission(addRolePermissions, setAddRolePermissions, perm.key)
                              }
                              className="mt-0.5 text-emerald-600 accent-emerald-600 rounded focus:ring-emerald-500 w-4 h-4"
                            />
                            <div className="min-w-0 flex-1">
                              <span className="font-bold text-slate-900 block text-xs leading-tight">
                                {perm.label}
                              </span>
                              <span className="text-[11px] text-slate-500 font-normal line-clamp-1 mt-0.5">
                                {perm.description}
                              </span>
                            </div>
                          </label>
                        );
                      })}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </form>
      </Modal>

      {/* ======================================================== */}
      {/* MODAL: KONFIGURASI ROLE & PERMISSIONS (UI/UX PRO MAX)     */}
      {/* ======================================================== */}
      <Modal
        isOpen={isEditRoleModalOpen}
        onClose={() => setIsEditRoleModalOpen(false)}
        title={`Konfigurasi Role: ${editingRole?.label || ""}`}
        description="Atur nama tampilan, deskripsi wewenang, dan izin akses modul operasional untuk role ini."
        maxWidth="2xl"
        footer={
          <div className="flex items-center justify-between w-full">
            <span className="text-xs text-slate-500 font-medium hidden sm:inline-block">
              <strong className="text-slate-800">{editRolePermissions.length}</strong> izin modul aktif
            </span>
            <div className="flex items-center justify-end gap-2.5">
              <Button
                type="button"
                variant="secondary"
                size="sm"
                onClick={() => setIsEditRoleModalOpen(false)}
              >
                Batal
              </Button>
              <Button
                form="edit-role-form"
                type="submit"
                variant="primary"
                size="sm"
                isLoading={updateRoleConfigMutation.isPending}
              >
                Simpan Konfigurasi
              </Button>
            </div>
          </div>
        }
      >
        <form id="edit-role-form" onSubmit={handleSaveRoleConfig} className="space-y-5">
          {editRoleError && (
            <div
              role="alert"
              className="rounded-2xl border border-rose-200/80 bg-rose-50/80 p-3.5 text-xs text-rose-700 flex items-start gap-2 animate-fade-in-up"
            >
              <AlertCircle className="w-4 h-4 text-rose-600 flex-shrink-0 mt-0.5" aria-hidden="true" />
              <p className="font-semibold">{editRoleError}</p>
            </div>
          )}

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">
                Nama Tampilan Role <span className="text-rose-500">*</span>
              </label>
              <input
                type="text"
                required
                value={editRoleLabel}
                onChange={(e) => setEditRoleLabel(e.target.value)}
                className="w-full px-3.5 py-2.5 text-xs rounded-xl border border-slate-200 bg-slate-50 focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/15 transition-all shadow-2xs font-semibold"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">
                Kode Identitas Slug (Kunci Sistem)
              </label>
              <input
                type="text"
                disabled
                value={editingRole?.key || ""}
                className="w-full px-3.5 py-2.5 text-xs rounded-xl border border-slate-200 bg-slate-100 text-slate-500 cursor-not-allowed font-mono shadow-2xs"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">
              Deskripsi Wewenang
            </label>
            <input
              type="text"
              value={editRoleDescription}
              onChange={(e) => setEditRoleDescription(e.target.value)}
              className="w-full px-3.5 py-2.5 text-xs rounded-xl border border-slate-200 bg-slate-50 focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/15 transition-all shadow-2xs"
            />
          </div>

          {/* Badge Color Swatches with Live Preview */}
          <div className="p-4 rounded-2xl bg-slate-50/80 border border-slate-200/80 space-y-3">
            <div className="flex items-center justify-between">
              <label className="block text-xs font-bold text-slate-800">
                Warna Badge Tampilan
              </label>
              <div className="flex items-center gap-2">
                <span className="text-[11px] text-slate-400">Pratinjau:</span>
                <span className={`px-2.5 py-0.5 rounded-lg border text-xs font-bold ${editRoleBadgeClass}`}>
                  {editRoleLabel.trim() || editingRole?.key}
                </span>
              </div>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              {BADGE_COLOR_OPTIONS.map((badge) => {
                const isSelected = editRoleBadgeClass === badge.value;
                return (
                  <button
                    key={badge.label}
                    type="button"
                    onClick={() => setEditRoleBadgeClass(badge.value)}
                    className={`flex items-center justify-between px-3 py-2 rounded-xl border text-xs font-semibold transition-all cursor-pointer ${
                      isSelected
                        ? "border-emerald-600 ring-2 ring-emerald-600/20 bg-white shadow-2xs"
                        : "border-slate-200/90 hover:border-slate-300 bg-white"
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      <span className={`w-2.5 h-2.5 rounded-full ${badge.dot}`} />
                      <span className="text-[11px] text-slate-700">{badge.label}</span>
                    </div>
                    {isSelected && <Check className="w-3.5 h-3.5 text-emerald-600" />}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Categorized Permissions Matrix */}
          <div>
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2.5">
              <div>
                <label className="block text-xs font-bold text-slate-800">
                  Hak Akses Modul Operasional
                </label>
                <span className="text-[11px] text-slate-400 font-normal">
                  Centang modul yang berhak diakses oleh pengguna dengan role ini.
                </span>
              </div>

              <div className="flex items-center gap-2.5 text-xs">
                <button
                  type="button"
                  onClick={() => {
                    const allKeys = availablePermissions.flatMap((c) => c.permissions.map((p) => p.key));
                    setEditRolePermissions(allKeys);
                  }}
                  className="text-emerald-700 hover:underline font-bold cursor-pointer"
                >
                  Pilih Semua
                </button>
                <span className="text-slate-300">•</span>
                <button
                  type="button"
                  onClick={() => setEditRolePermissions([])}
                  className="text-slate-500 hover:underline font-semibold cursor-pointer"
                >
                  Kosongkan
                </button>
              </div>
            </div>

            {/* Quick Search Permissions */}
            <div className="relative mb-3">
              <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              <input
                type="search"
                placeholder="Cari izin modul (contoh: payroll, cuti, shift)..."
                value={editPermSearchQuery}
                onChange={(e) => setEditPermSearchQuery(e.target.value)}
                className="w-full pl-8 pr-3 py-1.5 rounded-xl bg-slate-50 border border-slate-200 text-xs text-slate-800 placeholder:text-slate-400 focus:outline-none focus:bg-white focus:border-emerald-600"
              />
            </div>

            {/* Scrollable Categories List */}
            <div className="max-h-72 overflow-y-auto pr-1.5 space-y-3.5 divide-y divide-slate-100 border border-slate-200/90 rounded-2xl p-3.5 bg-slate-50/50">
              {availablePermissions.map((cat) => {
                const catFilteredPerms = cat.permissions.filter(
                  (p) =>
                    !editPermSearchQuery ||
                    p.label.toLowerCase().includes(editPermSearchQuery.toLowerCase()) ||
                    p.key.toLowerCase().includes(editPermSearchQuery.toLowerCase()) ||
                    p.description.toLowerCase().includes(editPermSearchQuery.toLowerCase())
                );

                if (catFilteredPerms.length === 0) return null;

                const catKeys = cat.permissions.map((p) => p.key);
                const allCatSelected = catKeys.every((k) => editRolePermissions.includes(k));

                return (
                  <div key={cat.category} className="pt-3 first:pt-0">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-bold text-[#0B2545] flex items-center gap-1.5">
                        <Layers className="w-3.5 h-3.5 text-slate-400" />
                        <span>{cat.category}</span>
                      </span>
                      <button
                        type="button"
                        onClick={() =>
                          toggleCategoryPermissions(
                            editRolePermissions,
                            setEditRolePermissions,
                            cat.permissions
                          )
                        }
                        className="text-[11px] font-bold text-emerald-700 hover:text-emerald-800 cursor-pointer"
                      >
                        {allCatSelected ? "Batal Kategori" : "Pilih Kategori"}
                      </button>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                      {catFilteredPerms.map((perm) => {
                        const isChecked = editRolePermissions.includes(perm.key);
                        return (
                          <label
                            key={perm.key}
                            className={`flex items-start gap-2.5 p-2.5 rounded-xl border text-xs cursor-pointer transition-all ${
                              isChecked
                                ? "bg-white border-emerald-500 ring-1 ring-emerald-500/20 shadow-2xs"
                                : "bg-white/70 border-slate-200/80 hover:bg-white hover:border-slate-300"
                            }`}
                          >
                            <input
                              type="checkbox"
                              checked={isChecked}
                              onChange={() =>
                                togglePermission(editRolePermissions, setEditRolePermissions, perm.key)
                              }
                              className="mt-0.5 text-emerald-600 accent-emerald-600 rounded focus:ring-emerald-500 w-4 h-4"
                            />
                            <div className="min-w-0 flex-1">
                              <span className="font-bold text-slate-900 block text-xs leading-tight">
                                {perm.label}
                              </span>
                              <span className="text-[11px] text-slate-500 font-normal line-clamp-1 mt-0.5">
                                {perm.description}
                              </span>
                            </div>
                          </label>
                        );
                      })}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </form>
      </Modal>

      {/* ======================================================== */}
      {/* MODAL: UBAH ROLE PENUGASAN PENGGUNA (UI/UX PRO MAX)      */}
      {/* ======================================================== */}
      <Modal
        isOpen={isUserRoleModalOpen}
        onClose={() => setIsUserRoleModalOpen(false)}
        title="Ubah Hak Akses & Penugasan Role"
        description={
          selectedUser
            ? `Atur penugasan role wewenang untuk ${selectedUser.name} (${selectedUser.email}).`
            : "Pilih peran baru untuk akun ini."
        }
        maxWidth="lg"
        footer={
          <div className="flex items-center justify-end gap-2.5 w-full">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              onClick={() => setIsUserRoleModalOpen(false)}
            >
              Batal
            </Button>
            <Button
              form="change-role-form"
              type="submit"
              variant="primary"
              size="sm"
              isLoading={updateUserRoleMutation.isPending}
            >
              Simpan Role Baru
            </Button>
          </div>
        }
      >
        <form id="change-role-form" onSubmit={handleSaveUserRole} className="space-y-4">
          {userRoleModalError && (
            <div
              role="alert"
              className="rounded-2xl border border-rose-200/80 bg-rose-50/80 p-3.5 text-xs text-rose-700 flex items-start gap-2 animate-fade-in-up"
            >
              <AlertCircle className="w-4 h-4 text-rose-600 flex-shrink-0 mt-0.5" aria-hidden="true" />
              <p className="font-semibold">{userRoleModalError}</p>
            </div>
          )}

          {/* User Card Summary */}
          {selectedUser && (
            <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-200/80 flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-700 font-bold text-sm flex items-center justify-center flex-shrink-0">
                {selectedUser.name.charAt(0).toUpperCase()}
              </div>
              <div className="min-w-0 flex-1">
                <div className="font-bold text-slate-900 text-xs truncate">{selectedUser.name}</div>
                <div className="text-[11px] text-slate-500 truncate">{selectedUser.email}</div>
                <div className="text-[10px] text-slate-400 mt-0.5">
                  Role Saat Ini:{" "}
                  <strong className="text-slate-700">
                    {getRoleDefinition(selectedUser.role).label}
                  </strong>
                </div>
              </div>
            </div>
          )}

          <div className="space-y-2.5">
            <label className="block text-xs font-bold text-slate-700">
              Pilih Role Wewenang Baru <span className="text-rose-500">*</span>
            </label>

            <div className="grid grid-cols-1 gap-2.5 max-h-80 overflow-y-auto pr-1">
              {roles.map((def) => {
                const isSelected = newRoleForUser === def.key;
                const roleMeta = getRoleMeta(def.key);
                const IconComponent = roleMeta.icon;

                return (
                  <label
                    key={def.key}
                    className={`flex items-start gap-3 p-3.5 rounded-2xl border transition-all cursor-pointer ${
                      isSelected
                        ? "border-emerald-600 bg-emerald-50/40 ring-2 ring-emerald-600/20 shadow-2xs"
                        : "border-slate-200/80 hover:border-slate-300 bg-white"
                    }`}
                  >
                    <input
                      type="radio"
                      name="user-role"
                      value={def.key}
                      checked={isSelected}
                      onChange={() => setNewRoleForUser(def.key)}
                      className="mt-1 text-emerald-600 accent-emerald-600 focus:ring-emerald-500 w-4 h-4"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <IconComponent className={`w-4 h-4 ${roleMeta.iconColor}`} />
                        <span className="text-xs font-bold text-slate-900">{def.label}</span>
                        <span
                          className={`text-[10px] font-bold px-2 py-0.5 rounded-full border shadow-2xs ${
                            def.badgeClass || "bg-slate-100 text-slate-700 border-slate-200"
                          }`}
                        >
                          {def.key}
                        </span>
                      </div>
                      <p className="text-xs text-slate-500 mt-1 leading-relaxed">
                        {def.description || "Tidak ada deskripsi"}
                      </p>
                    </div>
                  </label>
                );
              })}
            </div>
          </div>
        </form>
      </Modal>

      {/* ======================================================== */}
      {/* MODAL: HAPUS ROLE KUSTOM                                 */}
      {/* ======================================================== */}
      <Modal
        isOpen={!!deletingRole}
        onClose={() => setDeletingRole(null)}
        title="Konfirmasi Hapus Role Kustom"
        maxWidth="md"
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              onClick={() => setDeletingRole(null)}
            >
              Batal
            </Button>
            <Button
              type="button"
              variant="danger"
              size="sm"
              isLoading={deleteRoleMutation.isPending}
              disabled={!!(deletingRole && (deletingRole.user_count || 0) > 0)}
              onClick={() => deletingRole && deleteRoleMutation.mutate(deletingRole.key)}
            >
              Hapus Role
            </Button>
          </div>
        }
      >
        <div className="flex items-start gap-3 py-2">
          <div className="p-2.5 rounded-xl flex-shrink-0 bg-rose-50 text-rose-600">
            <AlertTriangle className="w-5 h-5" />
          </div>
          <div className="space-y-1.5">
            <p className="text-sm text-slate-700">
              Apakah Anda yakin ingin menghapus role kustom{" "}
              <strong className="text-slate-900">{deletingRole?.label}</strong>?
            </p>
            {deletingRole && (deletingRole.user_count || 0) > 0 ? (
              <div className="p-3 rounded-xl bg-amber-50 border border-amber-200 text-xs text-amber-800">
                Role ini saat ini masih digunakan oleh <strong>{deletingRole.user_count} akun</strong>.
                Pindahkan pengguna ke role lain terlebih dahulu sebelum menghapus role ini.
              </div>
            ) : (
              <p className="text-xs text-slate-500">
                Tindakan ini permanen dan akan menghapus konfigurasi hak akses role tersebut dari sistem organisasi Anda.
              </p>
            )}
          </div>
        </div>
      </Modal>

      {/* ======================================================== */}
      {/* MODAL: RESET ROLES KE DEFAULT STANDAR                   */}
      {/* ======================================================== */}
      <Modal
        isOpen={isResetConfirmOpen}
        onClose={() => setIsResetConfirmOpen(false)}
        title="Reset Konfigurasi Role ke Standar"
        maxWidth="md"
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              onClick={() => setIsResetConfirmOpen(false)}
            >
              Batal
            </Button>
            <Button
              type="button"
              variant="danger"
              size="sm"
              isLoading={resetRolesMutation.isPending}
              onClick={() => resetRolesMutation.mutate()}
            >
              Reset ke Standar
            </Button>
          </div>
        }
      >
        <div className="flex items-start gap-3 py-2">
          <div className="p-2.5 rounded-xl flex-shrink-0 bg-amber-50 text-amber-600">
            <RotateCcw className="w-5 h-5" />
          </div>
          <div className="space-y-1.5">
            <p className="text-sm text-slate-700">
              Apakah Anda yakin ingin mereset seluruh konfigurasi role kembali ke standar sistem?
            </p>
            <p className="text-xs text-slate-500 leading-relaxed">
              Seluruh modifikasi izin permission dan role kustom akan dikembalikan ke konfigurasi bawaan (Super Admin, HR, Manager, Karyawan).
            </p>
          </div>
        </div>
      </Modal>

      {/* ======================================================== */}
      {/* MODAL: KONFIRMASI STATUS AKUN (AKTIF / NONAKTIF)        */}
      {/* ======================================================== */}
      <Modal
        isOpen={!!togglingUser}
        onClose={() => setTogglingUser(null)}
        title={togglingUser?.is_active ? "Konfirmasi Nonaktifkan Akun" : "Konfirmasi Aktifkan Akun"}
        maxWidth="md"
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              onClick={() => setTogglingUser(null)}
            >
              Batal
            </Button>
            <Button
              type="button"
              variant={togglingUser?.is_active ? "danger" : "primary"}
              size="sm"
              isLoading={toggleStatusMutation.isPending}
              onClick={() => togglingUser && toggleStatusMutation.mutate(togglingUser.id_users)}
            >
              {togglingUser?.is_active ? "Nonaktifkan Akun" : "Aktifkan Akun"}
            </Button>
          </div>
        }
      >
        <div className="flex items-start gap-3 py-2">
          <div
            className={`p-2.5 rounded-xl flex-shrink-0 ${
              togglingUser?.is_active
                ? "bg-rose-50 text-rose-600"
                : "bg-emerald-50 text-emerald-600"
            }`}
          >
            <AlertTriangle className="w-5 h-5" />
          </div>
          <div>
            <p className="text-sm text-slate-700">
              Apakah Anda yakin ingin {togglingUser?.is_active ? "menonaktifkan" : "mengaktifkan"}{" "}
              akun <strong className="text-slate-900">{togglingUser?.name}</strong>?
            </p>
            <p className="text-xs text-slate-500 mt-1 leading-relaxed">
              {togglingUser?.is_active
                ? "Pengguna tidak akan dapat login ke aplikasi seluler maupun dashboard web."
                : "Pengguna akan dapat kembali login dan menggunakan hak akses sesuai role-nya."}
            </p>
          </div>
        </div>
      </Modal>
    </div>
  );
}
