"use client";

import React, { useState, useEffect, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Clock4,
  Plus,
  Minus,
  Trash2,
  CheckCircle2,
  AlertCircle,
  Check,
  X,
  Calendar,
  Clock,
  User as UserIcon,
  FileText,
  ExternalLink,
  Filter,
  CheckSquare,
  Timer,
  CheckCheck,
  CalendarDays,
  Edit3,
  Ban,
  AlertTriangle,
  Paperclip,
  RotateCcw,
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { Modal } from "@/components/ui/Modal";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import {
  SingleDateRangePicker,
  type DisabledDateRange,
} from "@/components/ui/SingleDateRangePicker";
import apiClient from "@/lib/axios";
import { cn, formatDate, getLocalDateIso } from "@/lib/utils";
import type { ApiResponse, OvertimeRequest, User } from "@/types";

const OVERTIME_TYPE_OPTIONS = [
  "Jam Lembur",
  "Lembur Hari Libur",
  "Lembur Sebelum Shift",
  "Lembur Setelah Shift",
];

const OVERTIME_REASON_CATEGORIES = [
  "Lembur",
  "Penyelesaian Target / Proyek",
  "Dukungan Operasional",
  "Perbaikan / Maintenance",
  "Inventaris / Audit",
];

const OVERTIME_ALLOWED_EXT = [
  "txt",
  "doc",
  "docx",
  "jpg",
  "png",
  "gif",
  "xls",
  "xlsx",
  "pdf",
  "jpeg",
];

const MAX_OVERTIME_FILE_BYTES = 5 * 1024 * 1024;

function addDaysToIso(isoDate: string, days: number): string {
  if (!isoDate) return "";
  const [y, m, d] = isoDate.split("-").map(Number);
  if (!y || !m || !d) return isoDate;
  const dt = new Date(y, m - 1, d + days);
  const yy = dt.getFullYear();
  const mm = String(dt.getMonth() + 1).padStart(2, "0");
  const dd = String(dt.getDate()).padStart(2, "0");
  return `${yy}-${mm}-${dd}`;
}

function extractAttachmentFileName(url?: string | null): string {
  if (!url) return "";
  const clean = url.split("?")[0];
  const parts = clean.split("/").filter(Boolean);
  return parts[parts.length - 1] || "Lampiran tersimpan";
}

export default function OvertimePage() {
  const queryClient = useQueryClient();

  // Role & Session State
  const [currentUser, setCurrentUser] = useState<User | null>(null);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const stored = localStorage.getItem("hris_user");
      if (stored) {
        try {
          setCurrentUser(JSON.parse(stored) as User);
        } catch {
          setCurrentUser(null);
        }
      }
    }
  }, []);

  const isEmployee = currentUser?.role === "employee";
  const canApprove =
    currentUser?.role &&
    ["owner", "hr", "manager", "superadmin", "super_admin"].includes(
      currentUser.role
    );

  // Tab State: Manager/HR can switch between Approval queue and My Requests
  const [selectedTab, setSelectedTab] = useState<"approvals" | "my-requests">(
    "approvals"
  );
  const activeTab = isEmployee ? "my-requests" : selectedTab;

  const [statusFilter, setStatusFilter] = useState<string>("all");

  // Apply Overtime Modal State
  const [isApplyOpen, setIsApplyOpen] = useState(false);
  const [applyRangeStart, setApplyRangeStart] = useState(() => getLocalDateIso());
  const [applyRangeEnd, setApplyRangeEnd] = useState(() => getLocalDateIso());
  const [applyEntries, setApplyEntries] = useState<
    Array<{ date: string; startTime: string; endTime: string }>
  >(() => [{ date: getLocalDateIso(), startTime: "17:00", endTime: "20:00" }]);
  const [extraDateInput, setExtraDateInput] = useState("");
  const [applyReason, setApplyReason] = useState("");
  const [applyError, setApplyError] = useState<string | null>(null);

  // Approval Action Modal State
  const [actionTarget, setActionTarget] = useState<OvertimeRequest | null>(null);
  const [actionType, setActionType] = useState<"approved" | "rejected" | null>(
    null
  );
  const [actionNotes, setActionNotes] = useState("");
  const [actionError, setActionError] = useState<string | null>(null);

  // Revision Overtime Modal State
  const [reviseTarget, setReviseTarget] = useState<OvertimeRequest | null>(null);
  const [reviseDate, setReviseDate] = useState("");
  const [reviseEndDate, setReviseEndDate] = useState("");
  const [reviseStartTime, setReviseStartTime] = useState("17:00");
  const [reviseEndTime, setReviseEndTime] = useState("20:00");
  const [reviseType, setReviseType] = useState<string>("Jam Lembur");
  const [reviseCategory, setReviseCategory] = useState<string>("Lembur");
  const [reviseReason, setReviseReason] = useState("");
  const [reviseAttachmentFile, setReviseAttachmentFile] = useState<File | null>(
    null
  );
  const [reviseRemoveAttachment, setReviseRemoveAttachment] = useState(false);
  const [reviseError, setReviseError] = useState<string | null>(null);

  // Cancellation Overtime Modal State
  const [cancelTarget, setCancelTarget] = useState<OvertimeRequest | null>(null);
  const [cancelReason, setCancelReason] = useState("");
  const [cancelError, setCancelError] = useState<string | null>(null);

  // Toast Notification
  const [toastNotice, setToastNotice] = useState<{
    type: "success" | "error";
    message: string;
  } | null>(null);

  const calcTimeDurationHours = (startTime: string, endTime: string): number | null => {
    if (!startTime || !endTime) return null;
    const [startH, startM] = startTime.split(":").map(Number);
    const [endH, endM] = endTime.split(":").map(Number);
    if (isNaN(startH) || isNaN(startM) || isNaN(endH) || isNaN(endM)) {
      return null;
    }
    const diff = endH * 60 + endM - (startH * 60 + startM);
    if (diff <= 0) return 0;
    return Math.round((diff / 60) * 100) / 100;
  };

  // Real-time calculated totals across all apply entries
  const applySummary = useMemo(() => {
    let totalHours = 0;
    let allValid = applyEntries.length > 0;
    for (const entry of applyEntries) {
      const h = calcTimeDurationHours(entry.startTime, entry.endTime);
      if (h === null || h <= 0) {
        allValid = false;
      } else {
        totalHours += h;
      }
    }
    return {
      count: applyEntries.length,
      totalHours: Math.round(totalHours * 100) / 100,
      allValid,
    };
  }, [applyEntries]);

  // Real-time calculated duration for revision (supports same-day or H+1 overnight)
  const calculatedReviseDuration = useMemo(() => {
    if (!reviseDate || !reviseEndDate || !reviseStartTime || !reviseEndTime) {
      return null;
    }
    const maxEnd = addDaysToIso(reviseDate, 1);
    if (reviseEndDate < reviseDate || reviseEndDate > maxEnd) {
      return {
        valid: false,
        hours: 0,
        error: "Tanggal berakhir maksimal H+1 dari tanggal mulai.",
      };
    }
    const startDt = new Date(`${reviseDate}T${reviseStartTime}:00`);
    const endDt = new Date(`${reviseEndDate}T${reviseEndTime}:00`);
    if (Number.isNaN(startDt.getTime()) || Number.isNaN(endDt.getTime())) {
      return null;
    }
    const diffMinutes = Math.round((endDt.getTime() - startDt.getTime()) / 60000);
    if (diffMinutes <= 0) {
      return {
        valid: false,
        hours: 0,
        error: "Jam selesai harus lebih akhir dari jam mulai.",
      };
    }
    if (diffMinutes > 1440) {
      return {
        valid: false,
        hours: 0,
        error: "Durasi satu sesi lembur tidak boleh melebihi 24 jam.",
      };
    }
    return {
      valid: true,
      hours: Math.round((diffMinutes / 60) * 100) / 100,
      error: null,
    };
  }, [reviseDate, reviseEndDate, reviseStartTime, reviseEndTime]);

  // Query: Data Lembur
  const {
    data: overtimeList = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: [
      activeTab === "approvals" ? "overtime-approvals" : "overtime-my-requests",
      statusFilter,
    ],
    queryFn: async () => {
      const endpoint =
        activeTab === "approvals"
          ? "/overtime/approvals"
          : "/overtime/my-requests";
      const params: Record<string, string> = {};
      if (statusFilter !== "all") {
        params.status = statusFilter;
      }

      const response = await apiClient.get<
        ApiResponse<OvertimeRequest[] | { data: OvertimeRequest[] }>
      >(endpoint, { params });

      if (response.data.success && response.data.data) {
        if (Array.isArray(response.data.data)) {
          return response.data.data;
        }
        if (
          typeof response.data.data === "object" &&
          "data" in response.data.data &&
          Array.isArray(response.data.data.data)
        ) {
          return response.data.data.data;
        }
      }
      return [];
    },
    enabled: Boolean(currentUser),
  });

  // Query: Daftar permohonan lembur mandiri untuk collision detector kalender
  const { data: myOwnOvertimeRequests = [] } = useQuery({
    queryKey: ["my-own-overtime-requests"],
    queryFn: async () => {
      const response = await apiClient.get<
        ApiResponse<OvertimeRequest[] | { data: OvertimeRequest[] }>
      >("/overtime/my-requests");
      if (response.data.success && response.data.data) {
        if (Array.isArray(response.data.data)) {
          return response.data.data;
        }
        if (
          typeof response.data.data === "object" &&
          "data" in response.data.data &&
          Array.isArray(response.data.data.data)
        ) {
          return response.data.data.data;
        }
      }
      return [];
    },
    enabled: isApplyOpen || Boolean(reviseTarget),
  });

  // Menghitung tanggal yang sudah terdaftar lembur (abu-abu dan tidak dapat diklik)
  const existingOvertimeDates = useMemo<DisabledDateRange[]>(() => {
    const sourceList = myOwnOvertimeRequests.length > 0 ? myOwnOvertimeRequests : overtimeList;
    return sourceList
      .filter((r) => {
        if (reviseTarget && r.id_overtime_requests === reviseTarget.id_overtime_requests) {
          return false;
        }
        return r.status === "approved" || r.status === "pending";
      })
      .map((r) => {
        const statusLabel = r.status === "approved" ? "Disetujui" : "Menunggu";
        const dateStr = typeof r.date === "string" ? r.date.split("T")[0] : r.date;
        const endDateStr = r.end_date
          ? (typeof r.end_date === "string" ? r.end_date.split("T")[0] : r.end_date)
          : dateStr;
        return {
          startDate: dateStr,
          endDate: endDateStr >= dateStr ? endDateStr : dateStr,
          label: `Lembur: ${r.start_time.slice(0, 5)}-${r.end_time.slice(0, 5)} (${statusLabel})`,
          status: r.status,
        };
      });
  }, [overtimeList, myOwnOvertimeRequests, reviseTarget]);

  // Mutasi: Ajukan Lembur Baru (Single atau Batch Multi-Hari)
  const applyMutation = useMutation({
    mutationFn: async (
      payload:
        | { date: string; start_time: string; end_time: string; reason: string }
        | {
            entries: Array<{ date: string; start_time: string; end_time: string }>;
            reason: string;
          }
    ) => {
      const res = await apiClient.post<
        ApiResponse<OvertimeRequest | OvertimeRequest[]>
      >("/overtime/request", payload);
      return res.data;
    },
    onSuccess: (resData) => {
      queryClient.invalidateQueries({ queryKey: ["overtime-my-requests"] });
      queryClient.invalidateQueries({ queryKey: ["my-own-overtime-requests"] });
      queryClient.invalidateQueries({ queryKey: ["overtime-approvals"] });
      setIsApplyOpen(false);
      const todayIso = getLocalDateIso();
      setApplyRangeStart(todayIso);
      setApplyRangeEnd(todayIso);
      setApplyEntries([{ date: todayIso, startTime: "17:00", endTime: "20:00" }]);
      setExtraDateInput("");
      setApplyReason("");
      setApplyError(null);
      setToastNotice({
        type: "success",
        message:
          resData?.message ||
          "Pengajuan lembur berhasil dikirim dan menunggu persetujuan atasan.",
      });
      setTimeout(() => setToastNotice(null), 4000);
    },
    onError: (err: {
      response?: { data?: { message?: string } };
      message?: string;
    }) => {
      setApplyError(
        err.response?.data?.message ||
          err.message ||
          "Gagal mengirimkan pengajuan lembur."
      );
    },
  });

  // Mutasi: Revisi Lembur (Karyawan)
  const reviseMutation = useMutation({
    mutationFn: async (payload: {
      id: number;
      date: string;
      end_date: string;
      start_time: string;
      end_time: string;
      overtime_type: string;
      reason_category: string;
      reason: string;
      attachment?: File | null;
      remove_attachment?: boolean;
    }) => {
      if (payload.attachment) {
        const formData = new FormData();
        formData.append("date", payload.date);
        formData.append("end_date", payload.end_date);
        formData.append("start_time", payload.start_time);
        formData.append("end_time", payload.end_time);
        formData.append("overtime_type", payload.overtime_type);
        formData.append("reason_category", payload.reason_category);
        formData.append("reason", payload.reason);
        formData.append("attachment", payload.attachment);
        const res = await apiClient.post<ApiResponse<OvertimeRequest>>(
          `/overtime/requests/${payload.id}/update`,
          formData,
          { headers: { "Content-Type": "multipart/form-data" } }
        );
        return res.data;
      }

      const res = await apiClient.put<ApiResponse<OvertimeRequest>>(
        `/overtime/requests/${payload.id}`,
        {
          date: payload.date,
          end_date: payload.end_date,
          start_time: payload.start_time,
          end_time: payload.end_time,
          overtime_type: payload.overtime_type,
          reason_category: payload.reason_category,
          reason: payload.reason,
          remove_attachment: Boolean(payload.remove_attachment),
        }
      );
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["overtime-my-requests"] });
      queryClient.invalidateQueries({ queryKey: ["my-own-overtime-requests"] });
      queryClient.invalidateQueries({ queryKey: ["overtime-approvals"] });
      setReviseTarget(null);
      setReviseAttachmentFile(null);
      setReviseRemoveAttachment(false);
      setReviseError(null);
      setToastNotice({
        type: "success",
        message: "Pengajuan lembur berhasil direvisi.",
      });
      setTimeout(() => setToastNotice(null), 4000);
    },
    onError: (err: {
      response?: {
        data?: { message?: string; errors?: Record<string, string[]> };
      };
      message?: string;
    }) => {
      const firstFieldError = err.response?.data?.errors
        ? Object.values(err.response.data.errors).flat()[0]
        : undefined;
      setReviseError(
        firstFieldError ||
          err.response?.data?.message ||
          err.message ||
          "Gagal merevisi pengajuan lembur."
      );
    },
  });

  // Mutasi: Batalkan Lembur (Karyawan)
  const cancelMutation = useMutation({
    mutationFn: async (payload: { id: number; reason?: string }) => {
      const res = await apiClient.post<ApiResponse<OvertimeRequest>>(
        `/overtime/requests/${payload.id}/cancel`,
        { reason: payload.reason?.trim() || null }
      );
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["overtime-my-requests"] });
      queryClient.invalidateQueries({ queryKey: ["my-own-overtime-requests"] });
      queryClient.invalidateQueries({ queryKey: ["overtime-approvals"] });
      setCancelTarget(null);
      setCancelReason("");
      setCancelError(null);
      setToastNotice({
        type: "success",
        message: "Pengajuan lembur berhasil dibatalkan.",
      });
      setTimeout(() => setToastNotice(null), 4000);
    },
    onError: (err: {
      response?: { data?: { message?: string } };
      message?: string;
    }) => {
      setCancelError(
        err.response?.data?.message ||
          err.message ||
          "Gagal membatalkan pengajuan lembur."
      );
    },
  });

  const openReviseModal = (item: OvertimeRequest) => {
    const startIso = typeof item.date === "string" ? item.date.split("T")[0] : item.date;
    const rawEnd = item.end_date
      ? (typeof item.end_date === "string" ? item.end_date.split("T")[0] : item.end_date)
      : startIso;
    const maxEnd = addDaysToIso(startIso, 1);
    const normalizedEnd = rawEnd >= startIso && rawEnd <= maxEnd ? rawEnd : startIso;

    setReviseTarget(item);
    setReviseDate(startIso);
    setReviseEndDate(normalizedEnd);
    setReviseStartTime(item.start_time.slice(0, 5));
    setReviseEndTime(item.end_time.slice(0, 5));
    setReviseType(item.overtime_type?.trim() || OVERTIME_TYPE_OPTIONS[0]);
    setReviseCategory(
      item.reason_category?.trim() || OVERTIME_REASON_CATEGORIES[0]
    );
    setReviseReason(item.reason);
    setReviseAttachmentFile(null);
    setReviseRemoveAttachment(false);
    setReviseError(null);
  };

  const handleReviseStartDateChange = (newStartIso: string) => {
    if (!newStartIso) return;
    const hadOvernightSpan = Boolean(
      reviseDate && reviseEndDate && reviseEndDate > reviseDate
    );
    setReviseDate(newStartIso);
    setReviseEndDate(hadOvernightSpan ? addDaysToIso(newStartIso, 1) : newStartIso);
    setReviseError(null);
  };

  const handleReviseAttachmentPick = (
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;

    const ext = file.name.split(".").pop()?.toLowerCase() || "";
    if (!ext || !OVERTIME_ALLOWED_EXT.includes(ext)) {
      setReviseError(
        "Format berkas tidak didukung. Gunakan txt, doc, docx, xls, xlsx, pdf, jpg, png, gif, atau jpeg."
      );
      return;
    }
    if (file.size > MAX_OVERTIME_FILE_BYTES) {
      setReviseError("Ukuran berkas melebihi batas maksimal 5 MB.");
      return;
    }
    setReviseAttachmentFile(file);
    setReviseRemoveAttachment(false);
    setReviseError(null);
  };

  const handleReviseSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!reviseTarget) return;
    setReviseError(null);

    if (
      !reviseDate ||
      !reviseEndDate ||
      !reviseStartTime ||
      !reviseEndTime ||
      !reviseReason.trim()
    ) {
      setReviseError("Harap lengkapi seluruh kolom formulir revisi lembur.");
      return;
    }

    if (reviseReason.trim().length < 5) {
      setReviseError("Uraian alasan / tugas lembur minimal 5 karakter.");
      return;
    }

    if (!calculatedReviseDuration || !calculatedReviseDuration.valid) {
      setReviseError(
        calculatedReviseDuration?.error ||
          "Jam selesai lembur harus lebih akhir dari jam mulai."
      );
      return;
    }

    reviseMutation.mutate({
      id: reviseTarget.id_overtime_requests,
      date: reviseDate,
      end_date: reviseEndDate,
      start_time: reviseStartTime,
      end_time: reviseEndTime,
      overtime_type: reviseType,
      reason_category: reviseCategory,
      reason: reviseReason.trim(),
      attachment: reviseAttachmentFile,
      remove_attachment: !reviseAttachmentFile && reviseRemoveAttachment,
    });
  };

  const openCancelModal = (item: OvertimeRequest) => {
    setCancelTarget(item);
    setCancelReason("");
    setCancelError(null);
  };

  const handleCancelSubmit = () => {
    if (!cancelTarget) return;
    cancelMutation.mutate({
      id: cancelTarget.id_overtime_requests,
      reason: cancelReason,
    });
  };

  // Mutasi: Persetujuan / Penolakan Lembur
  const actionMutation = useMutation({
    mutationFn: async ({
      id,
      action,
      notes,
    }: {
      id: number;
      action: "approved" | "rejected";
      notes?: string;
    }) => {
      const res = await apiClient.post<ApiResponse<OvertimeRequest>>(
        `/overtime/approvals/${id}/action`,
        {
          action,
          notes: notes?.trim() || null,
        }
      );
      return res.data;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["overtime-approvals"] });
      queryClient.invalidateQueries({ queryKey: ["overtime-my-requests"] });
      setActionTarget(null);
      setActionType(null);
      setActionNotes("");
      setActionError(null);
      setToastNotice({
        type: "success",
        message:
          variables.action === "approved"
            ? "Pengajuan lembur berhasil disetujui."
            : "Pengajuan lembur telah ditolak.",
      });
      setTimeout(() => setToastNotice(null), 4000);
    },
    onError: (err: {
      response?: { data?: { message?: string } };
      message?: string;
    }) => {
      setActionError(
        err.response?.data?.message ||
          err.message ||
          "Gagal memproses aksi persetujuan lembur."
      );
    },
  });

  const isDateBooked = (isoDate: string) =>
    existingOvertimeDates.some(
      (r) => r.startDate && r.endDate && isoDate >= r.startDate && isoDate <= r.endDate
    );

  const handleRangeSelection = (range: { startDate: string; endDate: string }) => {
    setApplyError(null);
    setApplyRangeStart(range.startDate);
    setApplyRangeEnd(range.endDate);

    if (!range.startDate) {
      setApplyEntries([]);
      return;
    }

    const effectiveEnd = range.endDate || range.startDate;
    const dates: string[] = [];
    const cursor = new Date(`${range.startDate}T00:00:00`);
    const endDt = new Date(`${effectiveEnd}T00:00:00`);

    while (cursor <= endDt && dates.length < 31) {
      const y = cursor.getFullYear();
      const m = String(cursor.getMonth() + 1).padStart(2, "0");
      const d = String(cursor.getDate()).padStart(2, "0");
      const iso = `${y}-${m}-${d}`;
      if (!isDateBooked(iso)) {
        dates.push(iso);
      }
      cursor.setDate(cursor.getDate() + 1);
    }

    setApplyEntries((prev) => {
      const prevMap = new Map(prev.map((item) => [item.date, item]));
      return dates.map(
        (date) => prevMap.get(date) || { date, startTime: "17:00", endTime: "20:00" }
      );
    });
  };

  const handleAddSpecificDate = () => {
    setApplyError(null);
    if (!extraDateInput) return;
    if (isDateBooked(extraDateInput)) {
      setApplyError(`Tanggal ${formatDate(extraDateInput)} sudah memiliki lembur aktif.`);
      return;
    }
    if (applyEntries.some((item) => item.date === extraDateInput)) {
      setApplyError(`Tanggal ${formatDate(extraDateInput)} sudah ada dalam daftar.`);
      return;
    }
    if (applyEntries.length >= 31) {
      setApplyError("Maksimal 31 hari lembur dalam satu pengajuan.");
      return;
    }

    const template = applyEntries[applyEntries.length - 1] || {
      startTime: "17:00",
      endTime: "20:00",
    };

    setApplyEntries((prev) =>
      [
        ...prev,
        {
          date: extraDateInput,
          startTime: template.startTime,
          endTime: template.endTime,
        },
      ].sort((a, b) => a.date.localeCompare(b.date))
    );
    setExtraDateInput("");
  };

  const updateApplyEntryTime = (
    date: string,
    field: "startTime" | "endTime",
    value: string
  ) => {
    setApplyEntries((prev) =>
      prev.map((item) => (item.date === date ? { ...item, [field]: value } : item))
    );
  };

  const stepApplyEntryDuration = (date: string, deltaMinutes: number) => {
    setApplyEntries((prev) =>
      prev.map((item) => {
        if (item.date !== date) return item;
        const [sH, sM] = item.startTime.split(":").map(Number);
        const [eH, eM] = item.endTime.split(":").map(Number);
        if (isNaN(sH) || isNaN(sM) || isNaN(eH) || isNaN(eM)) return item;
        const startMins = sH * 60 + sM;
        const endMins = eH * 60 + eM;
        const currentMins = endMins - startMins;
        const maxMins = Math.min(720, 23 * 60 + 59 - startMins);
        if (maxMins < 30) return item;

        let nextMins = currentMins;
        if (deltaMinutes < 0) {
          if (currentMins <= 30) return item;
          nextMins = Math.max(30, Math.floor((currentMins - 1) / 30) * 30);
        } else {
          if (currentMins >= maxMins) return item;
          nextMins = Math.min(maxMins, (Math.floor(currentMins / 30) + 1) * 30);
        }

        const totalEnd = startMins + nextMins;
        const newEndH = String(Math.floor(totalEnd / 60)).padStart(2, "0");
        const newEndM = String(totalEnd % 60).padStart(2, "0");
        return { ...item, endTime: `${newEndH}:${newEndM}` };
      })
    );
  };

  const removeApplyEntry = (date: string) => {
    setApplyEntries((prev) =>
      prev.length > 1 ? prev.filter((item) => item.date !== date) : prev
    );
  };

  const handleApplySubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setApplyError(null);

    if (applyEntries.length === 0 || !applyReason.trim()) {
      setApplyError("Pilih minimal 1 tanggal lembur dan isi alasan lembur.");
      return;
    }

    for (const entry of applyEntries) {
      if (isDateBooked(entry.date)) {
        setApplyError(
          `Tanggal ${formatDate(entry.date)} sudah memiliki pengajuan lembur aktif.`
        );
        return;
      }
      const hours = calcTimeDurationHours(entry.startTime, entry.endTime);
      if (hours === null || hours <= 0) {
        setApplyError(
          `Jam selesai lembur pada ${formatDate(entry.date)} harus lebih besar dari jam mulai.`
        );
        return;
      }
    }

    if (applyEntries.length === 1) {
      const single = applyEntries[0];
      applyMutation.mutate({
        date: single.date,
        start_time: single.startTime,
        end_time: single.endTime,
        reason: applyReason.trim(),
      });
      return;
    }

    applyMutation.mutate({
      entries: applyEntries.map((item) => ({
        date: item.date,
        start_time: item.startTime,
        end_time: item.endTime,
      })),
      reason: applyReason.trim(),
    });
  };

  const handleActionConfirm = () => {
    if (!actionTarget || !actionType) return;
    setActionError(null);

    if (actionType === "rejected" && !actionNotes.trim()) {
      setActionError("Alasan penolakan wajib diisi untuk penolakan lembur.");
      return;
    }

    actionMutation.mutate({
      id: actionTarget.id_overtime_requests,
      action: actionType,
      notes: actionNotes,
    });
  };

  // Metrik Ringkasan
  const stats = useMemo(() => {
    const totalApprovedHours = overtimeList
      .filter((item) => item.status === "approved")
      .reduce((acc, curr) => acc + (Number(curr.duration_hours) || 0), 0);
    const pendingCount = overtimeList.filter(
      (item) => item.status === "pending"
    ).length;
    const approvedCount = overtimeList.filter(
      (item) => item.status === "approved"
    ).length;
    const rejectedCount = overtimeList.filter(
      (item) => item.status === "rejected"
    ).length;
    const cancelledCount = overtimeList.filter(
      (item) => item.status === "cancelled"
    ).length;

    return {
      totalApprovedHours: Math.round(totalApprovedHours * 100) / 100,
      pendingCount,
      approvedCount,
      rejectedCount,
      cancelledCount,
    };
  }, [overtimeList]);

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      {/* 1. iOS Large Title & Action Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#0B2545]">
              Pengajuan Lembur
            </h1>
            <span className="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-[#DCFCE7] text-[#15803D] border border-[#BBF7D0]">
              {activeTab === "approvals" ? "Persetujuan Tim" : "Layanan Mandiri"}
            </span>
          </div>
          {canApprove && (
            <p className="text-xs sm:text-sm text-slate-500 mt-1">
              Tinjau dan proses persetujuan lembur staf untuk akumulasi otomatis upah lembur ke slip gaji.
            </p>
          )}
        </div>

        <div className="hidden sm:flex items-center gap-2 self-start sm:self-auto">
          {/* Apple HIG 48px touch target */}
          <button
            type="button"
            onClick={() => {
              setApplyError(null);
              setIsApplyOpen(true);
            }}
            className="inline-flex items-center justify-center gap-2 px-4 py-2.5 min-h-[44px] rounded-2xl bg-[#16A34A] hover:bg-[#15803D] active:scale-[0.98] text-white font-bold text-xs sm:text-sm shadow-xs transition-all cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600"
          >
            <Plus className="w-4 h-4" aria-hidden="true" />
            <span>Ajukan Lembur</span>
          </button>
        </div>
      </div>

      {/* 2. Toast Notice */}
      {toastNotice && (
        <div
          role="status"
          className={cn(
            "flex items-center justify-between p-3.5 sm:p-4 rounded-2xl text-xs sm:text-sm font-medium border shadow-[0_2px_8px_rgba(0,0,0,0.04)] transition-all",
            toastNotice.type === "success"
              ? "bg-emerald-50/90 border-emerald-200 text-emerald-800"
              : "bg-rose-50/90 border-rose-200 text-rose-800"
          )}
        >
          <div className="flex items-center gap-2.5">
            {toastNotice.type === "success" ? (
              <CheckCircle2 className="w-5 h-5 text-emerald-600 flex-shrink-0" />
            ) : (
              <AlertCircle className="w-5 h-5 text-rose-600 flex-shrink-0" />
            )}
            <span>{toastNotice.message}</span>
          </div>
          <button
            type="button"
            onClick={() => setToastNotice(null)}
            className="text-xs font-semibold hover:underline cursor-pointer ml-3"
          >
            Tutup
          </button>
        </div>
      )}

      {/* 3. Apple Fitness / Health Style KPI Metric Cards (Sembunyikan saat mode mobile) */}
      <div className="hidden sm:grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        {/* Card 1: Total Jam Disetujui */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-slate-500">
              Jam Disetujui
            </span>
            <div className="w-7 h-7 rounded-xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
              <Clock4 className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-slate-900 tabular-nums">
              {stats.totalApprovedHours}
            </span>
            <span className="text-xs text-slate-500 font-medium">Jam</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Masuk perhitungan payroll
          </div>
        </div>

        {/* Card 2: Menunggu Persetujuan */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-amber-600">
              Menunggu Keputusan
            </span>
            <div className="w-7 h-7 rounded-xl bg-amber-500/10 text-amber-600 flex items-center justify-center">
              <Timer className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-amber-700 tabular-nums">
              {stats.pendingCount}
            </span>
            <span className="text-xs text-slate-500 font-medium">Pengajuan</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Dalam proses verifikasi
          </div>
        </div>

        {/* Card 3: Disetujui */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-emerald-600">
              Lembur Disetujui
            </span>
            <div className="w-7 h-7 rounded-xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
              <CheckCircle2 className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-emerald-700 tabular-nums">
              {stats.approvedCount}
            </span>
            <span className="text-xs text-slate-500 font-medium">Selesai</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Telah tervalidasi
          </div>
        </div>

        {/* Card 4: Ditolak */}
        <div className="rounded-3xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] sm:text-xs font-semibold text-rose-600">
              Lembur Ditolak
            </span>
            <div className="w-7 h-7 rounded-xl bg-rose-500/10 text-rose-600 flex items-center justify-center">
              <X className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-1.5">
            <span className="text-xl sm:text-2xl font-extrabold font-mono tracking-tight text-rose-700 tabular-nums">
              {stats.rejectedCount}
            </span>
            <span className="text-xs text-slate-500 font-medium">Pengajuan</span>
          </div>
          <div className="mt-1 text-[11px] text-slate-400">
            Tidak disetujui
          </div>
        </div>
      </div>

      {/* 4. Controls: Role-aware Tabs & iOS Filter Pills */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        {canApprove ? (
          <div className="inline-flex p-1 bg-slate-200/60 rounded-2xl border border-slate-200/80 shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
            <button
              type="button"
              onClick={() => setSelectedTab("approvals")}
              className={cn(
                "px-3.5 py-1.5 text-xs font-semibold rounded-xl transition-all cursor-pointer flex items-center gap-1.5",
                activeTab === "approvals"
                  ? "bg-white text-slate-900 shadow-xs font-bold"
                  : "text-slate-600 hover:text-slate-900"
              )}
            >
              <CheckSquare className="w-3.5 h-3.5" />
              <span>Daftar Persetujuan</span>
            </button>
            <button
              type="button"
              onClick={() => setSelectedTab("my-requests")}
              className={cn(
                "px-3.5 py-1.5 text-xs font-semibold rounded-xl transition-all cursor-pointer flex items-center gap-1.5",
                activeTab === "my-requests"
                  ? "bg-white text-slate-900 shadow-xs font-bold"
                  : "text-slate-600 hover:text-slate-900"
              )}
            >
              <UserIcon className="w-3.5 h-3.5" />
              <span>Pengajuan Saya</span>
            </button>
          </div>
        ) : null}

        {/* Filter Pills (iOS Segmented style) */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0">
          {[
            { id: "all", label: "Semua" },
            { id: "pending", label: "Menunggu" },
            { id: "approved", label: "Disetujui" },
            { id: "rejected", label: "Ditolak" },
            { id: "cancelled", label: "Dibatalkan" },
          ].map((chip) => (
            <button
              key={chip.id}
              type="button"
              onClick={() => setStatusFilter(chip.id)}
              className={cn(
                "px-3 py-1.5 rounded-full text-xs font-semibold transition-all cursor-pointer whitespace-nowrap min-h-[36px]",
                statusFilter === chip.id
                  ? "bg-slate-900 text-white shadow-xs"
                  : "bg-white text-slate-600 hover:bg-slate-100 border border-slate-200/80"
              )}
            >
              {chip.label}
            </button>
          ))}
        </div>
      </div>

      {/* 5. Inset Grouped Card: Riwayat / Daftar Pengajuan Lembur */}
      <div className="rounded-3xl border border-slate-200/80 bg-white p-4 sm:p-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] space-y-4">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <div>
            <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
              {activeTab === "approvals"
                ? "Daftar Persetujuan Lembur Staf"
                : "Riwayat Pengajuan Lembur Saya"}
            </h2>
            <p className="text-[11px] sm:text-xs text-slate-500 mt-0.5">
              {activeTab === "approvals"
                ? "Daftar pengajuan lembur yang perlu ditinjau sebelum dikonfirmasi."
                : "Daftar jam lembur yang telah Anda ajukan beserta status atasan."}
            </p>
          </div>
          <span className="text-xs text-slate-500 font-mono tabular-nums">
            Total: <strong className="text-slate-800">{overtimeList.length}</strong> data
          </span>
        </div>

        {!currentUser || isLoading ? (
          <TableSkeleton rows={4} columns={6} />
        ) : isError ? (
          <ErrorState
            title="Gagal Memuat Data Lembur"
            message={
              (error as Error)?.message ||
              "Terjadi gangguan saat mengambil data permohonan lembur."
            }
            onRetry={() => refetch()}
          />
        ) : overtimeList.length === 0 ? (
          <EmptyState
            title="Tidak Ada Data Lembur"
            description={
              statusFilter !== "all"
                ? `Tidak ditemukan permohonan lembur dengan status "${statusFilter}".`
                : activeTab === "approvals"
                ? "Saat ini belum ada pengajuan lembur yang perlu ditinjau."
                : "Anda belum pernah mengajukan permohonan lembur."
            }
            actionLabel={activeTab === "my-requests" ? "Ajukan Lembur Baru" : undefined}
            onAction={
              activeTab === "my-requests"
                ? () => {
                    setApplyError(null);
                    setIsApplyOpen(true);
                  }
                : undefined
            }
          />
        ) : (
          <div>
            {/* 1. Mobile Inset Rows View (< sm) */}
            <div className="sm:hidden space-y-2.5">
              {overtimeList.map((item) => (
                <div
                  key={item.id_overtime_requests}
                  className="p-3.5 rounded-2xl border border-slate-200/70 bg-white hover:bg-slate-50/70 transition-colors space-y-2.5 shadow-[0_1px_2px_rgba(0,0,0,0.02)]"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center flex-shrink-0">
                        <Clock4 className="w-4 h-4" />
                      </div>
                      <div>
                        {activeTab === "approvals" && item.employee && (
                          <div className="text-xs font-bold text-slate-900 leading-tight">
                            {item.employee.user?.name || item.employee.nik}
                          </div>
                        )}
                        <div className="text-xs font-bold text-slate-900">
                          {item.end_date && item.end_date !== item.date
                            ? `${formatDate(item.date)} - ${formatDate(item.end_date)}`
                            : formatDate(item.date)}
                        </div>
                        <div className="text-[11px] text-slate-500 font-mono tabular-nums">
                          {item.start_time.slice(0, 5)} - {item.end_time.slice(0, 5)} WIB
                        </div>
                      </div>
                    </div>
                    <StatusBadge status={item.status} />
                  </div>

                  {/* Durasi & Alasan */}
                  <div className="p-2.5 rounded-xl bg-slate-50/80 border border-slate-100 text-[11.5px] space-y-1.5 font-sans">
                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">Durasi Lembur:</span>
                      <span className="font-mono font-bold text-slate-900 tabular-nums">
                        {item.duration_hours} Jam
                      </span>
                    </div>
                    {(item.overtime_type || item.reason_category) && (
                      <div className="text-[11px] text-slate-600 font-medium">
                        {[item.overtime_type, item.reason_category].filter(Boolean).join(" / ")}
                      </div>
                    )}
                    <div className="text-slate-700">
                      <span className="text-slate-400">Tugas: </span>
                      <span>{item.reason}</span>
                    </div>
                    {item.attachment_url && (
                      <a
                        href={item.attachment_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-[#1E40AF] hover:underline text-[11px] font-semibold"
                      >
                        <FileText className="w-3 h-3" />
                        <span>Lihat Lampiran</span>
                        <ExternalLink className="w-2.5 h-2.5" />
                      </a>
                    )}
                    {item.rejected_reason && (
                      <div className="text-rose-600 text-[11px] italic pt-1 border-t border-rose-100">
                        Alasan Penolakan: {item.rejected_reason}
                      </div>
                    )}
                  </div>

                  {/* Tombol Aksi Persetujuan pada Mobile */}
                  {activeTab === "approvals" &&
                    item.status === "pending" &&
                    canApprove && (
                      <div className="grid grid-cols-2 gap-2 pt-1">
                        <button
                          type="button"
                          onClick={() => {
                            setActionTarget(item);
                            setActionType("approved");
                            setActionNotes("");
                            setActionError(null);
                          }}
                          className="min-h-[40px] rounded-xl bg-emerald-600 hover:bg-emerald-700 active:scale-[0.98] text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-2xs transition-all cursor-pointer"
                        >
                          <Check className="w-3.5 h-3.5" />
                          <span>Setujui</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setActionTarget(item);
                            setActionType("rejected");
                            setActionNotes("");
                            setActionError(null);
                          }}
                          className="min-h-[40px] rounded-xl bg-rose-600 hover:bg-rose-700 active:scale-[0.98] text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-2xs transition-all cursor-pointer"
                        >
                          <X className="w-3.5 h-3.5" />
                          <span>Tolak</span>
                        </button>
                      </div>
                    )}

                  {/* Tombol Aksi Karyawan pada Mobile (Revisi & Batalkan) */}
                  {activeTab === "my-requests" && item.status === "pending" && (
                    <div className="grid grid-cols-2 gap-2 pt-1">
                      <button
                        type="button"
                        onClick={() => openReviseModal(item)}
                        className="min-h-[40px] rounded-xl bg-slate-100 hover:bg-slate-200 active:scale-[0.98] text-slate-800 font-bold text-xs flex items-center justify-center gap-1.5 border border-slate-200 transition-all cursor-pointer"
                      >
                        <Edit3 className="w-3.5 h-3.5 text-slate-600" />
                        <span>Revisi</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => openCancelModal(item)}
                        className="min-h-[40px] rounded-xl bg-rose-50 hover:bg-rose-100 active:scale-[0.98] text-rose-700 font-bold text-xs flex items-center justify-center gap-1.5 border border-rose-200 transition-all cursor-pointer"
                      >
                        <Ban className="w-3.5 h-3.5 text-rose-600" />
                        <span>Batalkan</span>
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>

            {/* 2. Desktop Table View (>= sm) */}
            <div className="hidden sm:block overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200/80 text-slate-500 uppercase tracking-wider font-semibold">
                    {activeTab === "approvals" && <th className="px-4 py-3">Karyawan</th>}
                    <th className="px-4 py-3">Tanggal Lembur</th>
                    <th className="px-4 py-3 font-mono">Waktu Mulai - Selesai</th>
                    <th className="px-4 py-3 text-center font-mono">Durasi</th>
                    <th className="px-4 py-3">Uraian Tugas Lembur</th>
                    <th className="px-4 py-3 text-center">Status</th>
                    <th className="px-4 py-3 text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {overtimeList.map((item) => (
                    <tr
                      key={item.id_overtime_requests}
                      className="hover:bg-slate-50/60 transition-colors"
                    >
                      {activeTab === "approvals" && (
                        <td className="px-4 py-3.5">
                          <div className="font-bold text-slate-900">
                            {item.employee?.user?.name || item.employee?.nik || "-"}
                          </div>
                          <div className="text-[11px] text-slate-400 font-mono">
                            {item.employee?.department?.name || "Karyawan"}
                          </div>
                        </td>
                      )}
                      <td className="px-4 py-3.5 font-bold text-slate-900">
                        <div>{formatDate(item.date)}</div>
                        {item.end_date && item.end_date !== item.date && (
                          <div className="text-[11px] font-normal text-slate-500">
                            s.d. {formatDate(item.end_date)}
                          </div>
                        )}
                      </td>
                      <td className="px-4 py-3.5 text-slate-600 font-mono tabular-nums">
                        {item.start_time.slice(0, 5)} - {item.end_time.slice(0, 5)} WIB
                      </td>
                      <td className="px-4 py-3.5 text-center font-mono font-bold text-slate-900 tabular-nums">
                        {item.duration_hours} Jam
                      </td>
                      <td className="px-4 py-3.5 text-slate-600 max-w-xs">
                        {(item.overtime_type || item.reason_category) && (
                          <div className="text-[11px] font-semibold text-slate-700 mb-0.5">
                            {[item.overtime_type, item.reason_category].filter(Boolean).join(" / ")}
                          </div>
                        )}
                        <div className="truncate">{item.reason}</div>
                        {item.attachment_url && (
                          <a
                            href={item.attachment_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1 text-[#1E40AF] hover:underline text-[11px] mt-0.5 font-semibold"
                          >
                            <FileText className="w-3 h-3" />
                            <span>Lampiran</span>
                            <ExternalLink className="w-2.5 h-2.5" />
                          </a>
                        )}
                        {item.rejected_reason && (
                          <div className="text-[11px] text-rose-600 mt-0.5 italic">
                            Catatan: {item.rejected_reason}
                          </div>
                        )}
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <StatusBadge status={item.status} />
                      </td>
                      <td className="px-4 py-3.5 text-right">
                        {activeTab === "approvals" ? (
                          item.status === "pending" && canApprove ? (
                            <div className="inline-flex items-center gap-1.5">
                              <button
                                type="button"
                                onClick={() => {
                                  setActionTarget(item);
                                  setActionType("approved");
                                  setActionNotes("");
                                  setActionError(null);
                                }}
                                className="px-2.5 py-1.5 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 font-bold text-xs flex items-center gap-1 border border-emerald-200 transition-colors cursor-pointer"
                              >
                                <Check className="w-3 h-3" />
                                <span>Setujui</span>
                              </button>
                              <button
                                type="button"
                                onClick={() => {
                                  setActionTarget(item);
                                  setActionType("rejected");
                                  setActionNotes("");
                                  setActionError(null);
                                }}
                                className="px-2.5 py-1.5 rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-700 font-bold text-xs flex items-center gap-1 border border-rose-200 transition-colors cursor-pointer"
                              >
                                <X className="w-3 h-3" />
                                <span>Tolak</span>
                              </button>
                            </div>
                          ) : (
                            <span className="text-xs text-slate-400 italic">
                              {item.approver?.name
                                ? `Oleh ${item.approver.name}`
                                : item.status === "cancelled"
                                ? "Dibatalkan"
                                : "Selesai"}
                            </span>
                          )
                        ) : item.status === "pending" ? (
                          <div className="inline-flex items-center gap-1.5">
                            <button
                              type="button"
                              onClick={() => openReviseModal(item)}
                              className="px-2.5 py-1.5 rounded-lg bg-slate-50 hover:bg-slate-100 text-slate-700 font-bold text-xs flex items-center gap-1 border border-slate-200 transition-colors cursor-pointer"
                              title="Revisi jadwal atau tugas lembur"
                            >
                              <Edit3 className="w-3 h-3 text-slate-600" />
                              <span>Revisi</span>
                            </button>
                            <button
                              type="button"
                              onClick={() => openCancelModal(item)}
                              className="px-2.5 py-1.5 rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-700 font-bold text-xs flex items-center gap-1 border border-rose-200 transition-colors cursor-pointer"
                              title="Batalkan pengajuan lembur ini"
                            >
                              <Ban className="w-3 h-3 text-rose-600" />
                              <span>Batalkan</span>
                            </button>
                          </div>
                        ) : (
                          <span className="text-xs text-slate-400 italic">
                            {item.status === "cancelled"
                              ? "Dibatalkan"
                              : item.approver?.name
                              ? `Disetujui ${item.approver.name}`
                              : "-"}
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* 6. Modal Ajukan Lembur Baru (Apple HIG Sheet Style) */}
      {isApplyOpen && (
        <Modal
          isOpen={true}
          onClose={() => {
            if (!applyMutation.isPending) {
              setIsApplyOpen(false);
              setApplyError(null);
            }
          }}
          title="Ajukan Permohonan Lembur"
          description="Pastikan jadwal lembur yang diajukan tidak bertabrakan dengan jadwal lainnya."
          maxWidth="lg"
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => {
                  setIsApplyOpen(false);
                  setApplyError(null);
                }}
                disabled={applyMutation.isPending}
                className="min-h-[44px] rounded-xl"
              >
                Batal
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={handleApplySubmit}
                isLoading={applyMutation.isPending}
                className="min-h-[44px] rounded-xl bg-[#16A34A] hover:bg-[#15803D] font-bold"
              >
                {applyEntries.length > 1
                  ? `Kirim ${applyEntries.length} Pengajuan`
                  : "Kirim Pengajuan"}
              </Button>
            </div>
          }
        >
          <form onSubmit={handleApplySubmit} className="space-y-4 text-xs">
            {applyError && (
              <div
                role="alert"
                className="p-3.5 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 font-medium"
              >
                {applyError}
              </div>
            )}

            <div>
              <SingleDateRangePicker
                singleDateMode={false}
                label="Pilih Tanggal / Rentang Lembur"
                required={true}
                startDate={applyRangeStart}
                endDate={applyRangeEnd}
                onChange={handleRangeSelection}
                disabledRanges={existingOvertimeDates}
              />
            </div>

            <div className="flex flex-col sm:flex-row sm:items-end gap-2">
              <div className="flex-1">
                <label
                  htmlFor="extra_overtime_date"
                  className="block text-xs font-semibold text-slate-700 mb-1"
                >
                  Atau Tambah Tanggal Spesifik
                </label>
                <input
                  id="extra_overtime_date"
                  type="date"
                  value={extraDateInput}
                  onChange={(e) => setExtraDateInput(e.target.value)}
                  className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs text-slate-900 min-h-[44px] focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600"
                />
              </div>
              <Button
                type="button"
                variant="secondary"
                size="md"
                onClick={handleAddSpecificDate}
                disabled={!extraDateInput}
                className="min-h-[44px] rounded-xl shrink-0"
              >
                <Plus className="w-3.5 h-3.5 mr-1" aria-hidden="true" />
                Tambah Tanggal
              </Button>
            </div>

            {/* Daftar Jadwal & Pengaturan Jam Per Hari */}
            <div className="space-y-2.5">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-700">
                  Pengaturan Jam Lembur Per Hari
                </span>
                <span className="px-2 py-0.5 rounded-md bg-slate-100 text-slate-700 font-semibold text-[11px]">
                  {applyEntries.length} Hari
                </span>
              </div>

              {applyEntries.length === 0 ? (
                <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-600 text-xs">
                  Pilih tanggal atau rentang tanggal pada kalender di atas untuk mengatur jam lembur harian.
                </div>
              ) : (
                <div className="divide-y divide-slate-200 border border-slate-200 rounded-xl bg-white max-h-64 overflow-y-auto">
                  {applyEntries.map((entry) => {
                    const hours = calcTimeDurationHours(entry.startTime, entry.endTime);
                    const isValid = hours !== null && hours > 0;
                    return (
                      <div key={entry.date} className="p-3 space-y-2.5">
                        <div className="flex items-center justify-between gap-2">
                          <span className="font-semibold text-slate-900 text-xs">
                            {formatDate(entry.date)}
                          </span>
                          <div className="flex items-center gap-1.5">
                            <button
                              type="button"
                              onClick={() => stepApplyEntryDuration(entry.date, -30)}
                              aria-label={`Kurangi durasi lembur ${entry.date}`}
                              className="w-8 h-8 rounded-lg border border-slate-200 bg-slate-50 hover:bg-slate-100 flex items-center justify-center text-slate-700 cursor-pointer"
                            >
                              <Minus className="w-3.5 h-3.5" />
                            </button>
                            <span
                              className={cn(
                                "min-w-[64px] text-center font-mono font-bold text-xs px-2 py-1 rounded-lg",
                                isValid
                                  ? "bg-emerald-50 text-emerald-700"
                                  : "bg-rose-50 text-rose-700"
                              )}
                            >
                              {isValid ? `${hours} jam` : "0 jam"}
                            </span>
                            <button
                              type="button"
                              onClick={() => stepApplyEntryDuration(entry.date, 30)}
                              aria-label={`Tambah durasi lembur ${entry.date}`}
                              className="w-8 h-8 rounded-lg border border-slate-200 bg-slate-50 hover:bg-slate-100 flex items-center justify-center text-slate-700 cursor-pointer"
                            >
                              <Plus className="w-3.5 h-3.5" />
                            </button>
                            {applyEntries.length > 1 && (
                              <button
                                type="button"
                                onClick={() => removeApplyEntry(entry.date)}
                                aria-label={`Hapus tanggal ${entry.date}`}
                                className="w-8 h-8 rounded-lg text-rose-700 hover:bg-rose-50 flex items-center justify-center cursor-pointer ml-1"
                              >
                                <Trash2 className="w-3.5 h-3.5" />
                              </button>
                            )}
                          </div>
                        </div>

                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                          <div>
                            <label
                              htmlFor={`overtime_start_${entry.date}`}
                              className="block text-[11px] font-medium text-slate-600 mb-1"
                            >
                              Jam Mulai
                            </label>
                            <input
                              id={`overtime_start_${entry.date}`}
                              type="time"
                              value={entry.startTime}
                              onChange={(e) =>
                                updateApplyEntryTime(entry.date, "startTime", e.target.value)
                              }
                              className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 min-h-[40px]"
                              required
                            />
                          </div>

                          <div>
                            <label
                              htmlFor={`overtime_end_${entry.date}`}
                              className="block text-[11px] font-medium text-slate-600 mb-1"
                            >
                              Jam Selesai
                            </label>
                            <input
                              id={`overtime_end_${entry.date}`}
                              type="time"
                              value={entry.endTime}
                              onChange={(e) =>
                                updateApplyEntryTime(entry.date, "endTime", e.target.value)
                              }
                              className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 min-h-[40px]"
                              required
                            />
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Total Durasi Terkalkulasi Otomatis */}
            <div className="p-3.5 rounded-2xl bg-emerald-50/70 border border-emerald-200/80 flex items-center justify-between text-xs">
              <span className="text-slate-700 font-semibold">
                {applySummary.count > 1
                  ? `Total Pengajuan (${applySummary.count} Hari):`
                  : "Estimasi Durasi Lembur:"}
              </span>
              <span
                className={cn(
                  "font-mono font-extrabold tabular-nums",
                  applySummary.allValid ? "text-emerald-700 text-sm" : "text-rose-600"
                )}
              >
                {applySummary.allValid
                  ? `${applySummary.totalHours} Jam (${Math.round(applySummary.totalHours * 60)} menit)`
                  : "Periksa jam lembur tiap hari"}
              </span>
            </div>

            <div>
              <label
                htmlFor="overtime_reason"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Uraian Alasan / Tugas Lembur <span className="text-rose-500">*</span>
              </label>
              <textarea
                id="overtime_reason"
                value={applyReason}
                onChange={(e) => setApplyReason(e.target.value)}
                placeholder="Tuliskan rincian tugas lembur yang dikerjakan secara spesifik..."
                rows={3}
                className="w-full rounded-2xl border border-slate-200/80 bg-white p-3.5 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600"
                required
              />
            </div>
          </form>
        </Modal>
      )}

      {/* 6b. Modal Revisi Lembur (Karyawan) */}
      {reviseTarget && (
        <Modal
          isOpen={true}
          onClose={() => {
            if (!reviseMutation.isPending) {
              setReviseTarget(null);
              setReviseAttachmentFile(null);
              setReviseRemoveAttachment(false);
              setReviseError(null);
            }
          }}
          title="Revisi Pengajuan Lembur"
          description="Perbarui jadwal, klasifikasi lembur, keterangan, atau lampiran sebelum pengajuan disetujui."
          maxWidth="lg"
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => {
                  setReviseTarget(null);
                  setReviseAttachmentFile(null);
                  setReviseRemoveAttachment(false);
                  setReviseError(null);
                }}
                disabled={reviseMutation.isPending}
                className="min-h-[44px] rounded-md"
              >
                Batal
              </Button>
              <Button
                variant="primary"
                size="md"
                onClick={handleReviseSubmit}
                isLoading={reviseMutation.isPending}
                className="min-h-[44px] rounded-md bg-[#1E40AF] hover:bg-[#1D3A9E] text-white font-semibold"
              >
                Simpan Revisi
              </Button>
            </div>
          }
        >
          <form onSubmit={handleReviseSubmit} className="space-y-4 text-xs">
            {reviseError && (
              <div
                role="alert"
                className="p-3 rounded-lg bg-[#FEF2F2] border border-red-200 text-[#B91C1C] font-medium"
              >
                {reviseError}
              </div>
            )}

            <div>
              <SingleDateRangePicker
                singleDateMode={true}
                label="Tanggal Mulai Lembur"
                required={true}
                defaultExpanded={false}
                startDate={reviseDate}
                endDate={reviseDate}
                onChange={(range) => handleReviseStartDateChange(range.startDate)}
                disabledRanges={existingOvertimeDates}
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label
                  htmlFor="revise_end_date"
                  className="block text-xs font-semibold text-[#0F172A] mb-1.5"
                >
                  Tanggal Berakhir <span className="text-[#B91C1C]">*</span>
                </label>
                <input
                  id="revise_end_date"
                  type="date"
                  value={reviseEndDate}
                  min={reviseDate}
                  max={addDaysToIso(reviseDate, 1)}
                  onChange={(e) => {
                    setReviseEndDate(e.target.value);
                    setReviseError(null);
                  }}
                  className="w-full rounded-md border border-[#CBD5E1] bg-white px-3 py-2 text-xs font-mono text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-[#1E40AF]/20 focus:border-[#1E40AF] min-h-[44px]"
                  required
                />
              </div>

              <div>
                <label
                  htmlFor="revise_start_time"
                  className="block text-xs font-semibold text-[#0F172A] mb-1.5"
                >
                  Jam Mulai <span className="text-[#B91C1C]">*</span>
                </label>
                <input
                  id="revise_start_time"
                  type="time"
                  value={reviseStartTime}
                  onChange={(e) => {
                    setReviseStartTime(e.target.value);
                    setReviseError(null);
                  }}
                  className="w-full rounded-md border border-[#CBD5E1] bg-white px-3 py-2 text-xs font-mono text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-[#1E40AF]/20 focus:border-[#1E40AF] min-h-[44px]"
                  required
                />
              </div>

              <div>
                <label
                  htmlFor="revise_end_time"
                  className="block text-xs font-semibold text-[#0F172A] mb-1.5"
                >
                  Jam Selesai <span className="text-[#B91C1C]">*</span>
                </label>
                <input
                  id="revise_end_time"
                  type="time"
                  value={reviseEndTime}
                  onChange={(e) => {
                    setReviseEndTime(e.target.value);
                    setReviseError(null);
                  }}
                  className="w-full rounded-md border border-[#CBD5E1] bg-white px-3 py-2 text-xs font-mono text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-[#1E40AF]/20 focus:border-[#1E40AF] min-h-[44px]"
                  required
                />
              </div>
            </div>

            {/* Durasi Terkalkulasi Otomatis */}
            <div className="p-3.5 rounded-lg bg-[#F8FAFC] border border-[#CBD5E1] flex flex-wrap items-center justify-between gap-2 text-xs">
              <div className="text-[#475569] font-semibold">
                Estimasi Durasi Lembur
                {reviseEndDate > reviseDate ? " (Lintas Hari H+1)" : ""}:
              </div>
              <span
                className={cn(
                  "font-mono font-bold tabular-nums",
                  calculatedReviseDuration?.valid
                    ? "text-[#1E40AF] text-sm"
                    : "text-[#B91C1C]"
                )}
              >
                {calculatedReviseDuration?.valid
                  ? `${calculatedReviseDuration.hours} Jam (${Math.round(
                      calculatedReviseDuration.hours * 60
                    )} menit)`
                  : calculatedReviseDuration?.error || "Format waktu tidak valid"}
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label
                  htmlFor="revise_overtime_type"
                  className="block text-xs font-semibold text-[#0F172A] mb-1.5"
                >
                  Tipe Lembur
                </label>
                <select
                  id="revise_overtime_type"
                  value={reviseType}
                  onChange={(e) => setReviseType(e.target.value)}
                  className="w-full rounded-md border border-[#CBD5E1] bg-white px-3 py-2 text-xs text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-[#1E40AF]/20 focus:border-[#1E40AF] min-h-[44px]"
                >
                  {(OVERTIME_TYPE_OPTIONS.includes(reviseType)
                    ? OVERTIME_TYPE_OPTIONS
                    : [...OVERTIME_TYPE_OPTIONS, reviseType]
                  ).map((opt) => (
                    <option key={opt} value={opt}>
                      {opt}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label
                  htmlFor="revise_reason_category"
                  className="block text-xs font-semibold text-[#0F172A] mb-1.5"
                >
                  Alasan Lembur
                </label>
                <select
                  id="revise_reason_category"
                  value={reviseCategory}
                  onChange={(e) => setReviseCategory(e.target.value)}
                  className="w-full rounded-md border border-[#CBD5E1] bg-white px-3 py-2 text-xs text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-[#1E40AF]/20 focus:border-[#1E40AF] min-h-[44px]"
                >
                  {(OVERTIME_REASON_CATEGORIES.includes(reviseCategory)
                    ? OVERTIME_REASON_CATEGORIES
                    : [...OVERTIME_REASON_CATEGORIES, reviseCategory]
                  ).map((opt) => (
                    <option key={opt} value={opt}>
                      {opt}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label
                  htmlFor="revise_reason"
                  className="block text-xs font-semibold text-[#0F172A]"
                >
                  Keterangan <span className="text-[#B91C1C]">*</span>
                </label>
                <span className="text-[11px] font-mono tabular-nums text-[#475569]">
                  {reviseReason.length}/1000
                </span>
              </div>
              <textarea
                id="revise_reason"
                value={reviseReason}
                maxLength={1000}
                onChange={(e) => setReviseReason(e.target.value)}
                placeholder="Tuliskan rincian tugas lembur yang direvisi..."
                rows={3}
                className="w-full rounded-md border border-[#CBD5E1] bg-white p-3 text-xs text-[#0F172A] placeholder:text-[#475569] focus:outline-none focus:ring-2 focus:ring-[#1E40AF]/20 focus:border-[#1E40AF]"
                required
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#0F172A] mb-1.5">
                Lampiran (Opsional)
              </label>
              <div className="rounded-lg border border-dashed border-[#CBD5E1] bg-[#F8FAFC] p-3.5 space-y-2.5">
                {reviseAttachmentFile ? (
                  <div className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-2 min-w-0">
                      <Paperclip
                        className="w-4 h-4 text-[#1E40AF] shrink-0"
                        aria-hidden="true"
                      />
                      <div className="min-w-0">
                        <div className="font-semibold text-[#0F172A] truncate">
                          {reviseAttachmentFile.name}
                        </div>
                        <div className="text-[11px] text-[#475569] font-mono tabular-nums">
                          {reviseAttachmentFile.size < 1024 * 1024
                            ? `${Math.max(
                                1,
                                Math.round(reviseAttachmentFile.size / 1024)
                              )} KB`
                            : `${(
                                reviseAttachmentFile.size /
                                (1024 * 1024)
                              ).toFixed(1)} MB`}
                        </div>
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={() => setReviseAttachmentFile(null)}
                      className="min-h-[44px] px-3 rounded-md border border-[#CBD5E1] bg-white hover:bg-slate-50 text-[#B91C1C] font-semibold text-xs inline-flex items-center gap-1 cursor-pointer shrink-0"
                    >
                      <X className="w-3.5 h-3.5" aria-hidden="true" />
                      <span>Hapus</span>
                    </button>
                  </div>
                ) : !reviseRemoveAttachment && reviseTarget.attachment_url ? (
                  <div className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-2 min-w-0 flex-1">
                      <Paperclip
                        className="w-4 h-4 text-[#1E40AF] shrink-0"
                        aria-hidden="true"
                      />
                      <div className="min-w-0 flex-1">
                        <div className="font-semibold text-[#0F172A] truncate">
                          {extractAttachmentFileName(reviseTarget.attachment_url)}
                        </div>
                        <div className="text-[11px] text-[#475569]">
                          Lampiran tersimpan saat ini
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <a
                        href={reviseTarget.attachment_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="min-h-[44px] px-3 rounded-md border border-[#CBD5E1] bg-white hover:bg-slate-50 text-[#1E40AF] font-semibold text-xs inline-flex items-center gap-1"
                      >
                        <span>Lihat</span>
                        <ExternalLink className="w-3 h-3" aria-hidden="true" />
                      </a>
                      <button
                        type="button"
                        onClick={() => setReviseRemoveAttachment(true)}
                        className="min-h-[44px] px-3 rounded-md border border-red-200 bg-white hover:bg-[#FEF2F2] text-[#B91C1C] font-semibold text-xs inline-flex items-center gap-1 cursor-pointer"
                      >
                        <X className="w-3.5 h-3.5" aria-hidden="true" />
                        <span>Hapus</span>
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-2">
                    <div className="flex flex-wrap items-center gap-2">
                      <label
                        htmlFor="revise_attachment_input"
                        className="min-h-[44px] px-4 rounded-md border border-[#CBD5E1] bg-white hover:bg-slate-50 text-[#1E40AF] font-semibold text-xs inline-flex items-center gap-1.5 cursor-pointer"
                      >
                        <Plus className="w-3.5 h-3.5" aria-hidden="true" />
                        <span>Pilih File</span>
                      </label>
                      <input
                        id="revise_attachment_input"
                        type="file"
                        accept=".txt,.doc,.docx,.jpg,.png,.gif,.xls,.xlsx,.pdf,.jpeg"
                        onChange={handleReviseAttachmentPick}
                        className="sr-only"
                      />
                      {reviseRemoveAttachment && reviseTarget.attachment_url && (
                        <button
                          type="button"
                          onClick={() => setReviseRemoveAttachment(false)}
                          className="min-h-[44px] px-3 rounded-md border border-[#CBD5E1] bg-white hover:bg-slate-50 text-[#1E40AF] font-semibold text-xs inline-flex items-center gap-1.5 cursor-pointer"
                        >
                          <RotateCcw className="w-3.5 h-3.5" aria-hidden="true" />
                          <span>Batalkan Hapus</span>
                        </button>
                      )}
                    </div>
                    {reviseRemoveAttachment && reviseTarget.attachment_url && (
                      <p className="text-[11px] font-medium text-[#A16207]">
                        Lampiran sebelumnya (
                        {extractAttachmentFileName(reviseTarget.attachment_url)})
                        akan dihapus saat revisi disimpan.
                      </p>
                    )}
                    <p className="text-[11px] text-[#475569]">
                      Format didukung: txt, doc, docx, jpg, png, gif, xls, xlsx, pdf, jpeg (maks. 5 MB).
                    </p>
                  </div>
                )}
              </div>
            </div>
          </form>
        </Modal>
      )}

      {/* 6c. Modal Batalkan Lembur (Karyawan) */}
      {cancelTarget && (
        <Modal
          isOpen={true}
          onClose={() => {
            if (!cancelMutation.isPending) {
              setCancelTarget(null);
              setCancelReason("");
              setCancelError(null);
            }
          }}
          title="Batalkan Pengajuan Lembur"
          description={`Apakah Anda yakin ingin membatalkan pengajuan lembur tanggal ${formatDate(cancelTarget.date)}?`}
          maxWidth="md"
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => {
                  setCancelTarget(null);
                  setCancelReason("");
                  setCancelError(null);
                }}
                disabled={cancelMutation.isPending}
                className="min-h-[44px] rounded-xl"
              >
                Kembali
              </Button>
              <Button
                variant="danger"
                size="md"
                onClick={handleCancelSubmit}
                isLoading={cancelMutation.isPending}
                className="min-h-[44px] rounded-xl font-bold bg-rose-600 hover:bg-rose-700"
              >
                Ya, Batalkan Lembur
              </Button>
            </div>
          }
        >
          <div className="space-y-4 text-xs">
            {cancelError && (
              <div
                role="alert"
                className="p-3.5 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 font-medium"
              >
                {cancelError}
              </div>
            )}

            <div className="p-3.5 rounded-2xl bg-amber-50 border border-amber-200 text-amber-800 space-y-1">
              <div className="font-bold">Perhatian</div>
              <p className="text-[11.5px] leading-relaxed">
                Pengajuan yang telah dibatalkan tidak akan diproses lebih lanjut oleh atasan dan statusnya tidak dapat dikembalikan.
              </p>
            </div>

            <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100 space-y-1.5 font-sans">
              <div className="flex justify-between">
                <span className="text-slate-500">Tanggal:</span>
                <span className="font-bold text-slate-900">
                  {formatDate(cancelTarget.date)}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Jam Lembur:</span>
                <span className="font-mono font-bold text-slate-900">
                  {cancelTarget.start_time.slice(0, 5)} - {cancelTarget.end_time.slice(0, 5)} WIB ({cancelTarget.duration_hours} Jam)
                </span>
              </div>
              <div className="text-slate-600 pt-1 border-t border-slate-200/60">
                <span className="text-slate-400">Tugas: </span>
                <span>{cancelTarget.reason}</span>
              </div>
            </div>

            <div>
              <label
                htmlFor="cancelReasonInput"
                className="block text-xs font-semibold text-slate-700 mb-1.5"
              >
                Alasan Pembatalan <span className="text-slate-400 font-normal">(opsional)</span>
              </label>
              <textarea
                id="cancelReasonInput"
                rows={3}
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
                placeholder="Contoh: Pekerjaan selesai lebih awal, perubahan jadwal proyek..."
                className="w-full rounded-2xl border border-slate-200/80 bg-white p-3.5 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
              />
            </div>
          </div>
        </Modal>
      )}

      {/* 7. Modal Konfirmasi Persetujuan / Penolakan (Admin / HR) */}
      {actionTarget && actionType && (
        <Modal
          isOpen={true}
          onClose={() => {
            if (!actionMutation.isPending) {
              setActionTarget(null);
              setActionType(null);
              setActionNotes("");
              setActionError(null);
            }
          }}
          title={
            actionType === "approved"
              ? "Konfirmasi Persetujuan Lembur"
              : "Konfirmasi Penolakan Lembur"
          }
          description={`Pengajuan dari ${
            actionTarget.employee?.user?.name || "Karyawan"
          } untuk lembur selama ${actionTarget.duration_hours} jam.`}
          maxWidth="md"
          footer={
            <div className="flex items-center justify-end gap-2 w-full">
              <Button
                variant="secondary"
                size="md"
                onClick={() => {
                  setActionTarget(null);
                  setActionType(null);
                  setActionNotes("");
                  setActionError(null);
                }}
                disabled={actionMutation.isPending}
                className="min-h-[44px] rounded-xl"
              >
                Batal
              </Button>
              <Button
                variant={actionType === "approved" ? "primary" : "danger"}
                size="md"
                onClick={handleActionConfirm}
                isLoading={actionMutation.isPending}
                className="min-h-[44px] rounded-xl font-bold"
              >
                {actionType === "approved" ? "Setujui Lembur" : "Tolak Lembur"}
              </Button>
            </div>
          }
        >
          <div className="space-y-4 text-xs">
            {actionError && (
              <div
                role="alert"
                className="p-3.5 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 font-medium"
              >
                {actionError}
              </div>
            )}

            <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100 space-y-1.5 font-sans">
              <div className="flex justify-between">
                <span className="text-slate-500">Tanggal:</span>
                <span className="font-bold text-slate-900">
                  {formatDate(actionTarget.date)}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Waktu:</span>
                <span className="font-mono font-bold text-slate-900">
                  {actionTarget.start_time.slice(0, 5)} - {actionTarget.end_time.slice(0, 5)} WIB ({actionTarget.duration_hours} Jam)
                </span>
              </div>
              <div className="text-slate-600 pt-1 border-t border-slate-200/60">
                <span className="text-slate-400">Tugas: </span>
                <span>{actionTarget.reason}</span>
              </div>
            </div>

            {actionType === "rejected" && (
              <div>
                <label
                  htmlFor="actionNotesInput"
                  className="block text-xs font-semibold text-slate-700 mb-1.5"
                >
                  Alasan Penolakan <span className="text-rose-500">*</span>
                </label>
                <textarea
                  id="actionNotesInput"
                  rows={3}
                  value={actionNotes}
                  onChange={(e) => setActionNotes(e.target.value)}
                  placeholder="Tuliskan catatan alasan penolakan..."
                  className="w-full rounded-2xl border border-slate-200/80 bg-white p-3.5 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
                  required
                />
              </div>
            )}
          </div>
        </Modal>
      )}

      {/* Floating Action Button (FAB) + Mobile */}
      <button
        type="button"
        onClick={() => {
          setApplyError(null);
          setIsApplyOpen(true);
        }}
        aria-label="Ajukan Lembur"
        className="sm:hidden fixed bottom-20 right-4 z-40 w-14 h-14 rounded-full bg-[#16A34A] hover:bg-[#15803D] active:scale-90 text-white shadow-[0_8px_24px_rgba(22,163,74,0.35)] flex items-center justify-center transition-transform cursor-pointer focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-emerald-500/30"
      >
        <Plus className="w-7 h-7 stroke-[2.5]" aria-hidden="true" />
      </button>
    </div>
  );
}
