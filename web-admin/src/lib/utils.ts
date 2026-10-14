import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

/**
 * Combines Tailwind class names cleanly without collision
 */
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

/**
 * Formats a numeric amount to Indonesian Rupiah (IDR).
 * Uses non-breaking space and consistent tabular presentation (DESIGN.md Section 1.5).
 */
export function formatRupiah(amount: number | null | undefined): string {
  if (amount === null || amount === undefined || isNaN(amount)) {
    return "Rp 0";
  }

  const formattedNumber = new Intl.NumberFormat("id-ID", {
    style: "decimal",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);

  return `Rp ${formattedNumber}`;
}

/**
 * Formats date into standard Indonesian locale date string (e.g. 17 Agustus 2026)
 */
export function formatDate(dateString: string | Date | null | undefined): string {
  if (!dateString) return "-";
  const date = typeof dateString === "string" ? new Date(dateString) : dateString;
  if (isNaN(date.getTime())) return "-";

  return new Intl.DateTimeFormat("id-ID", {
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(date);
}

/**
 * Formats time string (HH:mm:ss) into HH:mm (or HH:mm WIB if includeZone is true)
 */
export function formatTime(timeString: string | null | undefined, includeZone: boolean = false): string {
  if (!timeString) return "-";
  const parts = timeString.split(":");
  if (parts.length >= 2) {
    const formatted = `${parts[0]}:${parts[1]}`;
    return includeZone ? `${formatted} WIB` : formatted;
  }
  return timeString;
}

/**
 * Returns local date in YYYY-MM-DD format based on local client device timezone.
 * Avoids UTC date-shifting bug where toISOString() in UTC+7 at 00:00-06:59 shifts to previous day.
 */
export function getLocalDateIso(date: Date = new Date()): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

/**
 * Returns local month in YYYY-MM format.
 */
export function getLocalMonthIso(date: Date = new Date()): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
}

/**
 * Formats date into relative Indonesian time string (e.g., "5 menit lalu", "2 jam lalu", "Kemarin, 14:30")
 */
export function formatRelativeTime(dateString: string | Date | null | undefined): string {
  if (!dateString) return "-";
  const date = typeof dateString === "string" ? new Date(dateString) : dateString;
  if (isNaN(date.getTime())) return "-";

  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return "Baru saja";
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${diffInMinutes} menit lalu`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${diffInHours} jam lalu`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays === 1) {
    const hours = String(date.getHours()).padStart(2, "0");
    const minutes = String(date.getMinutes()).padStart(2, "0");
    return `Kemarin, ${hours}:${minutes}`;
  }

  if (diffInDays < 7) {
    return `${diffInDays} hari lalu`;
  }

  return new Intl.DateTimeFormat("id-ID", {
    day: "numeric",
    month: "short",
    year: date.getFullYear() !== now.getFullYear() ? "numeric" : undefined,
  }).format(date);
}

