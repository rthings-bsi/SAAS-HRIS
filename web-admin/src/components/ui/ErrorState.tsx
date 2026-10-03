"use client";

import { AlertCircle, RotateCcw } from "lucide-react";
import { Button } from "./Button";
import { cn } from "@/lib/utils";

export interface ErrorStateProps {
  title?: string;
  message?: string;
  onRetry?: () => void;
  retryLabel?: string;
  className?: string;
}

export function ErrorState({
  title = "Terjadi Kesalahan Memuat Data",
  message = "Gagal memuat informasi dari server. Periksa koneksi internet Anda dan coba kembali.",
  onRetry,
  retryLabel = "Coba Lagi",
  className,
}: ErrorStateProps) {
  return (
    <div
      role="alert"
      className={cn(
        "flex flex-col items-center justify-center p-8 sm:p-12 text-center rounded-2xl border border-rose-200/80 bg-rose-50/70 backdrop-blur-md shadow-[0_1px_3px_rgba(0,0,0,0.03),0_1px_2px_rgba(0,0,0,0.02)]",
        className
      )}
    >
      <div className="w-14 h-14 mb-4 flex items-center justify-center rounded-2xl bg-white/90 border border-rose-200 text-rose-600 shadow-2xs">
        <AlertCircle className="w-6 h-6" aria-hidden="true" />
      </div>

      <h3 className="text-base font-semibold text-slate-900 mb-1 tracking-tight">
        {title}
      </h3>

      <p className="text-sm text-slate-600 max-w-md mb-5 leading-relaxed">
        {message}
      </p>

      {onRetry && (
        <Button
          variant="secondary"
          size="md"
          onClick={onRetry}
          leftIcon={<RotateCcw className="w-4 h-4 text-slate-600" />}
        >
          {retryLabel}
        </Button>
      )}
    </div>
  );
}
