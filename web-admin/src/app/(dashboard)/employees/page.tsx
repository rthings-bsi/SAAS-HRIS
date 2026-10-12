"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Users, Trash2, Edit2, Building2, Wallet, AlertCircle, AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle } from "@/components/ui/Card";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { Modal } from "@/components/ui/Modal";
import { formatRupiah } from "@/lib/utils";
import { apiClient, ApiError } from "@/lib/axios";
import type { ApiResponse, Employee, Branch, Department, JobPosition } from "@/types";

export default function EmployeesPage() {
  const queryClient = useQueryClient();

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingEmployee, setEditingEmployee] = useState<Employee | null>(null);
  const [deletingEmployee, setDeletingEmployee] = useState<Employee | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string[]>>({});

  // Form Fields
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState<"employee" | "manager" | "hr">("employee");
  const [nik, setNik] = useState("");
  const [phone, setPhone] = useState("");
  const [gender, setGender] = useState<"male" | "female">("male");
  const [hireDate, setHireDate] = useState("2026-10-01");
  const [employmentStatus, setEmploymentStatus] = useState<"permanent" | "contract" | "probation">("contract");
  const [basicSalary, setBasicSalary] = useState("5000000");
  const [allowanceFixed, setAllowanceFixed] = useState("500000");
  const [idBranch, setIdBranch] = useState<string>("");
  const [idDepartment, setIdDepartment] = useState<string>("");
  const [idPosition, setIdPosition] = useState<string>("");

  // Query Employees
  const {
    data: employees = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["employees"],
    queryFn: async () => {
      const response = await apiClient.get<ApiResponse<Employee[]>>("/employees");
      if (response.data.success && Array.isArray(response.data.data)) {
        return response.data.data;
      }
      return [];
    },
  });

  // Query Branches
  const { data: branches = [] } = useQuery({
    queryKey: ["branches"],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<Branch[]>>("/branches");
      if (res.data.success && Array.isArray(res.data.data)) {
        return res.data.data;
      }
      return [];
    },
  });

  // Query Departments
  const { data: departments = [] } = useQuery({
    queryKey: ["departments"],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<Department[]>>("/departments");
      if (res.data.success && Array.isArray(res.data.data)) {
        return res.data.data;
      }
      return [];
    },
  });

  // Query Job Positions
  const { data: positions = [] } = useQuery({
    queryKey: ["job-positions"],
    queryFn: async () => {
      const res = await apiClient.get<ApiResponse<JobPosition[]>>("/job-positions");
      if (res.data.success && Array.isArray(res.data.data)) {
        return res.data.data;
      }
      return [];
    },
  });

  // Create Mutation
  const createMutation = useMutation({
    mutationFn: async (payload: {
      name: string;
      email: string;
      password?: string;
      role?: "employee" | "manager" | "hr";
      nik: string;
      phone: string;
      gender: "male" | "female";
      hire_date: string;
      employment_status: "permanent" | "contract" | "probation";
      basic_salary: number;
      allowance_fixed: number;
      id_branches: number;
      id_departments: number | null;
      id_job_positions: number | null;
    }) => {
      const response = await apiClient.post<ApiResponse<Employee>>("/employees", payload);
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setIsModalOpen(false);
        setEditingEmployee(null);
        setFieldErrors({});
        setFormError(null);
        queryClient.invalidateQueries({ queryKey: ["employees"] });
      } else {
        setFormError(data.message || "Gagal menyimpan data karyawan.");
      }
    },
    onError: (err: unknown) => {
      if (err instanceof ApiError) {
        setFormError(err.message || "Validasi data karyawan gagal.");
        if (err.errors) {
          setFieldErrors(err.errors);
        }
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
        email: string;
        password?: string;
        role?: "employee" | "manager" | "hr";
        nik: string;
        phone: string;
        gender: "male" | "female";
        hire_date: string;
        employment_status: "permanent" | "contract" | "probation";
        basic_salary: number;
        allowance_fixed: number;
        id_branches: number;
        id_departments: number | null;
        id_job_positions: number | null;
      };
    }) => {
      const response = await apiClient.put<ApiResponse<Employee>>(`/employees/${id}`, payload);
      return response.data;
    },
    onSuccess: (data) => {
      if (data.success) {
        setIsModalOpen(false);
        setEditingEmployee(null);
        setFieldErrors({});
        setFormError(null);
        queryClient.invalidateQueries({ queryKey: ["employees"] });
      } else {
        setFormError(data.message || "Gagal memperbarui data karyawan.");
      }
    },
    onError: (err: unknown) => {
      if (err instanceof ApiError) {
        setFormError(err.message || "Validasi pembaruan data gagal.");
        if (err.errors) {
          setFieldErrors(err.errors);
        }
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
      await apiClient.delete(`/employees/${id}`);
    },
    onSuccess: () => {
      setDeletingEmployee(null);
      setDeleteError(null);
      queryClient.invalidateQueries({ queryKey: ["employees"] });
    },
    onError: (err: Error) => {
      setDeleteError(err.message || "Gagal menghapus karyawan.");
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
    setEditingEmployee(null);
    setName("");
    setEmail("");
    setPassword("Password123!");
    setRole("employee");
    setNik(`EMP-${String(employees.length + 1).padStart(3, "0")}`);
    setPhone("08123456789");
    setGender("male");
    setHireDate("2026-10-01");
    setEmploymentStatus("contract");
    setBasicSalary("5000000");
    setAllowanceFixed("500000");
    if (branches.length > 0 && !idBranch) {
      setIdBranch(String(branches[0].id_branches));
    }
    setFormError(null);
    setFieldErrors({});
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (emp: Employee) => {
    setEditingEmployee(emp);
    setName(emp.user?.name || "");
    setEmail(emp.user?.email || "");
    setPassword(""); // Kosongkan bila tidak ingin mengubah kata sandi
    setRole((emp.user?.role as "employee" | "manager" | "hr") || "employee");
    setNik(emp.nik || "");
    setPhone(emp.phone || "");
    setGender((emp.gender as "male" | "female") || "male");
    setHireDate(emp.hire_date ? emp.hire_date.slice(0, 10) : "2026-10-01");
    setEmploymentStatus((emp.employment_status as "permanent" | "contract" | "probation") || "contract");
    setBasicSalary(String(emp.basic_salary || 0));
    setAllowanceFixed(String(emp.allowance_fixed || 0));
    setIdBranch(emp.id_branches ? String(emp.id_branches) : branches[0] ? String(branches[0].id_branches) : "");
    setIdDepartment(emp.id_departments ? String(emp.id_departments) : "");
    setIdPosition(emp.id_job_positions ? String(emp.id_job_positions) : "");
    setFormError(null);
    setFieldErrors({});
    setIsModalOpen(true);
  };

  const handleSaveEmployee = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    setFieldErrors({});

    const clientErrors: Record<string, string[]> = {};
    const trimmedName = name.trim();
    const trimmedNik = nik.trim();
    const trimmedEmail = email.trim();
    const trimmedPhone = phone.trim();

    if (!trimmedName) {
      clientErrors.name = ["Nama lengkap karyawan wajib diisi."];
    }
    if (!trimmedNik) {
      clientErrors.nik = ["NIK karyawan wajib diisi."];
    }
    if (!trimmedEmail) {
      clientErrors.email = ["Email login akun wajib diisi."];
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmedEmail)) {
      clientErrors.email = ["Format email tidak valid (contoh: staf@perusahaan.com)."];
    }
    if (!editingEmployee && (!password || password.length < 8)) {
      clientErrors.password = ["Kata sandi akun minimal harus 8 karakter."];
    } else if (editingEmployee && password && password.length < 8) {
      clientErrors.password = ["Kata sandi baru minimal harus 8 karakter."];
    }
    if (trimmedPhone && !/^[0-9+()\s-]+$/.test(trimmedPhone)) {
      clientErrors.phone = ["Nomor telepon hanya boleh berisi angka dan simbol (+, -)."];
    }
    const resolvedBranchId = idBranch || (branches[0] ? String(branches[0].id_branches) : "");
    if (!resolvedBranchId) {
      clientErrors.id_branches = ["Kantor cabang penempatan wajib dipilih."];
    }
    if (!hireDate) {
      clientErrors.hire_date = ["Tanggal mulai kerja wajib diisi."];
    }
    const parsedSalary = parseFloat(basicSalary);
    if (basicSalary === "" || isNaN(parsedSalary) || parsedSalary < 0) {
      clientErrors.basic_salary = ["Gaji pokok bulanan harus berupa angka valid (minimal 0)."];
    }
    const parsedAllowance = parseFloat(allowanceFixed);
    if (allowanceFixed !== "" && (isNaN(parsedAllowance) || parsedAllowance < 0)) {
      clientErrors.allowance_fixed = ["Tunjangan tetap harus berupa angka valid (minimal 0)."];
    }

    if (Object.keys(clientErrors).length > 0) {
      setFieldErrors(clientErrors);
      setFormError("Terdapat data yang belum sesuai. Silakan periksa kolom yang ditandai merah.");
      return;
    }

    const payload: {
      name: string;
      email: string;
      password?: string;
      role: "employee" | "manager" | "hr";
      nik: string;
      phone: string;
      gender: "male" | "female";
      hire_date: string;
      employment_status: "permanent" | "contract" | "probation";
      basic_salary: number;
      allowance_fixed: number;
      id_branches: number;
      id_departments: number | null;
      id_job_positions: number | null;
    } = {
      name: trimmedName,
      email: trimmedEmail,
      role,
      nik: trimmedNik,
      phone: trimmedPhone,
      gender,
      hire_date: hireDate,
      employment_status: employmentStatus,
      basic_salary: parsedSalary || 0,
      allowance_fixed: isNaN(parsedAllowance) ? 0 : parsedAllowance,
      id_branches: parseInt(resolvedBranchId, 10),
      id_departments: idDepartment ? parseInt(idDepartment, 10) : null,
      id_job_positions: idPosition ? parseInt(idPosition, 10) : null,
    };

    if (password && password.trim().length > 0) {
      payload.password = password.trim();
    }

    if (editingEmployee) {
      updateMutation.mutate({ id: editingEmployee.id_employees, payload });
    } else {
      createMutation.mutate(payload);
    }
  };

  const confirmDelete = () => {
    if (deletingEmployee) {
      deleteMutation.mutate(deletingEmployee.id_employees);
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Data Karyawan
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Daftar pegawai aktif, status kontrak kerja, dan penempatan cabang operasional.
          </p>
        </div>

        <div className="hidden sm:flex items-center gap-2">
          <Button
            variant="primary"
            size="sm"
            leftIcon={<Plus className="w-4 h-4" aria-hidden="true" />}
            onClick={handleOpenCreateModal}
          >
            Tambah Karyawan
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader className="p-5 border-b border-slate-100/80 flex flex-row items-center justify-between">
          <div>
            <CardTitle>Daftar Staf Aktif</CardTitle>
            <p className="text-xs text-slate-500 mt-1">
              Menampilkan {employees.length} staf terdaftar.
            </p>
          </div>
        </CardHeader>

        {isLoading ? (
          <TableSkeleton rows={4} columns={6} />
        ) : isError ? (
          <div className="p-6">
            <ErrorState
              title="Gagal Memuat Karyawan"
              message={error instanceof Error ? error.message : "Terjadi kendala."}
              onRetry={() => refetch()}
            />
          </div>
        ) : employees.length === 0 ? (
          <div className="p-6">
            <EmptyState
              title="Belum ada data karyawan"
              description="Tambahkan data staf pertama untuk mengatur jadwal shift dan presensi."
              actionLabel="Tambah Karyawan Baru"
              onAction={handleOpenCreateModal}
              icon={<Users className="w-6 h-6" />}
            />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="bg-slate-50/80 backdrop-blur-xs border-b border-slate-200/70 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  <th scope="col" className="px-5 py-3 font-mono">NIK</th>
                  <th scope="col" className="px-5 py-3">Nama Pegawai</th>
                  <th scope="col" className="px-4 py-3">Departemen & Jabatan</th>
                  <th scope="col" className="px-4 py-3">Cabang</th>
                  <th scope="col" className="px-4 py-3 text-right font-mono">Gaji Pokok</th>
                  <th scope="col" className="px-5 py-3 text-center">Status Kerja</th>
                  <th scope="col" className="px-4 py-3 text-right">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {employees.map((emp) => (
                  <tr key={emp.id_employees} className="hover:bg-slate-50/60 transition-colors">
                    <td className="px-5 py-3.5 text-xs font-mono tabular-nums text-slate-500">
                      {emp.nik}
                    </td>
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-slate-900">{emp.user?.name || "Karyawan"}</span>
                        {emp.user?.role && emp.user.role !== "employee" && (
                          <span
                            className={`text-[10.5px] font-semibold px-2 py-0.5 rounded-full border ${
                              emp.user.role === "manager"
                                ? "bg-amber-50 text-amber-800 border-amber-200"
                                : emp.user.role === "hr"
                                ? "bg-indigo-50 text-indigo-800 border-indigo-200"
                                : "bg-purple-50 text-purple-800 border-purple-200"
                            }`}
                          >
                            {emp.user.role === "manager"
                              ? "Manager"
                              : emp.user.role === "hr"
                              ? "HR Admin"
                              : "Owner"}
                          </span>
                        )}
                      </div>
                      <div className="text-xs text-slate-500 font-normal mt-0.5">{emp.user?.email}</div>
                    </td>
                    <td className="px-4 py-3.5 text-xs">
                      <div className="text-slate-900 font-medium">{emp.job_position?.name || "Staf"}</div>
                      <div className="text-slate-500">{emp.department?.name || "Operasional"}</div>
                    </td>
                    <td className="px-4 py-3.5 text-xs text-slate-500">
                      {emp.branch?.name || "Kantor Utama"}
                    </td>
                    <td className="px-4 py-3.5 text-xs font-mono tabular-nums text-right text-slate-900">
                      {formatRupiah(Number(emp.basic_salary))}
                    </td>
                    <td className="px-5 py-3.5 text-center">
                      <StatusBadge
                        status={emp.employment_status === "permanent" ? "approved" : "pending"}
                        label={emp.employment_status === "permanent" ? "Tetap" : "Kontrak"}
                      />
                    </td>
                    <td className="px-4 py-3.5 text-right">
                      <div className="inline-flex items-center gap-1.5 justify-end">
                        <button
                          type="button"
                          onClick={() => handleOpenEditModal(emp)}
                          aria-label={`Ubah data ${emp.user?.name || "karyawan"}`}
                          className="p-1.5 rounded-xl text-slate-500 hover:text-orange-600 hover:bg-orange-50 active:scale-95 transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-500 cursor-pointer"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button
                          type="button"
                          onClick={() => setDeletingEmployee(emp)}
                          aria-label={`Hapus ${emp.user?.name || "karyawan"}`}
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

      {/* Modal Tambah / Edit Karyawan */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingEmployee ? "Ubah Data Karyawan" : "Formulir Karyawan Baru"}
        description={
          editingEmployee
            ? "Perbarui informasi profil, penempatan kerja, dan kompensasi gaji staf."
            : "Lengkapi data profil dan akun login untuk staf baru."
        }
        maxWidth="2xl"
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
              form="employee-form"
              type="submit"
              variant="primary"
              size="sm"
              isLoading={createMutation.isPending || updateMutation.isPending}
            >
              {editingEmployee ? "Simpan Perubahan" : "Simpan Data Karyawan"}
            </Button>
          </div>
        }
      >
        <form
          id="employee-form"
          onSubmit={handleSaveEmployee}
          noValidate
          className="space-y-6 text-sm"
        >
          {formError && (
            <div
              role="alert"
              className="rounded-xl border border-rose-200 bg-rose-50 p-3.5 text-xs text-rose-700"
            >
              <div className="flex items-start gap-2.5">
                <AlertCircle className="w-4 h-4 text-rose-600 flex-shrink-0 mt-0.5" aria-hidden="true" />
                <div className="space-y-1">
                  <p className="font-semibold">{formError}</p>
                  {Object.keys(fieldErrors).length > 0 && (
                    <ul className="mt-1 list-disc list-inside space-y-0.5 text-rose-600">
                      {Object.entries(fieldErrors).map(([field, msgs]) =>
                        msgs.map((msg, i) => <li key={`${field}-${i}`}>{msg}</li>)
                      )}
                    </ul>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* Section 1: Data Akun & Pribadi */}
          <div className="space-y-3.5">
            <div className="flex items-center gap-2 pb-1.5 border-b border-slate-100">
              <div className="w-5 h-5 rounded-md bg-orange-100 text-orange-600 flex items-center justify-center flex-shrink-0">
                <Users className="w-3.5 h-3.5" aria-hidden="true" />
              </div>
              <span className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                1. Data Pribadi & Akun Login
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label htmlFor="emp-name" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Nama Lengkap <span className="text-rose-500">*</span>
                </label>
                <input
                  id="emp-name"
                  type="text"
                  required
                  value={name}
                  onChange={(e) => {
                    setName(e.target.value);
                    clearFieldError("name");
                  }}
                  placeholder="Contoh: Budi Santoso"
                  aria-invalid={fieldErrors.name ? "true" : undefined}
                  aria-describedby={fieldErrors.name ? "emp-name-error" : undefined}
                  className={`w-full px-3.5 py-2 text-sm rounded-xl border transition-all outline-none ${
                    fieldErrors.name
                      ? "border-rose-400 bg-rose-50/20 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20"
                      : "border-slate-200 bg-white placeholder:text-slate-400 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
                  }`}
                />
                {fieldErrors.name && (
                  <p id="emp-name-error" className="mt-1 text-xs text-rose-600 font-medium">
                    {fieldErrors.name[0]}
                  </p>
                )}
              </div>

              <div>
                <label htmlFor="emp-nik" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  NIK Karyawan <span className="text-rose-500">*</span>
                </label>
                <input
                  id="emp-nik"
                  type="text"
                  required
                  value={nik}
                  onChange={(e) => {
                    setNik(e.target.value);
                    clearFieldError("nik");
                  }}
                  placeholder="EMP-001"
                  aria-invalid={fieldErrors.nik ? "true" : undefined}
                  aria-describedby={fieldErrors.nik ? "emp-nik-error" : undefined}
                  className={`w-full px-3.5 py-2 text-sm font-mono tabular-nums rounded-xl border transition-all outline-none ${
                    fieldErrors.nik
                      ? "border-rose-400 bg-rose-50/20 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20"
                      : "border-slate-200 bg-white placeholder:text-slate-400 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
                  }`}
                />
                {fieldErrors.nik && (
                  <p id="emp-nik-error" className="mt-1 text-xs text-rose-600 font-medium">
                    {fieldErrors.nik[0]}
                  </p>
                )}
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label htmlFor="emp-email" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Email Login <span className="text-rose-500">*</span>
                </label>
                <input
                  id="emp-email"
                  type="email"
                  required
                  value={email}
                  onChange={(e) => {
                    setEmail(e.target.value);
                    clearFieldError("email");
                  }}
                  placeholder="staf@perusahaan.com"
                  aria-invalid={fieldErrors.email ? "true" : undefined}
                  aria-describedby={fieldErrors.email ? "emp-email-error" : undefined}
                  className={`w-full px-3.5 py-2 text-sm rounded-xl border transition-all outline-none ${
                    fieldErrors.email
                      ? "border-rose-400 bg-rose-50/20 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20"
                      : "border-slate-200 bg-white placeholder:text-slate-400 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
                  }`}
                />
                {fieldErrors.email && (
                  <p id="emp-email-error" className="mt-1 text-xs text-rose-600 font-medium">
                    {fieldErrors.email[0]}
                  </p>
                )}
              </div>

              <div>
                <label htmlFor="emp-password" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  {editingEmployee ? "Kata Sandi Akun (Opsional)" : "Kata Sandi Akun"} {!editingEmployee && <span className="text-rose-500">*</span>}
                </label>
                <input
                  id="emp-password"
                  type="password"
                  required={!editingEmployee}
                  value={password}
                  onChange={(e) => {
                    setPassword(e.target.value);
                    clearFieldError("password");
                  }}
                  placeholder={editingEmployee ? "Kosongkan jika tidak diubah" : "Minimal 8 karakter"}
                  aria-invalid={fieldErrors.password ? "true" : undefined}
                  aria-describedby={fieldErrors.password ? "emp-password-error" : undefined}
                  className={`w-full px-3.5 py-2 text-sm rounded-xl border transition-all outline-none ${
                    fieldErrors.password
                      ? "border-rose-400 bg-rose-50/20 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20"
                      : "border-slate-200 bg-white placeholder:text-slate-400 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
                  }`}
                />
                {fieldErrors.password && (
                  <p id="emp-password-error" className="mt-1 text-xs text-rose-600 font-medium">
                    {fieldErrors.password[0]}
                  </p>
                )}
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label htmlFor="emp-phone" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Nomor Telepon / WhatsApp
                </label>
                <input
                  id="emp-phone"
                  type="tel"
                  value={phone}
                  onChange={(e) => {
                    setPhone(e.target.value);
                    clearFieldError("phone");
                  }}
                  placeholder="08123456789"
                  aria-invalid={fieldErrors.phone ? "true" : undefined}
                  aria-describedby={fieldErrors.phone ? "emp-phone-error" : undefined}
                  className={`w-full px-3.5 py-2 text-sm font-mono tabular-nums rounded-xl border transition-all outline-none ${
                    fieldErrors.phone
                      ? "border-rose-400 bg-rose-50/20 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20"
                      : "border-slate-200 bg-white placeholder:text-slate-400 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
                  }`}
                />
                {fieldErrors.phone && (
                  <p id="emp-phone-error" className="mt-1 text-xs text-rose-600 font-medium">
                    {fieldErrors.phone[0]}
                  </p>
                )}
              </div>

              <div>
                <label htmlFor="emp-gender" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Jenis Kelamin
                </label>
                <select
                  id="emp-gender"
                  value={gender}
                  onChange={(e) => setGender(e.target.value as "male" | "female")}
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 bg-white focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20 transition-all cursor-pointer"
                >
                  <option value="male">Laki-laki</option>
                  <option value="female">Perempuan</option>
                </select>
              </div>

              <div className="sm:col-span-2">
                <label htmlFor="emp-role" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Wewenang & Hak Akses Akun (Role) <span className="text-rose-500">*</span>
                </label>
                <select
                  id="emp-role"
                  value={role}
                  onChange={(e) => setRole(e.target.value as "employee" | "manager" | "hr")}
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 bg-white focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20 transition-all cursor-pointer"
                >
                  <option value="employee">Karyawan (Staf operasional - presensi GPS & ajukan cuti)</option>
                  <option value="manager">Manager / Supervisor (Bisa mengevaluasi kinerja & menyetujui cuti)</option>
                  <option value="hr">HR Administrator (Kelola data karyawan, shift, payroll & SPK)</option>
                </select>
                <p className="text-[11px] text-slate-500 mt-1 font-normal">
                  Pilih Manager jika staf ini berhak mengevaluasi bawahan di modul SPK SMART.
                </p>
              </div>
            </div>
          </div>

          {/* Section 2: Penempatan & Hubungan Kerja */}
          <div className="space-y-3.5 pt-2">
            <div className="flex items-center gap-2 pb-1.5 border-b border-slate-100">
              <div className="w-5 h-5 rounded-md bg-blue-100 text-blue-600 flex items-center justify-center flex-shrink-0">
                <Building2 className="w-3.5 h-3.5" aria-hidden="true" />
              </div>
              <span className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                2. Penempatan & Hubungan Kerja
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label htmlFor="emp-branch" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Kantor Cabang <span className="text-rose-500">*</span>
                </label>
                <select
                  id="emp-branch"
                  required
                  value={idBranch}
                  onChange={(e) => {
                    setIdBranch(e.target.value);
                    clearFieldError("id_branches");
                  }}
                  aria-invalid={fieldErrors.id_branches ? "true" : undefined}
                  aria-describedby={fieldErrors.id_branches ? "emp-branch-error" : undefined}
                  className={`w-full px-3.5 py-2 text-sm rounded-xl border transition-all outline-none cursor-pointer ${
                    fieldErrors.id_branches
                      ? "border-rose-400 bg-rose-50/20 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20"
                      : "border-slate-200 bg-white focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
                  }`}
                >
                  {branches.length === 0 ? (
                    <option value="">Belum ada cabang</option>
                  ) : (
                    branches.map((b) => (
                      <option key={b.id_branches} value={b.id_branches}>
                        {b.name}
                      </option>
                    ))
                  )}
                </select>
                {fieldErrors.id_branches && (
                  <p id="emp-branch-error" className="mt-1 text-xs text-rose-600 font-medium">
                    {fieldErrors.id_branches[0]}
                  </p>
                )}
              </div>

              <div>
                <label htmlFor="emp-dept" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Departemen
                </label>
                <select
                  id="emp-dept"
                  value={idDepartment}
                  onChange={(e) => setIdDepartment(e.target.value)}
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 bg-white focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20 transition-all cursor-pointer"
                >
                  <option value="">Pilih Departemen</option>
                  {departments.map((d) => (
                    <option key={d.id_departments} value={d.id_departments}>
                      {d.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="emp-pos" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Jabatan Posisi
                </label>
                <select
                  id="emp-pos"
                  value={idPosition}
                  onChange={(e) => setIdPosition(e.target.value)}
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 bg-white focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20 transition-all cursor-pointer"
                >
                  <option value="">Pilih Jabatan</option>
                  {positions.map((p) => (
                    <option key={p.id_job_positions} value={p.id_job_positions}>
                      {p.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label htmlFor="emp-status" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Status Kontrak Kerja
                </label>
                <select
                  id="emp-status"
                  value={employmentStatus}
                  onChange={(e) => setEmploymentStatus(e.target.value as "permanent" | "contract" | "probation")}
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 bg-white focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20 transition-all cursor-pointer"
                >
                  <option value="contract">Karyawan Kontrak</option>
                  <option value="permanent">Karyawan Tetap</option>
                  <option value="probation">Masa Percobaan (Probation)</option>
                </select>
              </div>

              <div>
                <label htmlFor="emp-hire" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Tanggal Mulai Kerja <span className="text-rose-500">*</span>
                </label>
                <input
                  id="emp-hire"
                  type="date"
                  required
                  value={hireDate}
                  onChange={(e) => {
                    setHireDate(e.target.value);
                    clearFieldError("hire_date");
                  }}
                  aria-invalid={fieldErrors.hire_date ? "true" : undefined}
                  aria-describedby={fieldErrors.hire_date ? "emp-hire-error" : undefined}
                  className={`w-full px-3.5 py-2 text-sm font-mono tabular-nums rounded-xl border transition-all outline-none ${
                    fieldErrors.hire_date
                      ? "border-rose-400 bg-rose-50/20 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20"
                      : "border-slate-200 bg-white focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
                  }`}
                />
                {fieldErrors.hire_date && (
                  <p id="emp-hire-error" className="mt-1 text-xs text-rose-600 font-medium">
                    {fieldErrors.hire_date[0]}
                  </p>
                )}
              </div>
            </div>
          </div>

          {/* Section 3: Finansial & Kompensasi */}
          <div className="space-y-3.5 pt-2">
            <div className="flex items-center gap-2 pb-1.5 border-b border-slate-100">
              <div className="w-5 h-5 rounded-md bg-emerald-100 text-emerald-600 flex items-center justify-center flex-shrink-0">
                <Wallet className="w-3.5 h-3.5" aria-hidden="true" />
              </div>
              <span className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                3. Finansial & Kompensasi Gaji
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label htmlFor="emp-salary" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Gaji Pokok Bulanan <span className="text-rose-500">*</span>
                </label>
                <div className="relative">
                  <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400 select-none">
                    Rp
                  </span>
                  <input
                    id="emp-salary"
                    type="number"
                    min={0}
                    required
                    value={basicSalary}
                    onChange={(e) => {
                      setBasicSalary(e.target.value);
                      clearFieldError("basic_salary");
                    }}
                    aria-invalid={fieldErrors.basic_salary ? "true" : undefined}
                    aria-describedby={fieldErrors.basic_salary ? "emp-salary-error" : undefined}
                    className={`w-full pl-10 pr-3.5 py-2 text-sm font-mono tabular-nums rounded-xl border transition-all outline-none ${
                      fieldErrors.basic_salary
                        ? "border-rose-400 bg-rose-50/20 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20"
                        : "border-slate-200 bg-white focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
                    }`}
                  />
                </div>
                {fieldErrors.basic_salary ? (
                  <p id="emp-salary-error" className="mt-1 text-xs text-rose-600 font-medium">
                    {fieldErrors.basic_salary[0]}
                  </p>
                ) : (
                  <p className="text-[11px] text-slate-400 font-mono mt-1">
                    {formatRupiah(Number(basicSalary) || 0)} / bulan
                  </p>
                )}
              </div>

              <div>
                <label htmlFor="emp-allowance" className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Tunjangan Tetap
                </label>
                <div className="relative">
                  <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400 select-none">
                    Rp
                  </span>
                  <input
                    id="emp-allowance"
                    type="number"
                    min={0}
                    value={allowanceFixed}
                    onChange={(e) => {
                      setAllowanceFixed(e.target.value);
                      clearFieldError("allowance_fixed");
                    }}
                    aria-invalid={fieldErrors.allowance_fixed ? "true" : undefined}
                    aria-describedby={fieldErrors.allowance_fixed ? "emp-allowance-error" : undefined}
                    className={`w-full pl-10 pr-3.5 py-2 text-sm font-mono tabular-nums rounded-xl border transition-all outline-none ${
                      fieldErrors.allowance_fixed
                        ? "border-rose-400 bg-rose-50/20 focus:border-rose-500 focus:ring-2 focus:ring-rose-500/20"
                        : "border-slate-200 bg-white focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
                    }`}
                  />
                </div>
                {fieldErrors.allowance_fixed ? (
                  <p id="emp-allowance-error" className="mt-1 text-xs text-rose-600 font-medium">
                    {fieldErrors.allowance_fixed[0]}
                  </p>
                ) : (
                  <p className="text-[11px] text-slate-400 font-mono mt-1">
                    {formatRupiah(Number(allowanceFixed) || 0)} / bulan
                  </p>
                )}
              </div>
            </div>
          </div>
        </form>
      </Modal>

      {/* Confirmation Modal for Delete */}
      <Modal
        isOpen={!!deletingEmployee}
        onClose={() => {
          setDeletingEmployee(null);
          setDeleteError(null);
        }}
        title="Konfirmasi Hapus Data Karyawan"
        maxWidth="md"
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <Button
              type="button"
              variant="secondary"
              size="sm"
              onClick={() => {
                setDeletingEmployee(null);
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
              Hapus Karyawan
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
              Apakah Anda yakin ingin menghapus data staf{" "}
              <strong className="text-slate-900">{deletingEmployee?.user?.name || "ini"}</strong> (
              <span className="font-mono text-slate-600">{deletingEmployee?.nik}</span>)?
            </p>
            <p className="text-xs text-slate-500 mt-1.5">
              Tindakan ini akan menghapus data profil kepegawaian dan akun autentikasi login terkait secara permanen.
            </p>
          </div>
        </div>
      </Modal>

      {/* Floating Action Button (FAB) + Mobile */}
      <button
        type="button"
        onClick={handleOpenCreateModal}
        aria-label="Tambah Karyawan Baru"
        className="sm:hidden fixed bottom-20 right-4 z-40 w-14 h-14 rounded-full bg-orange-600 hover:bg-orange-700 active:scale-90 text-white shadow-[0_8px_24px_rgba(234,88,12,0.45)] flex items-center justify-center transition-transform cursor-pointer focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-orange-500/30"
      >
        <Plus className="w-7 h-7 stroke-[2.5]" aria-hidden="true" />
      </button>
    </div>
  );
}
