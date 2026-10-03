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
 * Formats time string (HH:mm:ss) into HH:mm WIB
 */
export function formatTime(timeString: string | null | undefined): string {
  if (!timeString) return "-";
  const parts = timeString.split(":");
  if (parts.length >= 2) {
    return `${parts[0]}:${parts[1]} WIB`;
  }
  return timeString;
}
