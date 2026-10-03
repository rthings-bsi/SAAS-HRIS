"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Building2,
  CheckCircle2,
  Clock,
  AlertTriangle,
  Users,
  Search,
  RotateCcw,
  Edit3,
  Trash2,
  Phone,
  Mail,
  ShieldCheck,
  X,
  Calendar,
  ChevronDown,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { Modal } from "@/components/ui/Modal";
import apiClient from "@/lib/axios";
import { formatDate, cn } from "@/lib/utils";
import type {
  ApiResponse,
  PlatformStats,
  CompanyWithCounts,
  SubscriptionStatus,
} from "@/types";

interface PaginatedCompanies {
  current_page: number;
  data: CompanyWithCounts[];
  total: number;
  last_page: number;
}

// Generate distinct monogram initials for enterprise branding
const getCompanyInitials = (name: string): string => {
  const cleanName = name.replace(/^(PT|CV|UD)\.?\s+/i, "").trim();
  const parts = cleanName.split(/\s+/);
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return cleanName.slice(0, 2).toUpperCase() || "CO";
};

// Deterministic pleasing palette for company avatars
const companyPalettes = [
  { bg: "bg-blue-50", text: "text-blue-700", border: "border-blue-200/80" },
  { bg: "bg-orange-50", text: "text-orange-700", border: "border-orange-200/80" },
  { bg: "bg-emerald-50", text: "text-emerald-700", border: "border-emerald-200/80" },
  { bg: "bg-purple-50", text: "text-purple-700", border: "border-purple-200/80" },
  { bg: "bg-indigo-50", text: "text-indigo-700", border: "border-indigo-200/80" },
  { bg: "bg-amber-50", text: "text-amber-700", border: "border-amber-200/80" },
  { bg: "bg-cyan-50", text: "text-cyan-700", border: "border-cyan-200/80" },
];

const getCompanyColor = (id: number) => {
  return companyPalettes[id % companyPalettes.length];
};

// Calculate remaining trial days
const getTrialInfo = (trialEndsAt?: string | null) => {
  if (!trialEndsAt) {
    return { text: "14 hari aktif", isExpired: false, badgeClass: "text-amber-700 bg-amber-50 border-amber-200" };
  }
  const endDate = new Date(trialEndsAt);
  const now = new Date();
  const diffTime = endDate.getTime() - now.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays < 0) {
    return {
      text: "Masa uji coba berakhir",
      isExpired: true,
      badgeClass: "text-rose-700 bg-rose-50 border-rose-200",
    };
  }
  if (diffDays === 0) {
    return {
      text: "Berakhir hari ini",
      isExpired: false,
      badgeClass: "text-amber-700 bg-amber-50 border-amber-200",
    };
  }
  return {
    text: `Sisa ${diffDays} hari lagi`,
    isExpired: false,
    badgeClass: "text-amber-700 bg-amber-50 border-amber-200",
  };
};

