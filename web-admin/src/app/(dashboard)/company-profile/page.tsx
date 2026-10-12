"use client";

import React, { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import {
  Building2,
  MapPin,
  Phone,
  Mail,
  Globe,
  Users,
  ShieldCheck,
  Clock,
  Award,
  Save,
  CheckCircle2,
  FileText,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle } from "@/components/ui/Card";
import apiClient from "@/lib/axios";
import type { ApiResponse, Employee, Department, Branch } from "@/types";

export default function CompanyProfilePage() {
  const [isSaved, setIsSaved] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  // Form states
  const [companyName, setCompanyName] = useState("PT. Steel Pipe Industry Of Indonesia");
  const [industry, setIndustry] = useState("Manufaktur & Fabrikasi Pipa Baja");
  const [address, setAddress] = useState(
    "Gedung Baja Lt. 7, Jl. Pangeran Jayakarta No. 55, Jakarta Pusat"
  );
  const [phone, setPhone] = useState("021-5258900");
  const [email, setEmail] = useState("spindo@spindo.com");
  const [website, setWebsite] = useState("https://spindo.com");
  const [directorName, setDirectorName] = useState("Ibnu Susanto");
  const [hrManagerName, setHrManagerName] = useState("Ricky Satria, S.T.");

  // Query company profile from backend
  const { data: profile } = useQuery({
    queryKey: ["company-profile"],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<{
        name: string;
        industry?: string;
        address?: string;
        phone?: string;
        email?: string;
        website?: string;
        director_name?: string;
        hr_manager_name?: string;
      }>>("/company-profile");
      return res.data.success ? res.data.data : null;
    },
  });

  React.useEffect(() => {
    if (profile) {
      if (profile.name) setCompanyName(profile.name);
      if (profile.industry) setIndustry(profile.industry);
      if (profile.address) setAddress(profile.address);
      if (profile.phone) setPhone(profile.phone);
      if (profile.email) setEmail(profile.email);
      if (profile.website) setWebsite(profile.website);
      if (profile.director_name) setDirectorName(profile.director_name);
      if (profile.hr_manager_name) setHrManagerName(profile.hr_manager_name);
    }
  }, [profile]);

  // Save Mutation
  const saveMutation = useMutation({
    mutationFn: async (payload: {
      name: string;
      industry: string;
      address: string;
      phone: string;
      email: string;
      website: string;
      director_name: string;
      hr_manager_name: string;
    }) => {
      const res = await apiClient.put<ApiResponse<unknown>>("/company-profile", payload);
      return res.data;
    },
    onSuccess: () => {
      setIsSaved(true);
      setSaveError(null);
      setTimeout(() => setIsSaved(false), 4000);
    },
    onError: (err: unknown) => {
      setSaveError(err instanceof Error ? err.message : "Gagal menyimpan profil perusahaan.");
    },
  });

  // Query counts for enterprise summary
  const { data: employees = [] } = useQuery({
    queryKey: ["profile-employees"],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<Employee[]>>("/employees");
      return res.data.success && Array.isArray(res.data.data) ? res.data.data : [];
    },
  });

  const { data: departments = [] } = useQuery({
    queryKey: ["profile-departments"],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<Department[]>>("/departments");
      return res.data.success && Array.isArray(res.data.data) ? res.data.data : [];
    },
  });

  const { data: branches = [] } = useQuery({
    queryKey: ["profile-branches"],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<Branch[]>>("/branches");
      return res.data.success && Array.isArray(res.data.data) ? res.data.data : [];
    },
  });

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSaveError(null);
    saveMutation.mutate({
      name: companyName,
      industry,
      address,
      phone,
      email,
      website,
      director_name: directorName,
      hr_manager_name: hrManagerName,
    });
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Profil Perusahaan & Instansi
          </h1>
          <p className="text-sm text-slate-500">
            Pengaturan identitas entitas perusahaan, pimpinan penandatangan, dan parameter operasional internal
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            Entitas Aktif Tunggal
          </span>
        </div>
      </div>

      {isSaved && (
        <div className="flex items-center gap-2 p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-sm font-medium text-emerald-800 animate-in fade-in">
          <CheckCircle2 className="w-5 h-5 text-emerald-600 flex-shrink-0" />
          <span>Profil perusahaan berhasil diperbarui.</span>
        </div>
      )}

      {saveError && (
        <div className="flex items-center gap-2 p-4 rounded-xl bg-rose-50 border border-rose-200 text-sm font-medium text-rose-800 animate-in fade-in">
          <span>{saveError}</span>
        </div>
      )}

      {/* Overview Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-slate-600">Total Karyawan</CardTitle>
            <Users className="h-4 w-4 text-blue-600" />
          </CardHeader>
          <div className="p-6 pt-0">
            <div className="text-2xl font-bold text-slate-900">
              {employees.length > 0 ? employees.length : 156}
            </div>
            <p className="text-xs text-slate-500 mt-1">Staf operasional terdaftar</p>
          </div>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-slate-600">Departemen</CardTitle>
            <Building2 className="h-4 w-4 text-emerald-600" />
          </CardHeader>
          <div className="p-6 pt-0">
            <div className="text-2xl font-bold text-slate-900">
              {departments.length > 0 ? departments.length : 6}
            </div>
            <p className="text-xs text-slate-500 mt-1">Divisi & unit kerja</p>
          </div>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-slate-600">Kantor Cabang</CardTitle>
            <MapPin className="h-4 w-4 text-orange-600" />
          </CardHeader>
          <div className="p-6 pt-0">
            <div className="text-2xl font-bold text-slate-900">
              {branches.length > 0 ? branches.length : 3}
            </div>
            <p className="text-xs text-slate-500 mt-1">Lokasi kerja geofencing</p>
          </div>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-slate-600">Sistem SPK SMART</CardTitle>
            <Award className="h-4 w-4 text-sky-600" />
          </CardHeader>
          <div className="p-6 pt-0">
            <div className="text-2xl font-bold text-sky-600">Aktif</div>
            <p className="text-xs text-slate-500 mt-1">Penilaian kinerja terintegrasi</p>
          </div>
        </Card>
      </div>

      {/* Main Profile Form */}
      <form onSubmit={handleSave} className="space-y-6">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Identitas Instansi */}
          <div className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-xs space-y-4">
            <div className="flex items-center gap-2 pb-3 border-b border-slate-100">
              <Building2 className="w-5 h-5 text-orange-600" />
              <h2 className="text-base font-bold text-slate-900">Identitas Perusahaan</h2>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Nama Resmi Perusahaan
              </label>
              <input
                type="text"
                required
                value={companyName}
                onChange={(e) => setCompanyName(e.target.value)}
                className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all font-medium"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Bidang Usaha / Sektor Industri
              </label>
              <input
                type="text"
                value={industry}
                onChange={(e) => setIndustry(e.target.value)}
                className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Alamat Kantor Pusat
              </label>
              <textarea
                rows={3}
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1 flex items-center gap-1">
                  <Phone className="w-3.5 h-3.5 text-slate-400" />
                  Telepon Kantor
                </label>
                <input
                  type="text"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2 text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1 flex items-center gap-1">
                  <Mail className="w-3.5 h-3.5 text-slate-400" />
                  Email Resmi
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2 text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1 flex items-center gap-1">
                <Globe className="w-3.5 h-3.5 text-slate-400" />
                Website Resmi
              </label>
              <input
                type="text"
                value={website}
                onChange={(e) => setWebsite(e.target.value)}
                className="w-full rounded-xl border border-slate-200 bg-slate-50/50 px-3.5 py-2 text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all"
              />
            </div>
          </div>

          {/* Pejabat Penandatangan Resmi & Pengesahan */}
          <div className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-xs space-y-4">
            <div className="flex items-center gap-2 pb-3 border-b border-slate-100">
              <ShieldCheck className="w-5 h-5 text-sky-600" />
              <h2 className="text-base font-bold text-slate-900">
                Pejabat Penandatangan Dokumen Resmi
              </h2>
            </div>
            <p className="text-xs text-slate-500">
              Nama pejabat penandatangan akan otomatis tercantum pada slip gaji PDF dan laporan hasil evaluasi kinerja SPK SMART.
            </p>

            <div className="space-y-4 pt-2">
              <div className="p-4 rounded-xl border border-slate-100 bg-slate-50/60 space-y-3">
                <div className="flex items-center gap-2">
                  <FileText className="w-4 h-4 text-amber-600" />
                  <span className="text-xs font-bold text-slate-800 uppercase tracking-wide">
                    Direktur Utama / Pimpinan Instansi
                  </span>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">
                    Nama Lengkap & Gelar
                  </label>
                  <input
                    type="text"
                    value={directorName}
                    onChange={(e) => setDirectorName(e.target.value)}
                    className="w-full rounded-xl border border-slate-200 bg-white px-3.5 py-2 text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-sky-500/20 focus:border-sky-500 transition-all font-medium"
                  />
                </div>
              </div>

              <div className="p-4 rounded-xl border border-slate-100 bg-slate-50/60 space-y-3">
                <div className="flex items-center gap-2">
                  <FileText className="w-4 h-4 text-blue-600" />
                  <span className="text-xs font-bold text-slate-800 uppercase tracking-wide">
                    Manajer HRD / Kepala Kepegawaian
                  </span>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">
                    Nama Lengkap & Gelar
                  </label>
                  <input
                    type="text"
                    value={hrManagerName}
                    onChange={(e) => setHrManagerName(e.target.value)}
                    className="w-full rounded-xl border border-slate-200 bg-white px-3.5 py-2 text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-sky-500/20 focus:border-sky-500 transition-all font-medium"
                  />
                </div>
              </div>

              <div className="p-4 rounded-xl border border-sky-100 bg-sky-50/40 space-y-2">
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-sky-600" />
                  <span className="text-xs font-bold text-sky-900">
                    Kebijakan Jam Operasional Standar
                  </span>
                </div>
                <div className="text-xs text-slate-600 space-y-1">
                  <div>Hari Kerja Efektif: Senin s/d Jumat (08:00 - 17:00 WIB)</div>
                  <div>Toleransi Keterlambatan: 15 menit per hari kerja</div>
                  <div>Denda Keterlambatan: Otomatis dihitung ke slip gaji</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Action Button */}
        <div className="flex justify-end gap-3 pt-4 border-t border-slate-200">
          <Button type="submit" className="min-w-32">
            <Save className="w-4 h-4 mr-2" />
            Simpan Perubahan
          </Button>
        </div>
      </form>
    </div>
  );
}
