import { cn } from "@/lib/utils";

export type StatusType =
  | "hadir"
  | "terlambat"
  | "alpha"
  | "cuti"
  | "pulang_cepat"
  | "pending"
  | "approved"
  | "rejected"
  | "draft"
  | "finalized"
  | "on_time"
  | "menunggu"
  | "paid"
  | "holiday"
  | "disetujui"
  | "ditolak"
  | "aktif";

interface StatusBadgeProps {
  status: StatusType | string;
  label?: string;
  className?: string;
}

interface StatusConfig {
  label: string;
  classes: string;
}

const statusMap: Record<string, StatusConfig> = {
  // Kehadiran (Attendance)
  hadir: {
    label: "Hadir",
    classes: "bg-emerald-50 text-emerald-700 border border-emerald-200",
  },
  present: {
    label: "Hadir",
    classes: "bg-emerald-50 text-emerald-700 border border-emerald-200",
  },
  on_time: {
    label: "Tepat Waktu",
    classes: "bg-emerald-50 text-emerald-700 border border-emerald-200",
  },
  terlambat: {
    label: "Terlambat",
    classes: "bg-amber-50 text-amber-700 border border-amber-200",
  },
  late: {
    label: "Terlambat",
    classes: "bg-amber-50 text-amber-700 border border-amber-200",
  },
  alpha: {
    label: "Alpha",
    classes: "bg-rose-50 text-rose-700 border border-rose-200",
  },
  absent: {
    label: "Alpha",
    classes: "bg-rose-50 text-rose-700 border border-rose-200",
  },
  cuti: {
    label: "Cuti",
    classes: "bg-blue-50 text-blue-700 border border-blue-200",
  },
  leave: {
    label: "Cuti",
    classes: "bg-blue-50 text-blue-700 border border-blue-200",
  },
  pulang_cepat: {
    label: "Pulang Cepat",
    classes: "bg-amber-50 text-amber-700 border border-amber-200",
  },
  early_leave: {
    label: "Pulang Cepat",
    classes: "bg-amber-50 text-amber-700 border border-amber-200",
  },
  holiday: {
    label: "Libur",
    classes: "bg-slate-50 text-slate-700 border border-slate-200",
  },

  // Persetujuan Cuti / Approval
  pending: {
    label: "Menunggu",
    classes: "bg-amber-50 text-amber-700 border border-amber-200",
  },
  menunggu: {
    label: "Menunggu",
    classes: "bg-amber-50 text-amber-700 border border-amber-200",
  },
  approved: {
    label: "Disetujui",
    classes: "bg-emerald-50 text-emerald-700 border border-emerald-200",
  },
  disetujui: {
    label: "Disetujui",
    classes: "bg-emerald-50 text-emerald-700 border border-emerald-200",
  },
  rejected: {
    label: "Ditolak",
    classes: "bg-rose-50 text-rose-700 border border-rose-200",
  },
  ditolak: {
    label: "Ditolak",
    classes: "bg-rose-50 text-rose-700 border border-rose-200",
  },

  // Status Akun / Langganan Internal
  trial: {
    label: "Masa Uji Coba",
    classes: "bg-amber-50 text-amber-700 border border-amber-200",
  },
  active: {
    label: "Aktif",
    classes: "bg-emerald-50 text-emerald-700 border border-emerald-200",
  },
  aktif: {
    label: "Aktif",
    classes: "bg-emerald-50 text-emerald-700 border border-emerald-200",
  },
  suspended: {
    label: "Ditangguhkan",
    classes: "bg-rose-50 text-rose-700 border border-rose-200",
  },
  cancelled: {
    label: "Dibatalkan",
    classes: "bg-slate-50 text-slate-700 border border-slate-200",
  },
  expired: {
    label: "Kedaluwarsa",
    classes: "bg-rose-50 text-rose-700 border border-rose-200",
  },

  // Payroll & Status Lain
  draft: {
    label: "Draft",
    classes: "bg-slate-50 text-slate-700 border border-slate-200",
  },
  calculated: {
    label: "Dihitung",
    classes: "bg-blue-50 text-blue-700 border border-blue-200",
  },
  finalized: {
    label: "Selesai",
    classes: "bg-emerald-50 text-emerald-700 border border-emerald-200",
  },
  paid: {
    label: "Berbayar",
    classes: "bg-emerald-50 text-emerald-700 border border-emerald-200",
  },
  unpaid: {
    label: "Tidak Berbayar",
    classes: "bg-slate-50 text-slate-700 border border-slate-200",
  },
  info: {
    label: "Info",
    classes: "bg-blue-50 text-blue-700 border border-blue-200",
  },
};

export function StatusBadge({ status, label, className }: StatusBadgeProps) {
  const normalizedKey = status.toLowerCase();
  const config = statusMap[normalizedKey] || {
    label: label || status,
    classes: "bg-blue-50 text-blue-700 border border-blue-200",
  };

  return (
    <span
      className={cn(
        "inline-flex items-center px-2.5 py-0.5 text-[11px] font-semibold rounded-full tracking-tight shadow-2xs transition-colors",
        config.classes,
        className
      )}
    >
      {label || config.label}
    </span>
  );
}