export function SuperAdminDashboardView() {
  const queryClient = useQueryClient();

  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("");
  const [selectedCompany, setSelectedCompany] = useState<CompanyWithCounts | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);

  // Form edit states
  const [editStatus, setEditStatus] = useState<SubscriptionStatus>("active");
  const [editTrialEndsAt, setEditTrialEndsAt] = useState<string>("");
  const [editAddress, setEditAddress] = useState<string>("");
  const [editPhone, setEditPhone] = useState<string>("");
  const [formError, setFormError] = useState<string | null>(null);

  // Query 1: Platform SaaS Stats
  const {
    data: stats,
    isLoading: isStatsLoading,
    isError: isStatsError,
    error: statsError,
    refetch: refetchStats,
    isRefetching: isStatsRefetching,
  } = useQuery({
    queryKey: ["superadmin-stats"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<PlatformStats>>(
        "/superadmin/stats"
      );
      if (response.data.success && response.data.data) {
        return response.data.data;
      }
      throw new Error(response.data.message || "Gagal memuat statistik platform.");
    },
  });

  // Query 2: Tenant Companies List
  const {
    data: companiesData,
    isLoading: isCompaniesLoading,
    isError: isCompaniesError,
    error: companiesError,
    refetch: refetchCompanies,
    isRefetching: isCompaniesRefetching,
  } = useQuery({
    queryKey: ["superadmin-companies", search, statusFilter],
    queryFn: async () => {
      const params: Record<string, string> = {};
      if (search.trim()) params.search = search.trim();
      if (statusFilter) params.status = statusFilter;

      const response = await apiClient.get<ApiResponse<PaginatedCompanies>>(
        "/superadmin/companies",
        { params }
      );
      if (response.data.success && response.data.data) {
        return response.data.data;
      }
      throw new Error(response.data.message || "Gagal memuat daftar tenant.");
    },
  });

  const isRefreshing = isStatsRefetching || isCompaniesRefetching;

  // Mutation: Update Company Subscription
  const updateMutation = useMutation({
    mutationFn: async ({
      id_companies,
      payload,
    }: {
      id_companies: number;
      payload: {
        subscription_status: SubscriptionStatus;
        trial_ends_at?: string | null;
        address?: string;
        phone?: string;
      };
    }) => {
      const response = await apiClient.put<ApiResponse<CompanyWithCounts>>(
        `/superadmin/companies/${id_companies}`,
        payload
      );
      if (!response.data.success) {
        throw new Error(response.data.message || "Gagal memperbarui status tenant.");
      }
      return response.data.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["superadmin-companies"] });
      queryClient.invalidateQueries({ queryKey: ["superadmin-stats"] });
      setIsEditModalOpen(false);
      setSelectedCompany(null);
      setFormError(null);
    },
    onError: (err: unknown) => {
      if (err instanceof Error) {
        setFormError(err.message);
      } else {
        setFormError("Terjadi kendala saat memperbarui tenant.");
      }
    },
  });

  // Mutation: Delete Company
  const deleteMutation = useMutation({
    mutationFn: async (id_companies: number) => {
      const response = await apiClient.delete<ApiResponse<null>>(
        `/superadmin/companies/${id_companies}`
      );
      if (!response.data.success) {
        throw new Error(response.data.message || "Gagal menghapus tenant.");
      }
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["superadmin-companies"] });
      queryClient.invalidateQueries({ queryKey: ["superadmin-stats"] });
      setIsDeleteModalOpen(false);
      setSelectedCompany(null);
    },
    onError: (err: unknown) => {
      if (err instanceof Error) {
        alert(err.message);
      } else {
        alert("Terjadi kendala saat menghapus tenant.");
      }
    },
  });

  const openEditModal = (company: CompanyWithCounts) => {
    setSelectedCompany(company);
    setEditStatus(company.subscription_status);
    setEditTrialEndsAt(
      company.trial_ends_at ? company.trial_ends_at.split("T")[0] : ""
    );
    setEditAddress(company.address || "");
    setEditPhone(company.phone || "");
    setFormError(null);
    setIsEditModalOpen(true);
  };

  const openDeleteModal = (company: CompanyWithCounts) => {
    setSelectedCompany(company);
    setIsDeleteModalOpen(true);
  };

  const handleSaveEdit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedCompany) return;

    updateMutation.mutate({
      id_companies: selectedCompany.id_companies,
      payload: {
        subscription_status: editStatus,
        trial_ends_at: editStatus === "trial" ? editTrialEndsAt || null : null,
        address: editAddress,
        phone: editPhone,
      },
    });
  };

  const statCards = [
    {
      label: "Total Tenant Terdaftar",
      value: isStatsLoading ? "..." : String(stats?.total_companies ?? 0),
      unit: "perusahaan",
      subtext: "Semua akun tenant di database",
      badge: "Database",
      icon: Building2,
      color: "text-blue-600",
      bg: "bg-blue-50",
      border: "border-blue-100",
      pillBg: "bg-blue-50 text-blue-700 border-blue-200/60",
    },
    {
      label: "Langganan Aktif",
      value: isStatsLoading ? "..." : String(stats?.active_companies ?? 0),
      unit: "perusahaan",
      subtext: "Pelanggan berbayar operasional",
      badge: "Berbayar",
      icon: CheckCircle2,
      color: "text-emerald-600",
      bg: "bg-emerald-50",
      border: "border-emerald-100",
      pillBg: "bg-emerald-50 text-emerald-700 border-emerald-200/60",
    },
    {
      label: "Masa Uji Coba (Trial)",
      value: isStatsLoading ? "..." : String(stats?.trial_companies ?? 0),
      unit: "perusahaan",
      subtext: "Masa evaluasi 14 hari",
      badge: "Evaluasi",
      icon: Clock,
      color: "text-amber-600",
      bg: "bg-amber-50",
      border: "border-amber-100",
      pillBg: "bg-amber-50 text-amber-700 border-amber-200/60",
    },
    {
      label: "Ditangguhkan / Suspended",
      value: isStatsLoading ? "..." : String(stats?.suspended_companies ?? 0),
      unit: "perusahaan",
      subtext: "Akses dibekukan sementara",
      badge: "Nonaktif",
      icon: AlertTriangle,
      color: "text-rose-600",
      bg: "bg-rose-50",
      border: "border-rose-100",
      pillBg: "bg-rose-50 text-rose-700 border-rose-200/60",
    },
    {
      label: "Total Karyawan Ekosistem",
      value: isStatsLoading ? "..." : String(stats?.total_employees ?? 0),
      unit: "orang",
      subtext: "Pegawai terdaftar di seluruh tenant",
      badge: "Ekosistem",
      icon: Users,
      color: "text-purple-600",
      bg: "bg-purple-50",
      border: "border-purple-100",
      pillBg: "bg-purple-50 text-purple-700 border-purple-200/60",
    },
  ];

  const companiesList = companiesData?.data || [];

  const filterTabs = [
    { label: "Semua", value: "", count: stats?.total_companies },
    { label: "Aktif", value: "active", count: stats?.active_companies },
    { label: "Uji Coba", value: "trial", count: stats?.trial_companies },
    { label: "Ditangguhkan", value: "suspended", count: stats?.suspended_companies },
  ];

  return (
    <div className="space-y-6 sm:space-y-7">
      {/* Header Halaman Modern & Elegan */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2.5 flex-wrap">
            <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-slate-900">
              Ringkasan Platform SaaS
            </h1>
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold rounded-full bg-slate-900 text-white shadow-2xs">
              <ShieldCheck className="w-3.5 h-3.5 text-purple-400" />
              <span>Superadmin</span>
            </span>
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-medium rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200/70">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>Sistem Normal</span>
            </span>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 font-normal mt-1.5 max-w-2xl leading-relaxed">
            Pantau pertumbuhan tenant pelanggan, aktivasi langganan berbayar, dan skala
            penggunaan seluruh ekosistem HRIS multi-tenant.
          </p>
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-2.5 self-start sm:self-auto">
          <Button
            variant="secondary"
            size="sm"
            onClick={() => {
              refetchStats();
              refetchCompanies();
            }}
            disabled={isRefreshing}
            className="rounded-xl border-slate-200/90 hover:bg-slate-50 text-slate-700 font-semibold shadow-2xs gap-2"
          >
            <RotateCcw
              className={cn("w-3.5 h-3.5 text-slate-500", isRefreshing && "animate-spin text-orange-600")}
            />
            <span>{isRefreshing ? "Menyinkronkan..." : "Segarkan Data"}</span>
          </Button>
        </div>
      </div>

      {/* Grid 5 Kartu Metrik Platform SaaS */}
      {isStatsError ? (
        <ErrorState
          title="Gagal Memuat Statistik Platform"
          message={
            statsError instanceof Error
              ? statsError.message
              : "Terjadi kesalahan saat memuat data statistik."
          }
          onRetry={() => refetchStats()}
        />
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
          {statCards.map((stat) => {
            const Icon = stat.icon;
            return (
              <div
                key={stat.label}
                className="group relative rounded-2xl border border-slate-200/80 bg-white/95 backdrop-blur-md p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03),0_1px_2px_rgba(0,0,0,0.02)] hover:shadow-xs hover:border-slate-300 active:scale-[0.99] transition-all duration-200 flex flex-col justify-between"
              >
                <div>
                  <div className="flex items-start justify-between gap-2">
                    <span className="text-xs font-semibold text-slate-500 leading-tight">
                      {stat.label}
                    </span>
                    <div
                      className={cn(
                        "w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 transition-transform duration-200 group-hover:scale-105 border",
                        stat.bg,
                        stat.border
                      )}
                      aria-hidden="true"
                    >
                      <Icon className={cn("w-4 h-4", stat.color)} />
                    </div>
                  </div>

                  <div className="mt-3 flex items-baseline gap-1.5">
                    <span className="text-3xl font-bold tracking-tight text-slate-900 tabular-nums">
                      {stat.value}
                    </span>
                    <span className="text-xs font-medium text-slate-500">
                      {stat.unit}
                    </span>
                  </div>
                </div>

                <div className="mt-3 pt-3 border-t border-slate-100 flex items-center justify-between text-[11.5px]">
                  <span className="text-slate-400 font-normal truncate mr-2">
                    {stat.subtext}
                  </span>
                  <span
                    className={cn(
                      "px-2 py-0.5 rounded-full text-[10.5px] font-semibold border flex-shrink-0",
                      stat.pillBg
                    )}
                  >
                    {stat.badge}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Tabel Manajemen Tenant Pelanggan */}
      <div className="rounded-2xl lg:rounded-3xl border border-slate-200/80 bg-white/95 backdrop-blur-md shadow-[0_1px_3px_rgba(0,0,0,0.03),0_1px_2px_rgba(0,0,0,0.02)] overflow-hidden">
        {/* Header & Filter Bar */}
        <div className="p-5 sm:p-6 border-b border-slate-100 space-y-4">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-base sm:text-lg font-bold tracking-tight text-slate-900">
                  Daftar Perusahaan Pelanggan (Tenant)
                </h2>
                <span className="inline-flex items-center justify-center px-2 py-0.5 text-xs font-semibold rounded-full bg-slate-100 text-slate-700 tabular-nums">
                  {companiesData?.total ?? 0}
                </span>
              </div>
              <p className="text-xs text-slate-500 font-normal mt-0.5">
                Kelola status langganan operasional, masa uji coba, dan hak akses tiap perusahaan klien SaaS.
              </p>
            </div>

            {/* Quick Search & Select */}
            <div className="flex flex-wrap items-center gap-2.5">
              <div className="relative min-w-[220px] flex-1 sm:flex-initial">
                <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400 pointer-events-none" />
                <input
                  type="text"
                  placeholder="Cari nama, email, slug..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full rounded-xl border border-slate-200 bg-white/90 py-2 pl-9 pr-8 text-xs text-slate-900 placeholder:text-slate-400 focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20 transition-all"
                />
                {search && (
                  <button
                    type="button"
                    onClick={() => setSearch("")}
                    aria-label="Bersihkan pencarian"
                    className="absolute right-2.5 top-2.5 p-0.5 rounded-md text-slate-400 hover:text-slate-700 hover:bg-slate-100 cursor-pointer"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                )}
              </div>

              {/* Status Dropdown */}
              <div className="relative">
                <select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  aria-label="Filter status langganan"
                  className="appearance-none rounded-xl border border-slate-200 bg-white/90 pl-3 pr-8 py-2 text-xs font-medium text-slate-700 focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20 transition-all cursor-pointer shadow-2xs active:scale-[0.98]"
                >
                  <option value="">Semua Status</option>
                  <option value="active">Aktif</option>
                  <option value="trial">Masa Uji Coba</option>
                  <option value="suspended">Ditangguhkan</option>
                  <option value="cancelled">Dibatalkan</option>
                </select>
                <ChevronDown className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-3 pointer-events-none" />
              </div>
            </div>
          </div>

          {/* Quick Filter Pill Buttons */}
          <div className="flex items-center gap-1.5 overflow-x-auto pt-1 pb-0.5">
            {filterTabs.map((tab) => {
              const isSelected = statusFilter === tab.value;
              return (
                <button
                  key={tab.label}
                  type="button"
                  onClick={() => setStatusFilter(tab.value)}
                  className={cn(
                    "inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold rounded-xl transition-all cursor-pointer select-none active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600",
                    isSelected
                      ? "bg-orange-50 text-orange-700 border border-orange-200 shadow-2xs"
                      : "text-slate-600 hover:bg-slate-100/80 border border-transparent"
                  )}
                >
                  <span>{tab.label}</span>
                  {tab.count !== undefined && (
                    <span
                      className={cn(
                        "text-[10px] px-1.5 py-0.2 rounded-full font-bold tabular-nums",
                        isSelected
                          ? "bg-orange-200/60 text-orange-800"
                          : "bg-slate-100 text-slate-500"
                      )}
                    >
                      {tab.count}
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* Table Content */}
        <div>
          {isCompaniesLoading ? (
            <div className="p-6">
              <TableSkeleton rows={5} columns={6} />
            </div>
          ) : isCompaniesError ? (
            <div className="p-6">
              <ErrorState
                title="Gagal Memuat Daftar Perusahaan"
                message={
                  companiesError instanceof Error
                    ? companiesError.message
                    : "Terjadi kesalahan saat memuat data tenant."
                }
                onRetry={() => refetchCompanies()}
              />
            </div>
          ) : companiesList.length === 0 ? (
            <div className="p-10">
              <EmptyState
                title="Tidak Ada Tenant Ditemukan"
                description={
                  search || statusFilter
                    ? "Tidak ada perusahaan yang sesuai dengan kriteria filter pencarian."
                    : "Belum ada tenant perusahaan yang terdaftar dalam sistem."
                }
                actionLabel={search || statusFilter ? "Reset Filter" : undefined}
                onAction={
                  search || statusFilter
                    ? () => {
                        setSearch("");
                        setStatusFilter("");
                      }
                    : undefined
                }
              />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs text-slate-900 border-collapse">
                <thead>
                  <tr className="bg-slate-50/90 backdrop-blur-xs border-b border-slate-200/80 text-[11px] font-bold text-slate-500 uppercase tracking-wider select-none">
                    <th scope="col" className="px-5 py-3.5">
                      Perusahaan
                    </th>
                    <th scope="col" className="px-4 py-3.5">
                      Kontak
                    </th>
                    <th scope="col" className="px-3 py-3.5 text-center">
                      Cabang
                    </th>
                    <th scope="col" className="px-3 py-3.5 text-center">
                      User
                    </th>
                    <th scope="col" className="px-3 py-3.5 text-center">
                      Karyawan
                    </th>
                    <th scope="col" className="px-4 py-3.5">
                      Status Langganan
                    </th>
                    <th scope="col" className="px-4 py-3.5">
                      Batas Trial / Masa Aktif
                    </th>
                    <th scope="col" className="px-5 py-3.5 text-right">
                      Aksi
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {companiesList.map((company) => {
                    const initials = getCompanyInitials(company.name);
                    const colorScheme = getCompanyColor(company.id_companies);
                    const trialInfo = getTrialInfo(company.trial_ends_at);

                    return (
                      <tr
                        key={company.id_companies}
                        className="hover:bg-slate-50/70 transition-colors group"
                      >
                        {/* 1. Perusahaan Monogram & Details */}
                        <td className="px-5 py-3.5">
                          <div className="flex items-center gap-3">
                            <div
                              className={cn(
                                "w-9 h-9 rounded-xl flex items-center justify-center font-bold text-xs flex-shrink-0 border transition-transform group-hover:scale-105 duration-200 shadow-2xs",
                                colorScheme.bg,
                                colorScheme.text,
                                colorScheme.border
                              )}
                            >
                              {initials}
                            </div>
                            <div className="min-w-0">
                              <div className="font-bold text-slate-900 text-sm leading-tight group-hover:text-orange-600 transition-colors truncate">
                                {company.name}
                              </div>
                              <div className="flex items-center gap-1.5 mt-0.5">
                                <span className="text-[11px] text-slate-400 font-mono">
                                  /{company.slug}
                                </span>
                              </div>
                            </div>
                          </div>
                        </td>

                        {/* 2. Kontak (Email & Phone) */}
                        <td className="px-4 py-3.5">
                          <div className="space-y-1">
                            <div className="flex items-center gap-1.5 text-xs text-slate-600">
                              <Mail className="w-3.5 h-3.5 text-slate-400 flex-shrink-0" />
                              <span className="truncate max-w-[200px]" title={company.email}>
                                {company.email}
                              </span>
                            </div>
                            {company.phone && (
                              <div className="flex items-center gap-1.5 text-[11px] text-slate-500">
                                <Phone className="w-3 h-3 text-slate-400 flex-shrink-0" />
                                <span>{company.phone}</span>
                              </div>
                            )}
                          </div>
                        </td>

                        {/* 3. Cabang */}
                        <td className="px-3 py-3.5 text-center">
                          <span className="inline-flex items-center justify-center min-w-[26px] h-6 px-1.5 text-xs font-semibold rounded-lg bg-slate-100 text-slate-700 tabular-nums">
                            {company.branches_count ?? 0}
                          </span>
                        </td>

                        {/* 4. User */}
                        <td className="px-3 py-3.5 text-center">
                          <span className="inline-flex items-center justify-center min-w-[26px] h-6 px-1.5 text-xs font-semibold rounded-lg bg-slate-100 text-slate-700 tabular-nums">
                            {company.users_count ?? 0}
                          </span>
                        </td>

                        {/* 5. Karyawan */}
                        <td className="px-3 py-3.5 text-center">
                          <span className="inline-flex items-center justify-center min-w-[26px] h-6 px-1.5 text-xs font-semibold rounded-lg bg-blue-50 text-blue-700 border border-blue-100 tabular-nums">
                            {company.employees_count ?? 0}
                          </span>
                        </td>

                        {/* 6. Status Langganan Pill */}
                        <td className="px-4 py-3.5">
                          {company.subscription_status === "active" ? (
                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200/70">
                              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                              <span>Aktif</span>
                            </span>
                          ) : company.subscription_status === "trial" ? (
                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold rounded-full bg-amber-50 text-amber-700 border border-amber-200/70">
                              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
                              <span>Masa Uji Coba</span>
                            </span>
                          ) : company.subscription_status === "suspended" ? (
                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold rounded-full bg-rose-50 text-rose-700 border border-rose-200/70">
                              <span className="w-1.5 h-1.5 rounded-full bg-rose-500" />
                              <span>Ditangguhkan</span>
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold rounded-full bg-slate-100 text-slate-600 border border-slate-200">
                              <span className="w-1.5 h-1.5 rounded-full bg-slate-400" />
                              <span>Dibatalkan</span>
                            </span>
                          )}
                        </td>

                        {/* 7. Batas Trial / Masa Aktif */}
                        <td className="px-4 py-3.5 text-xs">
                          {company.subscription_status === "trial" ? (
                            <div className="space-y-1">
                              <div className="flex items-center gap-1.5 text-slate-700 font-medium tabular-nums">
                                <Calendar className="w-3.5 h-3.5 text-amber-500 flex-shrink-0" />
                                <span>
                                  {company.trial_ends_at
                                    ? formatDate(new Date(company.trial_ends_at))
                                    : "14 hari aktif"}
                                </span>
                              </div>
                              <span
                                className={cn(
                                  "inline-flex items-center px-1.5 py-0.5 text-[10.5px] font-semibold rounded-md border",
                                  trialInfo.badgeClass
                                )}
                              >
                                {trialInfo.text}
                              </span>
                            </div>
                          ) : company.subscription_status === "active" ? (
                            <div className="flex items-center gap-1.5 text-emerald-700 font-semibold">
                              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500 flex-shrink-0" />
                              <span>Langganan Aktif</span>
                            </div>
                          ) : (
                            <div className="flex items-center gap-1.5 text-rose-600 font-medium">
                              <AlertTriangle className="w-3.5 h-3.5 text-rose-500 flex-shrink-0" />
                              <span>Akses Dibekukan</span>
                            </div>
                          )}
                        </td>

                        {/* 8. Aksi */}
                        <td className="px-5 py-3.5 text-right">
                          <div className="flex items-center justify-end gap-1.5">
                            <button
                              type="button"
                              onClick={() => openEditModal(company)}
                              aria-label={`Ubah status langganan ${company.name}`}
                              className="inline-flex items-center gap-1.5 h-8 px-3 text-xs font-semibold rounded-xl border border-slate-200 bg-white text-slate-700 hover:text-orange-700 hover:border-orange-300 hover:bg-orange-50/50 shadow-2xs transition-all cursor-pointer active:scale-[0.97] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-600"
                            >
                              <Edit3 className="w-3.5 h-3.5 text-slate-400 group-hover:text-orange-600" />
                              <span>Kelola</span>
                            </button>

                            <button
                              type="button"
                              onClick={() => openDeleteModal(company)}
                              aria-label={`Hapus perusahaan ${company.name}`}
                              title="Hapus tenant"
                              className="p-2 rounded-xl border border-slate-200 bg-white text-slate-400 hover:text-rose-600 hover:border-rose-200 hover:bg-rose-50/70 shadow-2xs transition-all cursor-pointer active:scale-95 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-600"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}

          {/* Footer Info Pagination */}
          {companiesData && companiesData.total > 0 && (
            <div className="flex flex-col sm:flex-row items-center justify-between px-5 py-3.5 border-t border-slate-100 bg-slate-50/70 backdrop-blur-xs text-xs text-slate-500 gap-2">
              <span className="font-medium">
                Menampilkan <strong className="text-slate-800">{companiesList.length}</strong> dari{" "}
                <strong className="text-slate-800">{companiesData.total}</strong> tenant terdaftar
              </span>
              <span className="tabular-nums font-medium">
                Halaman {companiesData.current_page} dari {companiesData.last_page}
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Modal Kelola Status Langganan Tenant */}
      <Modal
        isOpen={isEditModalOpen}
        onClose={() => setIsEditModalOpen(false)}
        title={`Kelola Langganan: ${selectedCompany?.name || ""}`}
        description="Atur status operasional, perpanjang masa uji coba, atau tangguhkan akses tenant."
        maxWidth="md"
        footer={
          <>
            <Button
              variant="secondary"
              size="sm"
              onClick={() => setIsEditModalOpen(false)}
              className="rounded-xl"
            >
              Batal
            </Button>
            <Button
              variant="primary"
              size="sm"
              onClick={handleSaveEdit}
              isLoading={updateMutation.isPending}
              className="rounded-xl shadow-xs"
            >
              Simpan Perubahan
            </Button>
          </>
        }
      >
        <form onSubmit={handleSaveEdit} className="space-y-4">
          {formError && (
            <div
              role="alert"
              className="p-3.5 text-xs rounded-2xl bg-rose-50/80 border border-rose-200/80 text-rose-700 shadow-2xs"
            >
              {formError}
            </div>
          )}

          <div>
            <label
              htmlFor="subscription_status"
              className="block text-xs font-semibold text-slate-900 mb-1.5"
            >
              Status Langganan Tenant
            </label>
            <select
              id="subscription_status"
              value={editStatus}
              onChange={(e) =>
                setEditStatus(e.target.value as SubscriptionStatus)
              }
              className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3.5 py-2 text-sm text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
            >
              <option value="active">Aktif (Berbayar / Akses Penuh)</option>
              <option value="trial">Masa Uji Coba (Trial)</option>
              <option value="suspended">Ditangguhkan (Suspended)</option>
              <option value="cancelled">Dibatalkan (Cancelled)</option>
            </select>
          </div>

          {editStatus === "trial" && (
            <div className="p-3.5 rounded-2xl bg-amber-50/60 border border-amber-200/70 space-y-2">
              <label
                htmlFor="trial_ends_at"
                className="block text-xs font-semibold text-slate-900 mb-1"
              >
                Batas Akhir Masa Uji Coba (Trial)
              </label>
              <input
                id="trial_ends_at"
                type="date"
                value={editTrialEndsAt}
                onChange={(e) => setEditTrialEndsAt(e.target.value)}
                className="w-full rounded-xl border border-amber-300/80 bg-white/95 px-3.5 py-2 text-sm text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
              />
              <div className="flex gap-2 pt-1">
                <button
                  type="button"
                  onClick={() => {
                    const d = new Date();
                    d.setDate(d.getDate() + 14);
                    setEditTrialEndsAt(d.toISOString().split("T")[0]);
                  }}
                  className="px-2.5 py-1 text-[11px] font-semibold text-amber-800 bg-amber-100 hover:bg-amber-200/80 rounded-lg transition-colors cursor-pointer active:scale-95"
                >
                  +14 Hari
                </button>
                <button
                  type="button"
                  onClick={() => {
                    const d = new Date();
                    d.setDate(d.getDate() + 30);
                    setEditTrialEndsAt(d.toISOString().split("T")[0]);
                  }}
                  className="px-2.5 py-1 text-[11px] font-semibold text-amber-800 bg-amber-100 hover:bg-amber-200/80 rounded-lg transition-colors cursor-pointer active:scale-95"
                >
                  +30 Hari
                </button>
              </div>
            </div>
          )}

          <div>
            <label
              htmlFor="phone"
              className="block text-xs font-semibold text-slate-900 mb-1.5"
            >
              Nomor Telepon Perusahaan
            </label>
            <input
              id="phone"
              type="text"
              value={editPhone}
              onChange={(e) => setEditPhone(e.target.value)}
              placeholder="021-xxxxxx atau 08xxxxxx"
              className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3.5 py-2 text-sm text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
            />
          </div>

          <div>
            <label
              htmlFor="address"
              className="block text-xs font-semibold text-slate-900 mb-1.5"
            >
              Alamat Kantor Utama
            </label>
            <textarea
              id="address"
              rows={2}
              value={editAddress}
              onChange={(e) => setEditAddress(e.target.value)}
              placeholder="Alamat kantor perusahaan..."
              className="w-full rounded-xl border border-slate-200/80 bg-white/95 px-3.5 py-2 text-sm text-slate-900 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
            />
          </div>
        </form>
      </Modal>

      {/* Modal Konfirmasi Hapus Tenant */}
      <Modal
        isOpen={isDeleteModalOpen}
        onClose={() => setIsDeleteModalOpen(false)}
        title="Konfirmasi Hapus Tenant"
        description="Tindakan ini permanen dan akan menghapus seluruh data perusahaan termasuk karyawan, cabang, presensi, dan slip gaji."
        maxWidth="sm"
        footer={
          <>
            <Button
              variant="secondary"
              size="sm"
              onClick={() => setIsDeleteModalOpen(false)}
              className="rounded-xl"
            >
              Batal
            </Button>
            <Button
              variant="danger"
              size="sm"
              onClick={() => {
                if (selectedCompany) {
                  deleteMutation.mutate(selectedCompany.id_companies);
                }
              }}
              isLoading={deleteMutation.isPending}
              className="rounded-xl shadow-xs"
            >
              Hapus Permanen
            </Button>
          </>
        }
      >
        <div className="space-y-3">
          <p className="text-xs text-slate-600 leading-relaxed">
            Apakah Anda yakin ingin menghapus data perusahaan{" "}
            <strong className="text-slate-900 font-semibold">{selectedCompany?.name}</strong>?
            Semua akun karyawan, histori absensi, dan data penggajian akan dihapus permanen dari sistem.
          </p>
        </div>
      </Modal>
    </div>
  );
}
